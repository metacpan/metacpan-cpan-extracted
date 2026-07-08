package DBIx::QuickORM::Dialect::DuckDB;
use strict;
use warnings;

our $VERSION = '0.000028';

use DBD::DuckDB;
use DBI ();

use Carp qw/croak/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;
use DBIx::QuickORM::Util qw/column_key/;

use parent 'DBIx::QuickORM::Dialect';
use Object::HashBase qw{+in_txn};

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::DuckDB - DuckDB dialect for DBIx::QuickORM.

=head1 DESCRIPTION

The DuckDB-specific L<DBIx::QuickORM::Dialect>. DuckDB is an embedded engine
(a file or C<:memory:>, no server), so this dialect closely mirrors
L<DBIx::QuickORM::Dialect::SQLite>. It introspects schema metadata from
DuckDB's C<pragma_table_info> and C<duckdb_constraints()> /
C<duckdb_indexes()> functions plus C<information_schema>, drives transactions
via the driver, and reports DuckDB's feature set (C<RETURNING> on all DML, no
async support, B<no savepoints>).

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::DuckDB->new(dbh => $dbh, db_name => $name);

=head1 CAVEATS

=over 4

=item No savepoints

DuckDB does not implement C<SAVEPOINT>, so the savepoint methods C<croak>.
Top-level transactions work; nested ORM transactions (which are implemented as
savepoints) are not supported on DuckDB.

=item No async

DuckDB has no async query support; the C<async_*> methods C<croak>.

=back

=head1 PUBLIC METHODS

=over 4

=item $driver = $dialect->dbi_driver

=item $name = $dialect->dialect_name

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Feature flags and constants describing the DuckDB dialect. DuckDB does not
support async queries.

=item $dialect->async_prepare_args

=item $dialect->async_ready

=item $dialect->async_result

=item $dialect->async_cancel

DuckDB does not support async queries; these C<croak>.

=item $version = $dialect->db_version

The DuckDB engine version (from C<SELECT version()>).

=cut

# {{{ Feature flags, version info, and async stubs

sub dbi_driver   { 'DBD::DuckDB' }
sub dialect_name { 'DuckDB' }

sub datetime_formatter { 'DateTime::Format::SQLite' }

