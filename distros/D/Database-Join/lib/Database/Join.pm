package Database::Join;

# ABSTRACT: Combined view across two or more Database::Abstraction objects

use 5.010001;
use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use List::Util qw(max);
use Readonly;
use Scalar::Util qw(blessed);
use Object::Configure;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Sub::Protected;

# Named-pair keys accepted by add_database; kept here so the guard and the
# validate_strict schema cannot silently diverge.
Readonly::Array my @_ADD_DB_KEYS => qw(database join_column filter remove_columns);

# SQL comparison operators that are safe to interpolate into WHERE clauses.
# Any operator not in this set is silently skipped to prevent SQL injection.
Readonly::Hash my %SAFE_SQL_OPS => map { $_ => 1 } qw(> < >= <= != =);

our $VERSION = '0.006.0';

# ---------------------------------------------------------------------------
# KNOWN GAPS & ROADMAP (derived from gap-analysis 2026-09-21)
#
# PRE-RELEASE BLOCKERS
#
# TODO: LIKE silently dropped on SQLite path (undocumented cross-backend gap)
#   %SAFE_SQL_OPS covers { > < >= <= != = } only.  LIKE, NOT LIKE, IN, NOT IN,
#   IS NULL, and IS NOT NULL are silently skipped on the SQLite path with no
#   warning, while the array path passes them directly to the component DA
#   (which may honour them).  A caller who develops against a small dataset
#   (array path) and deploys at scale (SQLite path) gets silently wider results.
#   Fix options: (a) add LIKE to %SAFE_SQL_OPS — safe with bind params; or
#   (b) add a carp when an unrecognised operator is encountered on the SQLite
#   path so callers are not silently misled.  Either way, add a COMMON PITFALLS
#   entry.  See t/cgi_security.t for the %SAFE_SQL_OPS operator-whitelist tests.
#
# TODO: Missing =head3 MESSAGES POD sections in eight public methods
#   Only new(), add_database(), and remove_column() document their error and
#   warning strings under =head3 MESSAGES.  The following methods can also
#   carp or croak and need matching sections: selectall_arrayref,
#   selectall_array, fetchrow_hashref, count, columns, schema, updated,
#   set_logger, AUTOLOAD.
#
# TODO: updated() not defensive against DAs without updated()
#   sub updated { return max(map { $_->updated() } @{$self->{_dbs}}) }
#   will propagate an uncaught exception if any component DA does not implement
#   updated().  _cache_fresh() already handles this gracefully with eval{}.
#   Either wrap the map body in eval and skip undef returns (consistent with
#   _cache_fresh), or document the contract requirement in LIMITATIONS.
#
# POST-RELEASE ROADMAP
#
# TODO: count() SQL push-down on the SQLite path
#   count() calls _joined_query() and returns scalar @{$rows}, fetching every
#   row just to count them.  On the cached SQLite backend a SELECT COUNT(*)
#   against the join SQL would be orders of magnitude cheaper for large tables.
#
# TODO: LIKE / NOT LIKE in %SAFE_SQL_OPS (also covers the pre-release gap above)
#   LIKE with a bind parameter (col LIKE ?) is injection-safe and would unify
#   array-path and SQLite-path behaviour for pattern-matching criteria.
#
# TODO: IN (...) / NOT IN (...) list-operator support
#   Set-membership criteria are common in read-only query layers.  Requires
#   bind-parameter list expansion (one ? per element) in the WHERE builder.
#
# TODO: IS NULL / IS NOT NULL operator support
#   Nullable-column filtering cannot be expressed as a bind-parameter operator.
#   Handle undef criterion values with a separate IS NULL generation path
#   instead of the current `next if !defined $val` no-op.
#
# TODO: Caller-specified ORDER BY on query methods
#   Results are sorted by join_column only.  An order_by => 'col' (or
#   order_by => ['col', 'DESC']) parameter would cover a common use-case:
#   SQL ORDER BY clause on the SQLite path; Perl sort block on the array path.
#
# TODO: Limit / offset for pagination
#   limit => N, offset => M on selectall_arrayref/selectall_array would enable
#   paginated access.  SQLite path: LIMIT ? OFFSET ? clauses; array path: slice.
#
# TODO: dbi_source() on Database::Join itself (composable nested joins)
#   The join object cannot act as a zero-copy SQLite source in a parent join.
#   Implementing dbi_source() — returning the cached File::Temp handle and the
#   join table name — would allow composable nested Database::Join objects at
#   full ATTACHed speed.
#
# TODO: Parallel DA queries in _fetch_indexed
#   Component DAs are queried sequentially.  An optional parallel => 1
#   constructor flag could reduce latency by the factor of the slowest DA,
#   with no change to the merge logic (Coro or IO::Async back-end).
#
# TODO: Schema type consistency validation at construction
#   Columns shared across two DAs (without collision_prefix) are merged
#   type-blind.  A validation pass comparing schema() types for overlapping
#   columns at new()/add_database() time could warn callers before silent
#   type coercion produces unexpected results.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# All user-facing strings route through this dictionary.  Supply an i18n
# object with a translate($key, @sprintf_args) method to localise them.
# ---------------------------------------------------------------------------
Readonly::Hash my %MESSAGES => (
	error_no_databases	=> 'At least one Database::Abstraction object is required',
	error_invalid_db	=> 'databases[%d] does not support the selectall_arrayref/columns interface',
	error_join_col_missing	=> 'join_column "%s" is absent from databases[%d] (%s)',
	error_col_conflict	=> 'Column "%s" exists in multiple databases; use the owning database directly or rename the column',
	error_remove_join_col	=> 'Cannot remove join_column "%s"; it is required for the join',
	warn_unknown_column	=> 'Column "%s" is not present in any configured database; criterion ignored',
	error_query_unsupported	=> 'query() chained builder is not supported on Database::Join; call selectall_arrayref / fetchrow_hashref directly',
	error_execute_unsupported => 'execute() raw SQL is not supported on Database::Join',
	error_unknown_message	=> 'Unknown message key "%s"',
	error_invalid_prefix	=> 'collision_prefix[%d] must be a plain string, not a reference; passing a reference would leak a heap address into column names',
	error_invalid_backend	=> 'backend must be "array", "sqlite", or "auto"; got "%s"',
	error_sqlite_connect	=> 'Failed to open temporary SQLite database for join backend: %s',
);

=head1 NAME

Database::Join - Read-only combined view across two or more Database::Abstraction objects

=head1 VERSION

Version 0.006.0

=head1 SYNOPSIS

B<Basic two-database join>

    use Database::Join;

    # Step 1: create each component database the normal way
    my $customers = Database::Customers->new(directory => '/data');
    my $loyalty   = Database::Loyalty->new(directory  => '/data');

    # Step 2: combine them on the shared key column 'entry'
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
    );

    # Step 3: query exactly as you would a single Database::Abstraction object
    my $all_rows  = $join->selectall_arrayref();
    my $vip_rows  = $join->selectall_arrayref(tier => 'gold');
    my $one_row   = $join->fetchrow_hashref(entry => 'C001');
    my $total     = $join->count();
    my $col_names = $join->columns();

B<Hiding internal columns>

    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        remove_columns => [ 'internal_id', 'audit_ts' ],
    );
    # 'internal_id' and 'audit_ts' never appear in results or columns()

B<join_map: when the key column has different names in each database>

    # $cities  (index 0) has a column called 'statecode' -- matches join_column
    # $stnames (index 1) has a column called 'entry'     -- different name

    my $join = Database::Join->new(
        databases   => [ $cities,  $stnames ],
        #                index 0   index 1
        join_column => 'statecode',
        join_map    => { 1 => 'entry' },  # index 1 calls its join key 'entry'
    );

    # All returned rows use 'statecode'; 'entry' is never exposed
    my $rows = $join->selectall_arrayref();

B<filters: permanently restrict a database's visible rows>

    # Only show orders placed more than 60 days ago, without repeating
    # the criterion on every query call.
    my $join = Database::Join->new(
        databases   => [ $customers, $orders ],
        join_column => 'entry',
        filters     => { 1 => { age_days => { '>' => 60 } } },
    );

    my $rows = $join->selectall_arrayref();                 # all old orders
    my $vip  = $join->selectall_arrayref(tier => 'gold');   # old + gold tier

B<Inner and outer join types>

    my $inner = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        join_type   => 'inner',   # only keys present in BOTH databases
    );

    my $outer = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        join_type   => 'outer',   # all keys from EITHER database
    );

B<Building the view incrementally with add_database>

    my $join = Database::Join->new(
        databases   => [ $customers ],
        join_column => 'entry',
    );

    $join->add_database($loyalty)
         ->add_database($scores, remove_columns => ['raw_score']);

B<AUTOLOAD column shortcut>

    # Returns the 'name' value for entry 'C001' (scalar context)
    my $name = $join->name(entry => 'C001');

    # Returns all 'tier' values (list context)
    my @tiers = $join->tier();

B<SQLite join backend for large datasets>

    # 'auto' (default): switches to SQLite automatically above the threshold
    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        backend        => 'auto',          # default
        max_array_rows => 50_000,          # use SQLite when combined rows > 50,000
    );

    # Always use SQLite -- useful when you know the data is large
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        backend     => 'sqlite',
        tmpdir      => '/fast/nvme/tmp',   # optional: faster temp disk
    );

    # Always use the original in-memory path
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
        backend     => 'array',
    );

=head1 DESCRIPTION

C<Database::Join> merges two or more L<Database::Abstraction> objects into a
single logical, read-only view.  Each component database is queried
independently through its own C<Database::Abstraction> interface.  The results
are combined using a shared key column (C<join_column>).
In effect, this means that you can view data from more than one database using
an intuitive, non-SQL interface.

Every storage format that C<Database::Abstraction> supports works as a
component database: CSV, PSV, TSV, SQLite, JSON, XML, XLSX, BerkeleyDB, HTML
URL, JSON URL, or any custom subclass.  Component databases may mix formats
within the same join.

The module exposes the same read-only API as C<Database::Abstraction>:
C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>, C<count>,
C<columns>, C<schema>, C<updated>, C<set_logger>, and the AUTOLOAD column
shortcut.  Callers do not need to know how many underlying databases are
involved.

Think of it as a virtual database table that is assembled on demand from
several real tables, one per component database.

B<Join backends>

By default (C<backend =E<gt> 'auto'>), C<Database::Join> first checks the
combined source row count.  For small datasets (up to C<max_array_rows>,
default 10,000 rows) it merges entirely in Perl memory.  For larger datasets it
automatically spills source rows into a temporary SQLite database and executes
a single SQL JOIN there, keeping peak RAM to roughly one times the source data
size instead of three.  You can also force either path unconditionally with
C<backend =E<gt> 'sqlite'> or C<backend =E<gt> 'array'>.

=head2 Join semantics

The C<join_type> parameter controls what happens when a particular key value
exists in some component databases but not all:

=over 4

=item C<left> (the default)

All rows from the I<primary> (first) database are returned.  Columns from
subsequent databases are included where a matching row is found, and simply
absent from the hashref where there is no match.  If you are familiar with
SQL, this is a LEFT OUTER JOIN on the first table.

=item C<inner>

Only rows whose join-column value is present in I<every> component database
are returned.  This is equivalent to a SQL INNER JOIN.

=item C<outer>

Every join-column value found in I<any> component database is returned.
Columns from databases that do not have that key value are absent from the
merged row.  This is a FULL OUTER JOIN.

=back

B<Important override rule:> whenever you pass a query criterion for a column
that belongs to a secondary database, that database automatically acts as an
inner-join partner for that query only -- regardless of C<join_type>.  This
gives WHERE-clause semantics.  For example, if you have a LEFT join but query
C<< tier => 'gold' >> on a secondary database, only rows whose secondary entry
has tier = 'gold' are returned (rows with no secondary entry are excluded, just
as a WHERE clause would exclude them).

=head2 Column ownership and routing

At construction time, C<Database::Join> calls C<columns()> on each component
database and builds an internal index that maps every column name to the
database that owns it.

When you pass criteria to a query method, each key-value pair is automatically
routed to the right database.  You never need to say which database a column
belongs to.

The C<join_column> is special: criteria on it are broadcast to I<all>
databases so that each database fetches only the relevant rows before the
in-memory merge.

When the same non-join column name exists in more than one database, the
I<last> database in the C<databases> array wins by default: its value
overwrites earlier ones in merged rows.  Use C<collision_prefix> to
preserve both values under distinct names instead.

=head1 LIMITATIONS

=over 4

=item Memory usage (array backend)

When C<backend> is C<'array'> (or C<'auto'> and the dataset is small), all
matching rows are fetched into Perl memory.  Peak RAM is roughly three times
the source data size.  For large datasets use C<backend =E<gt> 'sqlite'>, or
leave C<backend =E<gt> 'auto'> and set C<max_array_rows> appropriately.

=item SQLite backend uses a persistent cache file

When the SQLite path is active, a single C<.db> file with a randomly generated
name (chosen by C<File::Temp> to avoid collisions) is created in C<tmpdir> the
first time a query runs on a given C<Database::Join> object.  Source data is
spilled into that file once; subsequent queries against the same object reuse
the file without re-fetching the source data.

The cache is automatically invalidated and rebuilt whenever any source
database's C<updated()> timestamp changes (indicating new data), or when
C<add_database()> is called.

The file is deleted when the C<Database::Join> object is destroyed (typically
when it goes out of scope).  At any given moment no more than one such file
exists per object.  The directory must be writable and have enough free space
for the full source data (once, not per-query).

=item No chained builder or raw SQL

C<query()> and C<execute()> are not implemented.  Use C<selectall_arrayref>
or C<fetchrow_hashref> instead.

=item Single-column equi-join only

Joining on more than one column simultaneously, or on expressions, is not
supported.  When the join key has different names in different databases,
use C<join_map> to declare each database's local column name.

=item Sort order

Results are sorted by the C<join_column> value only.  Caller-specified
C<ORDER BY> is not propagated to the component databases.

=item count() fetches all rows

C<count()> executes the full join and counts the resulting rows in Perl.  It
does not push a C<COUNT(*)> query down to the databases.

=back

=head1 COMMON PITFALLS

=over 4

=item The join_column must exist in every component database

If even one database is missing the join key column, C<new()> (or
C<add_database()>) will C<croak> immediately.  Use C<join_map> when the
column has a different local name in some databases.

=item Criteria on a removed column are silently dropped

If you call C<remove_column('tier')> and later query
C<< selectall_arrayref(tier => 'gold') >>, the criterion is ignored (with a
C<carp> warning) and all rows are returned.  Always pass criteria before
removing columns, or restructure your code to avoid this.

=item You cannot remove the join column

C<< $join->remove_column($join->join_column) >> will C<croak>.  The join key
is required for the merge to work.

=item Left join does not guarantee all columns are populated

Under a LEFT join, rows from the primary database that have no matching row
in a secondary database will be returned with I<no keys> from that secondary
database.  Accessing C<< $row->{score} >> on such a row returns C<undef> --
not zero, not an empty string.  Always test C<defined $row->{score}> rather
than just C<$row->{score}> when the secondary match is optional.

=item Filters act as inner-join partners

Any database that has a C<filters> entry is promoted to an inner-join partner,
regardless of C<join_type>.  A row whose join-key value does not appear in
the filtered database's result is removed from the merged output entirely, not
merely missing its secondary columns.  This is intentional but can be
surprising if you expected LEFT join semantics.

=item Criteria-merging replaces scalar filters

When both a base filter and a query criterion target the same column, and both
are operator hashrefs (e.g. C<< { '>' => 60 } >>), the operators are combined
(AND semantics).  But if the query criterion is a plain scalar (e.g.
C<< score => 75 >>), it I<replaces> the base filter for that column entirely --
the base filter is ignored for that query.

=item AUTOLOAD sees the full merged join when filters or join_map are active

When either C<filters> or C<join_map> is in effect, the AUTOLOAD shortcut
(C<< $join->columnname(...) >>) runs the full join query rather than
delegating directly to the owning database.  This is necessary for correctness
but means the result respects all active filters and join-key translations,
which may differ from what the owning database would return on its own.

=item Duplicate column names: last database wins (unless collision_prefix is set)

