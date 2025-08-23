package DBIx::QuickORM::Dialect::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000019';

use Carp qw/croak/;
use DBIx::QuickORM::Util qw/column_key/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

use parent 'DBIx::QuickORM::Dialect';
use DBIx::QuickORM::Util::HashBase;

sub dbi_driver   { 'DBD::Pg' }
sub dialect_name { 'PostgreSQL' }

sub quote_binary_data { { pg_type => DBD::Pg::PG_BYTEA() } }

sub supports_returning_update { 1 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

sub async_supported        { 1 }
sub async_cancel_supported { 1 }
sub async_prepare_args     { pg_async => DBD::Pg::PG_ASYNC() }
sub async_result           { my ($s, %p) = @_; $p{sth}->pg_result() }
sub async_ready            { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->pg_ready() }
sub async_cancel           { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->pg_cancel() }

sub start_txn          { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->begin_work }
sub commit_txn         { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->commit }
sub rollback_txn       { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->rollback }
sub create_savepoint   { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->pg_savepoint($p{savepoint}) }
sub commit_savepoint   { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->pg_release($p{savepoint}) }
sub rollback_savepoint { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->pg_rollback_to($p{savepoint}) }

my %TYPES = (
    uuid => 'UUID',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return $TYPES{lc($type)};
}

sub db_version {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare("SHOW server_version");
    $sth->execute();

    my ($ver) = $sth->fetchrow_array;
    return $ver;
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################

my %TABLE_TYPES = (
    'BASE TABLE'      => 'DBIx::QuickORM::Schema::Table',
    'VIEW'            => 'DBIx::QuickORM::Schema::View',
    'LOCAL TEMPORARY' => 'DBIx::QuickORM::Schema::Table',
);

my %TEMP_TYPES = (
    'BASE TABLE'      => 0,
    'VIEW'            => 0,
    'LOCAL TEMPORARY' => 1,
);

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT table_name, table_type
          FROM information_schema.tables
         WHERE table_catalog = ?
           AND table_schema  NOT IN ('pg_catalog', 'information_schema')
    EOT

    $sth->execute($self->{+DB_NAME});

    my %tables;

    while (my ($tname, $type) = $sth->fetchrow_array) {
        next if $params{autofill}->skip(table => $tname);

        my $table = {name => $tname, db_name => $tname, is_temp => $TEMP_TYPES{$type} // 0};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';

        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params);
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params);
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params);

        $params{autofill}->hook(post_table => {table => $table, class => \$class});

        $tables{$table->{name}} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$tname}});
    }

    return \%tables;
}

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT pg_get_constraintdef(oid)
          FROM pg_constraint
         WHERE connamespace = 'public'::regnamespace AND conrelid::regclass::text = ?
    EOT

    $sth->execute($table);

    my ($pk, %unique, @links);

    while (my ($spec) = $sth->fetchrow_array) {
        if (my ($type, $columns) = $spec =~ m/^(UNIQUE|PRIMARY KEY) \(([^\)]+)\)$/gi) {
            my @columns = split /,\s+/, $columns;

            $pk = \@columns if $type eq 'PRIMARY KEY';

            my $key = column_key(@columns);
            $unique{$key} = \@columns;
        }

        if (my ($type, $columns, $ftable, $fcolumns) = $spec =~ m/(FOREIGN KEY) \(([^\)]+)\) REFERENCES\s+(\S+)\(([^\)]+)\)/gi) {
            my @columns  = split /,\s+/, $columns;
            my @fcolumns = split /,\s+/, $fcolumns;

            push @links => [[$table, \@columns], [$ftable, \@fcolumns]];
        }
    }

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return ($pk, \%unique, \@links);
}

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;
    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_catalog = ?
           AND table_name    = ?
           AND table_schema  NOT IN ('pg_catalog', 'information_schema')
    EOT

    $sth->execute($self->{+DB_NAME}, $table);

    my (%columns, @links);
    while (my $res = $sth->fetchrow_hashref) {
        next if $params{autofill}->skip(column => ($table, $res->{column_name}));

        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name} = $res->{column_name};
        $col->{db_name} = $res->{column_name};
        $col->{order} = $res->{ordinal_position};
        $col->{type} = \"$res->{udt_name}";
        $col->{nullable} = $self->_col_field_to_bool($res->{is_nullable});

        $col->{identity} //= 1 if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/identity/ } keys %$res;
        $col->{identity} //= 1 if $res->{column_default} && $res->{column_default} =~ m/^nextval\(/;

        $col->{affinity} //= affinity_from_type($res->{udt_name}) // affinity_from_type($res->{data_type});
        $col->{affinity} //= 'string'  if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/character/ } keys %$res;
        $col->{affinity} //= 'numeric' if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/numeric/ } keys %$res;
        $col->{affinity} //= 'string';

        $params{autofill}->process_column($col);

        $params{autofill}->hook(post_column => {column => $col, table_name => $table, column_info => $res});

        $columns{$col->{name}} = DBIx::QuickORM::Schema::Table::Column->new($col);
        $params{autofill}->hook(column => {column => $columns{$col->{name}}, table_name => $table, column_info => $res});
    }

    return \%columns;
}

sub _col_field_to_bool {
    my $self = shift;
    my ($val) = @_;

    return 0 unless defined $val;
    return 0 unless $val;
    $val = lc($val);
    return 0 if $val eq 'no';
    return 0 if $val eq 'undef';
    return 0 if $val eq 'never';
    return 1;
}

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $dbh = $self->dbh;

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT indexname AS name,
               indexdef  AS def
          FROM pg_indexes
         WHERE tablename = ?
      ORDER BY name
    EOT

    $sth->execute($table);

    my @out;

    while (my ($name, $def) = $sth->fetchrow_array) {
        $def =~ m/CREATE(?: (UNIQUE))? INDEX \Q$name\E ON \S+ USING ([^\(]+) \((.+)\)$/ or warn "Could not parse index: $def" and next;
        my ($unique, $type, $col_list) = ($1, $2, $3);
        my @cols = split /,\s*/, $col_list;
        push @out => {name => $name, type => $type, columns => \@cols, unique => $unique ? 1 : 0};
        $params{autofill}->hook(index => {index => $out[-1], table_name => $table, definition => $def});
    }

    return \@out;
}

###############################################################################
# }}} Schema Builder Code
###############################################################################


1;
