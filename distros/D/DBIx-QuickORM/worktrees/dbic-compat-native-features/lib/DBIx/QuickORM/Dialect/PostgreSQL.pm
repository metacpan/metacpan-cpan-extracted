package DBIx::QuickORM::Dialect::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000027';

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

Returns the native type name for a supported logical type (e.g. C<uuid>,
C<jsonb>), or nothing. Note: C<json> requires PostgreSQL 9.2+ and C<jsonb>
9.4+.

=cut

my %TYPES = (
    uuid        => 'UUID',
    json        => 'JSON',
    jsonb       => 'JSONB',
    text        => 'TEXT',
    timestamp   => 'TIMESTAMP',
    timestamptz => 'TIMESTAMPTZ',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return undef unless defined $type;
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

Introspects all tables and views visible through the connection's
C<search_path> and returns a hashref of name to schema-table object. When the
same table name exists in more than one schema on the path, the first match
in C<search_path> order wins, mirroring how PostgreSQL itself resolves
unqualified names.

=cut

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my $schemas = $self->_search_path_schemas;
    return {} unless @$schemas;

    my $in = join(', ' => ('?') x @$schemas);
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT table_name, table_type, table_schema
          FROM information_schema.tables
         WHERE table_catalog = ?
           AND table_schema IN ($in)
    EOT

    $sth->execute($self->{+DB_NAME}, @$schemas);

    my %rank;
    @rank{@$schemas} = (1 .. @$schemas);

    my %found;
    while (my ($tname, $type, $tschema) = $sth->fetchrow_array) {
        my $cur = $found{$tname};
        next if $cur && $rank{$cur->{schema}} <= $rank{$tschema};
        $found{$tname} = {type => $type, schema => $tschema};
    }

    # Sweep all columns, constraints, and indexes for the search-path schemas in
    # one query each, keyed by schema then table. The per-table builders below
    # consume these pre-fetched rows for the schema that won name resolution.
    my $all_columns = $self->_fetch_all_columns($schemas);
    my $all_indexes = $self->_fetch_all_indexes($schemas);
    my $all_keys    = $self->_fetch_all_keys($schemas);

    my %tables;

    for my $tname (sort keys %found) {
        next if $params{autofill}->skip(table => $tname);

        my $type    = $found{$tname}->{type};
        my $tschema = $found{$tname}->{schema};

        my $table = {name => $tname, db_name => $tname, is_temp => $TEMP_TYPES{$type} // 0};
        my $class = $TABLE_TYPES{$type} // 'DBIx::QuickORM::Schema::Table';

        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params, table_schema => $tschema, column_rows => ($all_columns->{$tschema}{$tname} // []));
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params, table_schema => $tschema, index_rows => ($all_indexes->{$tschema}{$tname} // []));
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params, table_schema => $tschema, key_rows => ($all_keys->{$tschema}{$tname} // []));

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
the C<pg_constraint> catalog, scoped to the table's schema (the
C<table_schema> param, or the first C<search_path> schema containing the
table).

=cut

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $specs = $params{key_rows};
    unless ($specs) {
        my $tschema = $params{table_schema} // $self->_table_schema($table);
        $specs = $self->_query_keys($table, $tschema);
    }

    my ($pk, %unique, @links);

    for my $spec (@$specs) {
        if (my ($type, $columns) = $spec =~ m/^(UNIQUE|PRIMARY KEY) \(([^\)]+)\)/gi) {
            my @columns = $self->_split_identifiers($columns);

            $pk = \@columns if $type eq 'PRIMARY KEY';

            my $key = column_key(@columns);
            $unique{$key} = \@columns;
        }

        if (my ($type, $columns, $ftable, $fcolumns) = $spec =~ m/(FOREIGN KEY) \(([^\)]+)\) REFERENCES\s+(.+?)\s*\(([^\)]+)\)/gi) {
            my @columns  = $self->_split_identifiers($columns);
            my @fcolumns = $self->_split_identifiers($fcolumns);

            push @links => [[$table, \@columns], [$self->_referenced_table($ftable), \@fcolumns]];
        }
    }

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return ($pk, \%unique, \@links);
}

=pod

=item $columns = $dialect->build_columns_from_db($table, %params)

Introspects a table's columns from C<information_schema.columns>, scoped to
the table's schema (the C<table_schema> param, or the first C<search_path>
schema containing the table), and returns a hashref of column name to column
object.

=back

=cut

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;

    my $rows = $params{column_rows};
    unless ($rows) {
        my $tschema = $params{table_schema} // $self->_table_schema($table);
        $rows = $self->_query_columns($table, $tschema);
    }

    my %columns;
    for my $res (@$rows) {
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

Introspects a table's indexes from the C<pg_index>/C<pg_attribute> catalogs,
scoped to the table's schema (the C<table_schema> param, or the first
C<search_path> schema containing the table), and returns an arrayref of index
specs.

=back