When two component databases each have a column called C<notes>, the second
database's value silently overwrites the first in every merged row.  Use
C<collision_prefix => { 1 => 'right' }> to publish the second database's
C<notes> as C<right.notes> so both values survive, or use C<remove_columns>
(or C<remove_column>) to drop the unwanted duplicate entirely.

=item Mutating the filters hashref after construction has no effect

C<Database::Join> deep-copies the C<filters> hashref (and any C<filter>
passed to C<add_database>) at the moment of construction.  The original hashref
you passed in is never stored.  If you later modify it -- for example, to
tighten or loosen a filter criterion -- the joined view is I<not> affected.
Construct a new C<Database::Join> object, or use a component
C<Database::Abstraction> that supports dynamic filter modification.

=item auto mode may always use the array path for some DAs

C<backend =E<gt> 'auto'> counts rows cheaply only when each component database
either implements C<dbi_source()> (SQLite-backed) or directly defines a
C<count()> method in its own package.  A DA that merely I<inherits> C<count()>
from C<Database::Abstraction> is treated as uncountable, because the parent
class C<count()> expects a key argument and behaves differently from a
"return total row count" function.  In that case C<Database::Join>
conservatively uses the array path for the whole query, even if the dataset is
large.  To opt in to the SQLite path for such a DA, either add your own
C<count()> override that returns the total row count, implement C<dbi_source()>,
or use C<backend =E<gt> 'sqlite'> unconditionally.

=item dbi_source() ATTACH is unconditional - query-time criteria go into WHERE

When a component database implements C<dbi_source()>, C<Database::Join> always
uses the zero-copy ATTACH path, I<even when the current query includes criteria
for columns in that database>.  The criteria are translated into parameterised
SQL C<WHERE> clauses applied against the ATTACHed table; no row-level copy is
performed.  (Prior to 0.005.0 the presence of any query-time criteria would
force a spill; that restriction has been removed.)

=item Broadcast join-column criterion does not force secondaries into inner-join

When a caller passes a join-column criterion (e.g. C<entry =E<gt> 'k1'>),
C<Database::Join> broadcasts it to all component databases so each DA can
filter its fetch to the requested key.  Prior to 0.006.0 this broadcast was
incorrectly counted as "having criteria" for secondary databases, causing
C<left> and C<outer> joins to silently behave as C<inner> joins when a
join-column criterion was present.  The fix: only non-join-column criteria
(e.g. column filters from the caller or base C<filters =E<gt> {...}>) promote
a secondary to inner-join status.  The broadcast itself is now a transparent
key-range selector that does not affect join semantics.

=item Temp file directory must be writable and have free space

The SQLite path creates one temporary C<.db> file per C<Database::Join> object
in C<tmpdir> (default: C<File::Spec-E<gt>tmpdir()>, usually C</tmp> on Unix).
The filename is randomly generated by C<File::Temp> -- you cannot predict it,
only the directory is under your control.  The file is created on the first
query and kept alive until the object is destroyed; it is not re-created on
every query call.  If the directory is not writable, or the filesystem is full,
the call will C<croak> with C<error_sqlite_connect>.  Check permissions and
free space if you see that error.

=back

=head1 METHODS

=head2 new

=head3 SYNOPSIS

    my $join = Database::Join->new(
        databases        => [ $db1, $db2 ],
        join_column      => 'entry',
        join_type        => 'left',
        join_map         => { 1 => 'local_col' },
        filters          => { 1 => { score => { '>' => 60 } } },
        collision_prefix => { 1 => 'right' },
        remove_columns   => [ 'email', 'internal_id' ],
        backend          => 'auto',        # 'auto' | 'sqlite' | 'array'
        max_array_rows   => 10_000,        # threshold for 'auto' mode
        tmpdir           => '/tmp',        # directory for temp SQLite file
        logger           => $log,
        i18n             => $locale,
    );

=head3 DESCRIPTION

Constructs and returns a new C<Database::Join> object.

Each element of C<databases> must be an already-instantiated subclass of
C<Database::Abstraction>.  The constructor calls C<columns()> on every
database to build an internal column-routing table and verifies that
C<join_column> (or its local alias from C<join_map>) is present in each one.

Columns listed in C<remove_columns> are hidden immediately: they do not appear
in C<columns()>, C<schema()>, or any returned row hashref.  This is equivalent
to calling C<remove_column> once per name after construction.

=head3 API SPECIFICATION

=head4 Input

    databases      => { type => 'arrayref', required => 1 }
                      # One or more Database::Abstraction subclass objects.
                      #
                      # DOMAIN -- EP valid:   non-empty arrayref of blessed DA subclasses.
                      # DOMAIN -- EP invalid: scalar, hashref, or absent => croak.
                      # DOMAIN -- BVA size:   minimum 1 element; no documented upper bound.
                      # DOMAIN -- BVA elem:   each element must pass isa('Database::Abstraction').

    join_column    => { type => 'string',   optional => 1, default => 'entry' }
                      # The column name shared by all databases (the join key).
                      #
                      # DOMAIN -- EP valid:   any non-empty string present in every component DA.
                      # DOMAIN -- EP invalid: column absent from any DA => croak join_col_missing.
                      # DOMAIN -- BVA:        empty string '' is treated as a column name and
                      #                       will croak if (as expected) it is absent from every DA.
                      # DOMAIN -- NOTE:       matching is case-sensitive and exact.

    join_type      => { type => 'string',   optional => 1, default => 'left',
                        enum => ['inner', 'left', 'outer'] }
                      # Controls which keys appear in the result when not all
                      # databases share the same key values.
                      #
                      # DOMAIN -- EP valid:   exactly 'inner', 'left', or 'outer'.
                      # DOMAIN -- EP invalid: any other string including 'INNER', 'LEFT',
                      #                       'OUTER' (enum check is case-sensitive), 'cross',
                      #                       or '' => croak from validate_strict.

    join_map       => { type => 'hashref',  optional => 1 }
                      # Zero-based database index => local column name.
                      # See the join_map section for full details.
                      #
                      # DOMAIN -- EP valid:   hashref values must be plain strings.
                      # DOMAIN -- EP invalid: reference value (hashref, arrayref, coderef, etc.)
                      #                       => croak; the guard prevents heap-address leakage.
                      # DOMAIN -- BVA:        out-of-range keys (beyond the databases array) are
                      #                       silently ignored.

    filters        => { type => 'hashref',  optional => 1 }
                      # Zero-based database index => criteria hashref.
                      # Permanent row restrictions on individual databases.
                      # See the filters section for full details.

    collision_prefix => { type => 'hashref', optional => 1 }
                      # Zero-based database index (>0) => prefix string.
                      # When a secondary database has a column that collides
                      # with a column already present in the merged view, the
                      # secondary column is published as "$prefix.$col" instead
                      # of silently overwriting the earlier value.
                      # Index 0 entries are silently ignored.
                      # Omitting this parameter preserves the original
                      # last-database-wins behaviour.
                      # See the collision_prefix section for full details.
                      #
                      # DOMAIN -- EP valid:   absent or {} => last-database-wins (no change).
                      # DOMAIN -- EP valid:   { N => 'prefix' } where N > 0 => colliding
                      #                       columns from DB[N] published as "$prefix.$col";
                      #                       non-colliding columns from the same DB added plain.
                      # DOMAIN -- EP note:    index-0 entries are silently ignored.
                      # DOMAIN -- Invariant:  join_column is never prefixed regardless of
                      #                       collision_prefix configuration.

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names to hide from the merged view.
                      #
                      # DOMAIN -- EP valid:   arrayref of any strings; non-existent columns
                      #                       are silently ignored (idempotent).
                      # DOMAIN -- EP invalid: join_column itself => croak remove_join_col.
                      # DOMAIN -- BVA:        [] empty arrayref is a safe no-op.

    backend        => { type => 'string',   optional => 1, default => 'auto',
                        enum => ['array', 'sqlite', 'auto'] }
                      # Controls which join strategy is used.
                      #   'auto'   -- (default) use 'array' when combined source row count
                      #              <= max_array_rows, 'sqlite' otherwise.
                      #   'sqlite' -- always spill to a temporary SQLite database.
                      #   'array'  -- always use the in-memory merge path.
                      #
                      # DOMAIN -- EP valid:   'array', 'sqlite', or 'auto' (case-sensitive).
                      # DOMAIN -- EP invalid: any other string => croak error_invalid_backend.
                      # DOMAIN -- Default:    'auto'.

    max_array_rows => { type => 'integer',  optional => 1, default => 10_000 }
                      # Row-count threshold for 'auto' mode.  When the combined
                      # source row count exceeds this value, the SQLite path is used.
                      # Ignored when backend is 'array' or 'sqlite'.
                      #
                      # DOMAIN -- EP valid:   any non-negative integer.
                      # DOMAIN -- BVA:        0 means always use SQLite (all counts exceed 0).
                      # DOMAIN -- Default:    10,000.

    tmpdir         => { type => 'string',   optional => 1 }
                      # Directory for the per-call temporary SQLite database file.
                      # The file is created securely by File::Temp and removed when
                      # the query completes.  Ignored when backend is 'array'.
                      #
                      # DOMAIN -- EP valid:   any writable directory path string.
                      # DOMAIN -- EP absent:  uses File::Spec->tmpdir() (system temp dir).

    logger         => { type => 'object',   optional => 1 }
                      # Logger object propagated to all component databases.

    i18n           => { type => 'object',   optional => 1 }
                      # Localisation object with a translate($key, @args) method.

=head4 Output

    A blessed Database::Join object.

=head3 EXAMPLE

    # Customers database: entry | name | email
    # Loyalty   database: entry | tier | points

    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        join_type      => 'inner',            # only customers who also have loyalty records
        remove_columns => [ 'email' ],        # hide PII from query results
        filters        => { 1 => { points => { '>' => 0 } } }, # ignore zero-point records
    );

    my $rows = $join->selectall_arrayref();
    # Each row: { entry => ..., name => ..., tier => ..., points => ... }
    # 'email' is absent. Zero-point loyalty records are excluded.

=head3 PSEUDOCODE

    validate all parameters with validate_strict
    croak if databases is empty
    croak if any element of databases is not a Database::Abstraction subclass
    bless the object with all fields initialised
    call _build_col_index to map every column to its owning database
        and verify join_column presence in each database
    for each column in remove_columns: call remove_column
    return the new object

=head3 MESSAGES

    error_no_databases     -- databases arrayref was empty
    error_invalid_db       -- an element of databases is not a D::A subclass
    error_join_col_missing -- join_column (or its join_map alias) not found in a database
    error_invalid_backend  -- backend value is not 'array', 'sqlite', or 'auto'
    error_sqlite_connect   -- temporary SQLite database could not be created (backend='sqlite'/'auto')

=cut

sub new {
	my ($class, @args) = @_;

	my $p = validate_strict(
		schema => {
			# databases	=> { type => 'arrayref', element_type => 'object' },
			databases	=> { type => 'arrayref' },
			join_column	=> { type => 'string',   optional => 1, default => 'entry' },
			join_type	=> {
				type => 'string',
				optional => 1,
				default => 'left',
				enum => ['inner', 'left', 'outer']
			},
			join_map	      => { type => 'hashref',  optional => 1 },
			filters		      => { type => 'hashref',  optional => 1 },
			collision_prefix  => { type => 'hashref',  optional => 1 },
			remove_columns	  => { type => 'arrayref', optional => 1 },
			backend	=> {
				type => 'string',
				optional => 1,
				default => 'auto',
				enum => ['array', 'sqlite', 'auto']
			},
			max_array_rows    => { type => 'integer',  optional => 1, default => 10_000 },
			tmpdir            => { type => 'string',   optional => 1 },
			logger		=> { type => 'object',   optional => 1 },
			i18n		=> { type => 'object',   optional => 1 },
		},
		input => get_params(undef, \@args) // {},
	);

	croak _msg($p->{i18n}, 'error_no_databases')
		unless @{ $p->{databases} };

	# Capture caller-supplied logger and i18n object BEFORE Object::Configure::configure
	# overwrites them with class-level defaults.  configure() reads default values
	# from Database::Abstraction's class config and silently replaces any caller-
	# supplied value if a class default exists for that key.
	my $caller_logger = $p->{logger};
	my $caller_i18n   = $p->{i18n};

	$p = Object::Configure::configure($class, $p);

	for my $i (0 .. $#{ $p->{databases} }) {
		croak _msg($p->{i18n}, 'error_invalid_db', $i)
			unless blessed($p->{databases}[$i])
			    && $p->{databases}[$i]->can('selectall_arrayref')
			    && $p->{databases}[$i]->can('columns');
	}

	# Cache the primary database's internal primary-key column name once at
	# construction.  AUTOLOAD uses this to map a bare positional argument to the
	# correct column when join_map is active and the primary DB's primary key
	# differs from join_column (e.g. join_col='statecode' but primary key='entry').
	# Accessing {id} here — at construction time, before the object is shared —
	# is the single permitted point of coupling to DA's internal field; caching
	# avoids repeating the hash intrusion on every AUTOLOAD call.
	my $primary_pk = $p->{databases}[0]{id} // $p->{join_column};

	my $self = bless {
		_dbs          => $p->{databases},
		_join_col     => $p->{join_column},
		_join_type    => $p->{join_type},
		_join_map     => $p->{join_map} // {},	# db_index => local join col name
		# Security: deep-copy filters so post-construction mutation of the caller's
		# hashref cannot silently bypass the inner-join row-security guarantee.
		# Two-level copy mirrors the broadcast-copy idiom in _partition_criteria:
		# outer keys are db indices (integers); inner values are criteria hashrefs
		# whose operator sub-hashrefs are also shallow-copied one level deeper.
		_filters          => _copy_filters($p->{filters}),	# db_index => criteria hashref
		_collision_prefix => $p->{collision_prefix} // {},	# db_index => prefix string
		_logger           => $caller_logger,
		_i18n             => $caller_i18n,
		_col_db           => {},	# published_col_name => db_index
		_db_cols          => [],	# per-db column-presence hashref
		_removed_cols     => {},	# published_col_name => 1 (hidden from view)
		_col_cache        => undef,	# memoised columns() result
		_schema_cache     => undef,	# memoised schema() result
		_col_rename       => [],	# per-db: { orig_col => published_col } for collisions
		_col_unrename     => [],	# per-db: { published_col => orig_col } reverse map
		_autoload_pk      => $primary_pk,	# primary DB's key col; positional arg for AUTOLOAD
		_backend          => $p->{backend},
		_max_array_rows   => $p->{max_array_rows},
		_tmpdir           => $p->{tmpdir} // File::Spec->tmpdir,
	}, $class;

	$self->_build_col_index();

	# Propagate the logger to every component database if one was supplied.
	# set_logger() is used here (rather than a direct hash write) to honour each
	# DA's own logging setup hook and remain decoupled from DA internals.
	if (my $log = $self->{_logger}) {
		$_->set_logger($log) for @{ $self->{_dbs} };
	}

	# Apply column removals requested in the constructor
	if (my $rc = $p->{remove_columns}) {
		$self->remove_column($_) for @{$rc};
	}

	return $self;
}

# ---------------------------------------------------------------------------
# Public API (mirrors Database::Abstraction)
# ---------------------------------------------------------------------------

=head2 join_map - joining on differently-named columns

By default every component database must have a column whose name matches
C<join_column>.  If a database uses a different local name for the join key,
declare the mapping with C<join_map>.

C<join_map> is a hashref.  Each B<key> is the B<zero-based position> of a
database in the C<databases> array (0 = first, 1 = second, and so on).  Each
B<value> is the name that B<that particular database> uses for the join key.

Databases not listed in C<join_map> are assumed to already have a column
named C<join_column> and need no entry.

Throughout the merged view the join key is I<always> referred to by the name
given in C<join_column>.  The local alias is never exposed in returned rows,
in C<columns()>, or in C<schema()>.

B<When do you need join_map?>

You need C<join_map> when you have two tables like:

    cities table  : entry (the city name) | statecode
    stnames table : entry (the state code) | state

Here you want to join cities.statecode to stnames.entry.  You choose
C<< join_column => 'statecode' >> as the canonical name, but stnames calls
that same concept C<entry>, so you declare:

    join_map => { 1 => 'entry' }  # stnames (index 1) calls it 'entry'

