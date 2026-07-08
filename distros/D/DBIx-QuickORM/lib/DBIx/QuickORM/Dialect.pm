package DBIx::QuickORM::Dialect;
use strict;
use warnings;

use Carp qw/croak confess carp/;
use Scalar::Util qw/blessed/;
use DBI();

our $VERSION = '0.000028';

use DBIx::QuickORM::Util qw/load_class/;

use DBIx::QuickORM::Schema;

use DBIx::QuickORM::Affinity qw/affinity_from_type affinity_from_sql_type_code/;

use Object::HashBase qw{
    <dbh
    <db_name

    +affinity_cache
    +db_type_code_map
    +warned_types
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect - Base class for database-specific dialects.

=head1 DESCRIPTION

A dialect adapts the ORM to a specific database engine. It owns the live
database handle, knows how to build a DSN, introspects schema metadata from
the live database, generates SQL from a schema, and brokers transactions,
savepoints, and (where supported) async queries.

This class is the abstract base: most of its database-specific methods are
stubs that C<confess>/C<croak> until overridden by a concrete subclass such
as L<DBIx::QuickORM::Dialect::SQLite> or L<DBIx::QuickORM::Dialect::PostgreSQL>.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => $name);

    my $schema = $dialect->build_schema_from_db(autofill => $autofill);

=head1 ATTRIBUTES

=over 4

=item dbh

The live C<DBI> database handle.

=item db_name

Name of the database this dialect is connected to.

=back

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $field = $dialect->dsn_socket_field

Name of the DSN field used to specify a unix socket. Defaults to C<host>.

=item $field = $dialect->dsn_dbname_field

Name of the DSN field used to specify the database name. Defaults to
C<dbname>; the MySQL family overrides this with C<database>.

=item $name = $dialect->dialect_name

Short name of the dialect, derived from the class name.

=item $value = $dialect->quote_binary_data

DBI bind type/attribute used to quote binary data. The return value is
whatever is valid as C<bind_param>'s third argument — a DBI type constant
(e.g. C<DBI::SQL_BINARY>) or a C<\%attrs> hashref — or C<undef> for none.

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_delete

True if the dialect supports a C<RETURNING> clause on the relevant statement.

=item $bool = $dialect->returning_reflects_write($source)

True if a write's C<RETURNING> clause can be trusted to reflect the final stored
row for C<$source>. On every engine C<RETURNING> is computed before AFTER
triggers run, so this returns false for a source with triggers (unless it is
asserted volatile-free): such a write reads its row back with a follow-up fetch
instead, so the in-memory result is consistent with engines that lack
C<RETURNING>.

=item $stype = $dialect->supports_type($type)

Returns the database-native type name if the dialect supports the given
logical type, otherwise nothing.

=item $bool = $dialect->cas_count_reliable(\%attrs)

True if a connection built with the given attributes reports the affected-row
count that compare-and-set needs (rows matched, not rows changed). The base is
always true; the MySQL family returns false when the found-rows flag was turned
off.

=cut

# {{{ Feature flags and simple accessors

sub dsn_socket_field { 'host' }
sub dsn_dbname_field { 'dbname' }

sub quote_binary_data         { my $self = shift; DBI::SQL_BINARY() }
sub supports_returning_update { 0 }
sub supports_returning_insert { 0 }
sub supports_returning_delete { 0 }

sub returning_reflects_write {
    my $self = shift;
    my ($source) = @_;

    # Whether a write's RETURNING clause can be trusted to reflect the final
    # stored row for this source. On every engine that supports RETURNING, the
    # clause is computed before AFTER triggers run, so a column an AFTER trigger
    # changes is not reflected. When the source has triggers we therefore do not
    # use RETURNING to populate the in-memory row -- the write reads it back with
    # a follow-up fetch instead, exactly as on engines without RETURNING, so the
    # result is consistent across flavors. A table asserted volatile-free
    # (no_volatile) declares its triggers change nothing, so RETURNING stays
    # trustworthy for it.
    return 1 unless $source;
    return 1 if $source->can('no_volatile')  && $source->no_volatile;
    return 0 if $source->can('has_triggers') && $source->has_triggers;
    return 1;
}

