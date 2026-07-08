package DBIx::QuickORM::Dialect::SQLite;
use strict;
use warnings;

our $VERSION = '0.000028';

use DBD::SQLite 1.70;

use Carp qw/croak/;
use DBIx::QuickORM::Affinity qw/affinity_from_type/;
use DBIx::QuickORM::Util qw/column_key/;

use parent 'DBIx::QuickORM::Dialect';
use Object::HashBase qw{ +all_triggers };

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Schema::View;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::SQLite - SQLite dialect for DBIx::QuickORM.

=head1 DESCRIPTION

The SQLite-specific L<DBIx::QuickORM::Dialect>. Introspects schema metadata
from SQLite's C<pragma_*> tables and C<sqlite_master>, drives transactions
and savepoints via the SQLite driver, and reports SQLite's feature set
(C<RETURNING> support, no async support).

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => $name);

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $driver = $dialect->dbi_driver

=item $name = $dialect->dialect_name

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Feature flags and constants describing the SQLite dialect. SQLite does not
support async queries.

=item $stype = $dialect->supports_type($type)

Returns SQLite's native storage type name for a supported logical type, or
nothing. SQLite has no native JSON type; JSON-ish types fall back to C<TEXT>
via C<supports_type('text')>.

=item $dialect->async_prepare_args

=item $dialect->async_ready

=item $dialect->async_result

=item $dialect->async_cancel

SQLite does not support async queries; these C<croak>.

=item $version = $dialect->db_version

The version of the SQLite library itself (not the C<DBD::SQLite> module
version).

=cut

# {{{ Feature flags, version info, and async stubs

sub dbi_driver   { 'DBD::SQLite' }
sub dialect_name { 'SQLite' }

sub datetime_formatter { 'DateTime::Format::SQLite' }

# SQLite's real storage types. There is no native JSON type; types like JSON
# fall back to TEXT via supports_type('text').
my %TYPES = (
    text    => 'TEXT',
    integer => 'INTEGER',
    int     => 'INTEGER',
    real    => 'REAL',
    blob    => 'BLOB',
    numeric => 'NUMERIC',
);
sub supports_type {
    my $self = shift;
    my ($type) = @_;
    return undef unless defined $type;
    return $TYPES{lc($type)};
}