B<Example>

    #                        index 0     index 1
    my @databases = (       $cities,    $stnames  );
    #  join key column:    'statecode'  'entry'
    #  join_column:        'statecode' (chosen canonical name)
    #  stnames differs, so declare the alias:

    my $join = Database::Join->new(
        databases   => \@databases,
        join_column => 'statecode',
        join_map    => { 1 => 'entry' },
    );

    my $rows = $join->selectall_arrayref();
    # Each $row has keys: entry (city), statecode, state
    # 'entry' from stnames is never exposed directly.

    my $row = $join->fetchrow_hashref(statecode => 'CA');

B<Using add_database instead>

If you build the join incrementally with C<add_database>, pass
C<join_column> directly to that call instead of using C<join_map>:

    my $join = Database::Join->new(
        databases   => [ $cities ],
        join_column => 'statecode',
    );
    $join->add_database($stnames, join_column => 'entry');

This is exactly equivalent to the C<join_map> form above.

=head2 filters - permanent per-database row filters

C<filters> lets you restrict a component database to a subset of its rows
permanently, without repeating the criterion on every query call.

Think of it as telling the join: "whenever you query this database, always
add these extra conditions".  Callers never need to specify the restriction
themselves and can never accidentally omit it.

C<filters> is a hashref.  Each B<key> is the B<zero-based position> of a
database in the C<databases> array (same numbering as C<join_map>).  Each
B<value> is a criteria hashref in the same format as C<selectall_arrayref>
accepts.

B<Key-set semantics>

A filtered database always acts as an inner-join partner, regardless of the
C<join_type> setting.  Any join-key value that does not pass the filter is
excluded from the merged output entirely -- not just missing its secondary
columns.  This ensures the filter genuinely restricts the view rather than
simply hiding a few fields.

B<Criteria merging>

When a query call also passes a criterion for a column that already has a base
filter, the two constraints are combined:

=over 4

=item *

When both the base filter value and the query criterion are operator hashrefs
(e.g. C<< { '>' => 60 } >> and C<< { '<' => 365 } >>), their operators are
merged: I<both> constraints apply simultaneously (AND semantics).

=item *

When either value is a plain scalar, or the operators conflict, the
query-time criterion wins and the base filter for that column is ignored for
that one call.

=back

B<Example -- only show orders placed more than 60 days ago>

    my $join = Database::Join->new(
        databases   => [ $customers, $orders ],
        join_column => 'entry',
        filters     => { 1 => { age_days => { '>' => 60 } } },
    );

    # Every query automatically sees only old orders
    my $rows = $join->selectall_arrayref();

    # Additional criteria layer on top -- gold tier AND old order
    my $vip  = $join->selectall_arrayref(tier => 'gold');

    # Range intersection: age_days > 60 AND age_days < 365
    my $mid  = $join->selectall_arrayref(age_days => { '<' => 365 });

When using C<add_database>, pass C<filter> (singular) to set the base
criteria for the new database:

    $join->add_database($orders, filter => { age_days => { '>' => 60 } });

=head2 collision_prefix - preserve colliding columns from secondary databases

By default, when a column name appears in more than one database the I<last>
database wins: its value silently overwrites earlier ones in merged rows.
This loses data and makes the origin invisible.

C<collision_prefix> changes this for secondary databases you designate.
When a secondary database at index N has a column that already exists in the
merged view, and C<collision_prefix-E<gt>{N}> is set, the colliding column is
published as C<"$prefix.$col"> instead of overwriting.  Both values are then
visible: the original column keeps its name (from the earlier database), and
the collision gets the prefixed name.

C<collision_prefix> is a hashref.  Each B<key> is the B<zero-based index> of
a secondary database in the C<databases> array (same numbering as C<join_map>).
Each B<value> is the prefix string to prepend.  An index-0 entry is
meaningless and silently ignored.  Omitting C<collision_prefix> entirely
preserves the previous last-wins behaviour and changes nothing.

Non-colliding columns from a secondary database are always added as-is with
no prefix, whether or not C<collision_prefix> is configured.

B<Example -- sales table and products table, both with a "product" column>

    # $sales    columns: id, product, amount, date
    # $products columns: sku, product, price, category
    # join on 'product' (left key) matched against 'sku' (right key via join_map)

    my $join = Database::Join->new(
        databases        => [$sales, $products],
        join_column      => 'product',
        join_map         => { 1 => 'sku' },
        collision_prefix => { 1 => 'products' },
    );

    $join->columns;
    # => ['amount', 'category', 'date', 'id', 'price', 'product', 'products.product']
    #                                                               ^-- prefixed collision

    my $row = $join->fetchrow_hashref(product => 'widget');
    # $row->{product}            -- value from $sales
    # $row->{'products.product'} -- value from $products (different row, same column name)
    # $row->{price}              -- from $products, no collision, kept as-is

B<Querying on a prefixed column>

Use the full published name as the criterion key:

    my $rows = $join->selectall_arrayref('products.product' => 'widget');
    # Internally routes as: product => 'widget' to $products

B<Interaction with remove_column>

C<remove_column> operates on published names.  To suppress a prefixed
collision column entirely, pass the prefixed name:

    $join->remove_column('products.product');

=head2 backend - SQLite join backend for large datasets

C<Database::Join> can merge component databases in two different ways,
controlled by the C<backend> constructor parameter.

=over 4

=item C<backend =E<gt> 'array'> -- in-memory merge (original behaviour)

All matching rows are fetched from every component database into Perl hashes
and merged there.  Simple and fast for small and medium datasets.  Peak RAM
is roughly three times the combined source data size (one copy per database
plus one merged copy).

=item C<backend =E<gt> 'sqlite'> -- SQL JOIN via a cached temporary file

C<Database::Join> creates a temporary SQLite database file, spills source
rows into it (one table per component database), then executes a single SQL
C<JOIN> statement per query call.  Peak RAM drops to roughly one times the
source data size.

The temporary file is created once and reused across multiple query calls on
the same object (the cache).  Only query-time criteria vary per call; they
are applied as SQL C<WHERE> clauses against the cached data.  The cache is
automatically rebuilt when any source database's C<updated()> timestamp
changes.  The file is deleted when the object is destroyed (goes out of
scope).  See I<Temporary file: name, location, and lifetime> below for
details.

Requires C<DBD::SQLite E<gt>= 1.70> (C<FULL OUTER JOIN> support was added in
SQLite 3.39.0; DBD::SQLite 1.70 ships SQLite 3.39.2).

=item C<backend =E<gt> 'auto'> (default)

C<Database::Join> counts the total rows from all component databases cheaply
-- without fetching them -- and then decides:

=over 4

=item *

If the combined count is less than or equal to C<max_array_rows> (default
10,000), use the array path.

=item *

If the combined count exceeds C<max_array_rows>, use the SQLite path.

=back

For counting to work without fetching, each component database must either
implement the C<dbi_source()> interface (for SQLite-backed sources, where a
C<COUNT(*)> SQL query is issued directly), or directly define a C<count()>
method in its own package -- not just inherit one from a parent class.  If
neither is available for a particular database, C<Database::Join> plays it
safe and uses the array path for the whole query without fetching any rows.

=back

B<Choosing max_array_rows>

The default of 10,000 is a reasonable starting point.  Adjust it to match
your hardware and typical row width.  For wide rows (many columns or long
strings) you may want a lower threshold; for narrow rows you can raise it.

B<Temporary file: name, location, and lifetime>

When the SQLite path is active, a single temporary SQLite database file acts
as the join cache for the life of the C<Database::Join> object.

B<Name>: the filename is randomly generated by C<File::Temp>, for example:

    /tmp/Cj8xK7mP2Q.db

The random portion (ten characters) is chosen automatically to avoid
collisions.  Only the directory is under your control; you cannot specify
the filename itself.

B<Location>: controlled by the C<tmpdir> constructor parameter.
If C<tmpdir> is not specified, C<File::Spec-E<gt>tmpdir()> is used (usually
C</tmp> on Unix, or the value of the C<TEMP> or C<TMP> environment variable
on Windows).

B<Lifetime: one file per object, deleted when the object is destroyed>: the
file is created on the first query call that uses the SQLite path and kept
alive until the C<Database::Join> object is destroyed (i.e. when it goes out
of scope or is explicitly C<undef>-d).  At most one file exists per object at
any given moment.  Calling C<selectall_arrayref()> ten times on the same
object creates and uses I<one> file, not ten.

B<Cache invalidation>: the cache is automatically rebuilt (the old file is
replaced with a new one) when any source database's C<updated()> return value
changes, or when C<add_database()> is called.  Base-filter criteria
(C<filters> constructor parameter) are applied once at build time for spilled
sources; query-time criteria are applied per-call as SQL C<WHERE> clauses.

To use a different directory -- for example a RAM-backed filesystem or a
faster local disk:

    my $join = Database::Join->new(
        databases      => [ $db1, $db2 ],
        join_column    => 'entry',
        backend        => 'sqlite',
        tmpdir         => '/dev/shm',     # Linux RAM disk
    );

B<Zero-copy ATTACH (C<dbi_source()> interface)>

Normally, when the SQLite path is active, rows from each component database
are fetched one by one and inserted into the temporary SQLite file.  This is
efficient but does involve INSERT overhead.

If a component database is itself SQLite-backed and implements a
C<dbi_source()> method, C<Database::Join> can skip the row-by-row copy
entirely and instead use C<ATTACH DATABASE> to link the source file directly
to the temporary join connection.  This is the zero-copy path and is
significantly faster for large SQLite sources.

The C<dbi_source()> method must return a hashref with two keys:

=over 4

=item C<dbh>

A connected C<DBD::SQLite> database handle (C<DBI> connection object).

=item C<table>

The name of the table in that database that holds the source rows.

=back

Example implementation:

    package My::SQLiteDatabase;
    use parent 'Database::Abstraction';

    sub dbi_source {
        my ($self) = @_;
        return {
            dbh   => $self->{_dbh},      # connected DBD::SQLite handle
            table => $self->{_table},    # table name in that database
        };
    }

    1;

The zero-copy ATTACH path is only used when there are no query-time criteria
for that database in the current call.  When criteria exist, the database is
queried via C<selectall_arrayref> as usual and the resulting rows are inserted
into the temporary file.

B<Result identity>

Both the array path and the SQLite path produce identical results for any
given query.  You can switch between them freely without changing callers.
The C<collision_prefix> column renaming, C<join_map> key translation, and all
three join types (left, inner, outer) work identically on both paths.

=head2 selectall_arrayref

=head3 SYNOPSIS

    my $rows = $join->selectall_arrayref();
    my $rows = $join->selectall_arrayref(tier  => 'gold');
    my $rows = $join->selectall_arrayref(score => { '>' => 80 });
    my $rows = $join->selectall_arrayref('C001');  # positional: entry => 'C001'

=head3 DESCRIPTION

Returns an arrayref of hashrefs representing the merged view of all component
databases, optionally filtered by the given criteria.

Criteria for columns that live in different databases are routed
automatically: each database is queried with only the criteria that apply to
its own columns.  The results are combined in memory using C<join_column>.

Accepts the same criteria syntax as C<Database::Abstraction::selectall_arrayref>.
A single plain scalar argument is interpreted as the C<join_column> value
(equivalent to C<< entry => 'C001' >> when C<join_column> is C<'entry'>).

=head3 API SPECIFICATION

=head4 Input

    Calling conventions (in order of precedence):
      1. No arguments             -- returns all rows
      2. One plain scalar         -- shorthand for join_column => $scalar
      3. Key-value pairs or
         a criteria hashref       -- routed per-database

    Values may be:
      Plain scalar                -- exact match
      Hashref of operators        -- e.g. { '>' => 80 }

=head4 Output

    Arrayref of hashrefs; one hashref per qualifying merged row,
    sorted ascending by join_column value.
    Returns a reference to an empty array when no rows match.

=head3 EXAMPLE

    # All rows from both databases
    my $all = $join->selectall_arrayref();

    # Only rows where the 'tier' column (from the loyalty database)
    # equals 'gold' -- the criterion is routed to the right database
    my $vip = $join->selectall_arrayref(tier => 'gold');

    # Operator hashref: score > 80
    my $high = $join->selectall_arrayref(score => { '>' => 80 });

    # Access each merged row
    for my $row (@{$vip}) {
        printf "%-10s tier=%-8s score=%d\n",
            $row->{entry}, $row->{tier}, $row->{score} // 0;
    }

=cut

sub selectall_arrayref {
	my ($self, @args) = @_;
	return $self->_joined_query($self->_parse_query_args(undef, @args));
}

=head2 selectall_array

=head3 SYNOPSIS

    my @rows = $join->selectall_array(tier => 'gold');

    # Scalar context: only the first matching row
    my $first = $join->selectall_array(entry => 'C001');

=head3 DESCRIPTION

In list context returns a list of merged hashrefs -- the same rows that
C<selectall_arrayref> would return, just as a flat list rather than an
arrayref.

In scalar context returns only the first matching hashref (or C<undef> if
nothing matches).

=head3 API SPECIFICATION

=head4 Input

    Same as selectall_arrayref.

=head4 Output

    List context:   list of hashrefs (may be empty).
    Scalar context: single hashref or undef.

=head3 EXAMPLE

    my @all = $join->selectall_array();
    print scalar @all, " rows\n";

    # First gold-tier customer only
    my $first_vip = $join->selectall_array(tier => 'gold');
    print $first_vip->{name}, "\n" if defined $first_vip;

=cut

sub selectall_array {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return wantarray ? @{$rows} : $rows->[0];
}

=head2 fetchrow_hashref

=head3 SYNOPSIS

    my $row = $join->fetchrow_hashref(entry => 'C001');
    my $row = $join->fetchrow_hashref('C001');   # positional shorthand

=head3 DESCRIPTION

Returns a single merged hashref for the first row matching the given
criteria, or C<undef> when nothing matches.

Equivalent to calling C<selectall_arrayref> and taking only the first element.
All the same criteria conventions apply.

=head3 API SPECIFICATION

=head4 Input

    Same as selectall_arrayref.

=head4 Output

    Hashref, or undef when no row matches.

=head3 EXAMPLE

    my $row = $join->fetchrow_hashref(entry => 'C001');
    if (defined $row) {
        print "Name: $row->{name}, Tier: $row->{tier}\n";
    } else {
        print "No record for C001\n";
    }

    # Positional: works when join_column is 'entry'
    my $row2 = $join->fetchrow_hashref('C001');

=cut

sub fetchrow_hashref {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return $rows->[0];
}

=head2 count

=head3 SYNOPSIS

    my $total  = $join->count();
    my $active = $join->count(tier => 'gold');

=head3 DESCRIPTION

Returns the number of merged rows that satisfy the given criteria.

The full join is performed and the resulting rows are counted in Perl; no
C<COUNT(*)> is pushed down to the component databases.

=head3 API SPECIFICATION

=head4 Input

    Same criteria syntax as selectall_arrayref.

=head4 Output

    Non-negative integer.

=head3 EXAMPLE

    my $total   = $join->count();
    my $gold    = $join->count(tier => 'gold');
    my $high    = $join->count(score => { '>' => 90 });

    printf "%d total, %d gold-tier, %d high-scorers\n",
        $total, $gold, $high;

=cut

sub count {
	my ($self, @args) = @_;
	my $rows = $self->_joined_query($self->_parse_query_args(undef, @args));
	return scalar @{$rows};
}

=head2 columns

=head3 SYNOPSIS

    my $cols = $join->columns();

=head3 DESCRIPTION

Returns an arrayref of all column names visible in the merged view,
deduplicated and sorted alphabetically.

The C<join_column> appears exactly once, even if it exists under different
local names in some databases (see C<join_map>).  Columns that have been
hidden with C<remove_column> or C<remove_columns> do not appear.

The result is memoised: repeated calls are cheap.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Arrayref of column name strings, sorted alphabetically.

=head3 EXAMPLE

    my $cols = $join->columns();
    print join(', ', @{$cols}), "\n";
    # e.g. "entry, name, score, tier"

=cut

