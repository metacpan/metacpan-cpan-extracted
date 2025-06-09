package DBIx::QuickORM::Dialect::MySQL;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key load_class/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;

use DBI();

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

use parent 'DBIx::QuickORM::Dialect';
use DBIx::QuickORM::Util::HashBase qw{
    +dbi_driver
};

sub async_supported        { 1 }
sub async_cancel_supported { 0 }
sub async_prepare_args     { my ($s, %p) = @_; $s->dbi_driver eq 'DBD::mysql' ? (async => 1) : (mariadb_async => 1) }
sub async_ready            { my ($s, %p) = @_; $s->dbi_driver eq 'DBD::mysql' ? $p{sth}->mysql_async_ready() : $p{sth}->mariadb_async_ready() }
sub async_result           { my ($s, %p) = @_; $s->dbi_driver eq 'DBD::mysql' ? $p{sth}->mysql_async_result() : $p{sth}->mariadb_async_result() }
sub async_cancel           { croak "Dialect '" . $_[0]->dialect_name . "' does not support canceling async queries" }

sub start_txn          { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->begin_work }
sub commit_txn         { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->commit }
sub rollback_txn       { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->rollback }
sub create_savepoint   { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->do("SAVEPOINT $p{savepoint}") }
sub commit_savepoint   { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->do("RELEASE SAVEPOINT $p{savepoint}") }
sub rollback_savepoint { my ($s, %p) = @_; my $dbh = $p{dbh} // $s->dbh; $dbh->do("ROLLBACK TO SAVEPOINT $p{savepoint}") }

BEGIN {
    my $mariadb = eval { require DBD::MariaDB; 1 };
    my $mysql   = eval { require DBD::mysql; 1 };

    croak "You must install either DBD::MariaDB or DBD::mysql" unless $mariadb || $mysql;

    *DEFAULT_DBI_DRIVER = $mariadb ? sub() { 'DBD::MariaDB' } : sub() { 'DBD::mysql' };
}

sub dbi_driver {
    my $in = shift;

    return DEFAULT_DBI_DRIVER() unless blessed($in);

    return $in->{+DBI_DRIVER} if $in->{+DBI_DRIVER};

    my $dbh = $in->dbh;

    return $in->{+DBI_DRIVER} = "DBD::" . $dbh->{Driver}->{Name};
}

sub quote_binary_data {
    my $self = shift;
    my $driver = $self->dbi_driver;
    return undef if $driver eq 'DBD::mysql';
    return DBI::SQL_BINARY if $driver eq 'DBD::MariaDB';
    croak "Unknown DBD::Driver '$driver'";
}

sub init {
    my $self = shift;

    if (blessed($self) eq __PACKAGE__) {
        if (my $vendor = $self->db_vendor) {
            if (my $class = load_class("DBIx::QuickORM::Dialect::MySQL::${vendor}")) {
                bless($self, $class);
                return $self->init();
            }
            elsif ($@ !~ m{Can't locate DBIx/QuickORM/Dialect/MySQL/${vendor}\.pm in \@INC}) {
                die $@;
            }

            warn "Could not find vendor specific dialect 'DBIx::QuickORM::Dialect::MySQL::${vendor}', using 'DBIx::QuickORM::Dialect::MySQL'. This can result in degraded capabilities compared to a dedicate dialect\n";
        }
        else {
            warn "Could not find vendor specific dialect 'DBIx::QuickORM::Dialect::MySQL::YOUR_VENDOR', using 'DBIx::QuickORM::Dialect::MySQL'. This can result in degraded capabilities compared to a dedicate dialect\n";
        }
    }

    return $self->SUPER::init();
}

sub dialect_name { 'MySQL' }

sub dsn_socket_field {
    my $this = shift;
    my ($driver) = @_;

    return 'mariadb_socket' if $driver eq 'DBD::MariaDB';
    return 'mysql_socket' if $driver eq 'DBD::mysql';

    $this->SUPER::dsn_socket_field($driver);
};

sub db_version {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare("SELECT version()");
    $sth->execute();

    my ($ver) = $sth->fetchrow_array;
    return $ver;
}

sub db_vendor {
    my $self = shift;

    my $dbh = $self->{+DBH};

    for my $cmd ('SELECT @@version_comment', "SELECT version()") {
        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        my ($val) = $sth->fetchrow_array;

        return 'MariaDB'   if $val =~ m/MariaDB/i;
        return 'Percona'   if $val =~ m/Percona/i;
        return 'Community' if $val =~ m/Community/i;
    }

    my $sth = $dbh->prepare('SHOW VARIABLES LIKE "%version%"');
    $sth->execute();

    while (my @vals = $sth->fetchrow_array) {
        for my $val (@vals) {
            return 'MariaDB'   if $val =~ m/MariaDB/i;
            return 'Percona'   if $val =~ m/Percona/i;
            return 'Community' if $val =~ m/Community/i;
        }
    }

    return undef;
}

sub upsert_statement {
    my $self = shift;
    my ($pk) = @_;
    return "ON DUPLICATE KEY UPDATE";
}


###############################################################################
# {{{ Schema Builder Code
###############################################################################

my %TABLE_TYPES = (
    'BASE TABLE' => 'DBIx::QuickORM::Schema::Table',
    'VIEW'       => 'DBIx::QuickORM::Schema::View',
    'TEMPORARY'  => 'DBIx::QuickORM::Schema::Table',
);

my %TEMP_TYPES = (
    'BASE TABLE' => 0,
    'VIEW'       => 0,
    'TEMPORARY'  => 1,
);

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare('SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = ?');
    $sth->execute($self->{+DB_NAME});

    my %tables;

    while (my ($tname, $type) = $sth->fetchrow_array) {
        my $table = {name => $tname, db_name => $tname, is_temp => $TEMP_TYPES{$type} // 0};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';
        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params);
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params);
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params);

        $params{autofill}->hook(post_table => {table => $table, class => \$class});
        $tables{$tname} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$tname}});
    }

    return \%tables;
}

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<"    EOT");
        SELECT tco.constraint_name          AS con,
               tco.constraint_type          AS type,
               kcu.column_name              AS col,
               kcu.referenced_table_name    AS ftab,
               kcu.referenced_column_name   AS fcol
          FROM information_schema.table_constraints tco
          JOIN information_schema.key_column_usage  kcu
            ON tco.constraint_schema = kcu.constraint_schema
           AND tco.constraint_name   = kcu.constraint_name
           AND tco.table_name        = kcu.table_name
         WHERE tco.table_schema NOT IN ('sys','information_schema', 'mysql', 'performance_schema')
           AND tco.table_name        = ?
           AND tco.table_schema      = ?
      ORDER BY tco.table_schema, tco.table_name, tco.constraint_name, kcu.ordinal_position
    EOT

    $sth->execute($table, $self->{+DB_NAME});

    my ($pk, %unique, @links);

    my %keys;
    while (my $row = $sth->fetchrow_hashref) {
        my $item = $keys{$row->{con}} //= {type => lc($row->{type})};

        push @{$item->{columns} //= []} => $row->{col};

        next unless $row->{type} eq 'FOREIGN KEY';

        my $link = $item->{link} //= [[$table, $item->{columns}],[$row->{ftab},[]]];
        push @{$link->[1]->[1]} => $row->{fcol};
    }

    for my $key (sort keys %keys) {
        my $item = $keys{$key};

        my $type = delete $item->{type};
        if ($type eq 'foreign key') {
            push @links => $item->{link};
        }
        elsif ($type eq 'unique') {
            $unique{column_key(@{$item->{columns}})} = $item->{columns};
        }
        elsif ($type eq 'unique' || $type eq 'primary key') {
            $unique{column_key(@{$item->{columns}})} = $item->{columns};
            $pk = $item->{columns} if $type eq 'primary key';
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
         WHERE table_name    = ?
           AND table_schema  = ?
    EOT

    $sth->execute($table, $self->{+DB_NAME});

    my (%columns, @links);
    while (my $res = $sth->fetchrow_hashref) {
        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name} = $res->{COLUMN_NAME};
        $col->{db_name} = $res->{COLUMN_NAME};
        $col->{order} = $res->{ORDINAL_POSITION};
        $col->{type} = \"$res->{DATA_TYPE}";
        $col->{nullable} = $self->_col_field_to_bool($res->{IS_NULLABLE});

        $col->{identity} = 1 if $res->{EXTRA} && $res->{EXTRA} eq 'auto_increment';

        $col->{affinity} //= affinity_from_type($res->{DATA_TYPE});
        $col->{affinity} //= 'string'  if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/CHARACTER/ } keys %$res;
        $col->{affinity} //= 'numeric' if grep { $self->_col_field_to_bool($res->{$_}) } grep { m/NUMERIC/ } keys %$res;
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
        SELECT index_name,
               column_name,
               non_unique,
               index_type
          FROM INFORMATION_SCHEMA.STATISTICS
         WHERE table_name = ?
           AND table_schema = ?
      ORDER BY index_name, seq_in_index
    EOT

    $sth->execute($table, $self->{+DB_NAME});

    my %out;
    while (my ($name, $col, $nu, $type) = $sth->fetchrow_array) {
        my $idx = $out{$name} //= {name => $name, unique => $nu ? 0 : 1, type => $type, columns => []};
        push @{$idx->{columns}} => $col;
    }

    return [map { $params{autofill}->hook(index => $out{$_}, table_name => $table); $out{$_} } sort keys %out];
}

###############################################################################
# }}} Schema Builder Code
###############################################################################

1;