=cut

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $rows = $params{index_rows};
    unless ($rows) {
        my $tschema = $params{table_schema} // $self->_table_schema($table);
        $rows = $self->_query_indexes($table, $tschema);
    }

    my (%seen, @out);
    for my $row (@$rows) {
        my $idx = $seen{$row->{name}};
        unless ($idx) {
            $idx = $seen{$row->{name}} = {name => $row->{name}, type => $row->{type}, columns => [], unique => $row->{is_unique} ? 1 : 0, definition => $row->{def}};
            push @out => $idx;
        }
        push @{$idx->{columns}} => $row->{column_name} if defined $row->{column_name};
    }

    for my $idx (@out) {
        my $def = delete $idx->{definition};
        $params{autofill}->hook(index => {index => $idx, table_name => $table, definition => $def});
    }

    return \@out;
}

=pod

=head1 PRIVATE METHODS (schema introspection)

=over 4

=item $by_schema = $dialect->_fetch_all_columns($schemas)

=item $by_schema = $dialect->_fetch_all_keys($schemas)

=item $by_schema = $dialect->_fetch_all_indexes($schemas)

Sweep all column, constraint, and index metadata for the given search-path
schemas in one query each, returning a hashref of schema name to table name to
the rows for that table (in the same shape the matching single-table
C<_query_*> helper returns).

=item $rows = $dialect->_query_columns($table, $tschema)

=item $specs = $dialect->_query_keys($table, $tschema)

=item $rows = $dialect->_query_indexes($table, $tschema)

Single-table fallbacks used when the per-table builders are called without
pre-fetched rows. Each issues one query scoped to C<$table> in C<$tschema>.

=back

=cut