sub columns {
	my ($self) = @_;

	return $self->{_col_cache} if $self->{_col_cache};

	my %seen;
	my @cols;
	my $join_col = $self->{_join_col};

	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $local_jc = $self->{_join_map}{$i};
		my $renames  = $self->{_col_rename}[$i] // {};
		for my $col (@{ $self->{_dbs}[$i]->columns() }) {
			# The local join-key alias is not a data column; the canonical name
			# is already contributed by the database that owns it under that name.
			next if $local_jc && $col eq $local_jc && $col ne $join_col;
			# Use the published name (prefixed if this column was a collision rename)
			my $pub = $renames->{$col} // $col;
			next if $seen{$pub}++;
			next if $self->{_removed_cols}{$pub};
			push @cols, $pub;
		}
	}

	$self->{_col_cache} = [ sort @cols ];
	return $self->{_col_cache};
}

=head2 schema

=head3 SYNOPSIS

    my $schema = $join->schema();

=head3 DESCRIPTION

Returns a merged schema hashref for all visible columns across all component
databases.  Each key is a column name; each value is the schema metadata
hashref returned by C<Database::Abstraction::schema()> for that column
(typically C<{ type, nullable, default, pk }>).

When the same column name appears in more than one database the I<last>
database's metadata is used.  Columns hidden with C<remove_column> are not
included.

The result is memoised.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Hashref: column_name => { type => ..., nullable => ..., default => ..., pk => ... }.

=head3 EXAMPLE

    my $schema = $join->schema();
    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%-15s type=%-10s nullable=%s\n",
            $col, $info->{type}, $info->{nullable} ? 'yes' : 'no';
    }

=cut

sub schema {
	my ($self) = @_;

	return $self->{_schema_cache} if $self->{_schema_cache};

	# Hash slice assignment (@merged{keys} = values) is O(M) per database;
	# the previous (%merged = (%merged, %s)) pattern was O(N×M) per iteration,
	# totalling O(N²×M) over all databases for the same result.
	my %merged;
	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $s        = $self->{_dbs}[$i]->schema() // {};
		my $local_jc = $self->{_join_map}{$i};
		my $renames  = $self->{_col_rename}[$i] // {};
		my $skip_jc  = $local_jc && $local_jc ne $self->{_join_col};
		if (!$skip_jc && !%{$renames}) {
			# Fast path: no join-key alias to exclude and no collision renames
			@merged{keys %{$s}} = values %{$s};
		} else {
			for my $col (keys %{$s}) {
				next if $skip_jc && $col eq $local_jc;
				$merged{ $renames->{$col} // $col } = $s->{$col};
			}
		}
	}

	delete @merged{keys %{ $self->{_removed_cols} }}
		if %{ $self->{_removed_cols} };

	$self->{_schema_cache} = \%merged;
	return $self->{_schema_cache};
}

=head2 updated

=head3 SYNOPSIS

    my $ts = $join->updated();

=head3 DESCRIPTION

Returns the Unix timestamp of the most recent modification across all
component databases.  This is the maximum of all individual C<updated()>
return values.

Use this to implement simple cache-invalidation logic: if C<updated()>
has advanced since your last snapshot, re-query.

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    Unix timestamp (positive integer).

=head3 EXAMPLE

    my $last_modified = $join->updated();
    if ($last_modified > $my_cache_timestamp) {
        $my_cache = $join->selectall_arrayref();
        $my_cache_timestamp = $last_modified;
    }

=cut

sub updated {
	my ($self) = @_;
	return max(map { $_->updated() } @{ $self->{_dbs} });
}

=head2 set_logger

=head3 SYNOPSIS

    $join->set_logger($log);

=head3 DESCRIPTION

Attaches a new logger object to the join and propagates it to every component
database.  The logger is used for diagnostic output by all component databases.

=head3 API SPECIFICATION

=head4 Input

    $log    Positional: a logger object (required).
            Must support whatever interface Database::Abstraction expects.

=head4 Output

    Returns C<$self> for method chaining.

=head3 EXAMPLE

    # Log::Any is used here as an example; any object that implements
    # debug() and info() (or whichever methods your component databases
    # call internally) works equally well.
    use Log::Any qw($log);

    my $join = Database::Join->new(databases => [$db1, $db2], join_column => 'entry');
    $join->set_logger($log);
    # $log is now used by $join and by $db1 and $db2

=cut

sub set_logger {
	my ($self, $logger) = @_;

	croak 'Usage: set_logger($logger)' unless defined $logger;

	$self->{_logger} = $logger;
	$_->set_logger($logger) for @{ $self->{_dbs} };

	return $self;
}

=head2 add_database

=head3 SYNOPSIS

    # Positional: database object as first argument
    $join->add_database($db);

    # Named: equivalent to the above
    $join->add_database(database => $db);

    # With options (mixed positional + named)
    $join->add_database($db, remove_columns => ['internal_id']);
    $join->add_database($db, join_column    => 'local_key_name');
    $join->add_database($db, filter         => { score => { '>' => 60 } });

    # Chainable
    $join->add_database($db1)->add_database($db2, remove_columns => ['notes']);

=head3 DESCRIPTION

Adds one more C<Database::Abstraction> subclass object to the logical view
and immediately updates the column-ownership index.

After the call, all query methods return rows that include columns from the
newly added database, and criteria on those new columns are routed to it
automatically.

When a column name in the new database already exists in an earlier database,
the new database becomes the authoritative source for that column
(last-database-wins, the same rule that applies at construction time).

The join-column must be present in the new database (or declared via
C<join_column>).  The logger is propagated to the new database if one is set.

C<add_database> is the runtime equivalent of listing the database in the
C<databases> array to C<new>.  The optional C<join_column> parameter is
equivalent to a C<join_map> entry; the optional C<filter> parameter is
equivalent to a C<filters> entry.

=head3 API SPECIFICATION

=head4 Input

    database       => { type => 'object',   required => 1 }
                      # A Database::Abstraction subclass instance.
                      #
                      # DOMAIN -- EP valid:   blessed object that passes
                      #                       isa('Database::Abstraction').
                      # DOMAIN -- EP invalid: non-reference, unblessed ref, wrong class,
                      #                       or non-reference non-key scalar (the guard at
                      #                       the top of add_database rejects it with
                      #                       error_invalid_db before validate_strict runs).

    join_column    => { type => 'string',   optional => 1 }
                      # The name of the join key in THIS new database,
                      # when it differs from the canonical join_column.
                      #
                      # DOMAIN -- EP valid:   any string that exists as a column in the
                      #                       new database.
                      # DOMAIN -- EP invalid: string absent from the new database's columns()
                      #                       => croak error_join_col_missing.

    filter         => { type => 'hashref',  optional => 1 }
                      # Permanent criteria for this database only.
                      # Same format as selectall_arrayref.
                      #
                      # DOMAIN -- EP valid:   hashref of criteria (may be {} for no-op).
                      # DOMAIN -- EP absent:  no permanent filter applied; all rows visible.
                      # DOMAIN -- Key-set:    a non-empty filter makes this DB an inner-join
                      #                       partner regardless of the outer join_type.

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names from this database to hide.
                      #
                      # DOMAIN -- EP valid:   arrayref of strings; non-existent columns silently
                      #                       ignored; empty [] is a safe no-op.
                      # DOMAIN -- EP invalid: join_column itself => croak error_remove_join_col.

=head4 Output

    Returns C<$self> to support method chaining.

=head3 EXAMPLE

    my $join = Database::Join->new(
        databases   => [ $customers ],
        join_column => 'entry',
    );

    # Add loyalty data; hide internal columns from it
    $join->add_database($loyalty, remove_columns => ['audit_ts']);

    # Add score data; only include rows with score > 60
    $join->add_database($scores, filter => { score => { '>' => 60 } });

    # Add a database whose join key has a different local name
    $join->add_database($stnames, join_column => 'state_code');

    # All three options combined, and chained
    $join->add_database($db4,
        join_column    => 'ref_id',
        filter         => { active => 1 },
        remove_columns => ['legacy_col'],
    );

=head3 PSEUDOCODE

    determine the new database's index (length of current _dbs array)
    extract the database object from positional or named argument
    croak if it is not a Database::Abstraction subclass
    register join_column alias in _join_map if different from canonical
    register filter in _filters if provided
    fetch column list from the new database
    croak if the join key is missing from the new database
    append the new database to _dbs and _db_cols
    update _col_db: for each new column, point it at the new index
        (last-database-wins; skip removed columns and the local join alias)
    invalidate _col_cache and _schema_cache
    propagate logger if set
    apply remove_columns if provided
    return $self

=head3 MESSAGES

    error_invalid_db       -- argument is not a Database::Abstraction subclass
    error_join_col_missing -- join_column not found in the new database

=cut

sub add_database {
	my ($self, @args) = @_;

	my $idx = scalar @{ $self->{_dbs} };
	my $db;

	# Fail-fast guard: a non-reference first arg must be a recognised named-pair key.
	# Modus Ponens: !ref(x) ∧ x ∉ @_ADD_DB_KEYS → cannot be a database object → croak.
	# De Morgan reduction: the elsif below is logically equivalent to (@args && ref(args[0]))
	# because the !ref branch was already handled; exhaustion makes the ref() check redundant.
	if (@args && !ref($args[0])) {
		croak $self->_err('error_invalid_db', $idx)
			unless defined($args[0]) && grep { $args[0] eq $_ } @_ADD_DB_KEYS;
	} elsif (@args) {
		# Positional form: first arg is a reference — extract it before get_params
		# to avoid the mixed positional+named-pairs confusion.
		$db = shift @args;
	}

	my $p = validate_strict(
		schema => {
			database  => {
				type => 'object',
				optional => 1,
				can => ['selectall_arrayref', 'columns']
			},
			join_column    => { type => 'string',   optional => 1 },
			filter         => { type => 'hashref',  optional => 1 },
			remove_columns => { type => 'arrayref', optional => 1 },
		},
		input => (@args ? get_params(undef, @args) : {}) // {},
	);

	$db //= $p->{database};

	croak $self->_err('error_invalid_db', $idx)
		unless blessed($db)
		    && $db->can('selectall_arrayref')
		    && $db->can('columns');

	# Determine and register the local join column name for this database
	my $local_jc = $p->{join_column} // $self->{_join_col};
	$self->{_join_map}{$idx} = $local_jc if $p->{join_column};
	# Security: deep-copy the filter; same rationale as the constructor's _copy_filters call.
	$self->{_filters}{$idx}  = _copy_criteria($p->{filter}) if $p->{filter};

	my $cols         = $db->columns();
	my %col_presence = map { $_ => 1 } @{$cols};

	croak $self->_err('error_join_col_missing', $local_jc, $idx, ref($db))
		unless $col_presence{$local_jc};

	# Register the new database
	push @{ $self->{_dbs} },     $db;
	push @{ $self->{_db_cols} }, \%col_presence;

	# Update column routing: last-database-wins for duplicates, unless a
	# collision_prefix is configured for this index (in which case the
	# duplicate is published under "$prefix.$col" instead of overwriting).
	my $prefix = $self->{_collision_prefix}{$idx};
	$self->{_col_rename}[$idx]   //= {};
	$self->{_col_unrename}[$idx] //= {};

	for my $col (@{$cols}) {
		next if $local_jc ne $self->{_join_col} && $col eq $local_jc;

		my $pub;
		if (defined $prefix && exists $self->{_col_db}{$col} && $col ne $self->{_join_col}) {
			# Same guard as _build_col_index: never prefix the join_column itself.
			$pub = "$prefix.$col";
			$self->{_col_rename}[$idx]{$col}   = $pub;
			$self->{_col_unrename}[$idx]{$pub} = $col;
		} else {
			$pub = $col;
		}

		next if $self->{_removed_cols}{$pub};
		$self->{_col_db}{$pub} = $idx;
	}

	# Invalidate memoisation caches
	$self->{_col_cache}    = undef;
	$self->{_schema_cache} = undef;

	# Invalidate the SQLite join cache: a new source requires a full rebuild.
	if (my $old = delete $self->{_sqlite_cache}) {
		local $@;
		eval { $old->{dbh}->disconnect } if $old->{dbh};
	}

	# Propagate logger if one is configured
	if (my $log = $self->{_logger}) {
		$db->set_logger($log);
	}

	# Apply any column removals requested for this database
	if (my $rc = $p->{remove_columns}) {
		$self->remove_column($_) for @{$rc};
	}

	return $self;
}

=head2 remove_column

=head3 SYNOPSIS

    $join->remove_column('email');

    # Chainable
    $join->remove_column('internal_id')->remove_column('audit_ts');

=head3 DESCRIPTION

Permanently hides a column from the merged view.  After this call:

=over 4

=item *

The column does not appear in C<columns()> or C<schema()>.

=item *

Returned row hashrefs do not contain the column key.

=item *

Any query criterion that references the removed column is silently dropped
(with a C<carp> warning).

=back

The C<join_column> cannot be removed; attempting to do so will C<croak>.
Removing a column that does not exist in any database is silently ignored
(the call is idempotent and safe).  The C<columns()> and C<schema()>
memoisation caches are cleared automatically.

=head3 API SPECIFICATION

=head4 Input

    $col    Positional string: the column name to remove.

            DOMAIN -- EP valid:   any string; non-existent columns are silently
                                  ignored (idempotent call, returns $self).
            DOMAIN -- EP invalid: join_column value => croak error_remove_join_col.
            DOMAIN -- BVA:        undef and '' are explicit no-ops (returns $self).
                                  These are below the minimum meaningful string
                                  length and are handled without any warning.

=head4 Output

    Returns C<$self> to support method chaining.

=head3 EXAMPLE

    # Hide private fields immediately after construction
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
    )->remove_column('email')
     ->remove_column('internal_notes');

    # Verify they are gone
    my $cols = $join->columns();
    # 'email' and 'internal_notes' are absent

=head3 MESSAGES

    error_remove_join_col -- attempt to remove the join_column itself

=cut

sub remove_column {
	my ($self, $col) = @_;

	# Premise: undef and '' are provably no-ops (nothing to remove).
	# Conclusion: guard at the top eliminates two separate defined() checks below.
	return $self unless defined $col && length $col;

	# Premise: $col is defined (proven above) and join_col is always a non-empty string.
	# Conclusion: direct string comparison is safe without a redundant defined() check.
	croak $self->_err('error_remove_join_col', $col)
		if $col eq $self->{_join_col};

	$self->{_removed_cols}{$col} = 1;
	delete $self->{_col_db}{$col};
	$self->{_col_cache}    = undef;
	$self->{_schema_cache} = undef;
	$self->{_removed_list} = undef;	# invalidate the cached removed-column list

	return $self;
}

=head2 query

Not supported.  C<Database::Join> does not implement the chained query
builder.  Calling this method will always C<croak> with an explanatory message.

Use C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>, or
C<count> instead.

=cut

sub query {
	my $self = $_[0];
	croak $self->_err('error_query_unsupported');
}

=head2 execute

Not supported.  Raw SQL cannot span heterogeneous backends that may use
different database engines.  Calling this method will always C<croak>.

Use C<selectall_arrayref> or C<fetchrow_hashref> to query the joined view.

=cut

sub execute {
	my $self = $_[0];
	croak $self->_err('error_execute_unsupported');
}

=head2 AUTOLOAD - column shortcut

Calling an unknown method whose name matches a visible column name performs
a column lookup across the merged view.

=head3 SYNOPSIS

    # Scalar context: value from the first matching row
    my $name  = $join->name(entry => 'C001');

    # List context: values from every matching row
    my @tiers = $join->tier();

    # With a positional join-key argument (when join_column is 'entry')
    my $score = $join->score('C001');

=head3 DESCRIPTION

AUTOLOAD routes the call to the appropriate component database by looking up
the column name in the internal column-ownership index.

When either C<join_map> or C<filters> is active, AUTOLOAD performs a full
join query instead of delegating directly to the owning database.  This is
necessary because:

=over 4

=item *

With C<join_map>, the owning database's primary key may differ from the
canonical join key used in the call arguments.

=item *

With C<filters>, bypassing the join would return rows that the filter is
meant to exclude.

=back

In list context, every matching merged row contributes one value to the
returned list.  In scalar context, only the first row's value is returned.

Calling a method whose name begins with C<_> (a private method) via AUTOLOAD
will C<croak> with a clear error message rather than being silently ignored.