sub supports_type { my $self = shift; return undef }

sub cas_count_reliable { return 1 }

sub datetime_formatter { my $self = shift; croak "No datetime formatter is defined for the '" . $self->dialect_name . "' dialect" }

sub dialect_name {
    my $self_or_class = shift;
    my $class = blessed($self_or_class) || $self_or_class;
    $class =~ s/^DBIx::QuickORM::Dialect:://;
    return $class;
}

# }}} Feature flags and simple accessors

=pod

=item $driver = $dialect->dbi_driver

The C<DBD::*> driver class for this dialect. Stub; subclasses override.

=item $version = $dialect->db_version

The server/engine version. Stub; subclasses override.

=cut

sub dbi_driver { my $self = shift; confess "Not Implemented" }
sub db_version { my $self = shift; confess "Not Implemented" }

=pod

=item $dialect->start_txn(%params)

=item $dialect->commit_txn(%params)

=item $dialect->rollback_txn(%params)

=item $dialect->create_savepoint(%params)

=item $dialect->commit_savepoint(%params)

=item $dialect->rollback_savepoint(%params)

Transaction and savepoint control. Each accepts an optional C<dbh> parameter,
defaulting to the dialect's own handle; savepoint methods take a C<savepoint>
name. The defaults drive transactions through the driver's
C<begin_work>/C<commit>/C<rollback> and savepoints through standard
C<SAVEPOINT> / C<RELEASE SAVEPOINT> / C<ROLLBACK TO SAVEPOINT> SQL; dialects
whose engine or driver needs different handling override.

=cut

sub start_txn    { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->begin_work }
sub commit_txn   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->commit }
sub rollback_txn { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; $dbh->rollback }