sub _fetch_all_columns {
    my $self = shift;
    my ($schemas) = @_;

    my $dbh = $self->{+DBH};
    my $in = join(', ' => ('?') x @$schemas);
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_catalog = ?
           AND table_schema IN ($in)
    EOT
    $sth->execute($self->{+DB_NAME}, @$schemas);

    my %by_schema;
    while (my $res = $sth->fetchrow_hashref) {
        push @{$by_schema{$res->{table_schema}}{$res->{table_name}} //= []} => $res;
    }

    return \%by_schema;
}

sub _query_columns {
    my $self = shift;
    my ($table, $tschema) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT *
          FROM information_schema.columns
         WHERE table_catalog = ?
           AND table_name    = ?
           AND table_schema  = ?
    EOT
    $sth->execute($self->{+DB_NAME}, $table, $tschema);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_keys {
    my $self = shift;
    my ($schemas) = @_;

    my $dbh = $self->{+DBH};
    my $in = join(', ' => ('?') x @$schemas);

    # Join on oids rather than casting conrelid through regclass (whose text
    # form is search_path- and quoting-sensitive) or using regnamespace
    # (PostgreSQL 9.5+); this works back to 9.3.
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT nsp.nspname,
               rel.relname,
               pg_get_constraintdef(con.oid)
          FROM pg_constraint con
          JOIN pg_class      rel ON rel.oid = con.conrelid
          JOIN pg_namespace  nsp ON nsp.oid = rel.relnamespace
         WHERE nsp.nspname IN ($in)
      ORDER BY nsp.nspname, rel.relname, con.conname, con.oid
    EOT
    $sth->execute(@$schemas);

    my %by_schema;
    while (my ($schema, $tname, $spec) = $sth->fetchrow_array) {
        push @{$by_schema{$schema}{$tname} //= []} => $spec;
    }

    return \%by_schema;
}

sub _query_keys {
    my $self = shift;
    my ($table, $tschema) = @_;

    my $dbh = $self->{+DBH};

    # Join on oids rather than casting conrelid through regclass (whose text
    # form is search_path- and quoting-sensitive) or using regnamespace
    # (PostgreSQL 9.5+); this works back to 9.3.
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT pg_get_constraintdef(con.oid)
          FROM pg_constraint con
          JOIN pg_class      rel ON rel.oid = con.conrelid
          JOIN pg_namespace  nsp ON nsp.oid = rel.relnamespace
         WHERE rel.relname  = ?
           AND nsp.nspname  = ?
      ORDER BY con.conname, con.oid
    EOT
    $sth->execute($table, $tschema);

    my @specs;
    while (my ($spec) = $sth->fetchrow_array) {
        push @specs => $spec;
    }

    return \@specs;
}

sub _fetch_all_indexes {
    my $self = shift;
    my ($schemas) = @_;

    my $dbh = $self->dbh;
    my $in = join(', ' => ('?') x @$schemas);

    # Read the catalogs instead of regex-parsing pg_indexes.indexdef, which
    # breaks on quoted mixed-case index names. The generate_series join with
    # indkey subscripting preserves column order and works back to PostgreSQL
    # 9.3 (no unnest WITH ORDINALITY, no array_position). Expression entries
    # have indkey 0, match no pg_attribute row, and are skipped.
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT n.nspname  AS table_schema,
               tc.relname AS table_name,
               ic.relname AS name,
               am.amname  AS type,
               CASE WHEN i.indisunique THEN 1 ELSE 0 END AS is_unique,
               a.attname  AS column_name,
               pg_get_indexdef(i.indexrelid) AS def
          FROM pg_index i
          JOIN pg_class      ic ON ic.oid = i.indexrelid
          JOIN pg_class      tc ON tc.oid = i.indrelid
          JOIN pg_namespace  n  ON n.oid  = tc.relnamespace
          JOIN pg_am         am ON am.oid = ic.relam
          JOIN generate_series(0, 31) s(i) ON s.i < i.indnatts
          LEFT JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[s.i]
         WHERE n.nspname IN ($in)
      ORDER BY n.nspname, tc.relname, ic.relname, s.i
    EOT
    $sth->execute(@$schemas);

    my %by_schema;
    while (my $row = $sth->fetchrow_hashref) {
        push @{$by_schema{$row->{table_schema}}{$row->{table_name}} //= []} => $row;
    }

    return \%by_schema;
}

sub _query_indexes {
    my $self = shift;
    my ($table, $tschema) = @_;

    my $dbh = $self->dbh;

    # Read the catalogs instead of regex-parsing pg_indexes.indexdef, which
    # breaks on quoted mixed-case index names. The generate_series join with
    # indkey subscripting preserves column order and works back to PostgreSQL
    # 9.3 (no unnest WITH ORDINALITY, no array_position). Expression entries
    # have indkey 0, match no pg_attribute row, and are skipped.
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT ic.relname AS name,
               am.amname  AS type,
               CASE WHEN i.indisunique THEN 1 ELSE 0 END AS is_unique,
               a.attname  AS column_name,
               pg_get_indexdef(i.indexrelid) AS def
          FROM pg_index i
          JOIN pg_class      ic ON ic.oid = i.indexrelid
          JOIN pg_class      tc ON tc.oid = i.indrelid
          JOIN pg_namespace  n  ON n.oid  = tc.relnamespace
          JOIN pg_am         am ON am.oid = ic.relam
          JOIN generate_series(0, 31) s(i) ON s.i < i.indnatts
          LEFT JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[s.i]
         WHERE tc.relname = ?
           AND n.nspname  = ?
      ORDER BY ic.relname, s.i
    EOT
    $sth->execute($table, $tschema);

    return $sth->fetchall_arrayref({});
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $schemas = $dialect->_search_path_schemas

Arrayref of schema names visible to the connection, in C<search_path>
priority order (the session's temp schema first when one exists), excluding
the system catalogs.

=cut

sub _search_path_schemas {
    my $self = shift;

    # current_schemas(true) includes the implicit schemas (the session's
    # pg_temp_N first, then pg_catalog) ahead of the configured search_path,
    # matching how PostgreSQL resolves unqualified names.
    my $sth = $self->dbh->prepare("SELECT unnest(current_schemas(true))");
    $sth->execute();

    my @schemas;
    while (my ($s) = $sth->fetchrow_array) {
        next if $s eq 'pg_catalog' || $s eq 'information_schema';
        push @schemas => $s;
    }

    return \@schemas;
}

=pod

=item $schema_or_undef = $dialect->_table_schema($table)

The first schema in C<search_path> order that contains the named table, or
undef when none does.

=cut

sub _table_schema {
    my $self = shift;
    my ($table) = @_;

    my $sth = $self->dbh->prepare(<<"    EOT");
        SELECT 1
          FROM pg_class     c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE c.relname = ?
           AND n.nspname = ?
    EOT

    for my $schema (@{$self->_search_path_schemas}) {
        $sth->execute($table, $schema);
        my ($found) = $sth->fetchrow_array;
        $sth->finish;
        return $schema if $found;
    }

    return undef;
}

=pod

=item @idents = $dialect->_split_identifiers($list)

Split a comma-separated identifier list from C<pg_get_constraintdef> output,
stripping double quotes from each identifier.

=cut

sub _split_identifiers {
    my $self = shift;
    my ($list) = @_;
    return map { $self->_unquote_identifier($_) } split /,\s*/, $list;
}

=pod

=item $ident = $dialect->_unquote_identifier($ident)

Strip surrounding double quotes (and unescape doubled inner quotes) from an
identifier captured out of C<pg_get_constraintdef> output.

=cut

sub _unquote_identifier {
    my $self = shift;
    my ($ident) = @_;

    return $ident unless defined $ident;

    $ident =~ s/^\s+//;
    $ident =~ s/\s+$//;
    $ident =~ s/""/"/g if $ident =~ s/^"(.*)"$/$1/s;

    return $ident;
}

=pod

=item $table = $dialect->_referenced_table($target)

The (unquoted) table name from a C<REFERENCES> target, dropping any schema
qualification.

=back

=cut

sub _referenced_table {
    my $self = shift;
    my ($target) = @_;

    my @parts = $target =~ m/("(?:[^"]|"")*"|[^".]+)/g;

    return $self->_unquote_identifier($parts[-1]);
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