=head3 EXAMPLE

    # Lookup a single customer's name (scalar context)
    my $name = $join->name('C001');   # 'C001' maps to entry => 'C001'
    print "Name: $name\n";

    # Get every tier value in the view (list context)
    my @all_tiers = $join->tier();
    my %freq;
    $freq{$_}++ for @all_tiers;

    # join_map active: AUTOLOAD runs a full join so the criteria are
    # translated correctly between the canonical and local key names.
    my @leesburg_states = sort $join->state('Leesburg');
    # ['Florida', 'Virginia'] if Leesburg appears in two states

=head3 PSEUDOCODE

    extract column name from $AUTOLOAD
    return if DESTROY
    croak if column name starts with '_' (private method guard)
    croak if column name is not in _col_db (unknown column)
    if join_map or filters are active:
        parse calling arguments using _parse_query_args
        call _joined_query to get all merged rows
        return map { $_->{col} } @rows  in list context
        return $rows[0]{col}            in scalar context
    else:
        delegate directly to the owning database

=cut

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;

	my ($col) = $AUTOLOAD =~ /
		::      # package separator — skip the fully-qualified prefix
		(\w++)  # method name: possessive quantifier commits immediately;
		        # no backtrack possible because \w chars cannot match \z
		\z      # strict end-of-string (\z never matches a trailing newline,
		        # unlike $ which can — important if $AUTOLOAD ever embeds \n)
	/x;

	# Private methods must not be reached via AUTOLOAD — croak immediately so
	# typos like $join->_join_col are not silently swallowed.
	# substr() avoids regex-engine overhead for this single-character prefix check.
	croak ref($self), ": cannot call private method '$col' via AUTOLOAD"
		if substr($col, 0, 1) eq '_';

	my $db_idx = $self->{_col_db}{$col};
	croak ref($self), ": unknown column '$col'" unless defined $db_idx;

	# Use a full join query when join_map OR filters are active.  Direct
	# delegation to the owning database would bypass the join key translation
	# (join_map) and skip any permanent per-database row filters (filters).
	if (%{ $self->{_join_map} } || %{ $self->{_filters} }) {
		# _autoload_pk was captured once at construction from the primary DA's
		# {id} field; using the cached value avoids re-introspecting the blessed
		# hash on every call and isolates the coupling to a single known site.
		my $params = $self->_parse_query_args($self->{_autoload_pk}, @_);
		my $rows   = $self->_joined_query($params);
		return map { $_->{$col} } @{$rows} if wantarray;
		return @{$rows} ? $rows->[0]{$col} : undef;
	}

	# $db is resolved here (not earlier) to avoid a dead store on the join path above.
	my $db = $self->{_dbs}[$db_idx];
	return $db->$col(@_);
}