sub supports_returning_update { 1 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

# DuckDB binds binary data as BLOB; SQL_BINARY (the base default) makes
# DBD::DuckDB try duckdb_bind_varchar, which fails on binary bytes.
sub quote_binary_data { my $self = shift; DBI::SQL_BLOB() }

# DuckDB native types. Returns the native type name for a supported logical
# type, undef otherwise (used by type modules to pick an affinity).
my %NATIVE_TYPE = (
    uuid      => 'UUID',
    json      => 'JSON',
    jsonb     => 'JSON',
    timestamp => 'TIMESTAMP',
    blob      => 'BLOB',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return undef unless defined $type;
    return $NATIVE_TYPE{lc($type)};
}

sub async_supported        { 0 }
sub async_cancel_supported { 0 }
sub async_prepare_args     { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_ready            { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_result           { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }
sub async_cancel           { croak "Dialect '" . $_[0]->dialect_name . "' does not support async queries" }

sub db_version {
    my $self = shift;
    my ($v) = $self->dbh->selectrow_array("SELECT version()");
    return $v;
}

# }}} Feature flags, version info, and async stubs

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

Transaction control via the DuckDB driver. Each accepts an optional C<dbh>
parameter, defaulting to the dialect's own handle.

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

DuckDB does not support savepoints; these C<croak>.

=cut

# {{{ Transactions (no savepoints)

# DBD::DuckDB's begin_work/commit/rollback (DBI AutoCommit management) leave the
# engine's transaction state out of sync after a rollback: a subsequent
# begin_work dies with "cannot start a transaction within a transaction". Issue
# the SQL transaction-control statements directly instead, which behave
# correctly across sequential commits and rollbacks. DBI's AutoCommit flag stays
# at its default, so track our own in-transaction state for in_txn().

sub start_txn    { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->do("BEGIN TRANSACTION"); $self->{+IN_TXN} = 1 }
sub commit_txn   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->do("COMMIT");            $self->{+IN_TXN} = 0 }
sub rollback_txn { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->do("ROLLBACK");          $self->{+IN_TXN} = 0 }

# Our own transactions use raw BEGIN/COMMIT/ROLLBACK and do not flip DBI's
# AutoCommit, so consult our flag first; then fall back to DBI's view to detect
# a transaction started externally (e.g. a raw $dbh->begin_work).
sub in_txn {
    my $self = shift;
    my %params = @_;
    return 1 if $self->{+IN_TXN};
    my $dbh = $params{dbh} // $self->dbh;
    return 1 if $dbh->{BegunWork};
    return 0 if $dbh->{AutoCommit};
    return 1;
}

sub create_savepoint   { croak "Dialect '" . $_[0]->dialect_name . "' does not support savepoints (nested transactions)" }
sub commit_savepoint   { croak "Dialect '" . $_[0]->dialect_name . "' does not support savepoints (nested transactions)" }
sub rollback_savepoint { croak "Dialect '" . $_[0]->dialect_name . "' does not support savepoints (nested transactions)" }

# }}} Transactions

=pod

=item $dsn = $dialect->dsn($db)

Builds a DuckDB DSN string from a database config object.

=back

=cut

sub dsn {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    $driver =~ s/^DBD:://;

    my $db_name = $db->db_name;

    return "dbi:${driver}:dbname=${db_name}";
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################

my %TABLE_TYPES = (
    'BASE TABLE'      => 'DBIx::QuickORM::Schema::Table',
    'LOCAL TEMPORARY' => 'DBIx::QuickORM::Schema::Table',
    'VIEW'            => 'DBIx::QuickORM::Schema::View',
);

=pod

=head1 SCHEMA INTROSPECTION

=over 4

=item $tables = $dialect->build_tables_from_db(%params)

Introspects all tables and views in the current schema and returns a hashref
of name to schema-table object.

=cut

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my $sth = $dbh->prepare(<<'    EOT');
        SELECT table_name, table_type
          FROM information_schema.tables
         WHERE table_schema = current_schema()
    EOT
    $sth->execute();
    my @table_list = @{$sth->fetchall_arrayref};

    # Sweep all constraints, columns, indexes, and table DDL for the current
    # schema in one query each, grouped by table, rather than a query-per-table.
    # The constraint sweep is shared by the key and index builders. Primary-key
    # membership (needed for identity detection) comes from the constraints,
    # since duckdb_columns() does not expose it.
    my $all_constraints = $self->_fetch_all_constraints;

    my %pk_by_table;
    for my $tname (keys %$all_constraints) {
        for my $con (@{$all_constraints->{$tname}}) {
            next unless $con->{constraint_type} eq 'PRIMARY KEY';
            $pk_by_table{$tname}{$_} = 1 for @{$con->{constraint_column_names} // []};
        }
    }

    my $all_columns   = $self->_fetch_all_columns(\%pk_by_table);
    my $all_indexes   = $self->_fetch_all_indexes;
    my $all_generated = $self->_fetch_all_generated;

    my %tables;
    for my $row (@table_list) {
        my ($tname, $type) = @$row;
        next if $params{autofill}->skip(table => $tname);

        my $table = {name => $tname, db_name => $tname, is_temp => ($type eq 'LOCAL TEMPORARY' ? 1 : 0)};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';
        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params, column_rows => ($all_columns->{$tname} // []), generated => ($all_generated->{$tname} // {}));
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params, constraint_rows => ($all_constraints->{$tname} // []), index_rows => ($all_indexes->{$tname} // []));
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params, constraint_rows => ($all_constraints->{$tname} // []));

        $params{autofill}->hook(post_table => {table => $table, class => \$class});

        # Hooks may rename the table; key by the final name.
        my $final_name = $table->{name};
        $tables{$final_name} = $class->new($table);
        $params{autofill}->hook(table => {table => $tables{$final_name}});
    }

    return \%tables;
}

=pod

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

Introspects a table's primary key, unique keys, and foreign-key links via
C<duckdb_constraints()>.

=cut

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $rows = $params{constraint_rows} // $self->_query_constraints($table);

    my ($pk, %unique, @links);
    for my $row (@$rows) {
        my $type = $row->{constraint_type};
        my $cols = $row->{constraint_column_names} // [];

        if ($type eq 'PRIMARY KEY') {
            $pk = [@$cols];
            $unique{column_key(@$cols)} = [@$cols];
        }
        elsif ($type eq 'UNIQUE') {
            $unique{column_key(@$cols)} = [@$cols];
        }
        elsif ($type eq 'FOREIGN KEY') {
            my $ftable = $row->{referenced_table};
            my $fcols  = $row->{referenced_column_names} // [];
            push @links => [[$table, [@$cols]], [$ftable, [@$fcols]]];
        }
        # NOT NULL constraints are handled per-column in build_columns_from_db.
    }

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return ($pk, \%unique, \@links);
}

=pod

=item $columns = $dialect->build_columns_from_db($table, %params)

Introspects a table's columns via C<pragma_table_info> (SQLite-compatible in
DuckDB) and returns a hashref of column name to column object.

=cut

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;

    my $rows = $params{column_rows} // $self->_query_columns($table);
    my $generated = $params{generated} // {$self->_generated_columns($table)};

    my %columns;
    for my $res (@$rows) {
        next if $params{autofill}->skip(column => ($table, $res->{name}));

        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name}    = $res->{name};
        $col->{db_name} = $res->{name};
        $col->{order}   = $res->{cid} + 1;

        # A PK column defaulting from a sequence is database-generated.
        $col->{identity} = 1
            if $res->{pk} && defined($res->{dflt_value}) && $res->{dflt_value} =~ /nextval/i;

        $col->{generated} = 1 if $generated->{lc $res->{name}};

        my $type = $res->{type};
        $type =~ s/\(.*$//;
        $col->{type} = \$type;

        $col->{nullable} = $res->{notnull} ? 0 : 1;
        $col->{affinity} //= affinity_from_type($type) // 'string';

        $params{autofill}->process_column($col);
        $params{autofill}->hook(post_column => {column => $col, table_name => $table, column_info => $res});

        $columns{$col->{name}} = DBIx::QuickORM::Schema::Table::Column->new($col);
        $params{autofill}->hook(column => {column => $columns{$col->{name}}, table_name => $table, column_info => $res});
    }

    return \%columns;
}

# DuckDB does not surface a generated flag in pragma_table_info,
# duckdb_columns(), or information_schema.columns. Parse the table's stored
# DDL instead and look for `<col> ... GENERATED ALWAYS AS (...)` clauses.
sub _generated_columns {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my ($ddl) = $dbh->selectrow_array(
        "SELECT sql FROM duckdb_tables() WHERE table_name = ?",
        undef, $table,
    );

    return $self->_parse_generated($ddl);
}

# Extract the names of GENERATED ALWAYS AS columns from a table's stored DDL.
sub _parse_generated {
    my $self = shift;
    my ($ddl) = @_;

    return unless defined $ddl && length $ddl;

    my %out;
    # The \b belongs inside the bare-word alternative: after a closing quote
    # there is no word boundary to match, so a trailing \b would reject every
    # quoted column name.
    while ($ddl =~ /(?:^|[(,])\s*("[^"]+"|`[^`]+`|\w+\b)[^,]*?\bGENERATED\s+ALWAYS\s+AS\s*\(/sgi) {
        my $name = $1;
        $name =~ s/\A["`]|["`]\z//g;
        $out{lc $name} = 1;
    }

    return %out;
}

=pod

=item $by_table = $dialect->_fetch_all_constraints

=item $by_table = $dialect->_fetch_all_columns(\%pk_by_table)

=item $by_table = $dialect->_fetch_all_indexes

=item $by_table = $dialect->_fetch_all_generated

Sweep all constraint, column, secondary-index, and generated-column metadata
for the current schema in one query each, returning a hashref of table name to
that table's data. C<_fetch_all_columns> maps C<duckdb_columns()> rows into the
C<pragma_table_info> shape the column builder expects, filling the C<pk> flag
from the supplied primary-key membership. C<_fetch_all_generated> returns, per
table, the hashref of generated column names produced by C<_parse_generated>.

=item $rows = $dialect->_query_constraints($table)

=item $rows = $dialect->_query_columns($table)

=item $rows = $dialect->_query_indexes($table)

Single-table fallbacks used when the per-table builders are called without
pre-fetched rows.

=cut

sub _fetch_all_constraints {
    my $self = shift;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT table_name,
               constraint_type,
               constraint_column_names,
               referenced_table,
               referenced_column_names
          FROM duckdb_constraints()
         WHERE schema_name = current_schema()
    EOT
    $sth->execute();

    my %by_table;
    while (my $row = $sth->fetchrow_hashref) {
        push @{$by_table{$row->{table_name}} //= []} => $row;
    }

    return \%by_table;
}

sub _query_constraints {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT constraint_type,
               constraint_column_names,
               referenced_table,
               referenced_column_names
          FROM duckdb_constraints()
         WHERE table_name = ?
    EOT
    $sth->execute($table);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_columns {
    my $self = shift;
    my ($pk_by_table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT table_name,
               column_name,
               column_index,
               data_type,
               is_nullable,
               column_default
          FROM duckdb_columns()
         WHERE schema_name = current_schema()
      ORDER BY table_name, column_index
    EOT
    $sth->execute();

    my %by_table;
    while (my $row = $sth->fetchrow_hashref) {
        my $tname = $row->{table_name};
        push @{$by_table{$tname} //= []} => {
            cid        => $row->{column_index} - 1,
            name       => $row->{column_name},
            type       => $row->{data_type},
            notnull    => $row->{is_nullable} ? 0 : 1,
            pk         => ($pk_by_table->{$tname}{$row->{column_name}} ? 1 : 0),
            dflt_value => $row->{column_default},
        };
    }

    return \%by_table;
}

sub _query_columns {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare("SELECT * FROM pragma_table_info(?)");
    $sth->execute($table);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_indexes {
    my $self = shift;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT table_name, index_name, is_unique, expressions
          FROM duckdb_indexes()
         WHERE schema_name = current_schema()
    EOT
    $sth->execute();

    my %by_table;
    while (my $row = $sth->fetchrow_hashref) {
        push @{$by_table{$row->{table_name}} //= []} => $row;
    }

    return \%by_table;
}

sub _query_indexes {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT index_name, is_unique, expressions
          FROM duckdb_indexes()
         WHERE table_name = ?
    EOT
    $sth->execute($table);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_generated {
    my $self = shift;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<'    EOT');
        SELECT table_name, sql
          FROM duckdb_tables()
         WHERE schema_name = current_schema()
    EOT
    $sth->execute();

    my %by_table;
    while (my ($tname, $ddl) = $sth->fetchrow_array) {
        $by_table{$tname} = {$self->_parse_generated($ddl)};
    }

    return \%by_table;
}

=pod

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Returns an arrayref of index specs. Primary-key and unique indexes come from
C<duckdb_constraints()>; named secondary indexes (with their columns and unique
flag) come from C<duckdb_indexes()> (the C<expressions> column gives the column
list).

=back

=cut

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $constraints = $params{constraint_rows} // $self->_query_constraints($table);
    my $indexes     = $params{index_rows}      // $self->_query_indexes($table);

    my %out;

    # Primary key and unique constraints.
    for my $row (@$constraints) {
        next unless $row->{constraint_type} eq 'PRIMARY KEY' || $row->{constraint_type} eq 'UNIQUE';
        my $cols = $row->{constraint_column_names} // [];
        my $is_pk = $row->{constraint_type} eq 'PRIMARY KEY';
        my $name = $is_pk ? "${table}:pk" : "${table}:uniq:" . column_key(@$cols);
        $out{$name} = {name => $name, columns => [@$cols], unique => 1};
    }

    # Named secondary indexes. 'expressions' is an arrayref of the indexed
    # column names.
    for my $row (@$indexes) {
        my $name = $row->{index_name} // next;
        next if exists $out{$name};

        # 'expressions' is usually an arrayref of column names, but DuckDB
        # sometimes renders it as a string like q{['"name"']}; handle both.
        my $expr = $row->{expressions};
        my @cols;
        if (ref($expr) eq 'ARRAY') {
            @cols = @$expr;
        }
        elsif (defined $expr) {
            @cols = $expr =~ /"([^"]+)"/g;             # quoted identifiers
            @cols = $expr =~ /([A-Za-z_]\w*)/g unless @cols;  # bare identifiers
        }

        $out{$name} = {name => $name, columns => \@cols, unique => $row->{is_unique} ? 1 : 0};
    }

    return [map { $params{autofill}->hook(index => {index => $out{$_}, table_name => $table}); $out{$_} } sort keys %out];
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

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
