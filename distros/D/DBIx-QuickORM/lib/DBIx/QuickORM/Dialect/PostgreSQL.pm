package DBIx::QuickORM::Dialect::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000021';

use Carp qw/croak/;
use DBIx::QuickORM::Util qw/column_key/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

use parent 'DBIx::QuickORM::Dialect';
use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::PostgreSQL - PostgreSQL dialect for DBIx::QuickORM.

=head1 DESCRIPTION

The PostgreSQL-specific L<DBIx::QuickORM::Dialect>. Introspects schema
metadata from C<information_schema> and the C<pg_*> catalogs, drives
transactions and savepoints via the C<DBD::Pg> driver, supports async
queries, and maps logical types (such as C<uuid>) to native ones.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::PostgreSQL->new(dbh => $dbh, db_name => $name);

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $driver = $dialect->dbi_driver

=item $name = $dialect->dialect_name

=item $value = $dialect->quote_binary_data

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Feature flags and constants describing the PostgreSQL dialect.

=item $dialect->async_prepare_args

Bind args to issue a statement asynchronously.

=item $result = $dialect->async_result(%params)

=item $bool = $dialect->async_ready(%params)

=item $dialect->async_cancel(%params)

Async query lifecycle: collect a result, check readiness, or cancel.

=cut

# {{{ Feature flags and async support

sub dbi_driver   { 'DBD::Pg' }
sub dialect_name { 'PostgreSQL' }

sub quote_binary_data { { pg_type => DBD::Pg::PG_BYTEA() } }

sub supports_returning_update { 1 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

sub async_supported        { 1 }
sub async_cancel_supported { 1 }
sub async_prepare_args     { my $self = shift; (pg_async => DBD::Pg::PG_ASYNC()) }
sub async_result           { my ($self, %p) = @_; $p{sth}->pg_result() }
sub async_ready            { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->pg_ready() }
sub async_cancel           { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->pg_cancel() }

# }}} Feature flags and async support

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

Transaction and savepoint control via C<DBD::Pg>. Each accepts an optional
C<dbh> parameter, defaulting to the dialect's own handle; savepoint methods
take a C<savepoint> name.

=cut

# {{{ Transactions and savepoints

sub start_txn          { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->begin_work }
sub commit_txn         { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->commit }
sub rollback_txn       { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->rollback }
sub create_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->pg_savepoint($p{savepoint}) }
sub commit_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->pg_release($p{savepoint}) }
sub rollback_savepoint { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->pg_rollback_to($p{savepoint}) }

# }}} Transactions and savepoints

=pod

=item $stype = $dialect->supports_type($type)

Returns the native type name for a supported logical type (e.g. C<uuid>),
or nothing.

=cut

my %TYPES = (
    uuid => 'UUID',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return $TYPES{lc($type)};
}

sub datetime_formatter { 'DateTime::Format::Pg' }

=pod

=item $version = $dialect->db_version

The PostgreSQL server version.

=back

=cut

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

=pod

=head1 PUBLIC METHODS

=over 4

=item $tables = $dialect->build_tables_from_db(%params)

Introspects all tables and views in the database and returns a hashref of
name to schema-table object.

=cut

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

        my $final_name = $table->{name};
        $tables{$final_name} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$final_name}});
    }

    return \%tables;
}

=pod

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

Introspects a table's primary key, unique keys, and foreign-key links from
the C<pg_constraint> catalog.

=cut

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

=pod

=item $columns = $dialect->build_columns_from_db($table, %params)

Introspects a table's columns from C<information_schema.columns> and returns
a hashref of column name to column object.

=back

=cut

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

        # is_generated is 'ALWAYS' for stored generated columns and 'NEVER'
        # otherwise; _col_field_to_bool treats 'NEVER' as false.
        $col->{generated} = 1 if $self->_col_field_to_bool($res->{is_generated});

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

=pod

=head1 PRIVATE METHODS

=over 4

=item $bool = $dialect->_col_field_to_bool($val)

Normalizes an C<information_schema> truthy/falsey string (C<YES>/C<NO>,
etc.) to a 1/0 boolean.

=back

=cut

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

=pod

=head1 PUBLIC METHODS

=over 4

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Introspects a table's indexes from C<pg_indexes>, parsing each index
definition, and returns an arrayref of index specs.

=back

=cut

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

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