sub DESTROY {
	my ($self) = @_;
	# Disconnect and release the cached SQLite handle (if any) so File::Temp
	# can unlink the temp file before the object is freed.
	if (my $cache = delete $self->{_sqlite_cache}) {
		local $@;
		eval { $cache->{dbh}->disconnect } if $cache->{dbh};
		# $cache->{tmpfile} (File::Temp, UNLINK => 1) is released here.
	}
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# _parse_query_args( $self, $positional_key, @caller_args ) -> \%params
# Purpose: Normalise the three calling conventions used by every public query
#          method and AUTOLOAD into a single criteria hashref.
# Entry:   $positional_key -- the column name mapped to a bare scalar argument;
#          pass undef to use the join_column (the default for public methods).
# Exit:    Always returns a hashref; never undef.
sub _parse_query_args :Protected {
	my ($self, $key, @args) = @_;
	# D~ elimination (Modus Tollens): when @args is empty the early return fires
	# before $key is ever read, making the $key //= assignment a dead store.
	# Moving the guard above the assignment removes the wasted hash dereference.
	return {} unless @args;
	$key //= $self->{_join_col};
	return { $key => $args[0] }        if @args == 1 && !ref($args[0]);
	return get_params(undef, @args) // {};
}

# _err( $self, $msg_key, @sprintf_args ) -> $string
# Convenience wrapper around _msg for use after construction, so callers do
# not have to extract $self->{_i18n} at every error site.
sub _err :Protected {
	my ($self, $key, @args) = @_;
	return _msg($self->{_i18n}, $key, @args);
}

# _build_col_index()
# Purpose: Populate _col_db (column_name => db_index) and _db_cols
#          (per-db column-presence hashrefs) by calling columns() on each
#          component database at construction time.
# Entry:   _dbs, _join_col, _join_map must already be set.
# Exit:    _col_db and _db_cols are set; join_column verified in every db.
# Effects: Croaks if any database is missing its join key column.
sub _build_col_index :Protected {
	my ($self) = @_;

	my $join_col = $self->{_join_col};
	my $cp       = $self->{_collision_prefix} // {};
	my %col_db;
	my @db_cols;
	my @col_rename;    # per-db: { orig_col => published_col } for renamed collisions
	my @col_unrename;  # per-db: { published_col => orig_col } reverse map

	for my $i (0 .. $#{ $self->{_dbs} }) {
		my $db        = $self->{_dbs}[$i];
		my $local_jc  = $self->{_join_map}{$i} // $join_col;
		my $cols      = $db->columns();
		$db_cols[$i]      = { map { $_ => 1 } @{$cols} };
		$col_rename[$i]   = {};
		$col_unrename[$i] = {};

		# Guard: a join_map value that is a reference (e.g. a hashref) would
		# stringify to "HASH(0x...)" when interpolated into an error message,
		# leaking a heap address to callers.  Reject early with a clear message.
		croak $self->_err('error_join_col_missing', "(join_map[$i] must be a string)", $i, ref($db))
			if ref $local_jc;

		croak $self->_err('error_join_col_missing', $local_jc, $i, ref($db))
			unless $db_cols[$i]{$local_jc};

		# collision_prefix only applies to secondary databases (index > 0);
		# an index-0 entry is meaningless and silently ignored.
		my $prefix = ($i > 0) ? $cp->{$i} : undef;

		# Guard: a collision_prefix value that is a reference would stringify
		# to "HASH(0x...)" or "ARRAY(0x...)" when interpolated into "$prefix.$col",
		# leaking a heap address into every column name, columns(), schema(), and
		# merged row hashref.  This is the same class of leak as the join_map guard
		# above; reject early with a clear message before any column name is built.
		croak $self->_err('error_invalid_prefix', $i)
			if defined $prefix && ref $prefix;

		for my $col (@{$cols}) {
			# Skip the local alias for the join key — it is not a data column
			next if $local_jc ne $join_col && $col eq $local_jc;

			if (defined $prefix && exists $col_db{$col} && $col ne $join_col) {
				# Column already claimed by an earlier database AND a prefix is
				# configured: publish the collision as "$prefix.$col" so both
				# values survive in the merged row rather than one silently winning.
				# The join_column itself is never prefixed — it is the shared merge
				# key and is always broadcast by name; renaming it would break routing.
				my $pub = "$prefix.$col";
				$col_rename[$i]{$col}   = $pub;
				$col_unrename[$i]{$pub} = $col;
				$col_db{$pub} = $i;
			} else {
				# No collision, or no prefix configured: last database wins
				# (preserved backward-compatible behaviour).
				$col_db{$col} = $i;
			}
		}
	}

	$self->{_col_db}       = \%col_db;
	$self->{_db_cols}      = \@db_cols;
	$self->{_col_rename}   = \@col_rename;
	$self->{_col_unrename} = \@col_unrename;

	return;
}

# _partition_criteria( \%params ) -> \@per_db
# Purpose: Split a flat criteria hashref into one slice per component database.
# Entry:   $params is a criteria hashref; all keys must be column names or
#          join_column.
# Exit:    Returns an arrayref of per-database criteria hashrefs.  The
#          join_column criterion is broadcast to every database using each
#          database's local join-key name.  Unknown columns trigger a carp.
# Effects: Carps for each unrecognised column name.
sub _partition_criteria :Protected {
	my ($self, $params) = @_;

	my $join_col = $self->{_join_col};
	my $n        = scalar @{ $self->{_dbs} };
	my @per_db   = map { {} } 1 .. $n;

	for my $col (keys %{$params}) {
		if ($col eq $join_col) {
			# Broadcast to every database using each one's local key column name.
			# Shallow-copy operator hashrefs so a malicious component DA that
			# mutates its criteria hashref contents cannot corrupt siblings.
			my $val = $params->{$col};
			for my $i (0 .. $n - 1) {
				my $local = $self->{_join_map}{$i} // $join_col;
				$per_db[$i]{$local} = ref($val) eq 'HASH' ? { %{$val} } : $val;
			}
		} elsif (defined(my $idx = $self->{_col_db}{$col})) {
			# Translate the published column name back to the database's own name
			# when the column was renamed for a collision (e.g. "pfx.col" -> "col").
			# Invariant: _col_unrename[$idx] is always initialised to {} by _build_col_index
		# and add_database, so the // {} fallback can never trigger (transitive reduction).
		my $db_col = $self->{_col_unrename}[$idx]{$col} // $col;
			$per_db[$idx]{$db_col} = $params->{$col};
		} else {
			carp $self->_err('warn_unknown_column', $col);
		}
	}

	return \@per_db;
}

# _fetch_indexed( $db_idx, \%criteria ) -> \%join_val_to_\@rows
# Purpose: Query one component database and index its rows by join-key value.
# Entry:   $db_idx is the zero-based database index; $criteria is the
#          pre-partitioned criteria hashref for this database.
# Exit:    Returns a hashref: join-key value => arrayref of row hashrefs.
#          Multiple rows sharing the same join-key value are all preserved
#          (important for the primary database when one key maps to many rows).
# Effects: Calls selectall_arrayref on the component database.
sub _fetch_indexed :Protected {
	my ($self, $db_idx, $criteria) = @_;

	my $db        = $self->{_dbs}[$db_idx];
	my $local_jc  = $self->{_join_map}{$db_idx} // $self->{_join_col};

	my $rows = $db->selectall_arrayref($criteria);
	$rows //= [];

	my %indexed;
	for my $row (@{$rows}) {
		my $key = $row->{$local_jc};
		next unless defined $key;
		push @{ $indexed{$key} }, $row;
	}

	return \%indexed;
}

# _joined_query( \%params ) -> \@merged_rows
#
# Purpose: Dispatcher — routes to the array (in-memory) or SQLite join backend
#          based on $self->{_backend}.
sub _joined_query :Protected {
	my ($self, $params) = @_;
	my $backend = $self->{_backend};
	return $self->_joined_query_array($params) if $backend eq 'array';
	return $self->_sqlite_join($params);
}

# _joined_query_array( \%params ) -> \@merged_rows
#
# Purpose: Core in-memory join algorithm.  Partitions criteria, fetches per-database
#          results, resolves the key set, and merges rows.
#
# Key-set resolution (applied for each secondary database after the primary):
#
#   If the database had criteria in this query call (after base filter overlay),
#   it acts as an INNER-JOIN partner: only keys present in its filtered result
#   survive.  This gives WHERE-clause semantics even under a LEFT join.
#
#   If the database had NO effective criteria:
#     inner  -> intersect  (standard inner join)
#     left   -> no change  (primary defines the key set)
#     outer  -> union      (all keys from any database)
#
# Row merge: for each qualifying primary row, secondary rows are overlaid in
# index order.  For duplicate columns, later databases win.  Local join-key
# aliases are renamed to the canonical join_column before merging.
# Removed columns are deleted from every merged row.
sub _joined_query_array :Protected {
	my ($self, $params) = @_;

	my $join_col  = $self->{_join_col};
	my $join_type = $self->{_join_type};
	my $n         = scalar @{ $self->{_dbs} };

	my $per_db = $self->_partition_criteria($params);

	# Overlay any per-database base filters onto the partitioned criteria.
	# A filtered database always has effective criteria, so $had_criteria will
	# be true for it — giving inner-join key-set semantics regardless of join_type.
	for my $i (0 .. $n - 1) {
		my $base = $self->{_filters}{$i} // {};
		next unless %{$base};
		$per_db->[$i] = _merge_criteria($base, $per_db->[$i]);
	}

	# Fetch and index each database with its own criteria slice.
	my @indexed;
	$indexed[0] = $self->_fetch_indexed(0, $per_db->[0]);

	# Early exit: for inner and left joins, an empty primary result means the
	# key set is provably empty (left: primary defines it; inner: ∩ ∅ = ∅).
	# Skipping secondary fetches avoids up to N-1 unnecessary DA round-trips.
	#
	# Two guards prevent premature exit:
	#   (a) join-column broadcast: when a join-col criterion is present it must
	#       be physically delivered to each secondary DA (the call itself is what
	#       forwards it; the partition only prepared the per-db slice).
	#   (b) secondary-owned criteria: a secondary with its own criteria (e.g.
	#       score => $val) must still be queried so those criteria are delivered.
	#       Without the call the DA never receives them — breaking the partition-
	#       isolation invariant the security tests verify.
	my $local_jc_0_early    = $self->{_join_map}{0} // $join_col;
	my $sec_has_criteria    = grep { %{ $per_db->[$_] } } 1 .. $n - 1;
	return [] if !%{ $indexed[0] }
	          && $join_type ne 'outer'
	          && !exists $per_db->[0]{$local_jc_0_early}
	          && !$sec_has_criteria;

	$indexed[$_] = $self->_fetch_indexed($_, $per_db->[$_]) for 1 .. $n - 1;

	# Premise: the key-set resolution loop starts at i=1 (primary seeds %key_set).
	# Conclusion: $had_criteria[0] is a dead store (D~); compute only for i >= 1.
	#
	# The broadcast join-column criterion (entry=>'A3' delivered to ALL databases)
	# must NOT count as "had criteria" for secondaries.  It is a key-range selector
	# on the merged view, not a predicate that bounds what the secondary contributes.
	# Only base filters and non-join-column query-time criteria trigger inner-join.
	my @had_criteria;
	for my $i (1 .. $n - 1) {
		my $local_jc   = $self->{_join_map}{$i} // $join_col;
		my $has_filter = !!%{ $self->{_filters}{$i} // {} };
		my %q          = %{ $per_db->[$i] };
		delete $q{$local_jc};
		$had_criteria[$i] = $has_filter || !!%q;
	}

	# Seed the key set from the primary database.
	# Hash-slice assignment avoids the intermediate 2K-element flat list that
	# map { $_ => 1 } would allocate before assigning to %key_set.  Values are
	# undef; only exists() is used for lookups, so the sentinel value is irrelevant.
	my %key_set;
	@key_set{ keys %{ $indexed[0] } } = ();

	# Merge in each secondary database.
	# Premise 1: indexed[$i] is a valid hashref (returned by _fetch_indexed).
	# Premise 2: join_type ∈ {left, inner, outer} (enforced by validate_strict).
	# Conclusion: the three branches below are exhaustive and mutually exclusive.
	for my $i (1 .. $n - 1) {
		if ($had_criteria[$i] || $join_type eq 'inner') {
			# Intersect: single-pass delete for keys absent from this secondary.
			# A single loop avoids the intermediate list that grep would allocate
			# before the delete loop could iterate it (saves O(K) allocations).
			for my $k (keys %key_set) {
				delete $key_set{$k} unless exists $indexed[$i]{$k};
			}
		} elsif ($join_type eq 'outer') {
			# Union: hash slice assignment is a single Perl op, not a per-key loop.
			@key_set{ keys %{ $indexed[$i] } } = ();
		}
		# left + no criteria: key_set unchanged (primary defines the set).
	}

	# Pre-hoist per-secondary constants outside the key loop.
	# $sec_local_jc[$i], the rename flag, and $sec_renames[$i] are all invariant
	# across every key and every primary row.  Computing them inside the key loop
	# wastes K dereferences per secondary database (K = number of qualifying keys).
	# Splitting the inner column loop on the rename flag eliminates the flag check
	# from inside the per-column loop, saving R-1 branch evaluations per secondary
	# per row (R = columns in the secondary row).
	my (@sec_local_jc, @sec_rename, @sec_renames);
	for my $i (1 .. $n - 1) {
		$sec_local_jc[$i] = $self->{_join_map}{$i};
		$sec_rename[$i]   = ($sec_local_jc[$i] && $sec_local_jc[$i] ne $join_col) ? 1 : 0;
		# _col_rename[$i] is always initialised to {} by _build_col_index / add_database
		# (transitive reduction: the // {} fallback can never trigger).
		$sec_renames[$i]  = $self->{_col_rename}[$i];
	}

	# Cache the removed-column list across calls; avoids extracting keys %hash every
	# query.  Lazily built here and invalidated to undef by remove_column().
	my $removed = ($self->{_removed_list} //= [keys %{ $self->{_removed_cols} }]);

	# Build one merged result row for every primary-database row that qualifies.
	# Secondary databases act as lookup tables: when a key maps to multiple
	# secondary rows, the last one wins (consistent with construction-time
	# last-database-wins column routing).
	my @result;
	for my $key (sort keys %key_set) {
		# Iterate directly over the arrayref: avoids copying primary rows into a
		# new @base_rows array (saves P element copies per key, P = rows per key).
		# [{}] ensures outer-join keys absent from the primary produce one merged row.
		for my $prow (@{ $indexed[0]{$key} // [{}] }) {
			my %merged = %{$prow};

			for my $i (1 .. $n - 1) {
				my $sec_arr = $indexed[$i]{$key};
				next unless $sec_arr && @{$sec_arr};

				# Write secondary columns directly into %merged without copying
				# the source row into a temporary hash first.
				# Before: %row_copy = %{$src}   then %merged = (%merged,%row_copy)
				#   → 2 full hash copies per secondary per row: O(C) + O(|merged|+C)
				# After: per-key loop writes straight into %merged
				#   → O(C) key assignments only; no intermediate allocation
				my $src = $sec_arr->[-1];

				if ($sec_rename[$i]) {
					my $local_jc = $sec_local_jc[$i];
					my $renames  = $sec_renames[$i];
					for my $k (keys %{$src}) {
						if ($k eq $local_jc) {
							# Translate local join-key alias to the canonical join_column name
							$merged{$join_col} = $src->{$k};
						} elsif (my $pub = $renames->{$k}) {
							$merged{$pub} = $src->{$k};
						} else {
							$merged{$k} = $src->{$k};
						}
					}
				} else {
					my $renames = $sec_renames[$i];
					for my $k (keys %{$src}) {
						if (my $pub = $renames->{$k}) {
							# Collision-renamed column: write under the published prefixed name
							$merged{$pub} = $src->{$k};
						} else {
							$merged{$k} = $src->{$k};
						}
					}
				}
			}

			delete @merged{@{$removed}} if @{$removed};
			push @result, \%merged;
		}
	}

	return \@result;
}

# _cache_fresh() -> bool
# Purpose: Check whether the SQLite join cache is still valid.
# Entry:   $self->{_sqlite_cache} may or may not be set.
# Exit:    Returns 1 if the cache exists, the DBI handle is active, the source
#          count matches, and all source updated() timestamps match.  Returns 0
#          if any of these conditions fail (caller must rebuild the cache).
sub _cache_fresh :Protected {
	my ($self) = @_;

	my $cache = $self->{_sqlite_cache} // return 0;
	my $n     = scalar @{ $self->{_dbs} };

	return 0 if ($cache->{n} // 0) != $n;

	# Verify the DBI handle is still usable.
	return 0 unless do { local $@; eval { $cache->{dbh}{Active} } };

	# Verify that no source has been updated since the cache was built.
	# If a source does not implement updated(), skip the timestamp check for
	# it (the data is assumed stable; the cache stays valid indefinitely for
	# that source unless add_database() is called or the object is destroyed).
	for my $i (0 .. $n - 1) {
		my $cached_ts = $cache->{updated}{$i} // next;   # not captured → skip
		my $current_ts;
		do { local $@; $current_ts = eval { $self->{_dbs}[$i]->updated() } };
		next unless defined $current_ts;                  # no updated() → skip
		return 0 if $current_ts != $cached_ts;
	}

	return 1;
}

# _build_sqlite_cache()
# Purpose: Create (or rebuild) the persistent SQLite join cache.  Spills each
#          source database into a temp SQLite file using filter-only criteria;
#          SQLite-backed sources are zero-copy ATTACHed instead of spilled.
#          Query-time criteria are NOT applied here — they become WHERE clauses
#          in the per-call SQL generated by _sqlite_join.
# _sql_quote_identifier( $name ) -> $quoted
# Purpose: Produce a properly double-quoted SQL identifier, escaping any
#          embedded double-quote characters by doubling them (SQL standard).
#          Defence-in-depth: prevents SQL identifier injection when DA-supplied
#          column names or table names contain literal double-quote characters.
#          SQLite, like all ANSI SQL databases, represents a literal " inside a
#          double-quoted identifier as ""; this routine applies that transform.
# Entry:   $name — raw identifier string (column name, table name, or alias).
# Exit:    Returns the double-quoted, injection-safe SQL identifier string.
sub _sql_quote_identifier {
	my ($name) = @_;
	(my $safe = $name) =~ s/"/""/g;
	return "\"$safe\"";
}

# Entry:   _dbs, _join_map, _filters, _tmpdir must be set.
# Exit:    $self->{_sqlite_cache} holds {dbh, tmpfile, table_refs, source_cols,
#          is_attached, updated, n}.  Any previous cache is disconnected first.
#          Each spilled table has a B-tree index on its join column.
# Effects: Creates a File::Temp file (SUFFIX='.db', DIR=_tmpdir, UNLINK=1).
#          Croaks with error_sqlite_connect if DBI::connect fails.
sub _build_sqlite_cache :Protected {
	my ($self) = @_;

	# Disconnect any previous cache to release the old temp file.
	if (my $old = delete $self->{_sqlite_cache}) {
		local $@;
		eval { $old->{dbh}->disconnect } if $old->{dbh};
	}

	require DBI;
	require File::Temp;

	my $join_col = $self->{_join_col};
	my $n        = scalar @{ $self->{_dbs} };

	my $tmpfile = File::Temp->new(
		SUFFIX => '.db',
		DIR    => $self->{_tmpdir},
		UNLINK => 1,
	);

	my $tmpdbh = DBI->connect(
		'dbi:SQLite:dbname=' . $tmpfile->filename, '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
	) or croak $self->_err('error_sqlite_connect', DBI->errstr // 'unknown error');

	my (@table_refs, @source_cols, @is_attached);

	for my $i (0 .. $n - 1) {
		my $db       = $self->{_dbs}[$i];
		my $local_jc = $self->{_join_map}{$i} // $join_col;

		# Zero-copy ATTACH path: unconditionally available when the source
		# implements dbi_source() returning a live SQLite handle.  Query-time
		# criteria for this source will go into the SQL WHERE clause.
		# eval wraps can() to suppress ISA warnings from stub packages in tests.
		if (do { local $@; eval { $db->can('dbi_source') } }) {
			my $src = eval { $db->dbi_source() };
			if ($src && ref($src) eq 'HASH' && $src->{dbh} && $src->{table}
				&& eval { $src->{dbh}{Driver}{Name} } eq 'SQLite') {
				my ($db_file) = $src->{dbh}->selectrow_array(
					"SELECT file FROM pragma_database_list WHERE name='main'"
				);
				my $alias = "ext$i";
				$tmpdbh->do(sprintf("ATTACH DATABASE %s AS %s",
					$tmpdbh->quote($db_file), $alias));
				$table_refs[$i]  = $alias . '.' . _sql_quote_identifier($src->{table});
				$is_attached[$i] = 1;
				# Transitive reduction: new() and add_database() both validate
				# can('columns') before registering any DA (P1 invariant).
				# The else branch is dead code; the guard is vacuous.
				$source_cols[$i] = $db->columns();
				next;
			}
		}

		# Spill path: fetch rows using filter-only criteria.  Query-time
		# criteria are NOT applied here — they become WHERE clauses per call.
		my $filter_crit = $self->{_filters}{$i} // {};
		my $rows        = $db->selectall_arrayref($filter_crit) // [];

		# No need to check if $rows exists or not
		# Transitive reduction (P1 invariant): can('columns') is guaranteed for
		# all _dbs elements
		$source_cols[$i] = $db->columns();

		my $tbl  = "t$i";
		my $cols = $source_cols[$i] // [];

		my $col_defs = join(', ', map { _sql_quote_identifier($_) . ' TEXT' } @{$cols});
		$tmpdbh->do('CREATE TABLE ' . _sql_quote_identifier($tbl) . " ($col_defs)");
		# Index on the join column: upgrades ON-clause equality lookups from
		# an O(N²) full-table nested-loop scan to O(N log N) b-tree seek.
		# SQLite query planner uses it for INNER JOIN / LEFT JOIN ON expressions.
		$tmpdbh->do('CREATE INDEX ' . _sql_quote_identifier("${tbl}_jc")
			. ' ON ' . _sql_quote_identifier($tbl)
			. ' (' . _sql_quote_identifier($local_jc) . ')');

		if (@{$rows}) {
			my $col_list     = join(', ', map { _sql_quote_identifier($_) } @{$cols});
			my $placeholders = join(', ', ('?') x scalar @{$cols});
			my $sth = $tmpdbh->prepare(
				'INSERT INTO ' . _sql_quote_identifier($tbl) . " ($col_list) VALUES ($placeholders)"
			);
			my $batch = 0;
			$tmpdbh->begin_work;
			for my $row (@{$rows}) {
				$sth->execute(map { $row->{$_} } @{$cols});
				if (++$batch >= 1_000) {
					$tmpdbh->commit;
					$tmpdbh->begin_work;
					$batch = 0;
				}
			}
			$tmpdbh->commit;
		}
		$table_refs[$i]  = _sql_quote_identifier($tbl);
		$is_attached[$i] = 0;
	}

	# Snapshot updated() timestamps for cache-validity checks.
	my %updated;
	for my $i (0 .. $n - 1) {
		local $@;
		my $ts = eval { $self->{_dbs}[$i]->updated() };
		$updated{$i} = $ts unless $@;
	}

	$self->{_sqlite_cache} = {
		dbh         => $tmpdbh,
		tmpfile     => $tmpfile,
		table_refs  => \@table_refs,
		source_cols => \@source_cols,
		is_attached => \@is_attached,
		updated     => \%updated,
		n           => $n,
	};

	return;
}

# _sqlite_join( \%params ) -> \@merged_rows
#
# Purpose: Join via a persistent SQLite database cache.  The first call (or
#          any call after a source updated() changes) spills source data into
#          a File::Temp SQLite file via _build_sqlite_cache; subsequent calls
#          reuse the same file and handle.  A single SQL JOIN with a per-call
#          WHERE clause (built from query-time criteria) produces the result.
#          For 'auto' mode, uses count() or dbi_source() COUNT(*) to check
#          the threshold without fetching rows; falls back to
#          _joined_query_array when count <= $self->{_max_array_rows} or when
#          no count method is available.
# Entry:   $params is the query criteria hashref.
# Exit:    Returns arrayref of merged hashrefs sorted by join_column.
# Effects: On the first call (or after cache invalidation), creates a
#          File::Temp SQLite file in _tmpdir; the file persists until the
#          Database::Join object is destroyed or the source data changes.
sub _sqlite_join :Protected {
	my ($self, $params) = @_;

	my $backend   = $self->{_backend};
	my $join_col  = $self->{_join_col};
	my $join_type = $self->{_join_type};
	my $n         = scalar @{ $self->{_dbs} };

	# Partition query-time criteria only (no filter overlay).
	# Filters are applied at cache-build time for spilled sources, and via the
	# SQL WHERE clause for ATTACHed sources.  Keeping them separate means the
	# cached tables can serve any query without rebuilding.
	my $per_db_query = $self->_partition_criteria($params);

	# Compute the full merged criteria (filter + query) for each source.
	# Used for had_criteria (join-type semantics) and the WHERE clause for
	# ATTACHed sources (which were not filtered at spill time).
	my @per_db_full;
	for my $i (0 .. $n - 1) {
		my $base = $self->{_filters}{$i} // {};
		$per_db_full[$i] = %{$base}
			? _merge_criteria($base, $per_db_query->[$i])
			: $per_db_query->[$i];
	}

	# Determine which secondary sources had effective criteria (inner-join semantics).
	# The broadcast join-column criterion must NOT count — it is a key-range selector
	# on the merged view, not a predicate that restricts the secondary's contribution.
	# Base filters always count (documented: a filtered db is always inner-join).
	my @had_criteria;
	for my $i (1 .. $n - 1) {
		my $local_jc   = $self->{_join_map}{$i} // $join_col;
		my $has_filter = !!%{ $self->{_filters}{$i} // {} };
		my %q          = %{ $per_db_query->[$i] };
		delete $q{$local_jc};
		$had_criteria[$i] = $has_filter || !!%q;
	}

	# For 'auto' mode: check total row count without fetching rows.
	# Count(*) is used for dbi_source() sources; count() for others.
	# If any source supports neither, fall back to the array path.
	if ($backend eq 'auto') {
		my $total     = 0;
		my $can_count = 1;
		for my $i (0 .. $n - 1) {
			my $db  = $self->{_dbs}[$i];
			# dbi_source() path: COUNT(*) against the entire source table
			# (no WHERE) gives a conservative upper bound on the spilled size.
			if (do { local $@; eval { $db->can('dbi_source') } }) {
				my $src = eval { $db->dbi_source() };
				if ($src && ref($src) eq 'HASH' && $src->{dbh} && $src->{table}
					&& eval { $src->{dbh}{Driver}{Name} } eq 'SQLite') {
					my ($cnt) = $src->{dbh}->selectrow_array(
						'SELECT COUNT(*) FROM "' . $src->{table} . '"'
					);
					$total += $cnt // 0;
					next;
				}
			}
			# count() path: only use it when the DA's own class directly defines
			# count() (not inherited).  Database::Abstraction's inherited count($entry)
			# takes a key argument and emits uninitialized-value warnings when called
			# with no args, so we must not invoke it for the threshold probe.
			my $pkg = ref($db) // '';
			if ($pkg && do { no strict 'refs'; defined &{"${pkg}::count"} }) {
				my ($cnt, $failed);
				do { local $@; $cnt = eval { $db->count() }; $failed = $@ };
				if ($failed) {
					$can_count = 0;
					last;
				}
				$total += $cnt // 0;
				next;
			}
			$can_count = 0;
			last;
		}
		return $self->_joined_query_array($params)
			if !$can_count || $total <= $self->{_max_array_rows};
	}

	# Ensure the SQLite cache is valid; rebuild if stale or absent.
	$self->_build_sqlite_cache() unless $self->_cache_fresh();

	my $cache       = $self->{_sqlite_cache};
	my $tmpdbh      = $cache->{dbh};
	my @table_refs  = @{ $cache->{table_refs}  };
	my @source_cols = @{ $cache->{source_cols} };
	my @is_attached = @{ $cache->{is_attached} };

	# Build the WHERE clause from per-call criteria.
	#   Spilled sources: query-only criteria (filter already applied to spilled data).
	#   ATTACHed sources: full criteria (filter + query), since source was not filtered.
	#   Secondary tables (i>0): the broadcast join-column criterion is omitted because
	#   it is already enforced by the ON clause; adding it to WHERE nullifies LEFT JOIN.
	my (@where_parts, @bind_vals);
	for my $i (0 .. $n - 1) {
		my $crit = $is_attached[$i] ? $per_db_full[$i] : $per_db_query->[$i];
		next unless %{$crit};
		my $tref       = $table_refs[$i];
		my $local_jc_i = $i > 0 ? ($self->{_join_map}{$i} // $join_col) : undef;
		for my $col (sort keys %{$crit}) {
			next if defined $local_jc_i && $col eq $local_jc_i;
			my $val = $crit->{$col};
			if (ref($val) eq 'HASH') {
				for my $op (sort keys %{$val}) {
					next unless $SAFE_SQL_OPS{$op};
					push @where_parts, $tref . '.' . _sql_quote_identifier($col) . " $op ?";
					push @bind_vals, $val->{$op};
				}
			} else {
				push @where_parts, $tref . '.' . _sql_quote_identifier($col) . ' = ?';
				push @bind_vals, $val;
			}
		}
	}
	my $where_sql = @where_parts ? ' WHERE ' . join(' AND ', @where_parts) : '';

	# Build SELECT clause.
	# Walk sources in order, applying collision_prefix renaming exactly as
	# _build_col_index does: first occurrence of a column name wins; subsequent
	# occurrences in a source that has a collision_prefix are published as
	# "$prefix.$col"; removed columns are omitted.
	my %pub_seen;
	my @selects;
	my $local_jc_0 = $self->{_join_map}{0} // $join_col;

	# Join-column expression: for outer joins, use COALESCE across all sources
	# so that B-only (primary-absent) rows carry their join key rather than NULL.
	unless ($self->{_removed_cols}{$join_col}) {
		my $jc_expr;
		if ($join_type eq 'outer' && $n > 1) {
			$jc_expr = 'COALESCE('
			         . join(', ', map {
			               my $lc = $self->{_join_map}{$_} // $join_col;
			               $table_refs[$_] . '.' . _sql_quote_identifier($lc)
			           } 0 .. $n - 1)
			         . ') AS ' . _sql_quote_identifier($join_col);
		} else {
			$jc_expr = $table_refs[0] . '.' . _sql_quote_identifier($local_jc_0);
			$jc_expr .= ' AS ' . _sql_quote_identifier($join_col) if $local_jc_0 ne $join_col;
		}
		push @selects, $jc_expr;
		$pub_seen{$join_col} = 1;
	}

	# Non-join columns from the primary table.
	for my $col (@{$source_cols[0] // []}) {
		next if $col eq $local_jc_0;	# join column already handled above
		next if $self->{_removed_cols}{$col};
		$pub_seen{$col} = 1;
		push @selects, $table_refs[0] . '.' . _sql_quote_identifier($col);
	}

	# Non-join columns from secondary tables, with collision_prefix renaming.
	for my $i (1 .. $n - 1) {
		my $local_jc = $self->{_join_map}{$i} // $join_col;
		my $prefix   = $self->{_collision_prefix}{$i};
		for my $col (@{$source_cols[$i] // []}) {
			next if $col eq $local_jc;	# join key already contributed above
			my $pub = $col;
			$pub = "$prefix.$col"
				if defined $prefix && exists $pub_seen{$col} && $col ne $join_col;
			next if $self->{_removed_cols}{$pub};
			$pub_seen{$pub} = 1;
			my $expr = $table_refs[$i] . '.' . _sql_quote_identifier($col);
			$expr   .= ' AS ' . _sql_quote_identifier($pub) if $pub ne $col;
			push @selects, $expr;
		}
	}

	# Build JOIN clauses.
	# Join type mirrors the key-set semantics of _joined_query_array:
	#   had_criteria[i] OR inner  => INNER JOIN
	#   outer (no criteria)       => FULL OUTER JOIN
	#   left  (no criteria)       => LEFT JOIN
	my $from     = $table_refs[0];
	my $join_sql = '';
	for my $i (1 .. $n - 1) {
		my $local_jc = $self->{_join_map}{$i} // $join_col;
		my $join_kw  = ($had_criteria[$i] || $join_type eq 'inner') ? 'JOIN'
		             : ($join_type eq 'outer')                       ? 'FULL OUTER JOIN'
		             :                                                  'LEFT JOIN';
		$join_sql .= " $join_kw $table_refs[$i]"
		          . ' ON ' . $table_refs[0] . '.' . _sql_quote_identifier($local_jc_0)
		          . ' = '  . $table_refs[$i] . '.' . _sql_quote_identifier($local_jc);
	}

	# ORDER BY: use a qualified column reference to avoid ambiguity.
	# For outer joins we aliased the join column via COALESCE, so reference
	# the alias (SQLite resolves ORDER BY aliases from the SELECT list).
	# For other join types, qualify with the primary table to be unambiguous.
	my $order_col = ($join_type eq 'outer' && $n > 1)
	              ? _sql_quote_identifier($join_col)
	              : $table_refs[0] . '.' . _sql_quote_identifier($local_jc_0);
	my $sql = 'SELECT '
	        . join(', ', @selects)
	        . ' FROM ' . $from . $join_sql
	        . $where_sql
	        . ' ORDER BY ' . $order_col;

	# prepare_cached reuses the parsed statement when the same SQL is executed
	# again (e.g. identical criteria pattern in a pagination or batch loop),
	# avoiding repeated statement compilation overhead.  fetchall_arrayref
	# always exhausts the result set, so the handle is never left active.
	my $sth = $tmpdbh->prepare_cached($sql);
	$sth->execute(@bind_vals);
	return $sth->fetchall_arrayref({});
}

# _merge_criteria( \%base, \%extra ) -> \%merged
# Purpose: Merge two criteria hashrefs for the same database column set.
# Entry:   %base is the permanent filter; %extra is the query-time criteria.
# Exit:    Returns a new hashref with both applied.
# Merging rule: when both values for the same column are operator hashrefs
#   (e.g. { '>' => 60 } and { '<' => 365 }), the operators are combined
#   so both constraints apply simultaneously (AND semantics).
#   Otherwise the extra (query-time) value overwrites the base value.
sub _merge_criteria :Protected {
	my ($base, $extra) = @_;
	my %merged = %{$base};
	for my $col (keys %{$extra}) {
		if (exists $merged{$col}
		        && ref($merged{$col}) eq 'HASH'
		        && ref($extra->{$col}) eq 'HASH') {
			$merged{$col} = { %{ $merged{$col} }, %{ $extra->{$col} } };
		} else {
			$merged{$col} = $extra->{$col};
		}
	}
	return \%merged;
}

# _copy_criteria( \%criteria ) -> \%copy
# Purpose: Return a two-level deep copy of a single criteria hashref so that
#          post-construction mutation of the caller's hash cannot change the
#          stored filter.  Operator sub-hashrefs (e.g. { '>' => 80 }) are
#          shallow-copied one additional level, matching the broadcast-copy
#          idiom used in _partition_criteria for join-column criteria.
# Entry:   $criteria is a hashref (may be undef).
# Exit:    Returns a new hashref; never returns the input reference itself.
sub _copy_criteria {
	my ($criteria) = @_;
	return {} unless $criteria && %{$criteria};
	return {
		map {
			$_ => ref($criteria->{$_}) eq 'HASH'
				? { %{ $criteria->{$_} } }  # shallow-copy operator sub-hashref
				: $criteria->{$_}
		} keys %{$criteria}
	};
}

# _copy_filters( \%filters ) -> \%copy
# Purpose: Deep-copy the filters hashref (db_index => criteria_hashref) so
#          that post-construction mutation of the caller's hash cannot silently
#          bypass the inner-join row-security guarantee.
# Entry:   $filters may be undef.
# Exit:    Returns a new hashref; never returns the input reference itself.
sub _copy_filters {
	my ($filters) = @_;
	return {} unless $filters && %{$filters};
	return { map { $_ => _copy_criteria($filters->{$_}) } keys %{$filters} };
}

# _msg( $i18n, $key, @sprintf_args ) -> $string
# Purpose: Format a user-facing message, routing through the i18n object when
#          one is provided.  Falls back to the built-in %MESSAGES dictionary.
# Entry:   $i18n may be undef.  $key must be a key in %MESSAGES.
# Exit:    Returns the formatted string.
sub _msg :Protected {
	my ($i18n, $key, @args) = @_;

	if ($i18n && $i18n->can('translate')) {
		return $i18n->translate($key, @args);
	}

	my $fmt = $MESSAGES{$key}
		// sprintf($MESSAGES{error_unknown_message}, $key);

	return @args ? sprintf($fmt, @args) : $fmt;
}

1;

__END__

=head1 ENCODING

All text that passes through C<Database::Join> at the Perl layer (column names,
criteria values, merged row values) is treated as opaque strings.
C<Database::Join> does not inspect, encode, or transform string content.

=over 4

=item Column names

Column names are plain ASCII strings as returned by C<Database::Abstraction::columns()>.
Non-ASCII column names are accepted but not tested; behaviour depends on the
underlying DA and database driver.

=item Criteria values and row data

Values are passed verbatim between callers and component DAs.  Full UTF-8 is
safe as long as the underlying C<Database::Abstraction> objects and their
database drivers handle UTF-8 correctly.  C<Database::Join> neither encodes
nor decodes any value.

=item SQLite backend

When the SQLite path is active, values are inserted into the temporary SQLite
database via DBI placeholders (never string interpolation), so binary-safe
round-tripping depends on C<DBD::SQLite>'s character encoding settings.
By default C<DBD::SQLite> operates in UTF-8 mode, which is correct for text
data.  Binary blobs are not explicitly tested.

=item i18n messages

All internal error and warning messages route through the C<i18n> object
(if one is supplied) via a C<translate($key, @args)> call.  The translation
dictionary controls the final encoding of those strings.

=back

=head1 MESSAGES

The following messages can be produced by C<Database::Join>.  All messages
can be localised by supplying an C<i18n> object to C<new>.

=over 4

=item C<error_no_databases>

B<When:> The C<databases> arrayref passed to C<new> is empty.

B<Fix:> Pass at least one C<Database::Abstraction> subclass object.

=item C<error_invalid_db>

B<When:> An element of the C<databases> array (or the argument to
C<add_database>) is not an object, or is not a C<Database::Abstraction>
subclass.

B<Fix:> Instantiate the component database with its own C<new> method before
passing it to C<Database::Join>.

=item C<error_join_col_missing>

B<When:> The join key column (or its C<join_map> alias) does not exist in one
of the component databases.

B<Fix:> Either add the column to the database, change C<join_column> to a
column that is present everywhere, or use C<join_map> to declare the local
alias for databases that call it something different.

=item C<error_remove_join_col>

B<When:> C<remove_column> is called with the name of the join key column.

B<Fix:> The join key is required for the merge to work and cannot be hidden.
Remove a different column.

=item C<error_invalid_prefix>

B<When:> A value in the C<collision_prefix> hashref is a reference (e.g. a
hashref or arrayref) rather than a plain string.

B<Fix:> All C<collision_prefix> values must be plain strings.  A reference
would be stringified to C<HASH(0x...)> or C<ARRAY(0x...)>, leaking a heap
address into every column name returned by C<columns()>, C<schema()>, and all
query results.  Pass a plain string such as C<'db2'> or C<'secondary'>.

=item C<warn_unknown_column> (carp)

B<When:> A criterion is passed for a column that does not exist in any
component database (or has been removed with C<remove_column>).

B<Fix:> Check the column name spelling.  The criterion is ignored.

=item C<error_query_unsupported>

B<When:> C<query()> is called on a C<Database::Join> object.

B<Fix:> Use C<selectall_arrayref>, C<selectall_array>, C<fetchrow_hashref>,
or C<count> instead.

=item C<error_execute_unsupported>

B<When:> C<execute()> is called on a C<Database::Join> object.

B<Fix:> Use the Perl-level query methods instead.  Raw SQL cannot span
heterogeneous database backends.

=item C<error_invalid_backend>

B<When:> The C<backend> parameter passed to C<new> is not one of C<'array'>,
C<'sqlite'>, or C<'auto'>.

B<Fix:> Use exactly one of those three strings.  The check is case-sensitive;
C<'SQLite'> or C<'Auto'> will not be accepted.

=item C<error_sqlite_connect>

B<When:> The SQLite join backend fails to open the temporary SQLite database
file.  Common causes: the C<tmpdir> directory is not writable, the filesystem
has no free space, or C<DBD::SQLite> is not installed.

B<Fix:> Check that the directory given by C<tmpdir> (or the system temp
directory if C<tmpdir> was not set) is writable and has sufficient free space.
Verify that C<DBD::SQLite> 1.70 or later is installed.

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Database-Join>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-Join/coverage/>

=item * L<Database::Abstraction>

=back

=head1 SECURITY CONSIDERATIONS

C<Database::Join> is a pure in-memory routing and merge layer.  It never
generates SQL strings, never opens files, and never calls C<system()>,
C<exec()>, or C<eval()>.  The security properties described below are
architectural guarantees, not run-time checks.

=head2 What Database::Join guarantees

=over 4

=item Criteria partition isolation

Every criterion you pass to a query method is routed to I<exactly one>
component database (the one that owns that column), or to I<all> databases
when the criterion is on the join key column.  A hostile value in a criterion
for column C<name> (owned by database A) will never reach database B.

=item Unknown columns are rejected before reaching any database

If a criterion column name is not present in any component database (or has
been hidden with C<remove_column>), C<Database::Join> logs a C<carp> warning
and silently drops the criterion.  No database receives the hostile key.

=item AUTOLOAD only accepts word-character column names

Perl's method dispatch extracts the column name via C<\w+>, which matches only
C<[A-Za-z0-9_]>.  Hostile method names with shell metacharacters, quotes, or
spaces cannot reach the AUTOLOAD dispatch path.  Private names (starting with
C<_>) are additionally blocked with an explicit C<croak>.

=item No value sanitisation (by design)

C<Database::Join> does I<not> sanitise, HTML-encode, or validate the
I<values> in criteria hashrefs.  Preventing SQL injection is the
responsibility of the underlying C<Database::Abstraction> objects (which use
parameterised queries).  Preventing XSS or header injection is the
responsibility of the CGI or web layer that renders the output.

=item Taint-mode compatible (array path)

The array merge path contains no C<system()>, C<exec()>, backtick,
C<open(PIPE)>, or C<eval STRING> calls.  It neither opens files nor constructs
shell commands.  The AUTOLOAD regex C</ :: (\w++) \z /x> uses a possessive
quantifier (C<\w++>) and a strict end-of-string anchor (C<\z>) and produces
an I<untainted> capture, so the column name used for dispatch is clean under
C<-T>.  Criteria values are passed verbatim to component C<Database::Abstraction>
objects; those objects are responsible for handling tainted values at the SQL
parameterisation layer.

=item SQLite backend: column names are quoted, values are parametrised

When the SQLite path is active, C<Database::Join> generates SQL internally.
All column and table names are double-quoted (SQL identifier quoting) before
being embedded in statement strings.  All row values are passed to SQLite
exclusively through DBI prepared statement placeholders -- never by string
interpolation.  A hostile value in a source row therefore cannot inject SQL
into the temporary database.

The temporary SQLite file is created by C<File::Temp> using a securely random,
unpredictable filename.  No C<system()> or shell command is used to create or
remove it.  The connection is made with C<DBI-E<gt>connect(..., { RaiseError =E<gt> 1,
PrintError =E<gt> 0 })> and is closed before the method returns.  Column names
in the generated SQL come from C<columns()>, which is produced by
C<Database::Abstraction> at construction time -- they are not derived from
caller-supplied criteria values.

=item Operator hashref broadcast copy

When the same join-key criterion (an operator hashref such as
C<< { '>' => 'A' } >>) is broadcast to multiple component databases, each
database receives its own I<shallow copy> of the hashref.  A component database
that mutates the hashref's contents at the top level cannot affect what
subsequent databases receive.

=item collision_prefix value type guard

C<_build_col_index> rejects any C<collision_prefix> value that is a reference
(hashref, arrayref, coderef, etc.) with an immediate C<croak>.  A reference
value would stringify to C<"HASH(0x...)">, leaking a heap address into every
column name, C<columns()> listing, and merged row returned to the caller.  The
guard fires before any column name is constructed.

=item Filter deep-copy isolation

The C<filters> constructor parameter and the C<filter> option of
C<add_database()> are I<deep-copied> at the point of use.  The caller's
original hashrefs are never stored; post-construction mutation of those
hashrefs cannot widen or bypass the configured row-security constraints.

=back

=head2 What the caller is responsible for

=over 4

=item Sanitise values before building criteria

DJ passes criterion values verbatim to component databases.  If your
application accepts user-supplied filter values (e.g. from a CGI query
string), those values I<must> be validated or sanitised by your application
before being passed to DJ.

=item Restrict which columns the caller can filter on

Any column in C<columns()> can be used as a filter criterion.  If a column
should not be filterable by end users (e.g. an internal status flag), hide it
with C<remove_column> so that queries on it are silently dropped.

=item Do not expose the joined view directly to user-supplied criteria

DJ is not a firewall.  It faithfully routes user input to component databases.
Wrap DJ calls in a thin service layer that whitelists the permitted criterion
columns and validates their values.

=back

=head3 API SPECIFICATION (security surface)

    Input accepted by all query methods and passed through DJ to component databases:

    Criterion values:
        type: scalar string | operator hashref { OP => scalar }
        validation: NONE (DJ trusts the caller; component DA is responsible)
        max size: unconstrained (OOM risk on very large values)

    Column name keys in criteria:
        type: string
        validation: must be present in _col_db (else carp + drop)
        character set: any Perl string (including control chars); DJ does
                       not impose a character-set restriction on criteria KEYS

    AUTOLOAD method-name-as-column:
        type: \w+ (enforced by Perl regex /::(\w+)$/)
        validation: must not start with '_'; must be in _col_db

=encoding UTF-8

=head1 FORMAL SPECIFICATION

Z calculus schemas for the key invariants and operations.
Unicode is used throughout this section as required by Z notation.

    ─── Database_Join ─────────────────────────────────────────────────
    dbs            : seq DATABASE_ABSTRACTION
    join_col       : NAME
    join_type      : {left, inner, outer}
    join_map       : ℕ ⇸ NAME
    filters        : ℕ ⇸ CRITERIA
    col_db         : NAME ⇸ ℕ
    removed        : ℙ NAME
    backend        : {array, sqlite, auto}
    max_array_rows : ℕ
    tmpdir         : PATH
    ───────────────────────────────────────────────────────────────────
    #dbs ≥ 1
    dom join_map ⊆ 0 ‥ (#dbs - 1)
    dom filters  ⊆ 0 ‥ (#dbs - 1)
    dom col_db   = (⋃ { i : 0 ‥ #dbs-1 • ran((dbs i).columns) }) \ removed
    join_col ∉ removed
    ∀ i : 0 ‥ #dbs-1 •
        local_jc(i) = if i ∈ dom join_map then join_map(i) else join_col
    ∀ i : 0 ‥ #dbs-1 •
        local_jc(i) ∈ ran((dbs i).columns)

    ─── Init ──────────────────────────────────────────────────────────
    ΔDatabase_Join
    dbs?           : seq DATABASE_ABSTRACTION
    join_col?      : NAME
    join_type?     : {left, inner, outer}
    join_map?      : ℕ ⇸ NAME
    filters?       : ℕ ⇸ CRITERIA
    removed?       : ℙ NAME
    backend?       : {array, sqlite, auto}   -- default auto
    max_array_rows? : ℕ                      -- default 10000
    tmpdir?        : PATH                    -- default File::Spec->tmpdir
    ───────────────────────────────────────────────────────────────────
    #dbs? ≥ 1
    dbs'           = dbs?
    join_col'      = join_col?
    join_type'     = join_type?
    join_map'      = join_map?
    filters'       = filters?
    col_db'        = buildColIndex(dbs?, join_col?, join_map?)
    removed'       = removed?
    backend'       = backend?
    max_array_rows' = max_array_rows?
    tmpdir'        = tmpdir?

    ─── SelectAllArrayref ─────────────────────────────────────────────
    ΞDatabase_Join        -- state unchanged
    criteria? : CRITERIA
    result!   : seq MERGED_ROW
    ───────────────────────────────────────────────────────────────────
    ∀ c : dom criteria? • c ∈ dom col_db ∪ {join_col}
    result! = joinedQuery(criteria?)
    result! is sorted ascending by join_col value

    ─── AddDatabase ───────────────────────────────────────────────────
    ΔDatabase_Join
    db?         : DATABASE_ABSTRACTION
    local_jc?   : NAME   -- optional; defaults to join_col
    filter?     : CRITERIA   -- optional
    remove?     : ℙ NAME     -- optional
    ───────────────────────────────────────────────────────────────────
    db?.isa('Database::Abstraction')
    local_jc? ∈ ran(db?.columns)
    dbs'      = dbs ^ ⟨db?⟩
    col_db'   = col_db ⊕ { c ↦ #dbs | c ∈ ran(db?.columns) \ {local_jc?} \ removed }
    filters'  = if filter? ≠ ∅ then filters ⊕ {#dbs ↦ filter?} else filters
    join_map' = if local_jc? ≠ join_col
                then join_map ⊕ {#dbs ↦ local_jc?}
                else join_map
    removed'  = removed ∪ remove?

    ─── RemoveColumn ──────────────────────────────────────────────────
    ΔDatabase_Join
    col? : NAME
    ───────────────────────────────────────────────────────────────────
    col? ≠ join_col
    removed'  = removed ∪ {col?}
    col_db'   = col_db \ {col?}
    join_map' = join_map
    filters'  = filters
    dbs'      = dbs

=head2 collision_prefix

    ─── CollisionPrefix ───────────────────────────────────────────────
    collision_prefix : ℕ ⇸ STRING
    dbs              : seq DATABASE_ABSTRACTION
    col_db           : NAME ⇸ ℕ
    ───────────────────────────────────────────────────────────────────
    -- Only secondary databases (index > 0) carry a meaningful prefix:
    dom collision_prefix ⊆ 1 ‥ (#dbs - 1)

    -- Published name for column col from database i:
    published(i, col) ==
        if i ∈ dom collision_prefix ∧ col ∈ dom col_db ∧ col_db(col) < i
        then (collision_prefix i) ^ "." ^ col
        else col

    -- col_db routes the published name to the owning database:
    col_db(published(i, col)) = i

    -- The original column name is never removed from an earlier database:
    ∀ i : 1 ‥ #dbs-1; col : columns(dbs i) •
        published(i, col) ≠ col  ⟹
            ∃ j : 0 ‥ i-1 • col ∈ dom col_db ∧ col_db(col) = j

=head2 join_map

    ─── JoinMap ───────────────────────────────────────────────────────
    join_map : ℕ ⇸ NAME
    dbs      : seq DATABASE_ABSTRACTION
    join_col : NAME
    ───────────────────────────────────────────────────────────────────
    dom join_map ⊆ 0 ‥ (#dbs - 1)
    ∀ i : dom join_map • (join_map i) ∈ ran(dbs i).columns
    ∀ i : 0 ‥ (#dbs - 1) \ dom join_map •
        join_col ∈ ran(dbs i).columns

    -- Resolution of the local join-key name for database i:
    local_jc(i) == if i ∈ dom join_map then join_map(i) else join_col

    -- The canonical name is always join_col; local_jc is never exposed.

=head2 SECURITY INVARIANTS

    ─── PartitionIsolation ─────────────────────────────────────────────
    -- For every query call with criteria C and column col ≠ join_col:
    ∀ i : 0 ‥ #dbs-1 •
        i ≠ _col_db(col)  ⟹  col ∉ dom(per_db(i))

    -- Unknown column is dropped before any database sees it:
    col ∉ dom(_col_db) ∧ col ≠ join_col  ⟹
        (∀ i : 0 ‥ #dbs-1 • col ∉ dom(per_db(i)))

    ─── NoCodeExecution ────────────────────────────────────────────────
    -- DJ contains no call to system(), exec(), open(PIPE), or eval().
    -- Hostile criterion values therefore cannot achieve code execution
    -- within the Database::Join layer.
    ∀ v : VALUE • _joined_query({col ↦ v}) ≠ ⊥ due to code injection

=head2 filters

    ─── Filters ─────────────────────────────────────────────────────
    filters  : ℕ ⇸ CRITERIA
    dbs      : seq DATABASE_ABSTRACTION
    ─────────────────────────────────────────────────────────────────
    dom filters ⊆ 0 ‥ (#dbs - 1)

    -- A filtered database i always contributes to key-set intersection.
    -- For each query with criteria C:
    effective_criteria(i, C) ==
        if i ∈ dom filters
        then merge_criteria(filters(i), partition(C, i))
        else partition(C, i)

    -- Criteria merging (AND semantics for operator hashrefs):
    merge_criteria(base, extra) ==
        { col : dom base ∪ dom extra •
            if col ∈ dom base ∩ dom extra
               ∧ base(col) ∈ HASHREF ∧ extra(col) ∈ HASHREF
            then col ↦ base(col) ∪ extra(col)   -- operator union
            else col ↦ (if col ∈ dom extra then extra(col) else base(col)) }

=head2 selectall_arrayref

    selectall_arrayref : CRITERIA → seq MERGED_ROW
    pre:  ∀ col : dom criteria • col ∈ dom self._col_db ∪ {self._join_col}
    post: result = _joined_query(criteria)
          result is sorted ascending by join_col value

=head2 selectall_array

    selectall_array : CRITERIA → seq MERGED_ROW | MERGED_ROW?
    pre:  same as selectall_arrayref
    post: wantarray  => result = @{ selectall_arrayref(criteria) }
          !wantarray => result = selectall_arrayref(criteria)[0]  (or undef)

=head2 fetchrow_hashref

    fetchrow_hashref : CRITERIA → MERGED_ROW?
    post: result = selectall_arrayref(criteria)[0]  (or undef if empty)

=head2 count

    count : CRITERIA → ℕ
    post: result = #selectall_arrayref(criteria)

=head2 columns

    columns : → seq NAME
    post: result = sort(
              (⋃ { i : 0 ‥ #dbs-1 • ran(dbs(i).columns) }
               \ dom removed_cols
               \ { local_jc(i) | i ∈ dom join_map ∧ local_jc(i) ≠ join_col })
          )

=head2 schema

    schema : → NAME ⇸ SCHEMA_INFO
    post: dom(result) = ran(columns())
          ∀ col : dom(result) •
              result(col) = (last database containing col).schema()(col)

=head2 updated

    updated : → ℕ
    post: result = max { i : 0 ‥ #dbs-1 • dbs(i).updated() }

=head2 remove_column

    remove_column : NAME → Database_Join
    pre:  col ≠ self._join_col
    post: self'._removed_cols = self._removed_cols ∪ {col}
          self'._col_db       = self._col_db \ {col}
          self'._col_cache    = undef
          self'._schema_cache = undef

=head2 AUTOLOAD

    AUTOLOAD : NAME × CRITERIA → VALUE | seq VALUE
    pre:  col ∈ dom self._col_db
          col does not begin with '_'
    post: let rows = _joined_query(criteria)
          wantarray  => result = { r : rows • r(col) }
          !wantarray => result = rows(0)(col)  (or undef if rows is empty)

=head2 backend

    ─── BackendDispatch ───────────────────────────────────────────────
    backend        : {array, sqlite, auto}
    max_array_rows : ℕ
    ───────────────────────────────────────────────────────────────────

    -- row_count(db): cheaply count rows in a component database.
    -- Uses dbi_source() COUNT(*) SQL for SQLite-backed sources,
    -- or the DA's own count() method when defined in its own package.
    -- Returns ⊥ (bottom / unknown) when neither is available.
    row_count(db) ==
        if (db has dbi_source() returning a SQLite dbh)
        then SELECT COUNT(*) FROM source_table
        else if (defined &{ref(db) ^ "::count"})
        then db.count()
        else ⊥

    -- Combined row count across all component databases.
    -- If any database returns ⊥, total is ⊥ (cannot determine).
    total_count ==
        if ∀ i : 0 ‥ #dbs-1 • row_count(dbs i) ≠ ⊥
        then Σ { i : 0 ‥ #dbs-1 • row_count(dbs i) }
        else ⊥

    -- Dispatch rule for _joined_query:
    use_sqlite(C) ==
        backend = 'sqlite'
        ∨ (backend = 'auto' ∧ total_count ≠ ⊥ ∧ total_count > max_array_rows)

    _joined_query(C) ==
        if use_sqlite(C)
        then _sqlite_join(C)
        else _joined_query_array(C)

    -- Result identity invariant: both paths return identical rows.
    ∀ C : CRITERIA •
        _sqlite_join(C) = _joined_query_array(C)

=head1 STATE DIAGRAM

C<Database::Join> objects follow three independent finite state machines (FSMs).
Each FSM is described with an ASCII diagram showing valid states (boxes), the
triggers that cause transitions (arrows), and important side-effects.

=head2 FSM 1: Object Lifecycle

Governs the structural state of a C<Database::Join> instance.
Query methods (C<selectall_arrayref>, C<fetchrow_hashref>, C<count>,
C<columns>, C<schema>, C<updated>) are schema-preserving (Xi-transitions) and
are not shown because they do not change state.

    [pre-creation]
         |
         | new( databases => [...], join_column => '...' )
         |   Side-effect: _col_db routing table built;
         |                _autoload_pk cached from dbs[0]{id}
         v
    [CONSTRUCTED] <-----------------------------------------+
         |    |                                              |
         |    +--------------------------------------------+ |
         |    (query methods: no structural change)         | |
         |                                                  | |
         |-- remove_column( col ) -------> [COL_REMOVED] <--+ |
         |                                      |    |        |
         |   Side-effect: col removed from       |    |        |
         |   _col_db; _col_cache and             +----+        |
         |   _schema_cache cleared.              (idempotent;  |
         |   Join column cannot be removed.)      chainable)   |
         |                                                     |
         +-- add_database( db ) ----------> [DB_ADDED] <------+
                                                |    |
             Side-effect: new columns added;    |    | add_database( db )
             _col_db extended; SQLite cache     |    | (chainable; each
             invalidated (if any).              +----+  extends the view)

    Note: COL_REMOVED and DB_ADDED are not mutually exclusive.
    Both transitions are legal on any valid object, in any order.

    Illegal triggers (always croak; object state is not changed):

      Trigger                              Error
      -----------------------------------  ---------------------------------
      new( databases => [] )               error_no_databases
      remove_column( join_column )         error_remove_join_column
      add_database( non-reference )        error_invalid_database
      new() with join_col absent from DB   error_join_col_absent

=head2 FSM 2: SQLite Cache Lifecycle

Governs the temporary SQLite cache used by the C<backend='sqlite'> and
C<backend='auto'> join paths.  The cache does not exist until the first
query on the SQLite path.

    [ABSENT] <----- add_database( db )
       |                  |
       |  (no temp file)  | Side-effect: old DBI handle disconnected;
       |                  |   _sqlite_cache deleted.
       |                  |
       |                  +<-------------------------------------------+
       |                                                               |
       | first query on SQLite path                                    |
       | Side-effect: File::Temp db created in tmpdir;                 |
       |   DBI connected; sources ATTACHed or spilled;                 |
       |   _sqlite_cache = { dbh, tmpfile, n, updated, ... }           |
       v                                                               |
    [FRESH] <--+                                                       |
       |        |                                                      |
       |        | subsequent queries                                   |
       |        | (cache reused; refaddr of _sqlite_cache unchanged)   |
       +--------+                                                      |
       |                                                               |
       | updated() timestamp of any source DA changes                  |
       | -- OR -- source row count changes                             |
       | Side-effect: none yet (_cache_fresh returns false)            |
       v                                                               |
    [STALE]                                                            |
       |                                                               |
       | next query                                                    |
       | Side-effect: old DBI handle disconnected; old temp file       |
       |   unlinked; new temp file built from current source data.     |
       +---------------------------------------------------------------+
       (transitions to FRESH)

    On object DESTROY:
      FRESH/STALE:  DBI handle disconnected; File::Temp object released
                    (temp file unlinked by File::Temp DESTROY).
      ABSENT:       No temp file exists; no-op.

=head2 FSM 3: Column Visibility (per column)

Each column in the logical view independently follows a two-state machine.
Transition from VISIBLE to REMOVED is one-way: C<add_database> never
restores a column that is in C<_removed_cols>.

    [VISIBLE] <-- initial state for every column at construction
         |    |
         |    | query / columns() / schema()
         |    | (column present in results; no state change)
         +----+
         |
         | remove_column( col )
         | Side-effect: col deleted from _col_db;
         |   _col_cache and _schema_cache cleared.
         v
    [REMOVED] <---+
         |         |
         |         | remove_column( col ) again
         |         | (idempotent; no error; no second side-effect)
         +---------+

    One-way invariant:
      If col is in _removed_cols, then add_database( db_that_has_col )
      does NOT re-add it.  Formal: col_db' = col_db ⊕ { c | c in
      ran(db.columns) \ {local_jc} \ removed }.

    Illegal trigger:
      remove_column( join_column )  -- error_remove_join_column (croaks;
                                       state unchanged)

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