sub supports_returning_update { 1 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

sub async_supported        { 0 }
sub async_cancel_supported { 0 }

sub db_version { my $self = shift; $self->dbh->{sqlite_version} }

# }}} Feature flags, version info, and async stubs

=pod

=item $dsn = $dialect->dsn($db)

Builds a SQLite DSN string from a database config object. Transactions and
savepoints use the inherited driver-level defaults.

=back

=cut

sub dsn { my $self_or_class = shift; $self_or_class->_dsn_dbname_only(@_) }

###############################################################################
# {{{ Schema Builder Code
###############################################################################


my %TABLE_TYPES = (
    'table' => 'DBIx::QuickORM::Schema::Table',
    'view'  => 'DBIx::QuickORM::Schema::View',
);

# Permanent and temporary schema catalogs. A temporary object shadows a
# permanent one of the same name, so the pragma sweeps qualify each catalog by
# its schema name ('main' vs 'temp') and key their results by (is_temp, name).
# Without the schema qualifier the unqualified pragma table-functions resolve
# temp-first, poisoning a shadowed permanent table with the temp object's
# metadata.
my @MASTERS = ('sqlite_master', 'sqlite_temp_master');
my @SCHEMAS = ('main',          'temp');

=pod

=head1 PUBLIC METHODS

=over 4

=item $tables = $dialect->build_tables_from_db(%params)

Introspects all tables and views (including temp ones) and returns a hashref
of name to schema-table object.

=cut

sub build_tables_from_db {
    my $self = shift;
    my %params = @_;

    my $dbh = $self->{+DBH};

    my @queries = (
        "SELECT name, type, 0 FROM sqlite_master      WHERE type IN ('table', 'view')",
        "SELECT name, type, 1 FROM sqlite_temp_master WHERE type IN ('table', 'view')",
    );

    my @table_list;
    for my $q (@queries) {
        my $sth = $dbh->prepare($q);
        $sth->execute();
        while (my ($tname, $type, $temp) = $sth->fetchrow_array) {
            push @table_list => [$tname, $type, $temp];
        }
    }

    # Sweep column, index, foreign-key, and DDL metadata for every table in one
    # query each (per catalog) instead of a query-per-table. The pragma_* table
    # functions are joined laterally against sqlite_master / sqlite_temp_master
    # so a single statement iterates all tables. The per-table builders below
    # consume these pre-fetched rows; primary key and rowid-alias detection are
    # derived from the pre-fetched xinfo rather than extra queries.
    my $all_xinfo   = $self->_fetch_all_xinfo;
    my $all_indexes = $self->_fetch_all_index_info;
    my $all_fks     = $self->_fetch_all_fks;
    my $all_ddl     = $self->_fetch_all_ddl;

    my %tables;
    for my $row (@table_list) {
        my ($tname, $type, $temp) = @$row;
        next if $tname =~ m/^sqlite_/;
        next if $params{autofill}->skip(table => $tname);

        # Pre-fetched metadata is keyed by (is_temp, name): a temporary object
        # shadows a permanent one of the same name, so both catalogs may hold a
        # table with the same name; keying by catalog keeps each one's columns,
        # indexes, foreign keys, and DDL separate.
        my $xinfo        = $all_xinfo->{$temp}{$tname} // [];
        my @pk           = $self->_pk_from_xinfo($xinfo);
        my $identity_col = $self->_rowid_alias_from($xinfo, $all_ddl->{$temp}{$tname});

        my $table = {name => $tname, db_name => $tname, is_temp => $temp};
        my $class = $TABLE_TYPES{lc($type)} // 'DBIx::QuickORM::Schema::Table';
        $params{autofill}->hook(pre_table => {table => $table, class => \$class});

        $table->{columns} = $self->build_columns_from_db($tname, %params, column_rows => $xinfo, identity_col => $identity_col);
        $params{autofill}->hook(columns => {columns => $table->{columns}, table => $table});

        $table->{indexes} = $self->build_indexes_from_db($tname, %params, index_rows => ($all_indexes->{$temp}{$tname} // []), pk_fallback => \@pk);
        $params{autofill}->hook(indexes => {indexes => $table->{indexes}, table => $table});

        @{$table}{qw/primary_key unique _links/} = $self->build_table_keys_from_db($tname, %params, index_rows => ($all_indexes->{$temp}{$tname} // []), fk_rows => ($all_fks->{$temp}{$tname} // []), pk_fallback => \@pk);

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

Introspects a table's primary key, unique keys, and foreign-key links.

=cut

sub build_table_keys_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $index_rows = $params{index_rows} // $self->_query_index_info($table);
    my $fk_rows    = $params{fk_rows}    // $self->_query_fks($table);

    my ($pk, %unique, @links);

    my %index;
    for my $row (@$index_rows) {
        my $idx = $index{$row->{name}} //= {cols => []};
        $idx->{type}    = $row->{origin};
        $idx->{unique}  = $row->{unique};
        $idx->{partial} = $row->{partial};

        # An expression index member (e.g. lower(a)) has no column name; record
        # that the index has expression parts and skip it in the column list.
        if (defined $row->{column}) {
            push @{$idx->{cols}} => $row->{column};
        }
        else {
            $idx->{has_expr} = 1;
        }
    }

    # Only indexes flagged unique are unique constraints; a plain CREATE INDEX
    # must not be recorded as one. The flag (not the origin) is the signal:
    # CREATE UNIQUE INDEX also has origin 'c'. A partial unique index (WHERE
    # clause) or one over expressions does not constrain the whole table, so it
    # is not a table-wide unique key.
    for my $grp (sort keys %index) {
        my $idx = $index{$grp};
        $unique{column_key(@{$idx->{cols}})} = $idx->{cols}
            if $idx->{unique} && !$idx->{partial} && !$idx->{has_expr};
        $pk = $idx->{cols} if $idx->{type} eq 'pk';
    }

    unless ($pk && @$pk) {
        my @found = $params{pk_fallback} ? @{$params{pk_fallback}} : $self->_primary_key($table);

        if (@found) {
            $pk = \@found;
            $unique{column_key(@found)} = \@found;
        }
        else {
            $pk = undef;
        }
    }

    %index = ();
    for my $row (@$fk_rows) {
        my $idx = $index{$row->{id}} //= {};

        push @{$idx->{columns} //= []} => $row->{from};

        $idx->{ftable} //= $row->{table};
        push @{$idx->{fcolumns} //= []} => $row->{to};
    }

    @links = map { [[$table, $_->{columns}], [$_->{ftable}, $_->{fcolumns}]] } values %index;

    $params{autofill}->hook(links       => {links       => \@links, table_name => $table});
    $params{autofill}->hook(primary_key => {primary_key => $pk, table_name => $table});
    $params{autofill}->hook(unique_keys => {unique_keys => \%unique, table_name => $table});

    return($pk, \%unique, \@links);
}

=pod

=item $bool = $dialect->table_has_autoinc($table)

True if the named table declares an C<AUTOINCREMENT> column.

=cut

sub table_has_autoinc {
    my $self = shift;
    my ($table) = @_;

    croak "A table name is required" unless $table;

    my $ddl = $self->_table_ddl($table) // return 0;

    # AUTOINCREMENT is only valid as part of a column definition's PRIMARY KEY
    # constraint, so match that grammar in the table's own CREATE TABLE DDL.
    # Matching the bare word against every sqlite_master row for the table
    # would false-positive on triggers (separate rows, excluded by the
    # type='table' filter in _table_ddl) and on comments or string literals
    # (stripped by _strip_sql_noise).
    return $self->_strip_sql_noise($ddl) =~ m/\bPRIMARY\s+KEY(?:\s+(?:ASC|DESC))?(?:\s+ON\s+CONFLICT\s+\w+)?\s+AUTOINCREMENT\b/i ? 1 : 0;
}

=pod

=item $columns = $dialect->build_columns_from_db($table, %params)

Introspects a table's columns and returns a hashref of column name to
column object.

=cut

sub build_columns_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    croak "A table name is required" unless $table;

    # pragma_table_xinfo (SQLite 3.31.0+, 2020-01-22) lists every column
    # including hidden virtual-table columns and GENERATED columns; the
    # older pragma_table_info silently omits them. The `hidden` flag
    # distinguishes them: 0 ordinary, 1 hidden virtual-table column,
    # 2 virtual generated column, 3 stored generated column.
    my $rows = $params{column_rows} // $self->_query_xinfo($table);

    # A rowid-alias column auto-assigns on insert (with or without
    # AUTOINCREMENT, which only changes rowid allocation policy), matching the
    # identity semantics of the other engines.
    my $identity_col = exists $params{identity_col} ? $params{identity_col} : $self->_rowid_alias_column($table);

    my %columns;
    for my $res (@$rows) {
        my $hidden = $res->{hidden} // 0;
        next if $hidden == 1;    # hidden virtual-table columns are not part of the ORM schema

        next if $params{autofill}->skip(column => ($table, $res->{name}));

        my $col = {};

        $params{autofill}->hook(pre_column => {column => $col, table_name => $table, column_info => $res});

        $col->{name}    = $res->{name};
        $col->{db_name} = $res->{name};
        $col->{order}   = $res->{cid} + 1;
        $col->{identity}  = 1 if defined($identity_col) && $res->{name} eq $identity_col;
        $col->{generated} = 1 if $hidden >= 2;
        $col->{volatile}  //= 1 if $self->column_is_volatile_by_metadata($col, default => $res->{dflt_value});

        my $type = $res->{type};
        $type =~ s/\(.*$//;
        $col->{type} = \$type;

        $col->{nullable} = $res->{notnull} ? 0 : 1;
        $col->{affinity} //= $self->affinity_from_db_type($type);

        $params{autofill}->process_column($col);
        $params{autofill}->hook(post_column => {column => $col, table_name => $table, column_info => $res});

        $columns{$col->{name}} = DBIx::QuickORM::Schema::Table::Column->new($col);
        $params{autofill}->hook(column => {column => $columns{$col->{name}}, table_name => $table, column_info => $res});
    }

    return \%columns;
}

=pod

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Introspects a table's indexes and returns an arrayref of index specs.

=item @triggers = $dialect->triggers_for_table($table)

Returns the C<CREATE TRIGGER> statements defined on a table (permanent and temp
catalogs), each as a C<< { event => 'INSERT'|'UPDATE'|'DELETE', body => $sql } >>
hashref, for volatile-column detection.

=back

=cut

sub build_indexes_from_db {
    my $self = shift;
    my ($table, %params) = @_;

    my $rows = $params{index_rows} // $self->_query_index_info($table);

    my %out;
    for my $row (@$rows) {
        my $idx = $out{$row->{name}} //= {name => $row->{name}, columns => [], unique => $row->{unique} ? 1 : 0};
        # Expression index members have no column name; keep the index but leave
        # the expression out of the column list.
        push @{$idx->{columns}} => $row->{column} if defined $row->{column};
    }

    my @pk = $params{pk_fallback} ? @{$params{pk_fallback}} : $self->_primary_key($table);
    if (@pk) {
        $out{"${table}:pk"} = {name => "${table}:pk", unique => 1, columns => \@pk};
    }

    return [map { $params{autofill}->hook(index => {index => $out{$_}, table_name => $table}); $out{$_} } sort keys %out];
}

sub triggers_for_table {
    my $self = shift;
    my ($table) = @_;

    my @out;
    for my $sql (@{$self->_all_triggers->{$table} // []}) {
        my $event = ($sql =~ m/\b(?:BEFORE|AFTER|INSTEAD\s+OF)\s+(INSERT|UPDATE|DELETE)\b/i) ? uc($1) : '';
        push @out => {event => $event, body => $sql};
    }

    return @out;
}

# All triggers keyed by table name, fetched once per dialect (both catalogs) so
# volatile-column detection does not add a query per table and stays within the
# fixed-query-count introspection budget.
sub _all_triggers {
    my $self = shift;

    return $self->{+ALL_TRIGGERS} if $self->{+ALL_TRIGGERS};

    my %map;
    for my $master (@MASTERS) {
        my $rows = $self->dbh->selectall_arrayref("SELECT tbl_name, sql FROM $master WHERE type = 'trigger'", {Slice => {}});
        for my $r (@$rows) {
            next unless defined $r->{tbl_name} && defined $r->{sql};
            push @{$map{$r->{tbl_name}}} => $r->{sql};
        }
    }

    return $self->{+ALL_TRIGGERS} = \%map;
}

=pod

=head1 PRIVATE METHODS (schema introspection)

=over 4

=item $by_table = $dialect->_fetch_all_xinfo

=item $by_table = $dialect->_fetch_all_index_info

=item $by_table = $dialect->_fetch_all_fks

=item $by_table = $dialect->_fetch_all_ddl

Sweep column (C<pragma_table_xinfo>), index (C<pragma_index_list> +
C<pragma_index_info>), foreign-key (C<pragma_foreign_key_list>), and stored-DDL
metadata for every table in a single statement per catalog. The pragma table
functions are qualified by catalog schema (C<main> / C<temp>) and joined
laterally against C<sqlite_master> / C<sqlite_temp_master> so one statement
iterates all tables. All four sweeps return a hashref keyed by temp-flag
(0 permanent, 1 temporary) then table name, so a temporary object never merges
with (or shadows) a permanent one of the same name.

=item $by_table = $dialect->_all_triggers

All triggers keyed by table name, fetched once per dialect from both catalogs
(cached), so volatile-column detection adds a fixed two queries rather than one
per table.

=item @cols = $dialect->_pk_from_xinfo($xinfo_rows)

The primary-key column names (ordered by key position) derived from pre-fetched
C<pragma_table_xinfo> rows, without an extra query.

=item $col_or_undef = $dialect->_rowid_alias_from($xinfo_rows, $ddl)

The rowid-alias column derived from pre-fetched xinfo rows and stored DDL,
without an extra query. See C<_rowid_alias_column> for the alias rule.

=item $rows = $dialect->_query_xinfo($table)

=item $rows = $dialect->_query_index_info($table)

=item $rows = $dialect->_query_fks($table)

Single-table fallbacks used when the per-table builders are called without
pre-fetched rows.

=back

=cut

sub _fetch_all_xinfo {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my %by_table;
    for my $is_temp (0 .. $#MASTERS) {
        my $master = $MASTERS[$is_temp];
        my $schema = $SCHEMAS[$is_temp];
        my $sth = $dbh->prepare(<<"        EOT");
            SELECT m.name AS qorm_tbl, x.*
              FROM $master m
              JOIN pragma_table_xinfo(m.name, '$schema') x
             WHERE m.type IN ('table', 'view')
          ORDER BY m.name, x.cid
        EOT
        $sth->execute();
        while (my $row = $sth->fetchrow_hashref) {
            my $tname = delete $row->{qorm_tbl};
            push @{$by_table{$is_temp}{$tname} //= []} => $row;
        }
    }

    return \%by_table;
}

sub _query_xinfo {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare("SELECT * FROM pragma_table_xinfo(?)");
    $sth->execute($table);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_index_info {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my %by_table;
    for my $is_temp (0 .. $#MASTERS) {
        my $master = $MASTERS[$is_temp];
        my $schema = $SCHEMAS[$is_temp];
        my $sth = $dbh->prepare(<<"        EOT");
            SELECT m.name, il.name, il.`unique`, il.origin, il.partial, ii.name
              FROM $master m
              JOIN pragma_index_list(m.name, '$schema')  AS il
              JOIN pragma_index_info(il.name, '$schema') AS ii
             WHERE m.type IN ('table', 'view')
          ORDER BY m.name, il.name, ii.seqno
        EOT
        $sth->execute();
        while (my ($tbl, $name, $uniq, $origin, $partial, $col) = $sth->fetchrow_array) {
            push @{$by_table{$is_temp}{$tbl} //= []} => {name => $name, unique => $uniq, origin => $origin, partial => $partial, column => $col};
        }
    }

    return \%by_table;
}

sub _query_index_info {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare(<<"    EOT");
        SELECT il.name, il.`unique`, il.origin, il.partial, ii.name
          FROM pragma_index_list(?)       AS il,
               pragma_index_info(il.name) AS ii
      ORDER BY il.name, ii.seqno
    EOT
    $sth->execute($table);

    my @rows;
    while (my ($name, $uniq, $origin, $partial, $col) = $sth->fetchrow_array) {
        push @rows => {name => $name, unique => $uniq, origin => $origin, partial => $partial, column => $col};
    }

    return \@rows;
}

sub _fetch_all_fks {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my %by_table;
    for my $is_temp (0 .. $#MASTERS) {
        my $master = $MASTERS[$is_temp];
        my $schema = $SCHEMAS[$is_temp];
        my $sth = $dbh->prepare(<<"        EOT");
            SELECT m.name, fk.id, fk.`table`, fk.`from`, fk.`to`
              FROM $master m
              JOIN pragma_foreign_key_list(m.name, '$schema') AS fk
             WHERE m.type IN ('table', 'view')
          ORDER BY m.name, fk.id, fk.seq
        EOT
        $sth->execute();
        while (my ($tbl, $id, $ftable, $ffrom, $fto) = $sth->fetchrow_array) {
            push @{$by_table{$is_temp}{$tbl} //= []} => {id => $id, table => $ftable, from => $ffrom, to => $fto};
        }
    }

    return \%by_table;
}

sub _query_fks {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->{+DBH};
    my $sth = $dbh->prepare("SELECT `id`, `table`, `from`, `to` FROM pragma_foreign_key_list(?) order by id, seq");
    $sth->execute($table);

    return $sth->fetchall_arrayref({});
}

sub _fetch_all_ddl {
    my $self = shift;

    my $dbh = $self->{+DBH};

    my %by_table;
    for my $is_temp (0 .. $#MASTERS) {
        my $master = $MASTERS[$is_temp];
        my $sth = $dbh->prepare("SELECT name, sql FROM $master WHERE type = 'table'");
        $sth->execute();
        while (my ($name, $sql) = $sth->fetchrow_array) {
            $by_table{$is_temp}{$name} = $sql;
        }
    }

    return \%by_table;
}

sub _pk_from_xinfo {
    my $self = shift;
    my ($rows) = @_;

    my @pk = grep { ($_->{pk} // 0) > 0 && (!defined $_->{hidden} || $_->{hidden} < 2) } @$rows;

    return map { $_->{name} } sort { $a->{pk} <=> $b->{pk} } @pk;
}

sub _rowid_alias_from {
    my $self = shift;
    my ($rows, $ddl) = @_;

    my @pk = grep { ($_->{pk} // 0) > 0 && (!defined $_->{hidden} || $_->{hidden} < 2) } @$rows;

    return undef unless @pk == 1;
    return undef unless uc($pk[0]->{type} // '') eq 'INTEGER';
    return undef if defined($ddl) && $self->_strip_sql_noise($ddl) =~ m/\bWITHOUT\s+ROWID\b/i;

    return $pk[0]->{name};
}

=pod

=head1 PRIVATE METHODS

=over 4

=item @cols = $dialect->_primary_key($table)

Returns the primary-key column names for a table, ordered by key position.

=cut

sub _primary_key {
    my $self = shift;
    my ($table) = @_;

    my $sth = $self->dbh->prepare("SELECT name FROM pragma_table_xinfo(?) WHERE pk > 0 AND (hidden IS NULL OR hidden < 2) ORDER BY pk ASC");
    $sth->execute($table);

    my @out;
    while (my $row = $sth->fetchrow_hashref()) {
        push @out => $row->{name};
    }

    return @out;
}

=pod

=item $ddl_or_undef = $dialect->_table_ddl($table)

The stored C<CREATE TABLE> statement for the named table (permanent or temp),
or undef when the table does not exist.

=cut

sub _table_ddl {
    my $self = shift;
    my ($table) = @_;

    my $dbh = $self->dbh;

    # A temp table shadows a permanent one of the same name, and the
    # unqualified pragma introspection resolves to the temp object, so prefer
    # the temp DDL here to stay consistent.
    my ($ddl) = $dbh->selectrow_array("SELECT sql FROM sqlite_temp_master WHERE type = 'table' AND name = ?", undef, $table);
    ($ddl) = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?", undef, $table) unless defined $ddl;

    return $ddl;
}

=pod

=item $col_or_undef = $dialect->_rowid_alias_column($table)

The name of the column that aliases SQLite's rowid, or undef if the table has
none. The alias rule: a rowid table (no C<WITHOUT ROWID>) with a single-column
primary key whose declared type is exactly C<INTEGER> (C<INT>, C<BIGINT>, etc.
do not alias). Not handled: the obscure C<x INTEGER PRIMARY KEY DESC>
column-definition form, which SQLite does not treat as an alias.

=back

=cut

sub _rowid_alias_column {
    my $self = shift;
    my ($table) = @_;

    my $sth = $self->dbh->prepare("SELECT name, type FROM pragma_table_xinfo(?) WHERE pk > 0 AND (hidden IS NULL OR hidden < 2)");
    $sth->execute($table);

    my @pk;
    while (my $row = $sth->fetchrow_hashref()) {
        push @pk => $row;
    }

    return undef unless @pk == 1;
    return undef unless uc($pk[0]->{type} // '') eq 'INTEGER';

    my $ddl = $self->_table_ddl($table);
    return undef if defined($ddl) && $self->_strip_sql_noise($ddl) =~ m/\bWITHOUT\s+ROWID\b/i;

    return $pk[0]->{name};
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