sub create_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("SAVEPOINT $sp") }
sub commit_savepoint   { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("RELEASE SAVEPOINT $sp") }
sub rollback_savepoint { my ($self, %p) = @_; my $dbh = $p{dbh} // $self->dbh; my $sp = $dbh->quote_identifier($p{savepoint}); $dbh->do("ROLLBACK TO SAVEPOINT $sp") }

=pod

=item $bool = $dialect->async_supported

=item $bool = $dialect->async_cancel_supported

Async feature flags. False by default; dialects with async support override.

=item $dialect->async_prepare_args(%params)

=item $bool = $dialect->async_ready(%params)

=item $result = $dialect->async_result(%params)

=item $dialect->async_cancel(%params)

Async query lifecycle. The defaults croak with a "does not support async
queries" message; dialects with async support override.

=cut

sub async_supported        { 0 }
sub async_cancel_supported { 0 }

sub async_prepare_args { my $self = shift; croak "Dialect '" . $self->dialect_name . "' does not support async queries" }
sub async_ready        { my $self = shift; croak "Dialect '" . $self->dialect_name . "' does not support async queries" }
sub async_result       { my $self = shift; croak "Dialect '" . $self->dialect_name . "' does not support async queries" }
sub async_cancel       { my $self = shift; croak "Dialect '" . $self->dialect_name . "' does not support async queries" }

=pod

=item $bool = $dialect->in_txn(%params)

True if a transaction is currently in progress on the handle (the C<dbh>
parameter, or the dialect's own handle).

=cut

sub in_txn {
    my $self = shift;
    my %params = @_;
    my $dbh = $params{dbh} // $self->dbh;

    return 1 if $dbh->{BegunWork};
    return 0 if $dbh->{AutoCommit};
    return 1;
}

=pod

=item $dialect->init

Validates that C<dbh> and C<db_name> were provided.

=cut

sub init {
    my $self = shift;

    croak "A 'dbh' is required"      unless $self->{+DBH};
    croak "A 'db_name' is required" unless $self->{+DB_NAME};
}

=pod

=item $dsn = $dialect->dsn($db)

Builds a DSN string from a database config object, loading the driver as
needed.

=cut

sub dsn {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    load_class($driver) or croak "Could not load '$driver': $@";
    my $dsn_driver = $driver;
    $dsn_driver =~ s/^DBD:://;

    my $db_name = $db->db_name;
    my $dbname_field = $self_or_class->dsn_dbname_field($driver);
    my $dsn = "dbi:${dsn_driver}:${dbname_field}=${db_name};";

    if (my $socket = $db->socket) {
        $dsn .= $self_or_class->dsn_socket_field($driver) . "=$socket";
    }
    elsif (my $host = $db->host) {
        $dsn .= "host=$host;";
        if (my $port = $db->port) {
            $dsn .= "port=$port;";
        }
    }
    else {
        croak "Cannot construct dsn without a host or socket";
    }

    return $dsn;
}

=pod

=item $sql = $dialect->upsert_statement($pk)

Returns the SQL fragment implementing an upsert keyed on the given primary
key columns. Column names are quoted so reserved-word or mixed-case columns
work.

=cut

sub upsert_statement {
    my $self = shift;
    my ($pk) = @_;
    my $dbh = $self->dbh;
    return "ON CONFLICT(" . join(", " => map { $dbh->quote_identifier($_) } @$pk) . ") DO UPDATE SET";
}

sub upsert_noop_assignment {
    my $self = shift;
    my ($quoted_col) = @_;
    # A self-assignment keeps the conflict clause a valid no-op (so RETURNING
    # still yields the row) without changing any data.
    return "$quoted_col = $quoted_col";
}

###############################################################################
# {{{ Schema Builder Code
###############################################################################

=pod

=item $schema = $dialect->build_schema_from_db(%params)

Introspects the live database and returns a L<DBIx::QuickORM::Schema>.
Requires an C<autofill> object. After all tables are built it runs the
autofill C<tables> hook with the complete name-to-table hashref under the
C<tables> key, giving callbacks one place to inspect or adjust the full set.

=cut

sub build_schema_from_db {
    my $self = shift;
    my %params = @_;

    croak "No autofill object provided" unless $params{autofill};

    my $tables = $self->build_tables_from_db(%params);

    # Volatile is a write-time concern, and views are not written through, so a
    # view column that merely inherits a base column's default/identity during
    # introspection should not carry the volatile flag. Clear it before the
    # trigger pass (which does not touch views).
    for my $table (values %$tables) {
        next unless $table->can('is_view') && $table->is_view && $table->can('column_names');
        for my $cname ($table->column_names) {
            my $col = $table->column($cname) or next;
            $col->clear_volatile if $col->can('clear_volatile');
        }
    }

    # Best-effort: flag columns a trigger is seen to modify as volatile, and warn
    # once per table when a table has an insert/update trigger whose effects we
    # cannot resolve (unless the table is asserted volatile-free).
    $self->_apply_trigger_volatility($tables, \%params);

    $params{autofill}->hook(tables => {tables => $tables});

    return DBIx::QuickORM::Schema->new(
        tables => $tables,
    );
}

sub triggers_for_table {
    my $self = shift;
    # Subclasses that support triggers override this to return a list of
    # { event => 'INSERT'|'UPDATE'|'DELETE', body => $trigger_sql } hashrefs for
    # the named table. The base class reports none.
    return ();
}

=pod

=item $tables = $dialect->build_tables_from_db(%params)

=item ($pk, $unique, $links) = $dialect->build_table_keys_from_db($table, %params)

=item $columns = $dialect->build_columns_from_db($table, %params)

=item $indexes = $dialect->build_indexes_from_db($table, %params)

Per-table introspection helpers. Stubs; subclasses override.

=item $affinity = $dialect->affinity_from_db_type(@type_names)

Resolve a storage affinity for a database column type during introspection.
Tries the static type-name map first (the fast, authoritative path); on a miss,
consults the database's own type catalog to turn the name into a numeric SQL
type code and maps that code to an affinity; on a further miss, gives the
dialect a chance to resolve the name from its own system catalogs (see
C<_affinity_from_native_type>, which the PostgreSQL dialect uses for enums and
other user-defined types). The result is cached. When nothing recognizes the
type, warns once (asking for a ticket so the type can be added) and defaults to
C<string>. Always returns a defined affinity. Accepts more than one candidate
name (e.g. a driver's concrete and standard names) and tries each in turn.

=item $bool = $dialect->column_is_volatile_by_metadata(\%col, default => $raw, on_update => $bool)

Returns true when a column should be auto-marked volatile from its declarative
metadata: it is generated, identity/sequence-backed, carries a server-side
default, or has an on-update clause. Only the existence of a default matters, not
its value; a bare C<NULL> default (including MySQL's literal C<'NULL'> string) is
not treated as a default. Trigger effects are handled separately.

=cut

sub build_tables_from_db     { my $self = shift; confess "Not Implemented" }
sub build_table_keys_from_db { my $self = shift; confess "Not Implemented" }
sub build_columns_from_db    { my $self = shift; confess "Not Implemented" }
sub build_indexes_from_db    { my $self = shift; confess "Not Implemented" }

sub column_is_volatile_by_metadata {
    my $self = shift;
    my ($col, %sig) = @_;

    # A column whose stored value the database sets or changes on write is
    # volatile: a generated/computed column, an identity/sequence-backed column,
    # a column carrying a server-side default (the database fills it when the
    # caller omits it), or one with an on-update clause. We only need to know a
    # default EXISTS, not what it is. Trigger effects are handled separately
    # (they are not statically resolvable in general).
    return 1 if $col->{generated};
    return 1 if $col->{identity};
    return 1 if $self->_has_real_default($sig{default});
    return 1 if $sig{on_update};
    return 0;
}

sub _has_real_default {
    my $self = shift;
    my ($raw) = @_;

    return 0 unless defined $raw;
    (my $v = $raw) =~ s/^\s+//;
    $v =~ s/\s+$//;
    return 0 if $v eq '';

    # A bare NULL default -- the implicit default of a nullable column, or an
    # explicit DEFAULT NULL -- is not a meaningful default. Most engines report
    # it as SQL NULL (undef); MySQL/MariaDB report the literal string 'NULL'. A
    # real string-literal default of "NULL" is quoted ('NULL'), so it is not
    # matched here.
    return 0 if uc($v) eq 'NULL';
    return 1;
}

sub affinity_from_db_type {
    my $self  = shift;
    my @names = grep { defined && length } @_;

    return 'string' unless @names;

    # 1. Static type-name map: fast and authoritative.
    for my $name (@names) {
        my $aff = affinity_from_type($name);
        return $aff if $aff;
    }

    my $key   = $self->_normalize_type_name($names[0]);
    my $cache = $self->{+AFFINITY_CACHE} //= {};
    return $cache->{$key} if exists $cache->{$key};

    # 2. Database type catalog: name -> numeric code -> affinity.
    for my $name (@names) {
        my $code = $self->_sql_type_code_for($name)      // next;
        my $aff  = affinity_from_sql_type_code($code)     // next;
        return $cache->{$key} = $aff;
    }

    # 3. Dialect-native type catalog. The generic driver catalog above does not
    #    list a database's user-defined types (e.g. a PostgreSQL enum), so a
    #    dialect that can resolve those from its own system catalogs gets a shot
    #    before we give up. Base classes return undef; the PostgreSQL dialect
    #    overrides this.
    for my $name (@names) {
        my $aff = $self->_affinity_from_native_type($name) // next;
        return $cache->{$key} = $aff;
    }

    # 4. Unknown even to the database catalog: warn once, default to string.
    $self->_warn_unknown_type($names[0]);
    return $cache->{$key} = 'string';
}

=pod

=back

=cut

###############################################################################
# }}} Schema Builder Code
###############################################################################

=pod

=head1 PRIVATE METHODS

=over 4

=item $dsn = $dialect->_dsn_dbname_only($db)

Builds a C<dbi:$driver:dbname=$name> DSN for embedded, file-backed engines
(no host, port, or socket). Shared by the SQLite and DuckDB dialects.

=cut

sub _dsn_dbname_only {
    my $self_or_class = shift;
    my ($db) = @_;

    my $driver = $db->dbi_driver // $self_or_class->dbi_driver;
    $driver =~ s/^DBD:://;

    my $db_name = $db->db_name;

    return "dbi:${driver}:dbname=${db_name}";
}

=pod

=item $name = $dialect->_normalize_type_name($type)

Lower-cases a database type name and strips any parenthesized size/precision so
it can key the type-name caches consistently.

=item $map = $dialect->_type_code_map

A per-dialect (built once, cached) map of normalized type name to its numeric
SQL type code, derived from the driver's C<type_info_all> catalog.

=item $code_or_undef = $dialect->_sql_type_code_for($type)

The numeric SQL type code for a type name from the driver's catalog, or undef
when the driver does not list it.

=item $affinity_or_undef = $dialect->_affinity_from_native_type($type)

Resolve an affinity for a type the generic driver catalog does not list, using
the dialect's own system catalogs. The base implementation returns undef (no
native resolution); the PostgreSQL dialect overrides it to resolve user-defined
types such as enums. Called by C<affinity_from_db_type> as a last step before
warning and defaulting to C<string>.

=item $dialect->_warn_unknown_type($type)

Warn (once per type) that a database type could not be mapped to an affinity,
asking for a ticket so it can be added.

=item $set = $dialect->_no_volatile_set($no_volatile)

Normalize a C<no_volatile> value (a true scalar meaning "every table", an
arrayref of names, or a hashref) into a hashref set. A C<'*'> key means every
table is asserted volatile-free.

=item $dialect->_apply_trigger_volatility(\%tables, \%params)

For each introspected table with an insert/update trigger, best-effort flag the
columns the trigger is seen to modify as volatile, and warn once per table
whose trigger effects cannot be resolved unless it is asserted volatile-free
(via C<< $params{no_volatile} >> or the table's own C<no_volatile>).

=item @cols = $dialect->_columns_set_by_trigger($trigger_sql, \%columns)

Best-effort parse of a trigger body: returns the names of the table's columns it
is seen to assign (C<NEW.col => ...> or C<UPDATE ... SET col => ...>).

=item $dialect->_warn_trigger_volatility($table)

Warn that a table has an insert/update trigger whose column effects could not be
resolved.

=cut

sub _normalize_type_name {
    my $self = shift;
    my ($name) = @_;

    return '' unless defined $name;
    $name = lc($name);
    $name =~ s/\s*\(.*\)\s*$//;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    return $name;
}

sub _type_code_map {
    my $self = shift;

    return $self->{+DB_TYPE_CODE_MAP} if $self->{+DB_TYPE_CODE_MAP};

    my %map;
    my $info = eval { $self->dbh->type_info_all };
    if ($info && ref($info) eq 'ARRAY' && @$info) {
        my $idx = shift @$info;    # first element maps column name -> position
        if (ref($idx) eq 'HASH') {
            my $ni = $idx->{TYPE_NAME};
            my $di = $idx->{DATA_TYPE};
            if (defined($ni) && defined($di)) {
                for my $row (@$info) {
                    next unless ref($row) eq 'ARRAY';
                    my $name = $row->[$ni];
                    next unless defined $name;
                    $map{$self->_normalize_type_name($name)} //= $row->[$di];
                }
            }
        }
    }

    return $self->{+DB_TYPE_CODE_MAP} = \%map;
}

sub _sql_type_code_for {
    my $self = shift;
    my ($name) = @_;
    return $self->_type_code_map->{$self->_normalize_type_name($name)};
}

sub _affinity_from_native_type { my $self = shift; return undef }

sub _warn_unknown_type {
    my $self = shift;
    my ($name) = @_;

    my $key  = $self->_normalize_type_name($name);
    my $seen = $self->{+WARNED_TYPES} //= {};
    return if $seen->{$key}++;

    carp "DBIx::QuickORM does not recognize the database type '$name' for the '"
        . $self->dialect_name . "' dialect, and could not derive its affinity from "
        . "the database's own type catalog; defaulting to 'string' affinity. If "
        . "this type should map to a specific affinity, please file a ticket at "
        . "https://github.com/exodist/DBIx-QuickORM/issues so it can be added.";
}

sub _no_volatile_set {
    my $self = shift;
    my ($nv) = @_;

    return {} unless $nv;
    return {'*' => 1} if !ref($nv) && $nv;                 # a true scalar means "every table"
    return {map { $_ => 1 } @$nv} if ref($nv) eq 'ARRAY';
    return {%$nv} if ref($nv) eq 'HASH';
    return {};
}

sub _apply_trigger_volatility {
    my $self = shift;
    my ($tables, $params) = @_;

    my $no_vol = $self->_no_volatile_set($params->{no_volatile});
    my $all    = $no_vol->{'*'} ? 1 : 0;

    for my $tname (sort keys %$tables) {
        my $table = $tables->{$tname};
        next unless $table->can('column_names') && $table->can('column');

        my @triggers = grep { ($_->{event} // '') =~ m/\b(?:INSERT|UPDATE)\b/i } $self->triggers_for_table($tname);
        next unless @triggers;

        # Factual: the table has insert/update triggers. Flag it regardless of a
        # volatile-free assertion, so writes can decide whether RETURNING is
        # trustworthy for it (RETURNING does not reflect AFTER-trigger effects).
        $table->mark_has_triggers if $table->can('mark_has_triggers');

        # A volatile-free assertion means "trust me, the triggers here do not
        # make any column volatile": skip both the best-effort trigger flagging
        # and the warning (but not the has_triggers flag above). (Declarative
        # auto-detection of generated/identity columns already happened during
        # column introspection and stands.)
        next if $all || $no_vol->{$tname} || ($table->can('no_volatile') && $table->no_volatile);

        my %cols = map { $_ => $table->column($_) } $table->column_names;
        my %affected;
        for my $t (@triggers) {
            $affected{$_} = 1 for $self->_columns_set_by_trigger($t->{body}, \%cols);
        }

        my @marked = grep { $cols{$_} } keys %affected;
        $cols{$_}->mark_volatile for @marked;

        # Only warn when the best-effort parse could not name a single column the
        # trigger sets: then a written column really might hold a stale value and
        # the user needs to mark it volatile (or assert no_volatile). When the
        # parse did resolve columns we have already marked them volatile, so there
        # is nothing left to warn about.
        $self->_warn_trigger_volatility($tname) unless @marked;
    }

    return;
}

sub _columns_set_by_trigger {
    my $self = shift;
    my ($body, $cols) = @_;

    return () unless defined($body) && length($body);

    # Strip string literals and comments so keyword/column matching cannot
    # false-positive on text inside them.
    my $clean = $self->_strip_sql_noise($body);

    my %found;

    # BEFORE/AFTER triggers that assign to the new row: NEW.col = ... (or the
    # PL/pgSQL := assignment).
    while ($clean =~ m/\bNEW\s*\.\s*"?(\w+)"?\s*:?=(?!=)/gi) {
        $found{$1} = 1 if $cols->{$1};
    }

    # UPDATE ... SET col = ..., col2 := ... [WHERE ...]
    while ($clean =~ m/\bSET\b(.*?)(?:\bWHERE\b|;|\z)/gis) {
        my $set = $1;
        while ($set =~ m/"?(\w+)"?\s*:?=(?!=)/g) {
            $found{$1} = 1 if $cols->{$1};
        }
    }

    return keys %found;
}

sub _warn_trigger_volatility {
    my $self = shift;
    my ($table) = @_;

    carp "Table '$table' has an insert/update trigger, and QuickORM cannot "
        . "reliably determine which columns the trigger modifies, so a column it "
        . "changes may hold a stale value in memory after a write. Mark the "
        . "affected columns 'volatile', or assert the table has no volatile "
        . "columns (no_volatile) to silence this warning.";
}

=pod

=item $bool = $dialect->_col_field_to_bool($val)

Interprets an C<information_schema> string field as a boolean, treating
C<no>/C<undef>/C<never> and empty/undefined values as false.

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

=item $sql = $dialect->_strip_sql_noise($sql)

Returns the SQL with string literals replaced by empty strings and comments
removed, so keyword matching cannot false-positive on either.

=back

=cut

sub _strip_sql_noise {
    my $self = shift;
    my ($sql) = @_;

    # One left-to-right pass so a quote inside a comment (or a comment marker
    # inside a string) cannot derail the other rule.
    $sql =~ s{('(?:[^']|'')*')|(--[^\n]*)|(/\*.*?\*/)}{defined $1 ? "''" : " "}ges;

    return $sql;
}

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
