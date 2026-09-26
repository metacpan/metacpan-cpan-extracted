## Name

Database::Join - Read-only combined view across two or more Database::Abstraction objects

## Version

Version 0.007.1

## Synopsis

**Basic two-database join**

```perl
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
```

**Hiding internal columns**

```perl
my $join = Database::Join->new(
    databases      => [ $customers, $loyalty ],
    join_column    => 'entry',
    remove_columns => [ 'internal_id', 'audit_ts' ],
);
# 'internal_id' and 'audit_ts' never appear in results or columns()
```

**join\_map: when the key column has different names in each database**

```perl
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
```

**filters: permanently restrict a database's visible rows**

```perl
# Only show orders placed more than 60 days ago, without repeating
# the criterion on every query call.
my $join = Database::Join->new(
    databases   => [ $customers, $orders ],
    join_column => 'entry',
    filters     => { 1 => { age_days => { '>' => 60 } } },
);

my $rows = $join->selectall_arrayref();                 # all old orders
my $vip  = $join->selectall_arrayref(tier => 'gold');   # old + gold tier
```

**Inner and outer join types**

```perl
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
```

**Building the view incrementally with add\_database**

```perl
my $join = Database::Join->new(
    databases   => [ $customers ],
    join_column => 'entry',
);

$join->add_database($loyalty)
     ->add_database($scores, remove_columns => ['raw_score']);
```

**AUTOLOAD column shortcut**

```perl
# Returns the 'name' value for entry 'C001' (scalar context)
my $name = $join->name(entry => 'C001');

# Returns all 'tier' values (list context)
my @tiers = $join->tier();
```

**SQLite join backend for large datasets**

```perl
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
```

## Description

`Database::Join` merges two or more [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) objects into a
single logical, read-only view.  Each component database is queried
independently through its own `Database::Abstraction` interface.  The results
are combined using a shared key column (`join_column`).
In effect, this means that you can view data from more than one database using
an intuitive, non-SQL interface.

Every storage format that `Database::Abstraction` supports works as a
component database: CSV, PSV, TSV, SQLite, JSON, XML, XLSX, BerkeleyDB, HTML
URL, JSON URL, or any custom subclass.  Component databases may mix formats
within the same join.

The module exposes the same read-only API as `Database::Abstraction`:
`selectall_arrayref`, `selectall_array`, `fetchrow_hashref`, `count`,
`columns`, `schema`, `updated`, `set_logger`, and the AUTOLOAD column
shortcut.  Callers do not need to know how many underlying databases are
involved.

Think of it as a virtual database table that is assembled on demand from
several real tables, one per component database.

**Join backends**

By default (`backend => 'auto'`), `Database::Join` first checks the
combined source row count.  For small datasets (up to `max_array_rows`,
default 10,000 rows) it merges entirely in Perl memory.  For larger datasets it
automatically spills source rows into a temporary SQLite database and executes
a single SQL JOIN there, keeping peak RAM to roughly one times the source data
size instead of three.  You can also force either path unconditionally with
`backend => 'sqlite'` or `backend => 'array'`.

### Join Semantics

The `join_type` parameter controls what happens when a particular key value
exists in some component databases but not all:

- `left` (the default)

    All rows from the _primary_ (first) database are returned.  Columns from
    subsequent databases are included where a matching row is found, and simply
    absent from the hashref where there is no match.  If you are familiar with
    SQL, this is a LEFT OUTER JOIN on the first table.

- `inner`

    Only rows whose join-column value is present in _every_ component database
    are returned.  This is equivalent to a SQL INNER JOIN.

- `outer`

    Every join-column value found in _any_ component database is returned.
    Columns from databases that do not have that key value are absent from the
    merged row.  This is a FULL OUTER JOIN.

**Important override rule:** whenever you pass a query criterion for a column
that belongs to a secondary database, that database automatically acts as an
inner-join partner for that query only -- regardless of `join_type`.  This
gives WHERE-clause semantics.  For example, if you have a LEFT join but query
`tier => 'gold'` on a secondary database, only rows whose secondary entry
has tier = 'gold' are returned (rows with no secondary entry are excluded, just
as a WHERE clause would exclude them).

### Column Ownership and Routing

At construction time, `Database::Join` calls `columns()` on each component
database and builds an internal index that maps every column name to the
database that owns it.

When you pass criteria to a query method, each key-value pair is automatically
routed to the right database.  You never need to say which database a column
belongs to.

The `join_column` is special: criteria on it are broadcast to _all_
databases so that each database fetches only the relevant rows before the
in-memory merge.

When the same non-join column name exists in more than one database, the
_last_ database in the `databases` array wins by default: its value
overwrites earlier ones in merged rows.  Use `collision_prefix` to
preserve both values under distinct names instead.

## Limitations

- Memory usage (array backend)

    When `backend` is `'array'` (or `'auto'` and the dataset is small), all
    matching rows are fetched into Perl memory.  Peak RAM is roughly three times
    the source data size.  For large datasets use `backend => 'sqlite'`, or
    leave `backend => 'auto'` and set `max_array_rows` appropriately.

- SQLite backend uses a persistent cache file

    When the SQLite path is active, a single `.db` file with a randomly generated
    name (chosen by `File::Temp` to avoid collisions) is created in `tmpdir` the
    first time a query runs on a given `Database::Join` object.  Source data is
    spilled into that file once; subsequent queries against the same object reuse
    the file without re-fetching the source data.

    The cache is automatically invalidated and rebuilt whenever any source
    database's `updated()` timestamp changes (indicating new data), or when
    `add_database()` is called.

    The file is deleted when the `Database::Join` object is destroyed (typically
    when it goes out of scope).  At any given moment no more than one such file
    exists per object.  The directory must be writable and have enough free space
    for the full source data (once, not per-query).

- No chained builder or raw SQL

    `query()` and `execute()` are not implemented.  Use `selectall_arrayref`
    or `fetchrow_hashref` instead.

- Single-column equi-join only

    Joining on more than one column simultaneously, or on expressions, is not
    supported.  When the join key has different names in different databases,
    use `join_map` to declare each database's local column name.

- Sort order

    Results are sorted ascending by `join_column` by default.  Pass
    `sort_by => 'colname'` (or `sort_by => ['colname', 'DESC']`)
    to any query method to override this.  The array path uses string comparison
    (`cmp`); for accurate numeric ordering on large datasets use the SQLite
    backend, which sorts natively by type.

- count() on the array backend fetches all rows

    On the array backend, `count()` executes the full in-memory join and counts
    the resulting rows in Perl; no `COUNT(*)` is pushed to the component
    databases.  On the SQLite backend, `count()` executes a `SELECT COUNT(*)`
    SQL query against the cached join tables, avoiding a full row transfer.

## Common Pitfalls

- The join\_column must exist in every component database

    If even one database is missing the join key column, `new()` (or
    `add_database()`) will `croak` immediately.  Use `join_map` when the
    column has a different local name in some databases.

- Criteria on a removed column are silently dropped

    If you call `remove_column('tier')` and later query
    `selectall_arrayref(tier => 'gold')`, the criterion is ignored (with a
    `carp` warning) and all rows are returned.  Always pass criteria before
    removing columns, or restructure your code to avoid this.

- You cannot remove the join column

    `$join->remove_column($join->join_column)` will `croak`.  The join key
    is required for the merge to work.

- Left join does not guarantee all columns are populated

    Under a LEFT join, rows from the primary database that have no matching row
    in a secondary database will be returned with _no keys_ from that secondary
    database.  Accessing `$row->{score}` on such a row returns `undef` --
    not zero, not an empty string.  Always test `defined $row-`{score}> rather
    than just `$row-`{score}> when the secondary match is optional.

- Filters act as inner-join partners

    Any database that has a `filters` entry is promoted to an inner-join partner,
    regardless of `join_type`.  A row whose join-key value does not appear in
    the filtered database's result is removed from the merged output entirely, not
    merely missing its secondary columns.  This is intentional but can be
    surprising if you expected LEFT join semantics.

- Criteria-merging replaces scalar filters

    When both a base filter and a query criterion target the same column, and both
    are operator hashrefs (e.g. `{ '>' => 60 }`), the operators are combined
    (AND semantics).  But if the query criterion is a plain scalar (e.g.
    `score => 75`), it _replaces_ the base filter for that column entirely --
    the base filter is ignored for that query.

- AUTOLOAD sees the full merged join when filters or join\_map are active

    When either `filters` or `join_map` is in effect, the AUTOLOAD shortcut
    (`$join->columnname(...)`) runs the full join query rather than
    delegating directly to the owning database.  This is necessary for correctness
    but means the result respects all active filters and join-key translations,
    which may differ from what the owning database would return on its own.

- Duplicate column names: last database wins (unless collision\_prefix is set)

    When two component databases each have a column called `notes`, the second
    database's value silently overwrites the first in every merged row.  Use
    `collision_prefix =` { 1 => 'right' }> to publish the second database's
    `notes` as `right.notes` so both values survive, or use `remove_columns`
    (or `remove_column`) to drop the unwanted duplicate entirely.

- Mutating the filters hashref after construction has no effect

    `Database::Join` deep-copies the `filters` hashref (and any `filter`
    passed to `add_database`) at the moment of construction.  The original hashref
    you passed in is never stored.  If you later modify it -- for example, to
    tighten or loosen a filter criterion -- the joined view is _not_ affected.
    Construct a new `Database::Join` object, or use a component
    `Database::Abstraction` that supports dynamic filter modification.

- auto mode may always use the array path for some DAs

    `backend => 'auto'` counts rows cheaply only when each component database
    either implements `dbi_source()` (SQLite-backed) or directly defines a
    `count()` method in its own package.  A DA that merely _inherits_ `count()`
    from `Database::Abstraction` is treated as uncountable, because the parent
    class `count()` expects a key argument and behaves differently from a
    "return total row count" function.  In that case `Database::Join`
    conservatively uses the array path for the whole query, even if the dataset is
    large.  To opt in to the SQLite path for such a DA, either add your own
    `count()` override that returns the total row count, implement `dbi_source()`,
    or use `backend => 'sqlite'` unconditionally.

- dbi\_source() ATTACH is unconditional - query-time criteria go into WHERE

    When a component database implements `dbi_source()`, `Database::Join` always
    uses the zero-copy ATTACH path, _even when the current query includes criteria
    for columns in that database_.  The criteria are translated into parameterised
    SQL `WHERE` clauses applied against the ATTACHed table; no row-level copy is
    performed.  (Prior to 0.005.0 the presence of any query-time criteria would
    force a spill; that restriction has been removed.)

- Broadcast join-column criterion does not force secondaries into inner-join

    When a caller passes a join-column criterion (e.g. `entry => 'k1'`),
    `Database::Join` broadcasts it to all component databases so each DA can
    filter its fetch to the requested key.  Prior to 0.006.0 this broadcast was
    incorrectly counted as "having criteria" for secondary databases, causing
    `left` and `outer` joins to silently behave as `inner` joins when a
    join-column criterion was present.  The fix: only non-join-column criteria
    (e.g. column filters from the caller or base `filters => {...}`) promote
    a secondary to inner-join status.  The broadcast itself is now a transparent
    key-range selector that does not affect join semantics.

- LIKE and NOT LIKE work on the SQLite path; other pattern operators do not yet

    `LIKE`, `NOT LIKE`, `IN`, and `NOT IN` are fully supported on the SQLite
    backend.  `LIKE`/`NOT LIKE` take a scalar pattern; `IN`/`NOT IN` take an
    arrayref of values.  All are injection-safe because values are passed as bind
    parameters, never interpolated.

    ```perl
    # LIKE
    my $rows = $join->selectall_arrayref(name => { LIKE => 'A%' });

    # IN
    my $rows = $join->selectall_arrayref(tier => { IN => ['gold', 'silver'] });

    # NOT IN
    my $rows = $join->selectall_arrayref(tier => { 'NOT IN' => ['bronze'] });
    ```

    `IN` with an empty arrayref matches no rows (SQL semantics: `IN ()` is
    always false).  `NOT IN` with an empty arrayref matches all rows (no
    constraint added).

    `IS NULL` and `IS NOT NULL` are supported on the SQLite backend using an
    explicit operator hashref:

    ```perl
    my $rows = $join->selectall_arrayref(score => { 'IS NULL'     => undef });
    my $rows = $join->selectall_arrayref(score => { 'IS NOT NULL' => 1    });
    ```

    The hashref value is ignored; only the key selects the operator.  A bare
    `undef` criterion value (`score => undef`) also generates `IS NULL`
    on the SQLite path.  Note: on the in-memory array path, the component DA
    may treat an `undef` criterion value as `no filter` rather than
    `IS NULL`, so use the explicit hashref form for consistent behaviour
    across backends.

    Any operator not in the supported set is skipped on the SQLite path with a
    `carp` warning.  The array path forwards all operators to the component DA
    unchanged, which may or may not honour them.

- Temp file directory must be writable and have free space

    The SQLite path creates one temporary `.db` file per `Database::Join` object
    in `tmpdir` (default: `File::Spec->tmpdir()`, usually `/tmp` on Unix).
    The filename is randomly generated by `File::Temp` -- you cannot predict it,
    only the directory is under your control.  The file is created on the first
    query and kept alive until the object is destroyed; it is not re-created on
    every query call.  If the directory is not writable, or the filesystem is full,
    the call will `croak` with `error_sqlite_connect`.  Check permissions and
    free space if you see that error.

## Methods

### New

#### Synopsis

```perl
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
```

#### Description

Constructs and returns a new `Database::Join` object.

Each element of `databases` must be an already-instantiated subclass of
`Database::Abstraction`.  The constructor calls `columns()` on every
database to build an internal column-routing table and verifies that
`join_column` (or its local alias from `join_map`) is present in each one.

Columns listed in `remove_columns` are hidden immediately: they do not appear
in `columns()`, `schema()`, or any returned row hashref.  This is equivalent
to calling `remove_column` once per name after construction.

#### Api Specification

##### Input

```perl
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

parallel       => { type => 'integer',  optional => 1, default => 0 }
                  # When set to 1 and the join has more than 2 databases (primary +
                  # 2 or more secondaries), secondary DA fetches are issued in
                  # parallel Perl threads.  Requires the 'threads' module; falls
                  # back to sequential with a carp warning when unavailable.
                  # Has no effect on the SQLite backend (which uses a single SQL
                  # JOIN).  DBI-backed DAs are not thread-safe by default; only
                  # enable this for in-memory or otherwise thread-safe DA backends.
                  #
                  # DOMAIN -- EP valid:   0 (sequential, default) or 1 (parallel).
                  # DOMAIN -- EP invalid: any other integer is treated as truthy/falsy.
                  # DOMAIN -- Default:    0.

logger         => { type => 'object',   optional => 1 }
                  # Logger object propagated to all component databases.

i18n           => { type => 'object',   optional => 1 }
                  # Localisation object with a translate($key, @args) method.
```

##### Output

```
A blessed Database::Join object.
```

#### Example

```perl
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
```

#### Pseudocode

```
validate all parameters with validate_strict
croak if databases is empty
croak if any element of databases is not a Database::Abstraction subclass
bless the object with all fields initialised
call _build_col_index to map every column to its owning database
    and verify join_column presence in each database
for each column in remove_columns: call remove_column
return the new object
```

#### Messages

```perl
error_no_databases        -- databases arrayref was empty
error_invalid_db          -- an element of databases is not a D::A subclass
error_join_col_missing    -- join_column (or its join_map alias) not found in a database
error_invalid_backend     -- backend value is not 'array', 'sqlite', or 'auto'
error_sqlite_connect      -- temporary SQLite database could not be created (backend='sqlite'/'auto')
warn_schema_type_mismatch -- (carp) a shared column has different types across databases;
                             use collision_prefix to preserve both values
```

### Join\_Map - Joining on Differently-Named Columns

By default every component database must have a column whose name matches
`join_column`.  If a database uses a different local name for the join key,
declare the mapping with `join_map`.

`join_map` is a hashref.  Each **key** is the **zero-based position** of a
database in the `databases` array (0 = first, 1 = second, and so on).  Each
**value** is the name that **that particular database** uses for the join key.

Databases not listed in `join_map` are assumed to already have a column
named `join_column` and need no entry.

Throughout the merged view the join key is _always_ referred to by the name
given in `join_column`.  The local alias is never exposed in returned rows,
in `columns()`, or in `schema()`.

**When do you need join\_map?**

You need `join_map` when you have two tables like:

```
cities table  : entry (the city name) | statecode
stnames table : entry (the state code) | state
```

Here you want to join cities.statecode to stnames.entry.  You choose
`join_column => 'statecode'` as the canonical name, but stnames calls
that same concept `entry`, so you declare:

```perl
join_map => { 1 => 'entry' }  # stnames (index 1) calls it 'entry'
```

**Example**

```perl
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
```

**Using add\_database instead**

If you build the join incrementally with `add_database`, pass
`join_column` directly to that call instead of using `join_map`:

```perl
my $join = Database::Join->new(
    databases   => [ $cities ],
    join_column => 'statecode',
);
$join->add_database($stnames, join_column => 'entry');
```

This is exactly equivalent to the `join_map` form above.

### Filters - Permanent Per-Database Row Filters

`filters` lets you restrict a component database to a subset of its rows
permanently, without repeating the criterion on every query call.

Think of it as telling the join: "whenever you query this database, always
add these extra conditions".  Callers never need to specify the restriction
themselves and can never accidentally omit it.

`filters` is a hashref.  Each **key** is the **zero-based position** of a
database in the `databases` array (same numbering as `join_map`).  Each
**value** is a criteria hashref in the same format as `selectall_arrayref`
accepts.

**Key-set semantics**

A filtered database always acts as an inner-join partner, regardless of the
`join_type` setting.  Any join-key value that does not pass the filter is
excluded from the merged output entirely -- not just missing its secondary
columns.  This ensures the filter genuinely restricts the view rather than
simply hiding a few fields.

**Criteria merging**

When a query call also passes a criterion for a column that already has a base
filter, the two constraints are combined:

- When both the base filter value and the query criterion are operator hashrefs
(e.g. `{ '>' => 60 }` and `{ '<' => 365 }`), their operators are
merged: _both_ constraints apply simultaneously (AND semantics).
- When either value is a plain scalar, or the operators conflict, the
query-time criterion wins and the base filter for that column is ignored for
that one call.

**Example -- only show orders placed more than 60 days ago**

```perl
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
```

When using `add_database`, pass `filter` (singular) to set the base
criteria for the new database:

```perl
$join->add_database($orders, filter => { age_days => { '>' => 60 } });
```

### Collision\_Prefix - Preserve Colliding Columns From Secondary Databases

By default, when a column name appears in more than one database the _last_
database wins: its value silently overwrites earlier ones in merged rows.
This loses data and makes the origin invisible.

`collision_prefix` changes this for secondary databases you designate.
When a secondary database at index N has a column that already exists in the
merged view, and `collision_prefix->{N}` is set, the colliding column is
published as `"$prefix.$col"` instead of overwriting.  Both values are then
visible: the original column keeps its name (from the earlier database), and
the collision gets the prefixed name.

`collision_prefix` is a hashref.  Each **key** is the **zero-based index** of
a secondary database in the `databases` array (same numbering as `join_map`).
Each **value** is the prefix string to prepend.  An index-0 entry is
meaningless and silently ignored.  Omitting `collision_prefix` entirely
preserves the previous last-wins behaviour and changes nothing.

Non-colliding columns from a secondary database are always added as-is with
no prefix, whether or not `collision_prefix` is configured.

**Example -- sales table and products table, both with a "product" column**

```perl
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
```

**Querying on a prefixed column**

Use the full published name as the criterion key:

```perl
my $rows = $join->selectall_arrayref('products.product' => 'widget');
# Internally routes as: product => 'widget' to $products
```

**Interaction with remove\_column**

`remove_column` operates on published names.  To suppress a prefixed
collision column entirely, pass the prefixed name:

```
$join->remove_column('products.product');
```

### Backend - SQLite Join Backend for Large Datasets

`Database::Join` can merge component databases in two different ways,
controlled by the `backend` constructor parameter.

- `backend => 'array'` -- in-memory merge (original behaviour)

    All matching rows are fetched from every component database into Perl hashes
    and merged there.  Simple and fast for small and medium datasets.  Peak RAM
    is roughly three times the combined source data size (one copy per database
    plus one merged copy).

- `backend => 'sqlite'` -- SQL JOIN via a cached temporary file

    `Database::Join` creates a temporary SQLite database file, spills source
    rows into it (one table per component database), then executes a single SQL
    `JOIN` statement per query call.  Peak RAM drops to roughly one times the
    source data size.

    The temporary file is created once and reused across multiple query calls on
    the same object (the cache).  Only query-time criteria vary per call; they
    are applied as SQL `WHERE` clauses against the cached data.  The cache is
    automatically rebuilt when any source database's `updated()` timestamp
    changes.  The file is deleted when the object is destroyed (goes out of
    scope).  See _Temporary file: name, location, and lifetime_ below for
    details.

    Requires `DBD::SQLite >= 1.70` (`FULL OUTER JOIN` support was added in
    SQLite 3.39.0; DBD::SQLite 1.70 ships SQLite 3.39.2).

- `backend => 'auto'` (default)

    `Database::Join` counts the total rows from all component databases cheaply
    \-- without fetching them -- and then decides:

    - If the combined count is less than or equal to `max_array_rows` (default
    10,000), use the array path.
    - If the combined count exceeds `max_array_rows`, use the SQLite path.

    For counting to work without fetching, each component database must either
    implement the `dbi_source()` interface (for SQLite-backed sources, where a
    `COUNT(*)` SQL query is issued directly), or directly define a `count()`
    method in its own package -- not just inherit one from a parent class.  If
    neither is available for a particular database, `Database::Join` plays it
    safe and uses the array path for the whole query without fetching any rows.

**Choosing max\_array\_rows**

The default of 10,000 is a reasonable starting point.  Adjust it to match
your hardware and typical row width.  For wide rows (many columns or long
strings) you may want a lower threshold; for narrow rows you can raise it.

**Temporary file: name, location, and lifetime**

When the SQLite path is active, a single temporary SQLite database file acts
as the join cache for the life of the `Database::Join` object.

**Name**: the filename is randomly generated by `File::Temp`, for example:

```
/tmp/Cj8xK7mP2Q.db
```

The random portion (ten characters) is chosen automatically to avoid
collisions.  Only the directory is under your control; you cannot specify
the filename itself.

**Location**: controlled by the `tmpdir` constructor parameter.
If `tmpdir` is not specified, `File::Spec->tmpdir()` is used (usually
`/tmp` on Unix, or the value of the `TEMP` or `TMP` environment variable
on Windows).

**Lifetime: one file per object, deleted when the object is destroyed**: the
file is created on the first query call that uses the SQLite path and kept
alive until the `Database::Join` object is destroyed (i.e. when it goes out
of scope or is explicitly `undef`-d).  At most one file exists per object at
any given moment.  Calling `selectall_arrayref()` ten times on the same
object creates and uses _one_ file, not ten.

**Cache invalidation**: the cache is automatically rebuilt (the old file is
replaced with a new one) when any source database's `updated()` return value
changes, or when `add_database()` is called.  Base-filter criteria
(`filters` constructor parameter) are applied once at build time for spilled
sources; query-time criteria are applied per-call as SQL `WHERE` clauses.

To use a different directory -- for example a RAM-backed filesystem or a
faster local disk:

```perl
my $join = Database::Join->new(
    databases      => [ $db1, $db2 ],
    join_column    => 'entry',
    backend        => 'sqlite',
    tmpdir         => '/dev/shm',     # Linux RAM disk
);
```

**Parallel secondary fetches (`parallel` constructor parameter)**

By default, component databases are queried sequentially - the primary first,
then each secondary in order.  When the component databases are network- or
disk-backed and have non-trivial per-query latency, the sequential fetch means
total latency is the _sum_ of all per-DA latencies.

Setting `parallel => 1` in the constructor enables concurrent fetching
of secondary databases using Perl `threads`.  With `parallel =` 1> and
two or more secondary databases (`n > 2` total), secondary fetches run in
parallel after the primary fetch completes; total latency drops to
_max(secondary latencies)_ instead of _sum(secondary latencies)_.

```perl
my $join = Database::Join->new(
    databases   => [ $customers, $loyalty, $scores ],   # 3 DAs - 2 secondaries
    join_column => 'entry',
    parallel    => 1,    # loyalty and scores fetched concurrently
);
```

Requirements and caveats:

- The `threads` module must be available.  Most distributions ship it, but it
requires a Perl binary compiled with `-Dusethreads`.  When threads are
unavailable, a `carp` warning is emitted and fetching falls back to
sequential; the result is identical, only slower.
- Parallel fetching is only active when the join has three or more total
databases (`n > 2`).  With two databases (one secondary), the thread
creation overhead exceeds the benefit of concurrency; sequential is used
regardless of `parallel`.
- Component databases must be safe to call from Perl threads.  In-memory
databases (CSV, JSON, TSV after slurp) are safe.  DBI-backed databases
whose handles were created in the same thread may not be safe - consult your
DBD driver's thread documentation.  The array backend is recommended for
DBI-backed sources; the SQLite backend performs its join in a single SQL
statement and does not use parallel fetching.
- `parallel =` 1> applies to the array backend only.  The SQLite backend
performs a single SQL JOIN after spilling source data, so per-DA parallelism
is irrelevant.

**Zero-copy ATTACH (`dbi_source()` interface)**

Normally, when the SQLite path is active, rows from each component database
are fetched one by one and inserted into the temporary SQLite file.  This is
efficient but does involve INSERT overhead.

If a component database is itself SQLite-backed and implements a
`dbi_source()` method, `Database::Join` can skip the row-by-row copy
entirely and instead use `ATTACH DATABASE` to link the source file directly
to the temporary join connection.  This is the zero-copy path and is
significantly faster for large SQLite sources.

The `dbi_source()` method must return a hashref with two keys:

- `dbh`

    A connected `DBD::SQLite` database handle (`DBI` connection object).

- `table`

    The name of the table in that database that holds the source rows.

Example implementation:

```perl
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
```

The zero-copy ATTACH path is always used when a component database implements
`dbi_source()`.  Query-time criteria are applied as parameterised SQL
`WHERE` clauses against the ATTACHed source table, so no row-level copy is
needed even when the current call includes column filters.  (Prior to 0.005.0
any query-time criteria forced a spill; that restriction was removed in
0.005.0.)

**Result identity**

Both the array path and the SQLite path produce identical results for any
given query.  You can switch between them freely without changing callers.
The `collision_prefix` column renaming, `join_map` key translation, and all
three join types (left, inner, outer) work identically on both paths.

### Selectall\_Arrayref

#### Synopsis

```perl
my $rows = $join->selectall_arrayref();
my $rows = $join->selectall_arrayref(tier  => 'gold');
my $rows = $join->selectall_arrayref(score => { '>' => 80 });
my $rows = $join->selectall_arrayref('C001');  # positional: entry => 'C001'
my $rows = $join->selectall_arrayref(sort_by => 'name');
my $rows = $join->selectall_arrayref(tier => 'gold', sort_by => ['score', 'DESC']);
my $rows = $join->selectall_arrayref(limit => 10);
my $rows = $join->selectall_arrayref(limit => 10, offset => 20);
my $rows = $join->selectall_arrayref(tier => 'gold', sort_by => 'name', limit => 5);
```

#### Description

Returns an arrayref of hashrefs representing the merged view of all component
databases, optionally filtered by the given criteria.

Criteria for columns that live in different databases are routed
automatically: each database is queried with only the criteria that apply to
its own columns.  The results are combined in memory using `join_column`.

Accepts the same criteria syntax as `Database::Abstraction::selectall_arrayref`.
A single plain scalar argument is interpreted as the `join_column` value
(equivalent to `entry => 'C001'` when `join_column` is `'entry'`).

#### Api Specification

##### Input

```perl
Calling conventions (in order of precedence):
  1. No arguments             -- returns all rows
  2. One plain scalar         -- shorthand for join_column => $scalar
  3. Key-value pairs or
     a criteria hashref       -- routed per-database

Values may be:
  Plain scalar                -- exact match
  Hashref of operators        -- e.g. { '>' => 80 }

Optional parameters (mixed in with any of the above):
  sort_by => 'colname'            -- sort ascending by that column
  sort_by => ['colname', 'DESC']  -- sort descending
  sort_by => ['colname', 'ASC']   -- sort ascending (explicit)
  limit    => N                    -- return at most N rows (positive integer)
  offset   => M                   -- skip the first M rows (non-negative integer)

The column named in sort_by must be present in the merged view (i.e. it
must appear in columns()).  An unknown column or an invalid direction emits
a carp warning and falls back to the default join_column ascending sort.

limit and offset are applied after ordering.  offset without limit skips
rows but returns all remaining rows.  limit without offset starts from
the first qualifying row.  An invalid limit or offset emits a carp warning
and the parameter is ignored (treated as absent).

DOMAIN -- sort_by:
  EP absent:          result sorted by join_column ASC (default).
  EP string:          any column name in columns(); sorts ASC by that column.
  EP ['col','ASC']:   explicit ascending; equivalent to the string form.
  EP ['col','DESC']:  descending sort by the named column.
  EP ['col']:         single-element arrayref; direction defaults to ASC.
  EP []:              empty arrayref; column is undef -> carp + join_col ASC fallback.
  EP invalid column:  column not in columns() -> carp + join_col ASC fallback.
  EP invalid dir:     direction not 'ASC' or 'DESC' -> carp + ASC used.
  Sort is lexicographic (cmp); use backend=>'sqlite' for numeric ORDER BY.

DOMAIN -- limit:
  EP absent:          no truncation; all qualifying rows are returned.
  EP 0:               not a positive integer -> carp + ignored (all rows returned).
  BVA min valid = 1:  exactly 1 row returned.
  BVA at count:       limit == total rows -> all rows returned (no truncation).
  BVA above count:    limit > total rows -> all rows returned.
  EP invalid:         negative integer, float string, or non-numeric string
                      => carp + ignored (all rows returned).
  Valid domain:       integers in [1, INF); matched by /^\d+\z/a with value >= 1.

DOMAIN -- offset:
  EP absent:          no rows skipped; result starts from row 0.
  BVA min valid = 0:  no rows skipped (zero is a valid non-negative integer).
  BVA offset=1:       first row skipped; result starts from row 1.
  BVA offset=N-1:     N-1 rows skipped; only the last row returned.
  BVA offset=N:       all N rows skipped; empty result returned.
  BVA offset>N:       all rows skipped; empty result returned.
  EP invalid:         negative integer, float string, or non-numeric string
                      => carp + ignored (no rows skipped).
  Valid domain:       integers in [0, INF); matched by /^\d+\z/a.
```

##### Output

```
Arrayref of hashrefs; one hashref per qualifying merged row.
Sorted ascending by join_column by default; caller-controlled via sort_by.
At most C<limit> rows when limit is given; the first C<offset> rows are
skipped when offset is given.
Returns a reference to an empty array when no rows match.
```

#### Example

```perl
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
```

#### Messages

```
warn_unknown_column (carp)
    -- A criterion key names a column not present in any component database;
       the criterion is silently dropped and all rows are returned.
sort_by column unknown (carp)
    -- The column given in sort_by is not in the merged view; the result
       is returned in the default join_column ascending order instead.
sort_by direction invalid (carp)
    -- The direction given in sort_by is not 'ASC' or 'DESC'; ASC is used.
limit invalid (carp)
    -- The value given for limit is not a positive integer; it is ignored.
offset invalid (carp)
    -- The value given for offset is not a non-negative integer; it is ignored.
operator-unsupported (carp, SQLite/auto path only)
    -- An operator hashref key is not in the supported set (>, <, >=, <=,
       !=, =, LIKE, NOT LIKE, IS NULL, IS NOT NULL, IN, NOT IN); the
       individual operator term is dropped from the WHERE clause (other
       operators in the same hashref still apply).
IN/NOT IN wrong value type (carp, SQLite/auto path only)
    -- An IN or NOT IN criterion was given a non-arrayref value; the operator
       term is skipped.
error_sqlite_connect (croak, SQLite/auto path only)
    -- The temporary SQLite join file could not be created; check tmpdir
       permissions and available disk space.
```

### Selectall\_Array

#### Synopsis

```perl
my @rows = $join->selectall_array(tier => 'gold');

# Scalar context: only the first matching row
my $first = $join->selectall_array(entry => 'C001');
```

#### Description

In list context returns a list of merged hashrefs -- the same rows that
`selectall_arrayref` would return, just as a flat list rather than an
arrayref.

In scalar context returns only the first matching hashref (or `undef` if
nothing matches).

#### Api Specification

##### Input

```
Same as selectall_arrayref.
```

##### Output

```
List context:   list of hashrefs (may be empty).
Scalar context: single hashref or undef.
```

#### Example

```perl
my @all = $join->selectall_array();
print scalar @all, " rows\n";

# First gold-tier customer only
my $first_vip = $join->selectall_array(tier => 'gold');
print $first_vip->{name}, "\n" if defined $first_vip;
```

#### Messages

Same messages as `selectall_arrayref`.

### Fetchrow\_Hashref

#### Synopsis

```perl
my $row = $join->fetchrow_hashref(entry => 'C001');
my $row = $join->fetchrow_hashref('C001');   # positional shorthand
```

#### Description

Returns a single merged hashref for the first row matching the given
criteria, or `undef` when nothing matches.

Equivalent to calling `selectall_arrayref` and taking only the first element.
All the same criteria conventions apply.

#### Api Specification

##### Input

```
Same as selectall_arrayref.
```

##### Output

```
Hashref, or undef when no row matches.
```

#### Example

```perl
my $row = $join->fetchrow_hashref(entry => 'C001');
if (defined $row) {
    print "Name: $row->{name}, Tier: $row->{tier}\n";
} else {
    print "No record for C001\n";
}

# Positional: works when join_column is 'entry'
my $row2 = $join->fetchrow_hashref('C001');
```

#### Messages

Same messages as `selectall_arrayref`.

### Count

#### Synopsis

```perl
my $total  = $join->count();
my $active = $join->count(tier => 'gold');
```

#### Description

Returns the number of merged rows that satisfy the given criteria.

On the array backend, the full in-memory join is performed and the resulting
rows are counted in Perl.  On the SQLite backend, a `SELECT COUNT(*)` SQL
query is executed against the cached join tables, avoiding a full row fetch.

#### Api Specification

##### Input

```
Same criteria syntax as selectall_arrayref.
```

##### Output

```
Non-negative integer.
```

#### Example

```perl
my $total   = $join->count();
my $gold    = $join->count(tier => 'gold');
my $high    = $join->count(score => { '>' => 90 });

printf "%d total, %d gold-tier, %d high-scorers\n",
    $total, $gold, $high;
```

#### Messages

Same messages as `selectall_arrayref`.

### Dbi\_Source

#### Synopsis

```perl
# Use a Database::Join object as a zero-copy SQLite source inside a
# parent Database::Join, giving the parent ATTACHed-speed access to
# the child's joined data without iterating through Perl.
my $child  = Database::Join->new(databases => [$da, $db], join_column => 'id', backend => 'sqlite');
my $parent = Database::Join->new(databases => [$child, $dc], join_column => 'id', backend => 'sqlite');
```

#### Description

Returns a hashref `{ dbh => $sqlite_dbh, table => '_dj_result' }` that
allows a parent `Database::Join` (or any other caller that understands the
`dbi_source()` interface) to ATTACH the child's temporary SQLite database
file and query the materialised join result directly via SQL, without routing
rows through Perl.

The first call builds the SQLite cache (if not already current) and
materialises the full join result - with `filters` applied but no query-time
criteria - into a real table named `_dj_result` inside the cache file.
Subsequent calls within the same cache cycle reuse the existing table.

Returns `undef` when the backend is `'array'` (no SQLite file exists).

#### Api Specification

##### Input

```
None.
```

##### Output

```perl
On the SQLite/auto backend:
  Hashref with keys:
    dbh   => DBI handle to the child's temporary SQLite database file.
    table => '_dj_result'  (the materialized join table inside that file).
On the array backend:
  undef
```

#### Example

```perl
# The parent automatically ATTACHes the child's SQLite file and queries
# _dj_result for zero-copy composable nested joins.
my $inner = Database::Join->new(
    databases   => [$customers, $loyalty],
    join_column => 'entry',
    backend     => 'sqlite',
);
my $outer = Database::Join->new(
    databases   => [$inner, $scores],
    join_column => 'entry',
    backend     => 'sqlite',
);
my $rows = $outer->selectall_arrayref(tier => 'gold');
```

#### Messages

```
error_sqlite_connect (croak)
    -- The temporary SQLite join file could not be created.
```

### Columns

#### Synopsis

```perl
my $cols = $join->columns();
```

#### Description

Returns an arrayref of all column names visible in the merged view,
deduplicated and sorted alphabetically.

The `join_column` appears exactly once, even if it exists under different
local names in some databases (see `join_map`).  Columns that have been
hidden with `remove_column` or `remove_columns` do not appear.

The result is memoised: repeated calls are cheap.

#### Api Specification

##### Input

```
None.
```

##### Output

```
Arrayref of column name strings, sorted alphabetically.
```

#### Example

```perl
my $cols = $join->columns();
print join(', ', @{$cols}), "\n";
# e.g. "entry, name, score, tier"
```

#### Messages

`columns()` does not itself emit any warnings or errors.  Any exception thrown
by a component database's `columns()` method propagates uncaught.

### Schema

#### Synopsis

```perl
my $schema = $join->schema();
```

#### Description

Returns a merged schema hashref for all visible columns across all component
databases.  Each key is a column name; each value is the schema metadata
hashref returned by `Database::Abstraction::schema()` for that column
(typically `{ type, nullable, default, pk }`).

When the same column name appears in more than one database the _last_
database's metadata is used.  Columns hidden with `remove_column` are not
included.

The result is memoised.

#### Api Specification

##### Input

```
None.
```

##### Output

```perl
Hashref: column_name => { type => ..., nullable => ..., default => ..., pk => ... }.
```

#### Example

```perl
my $schema = $join->schema();
for my $col (sort keys %{$schema}) {
    my $info = $schema->{$col};
    printf "%-15s type=%-10s nullable=%s\n",
        $col, $info->{type}, $info->{nullable} ? 'yes' : 'no';
}
```

#### Messages

`schema()` does not itself emit any warnings or errors.  Any exception thrown
by a component database's `schema()` method propagates uncaught.

### Updated

#### Synopsis

```perl
my $ts = $join->updated();
```

#### Description

Returns the Unix timestamp of the most recent modification across all
component databases.  This is the maximum of all individual `updated()`
return values.

Use this to implement simple cache-invalidation logic: if `updated()`
has advanced since your last snapshot, re-query.

#### Api Specification

##### Input

```
None.
```

##### Output

```
Unix timestamp (positive integer).
```

#### Example

```perl
my $last_modified = $join->updated();
if ($last_modified > $my_cache_timestamp) {
    $my_cache = $join->selectall_arrayref();
    $my_cache_timestamp = $last_modified;
}
```

#### Messages

`updated()` does not emit any warnings or errors.  Component databases that do
not implement `updated()`, or whose `updated()` throws, are silently skipped;
only defined return values contribute to the maximum.  If no component database
implements `updated()`, `undef` is returned (same as `List::Util::max` on an
empty list).

### Set\_Logger

#### Synopsis

```
$join->set_logger($log);
```

#### Description

Attaches a new logger object to the join and propagates it to every component
database.  The logger is used for diagnostic output by all component databases.

#### Api Specification

##### Input

```
$log    Positional: a logger object (required).
        Must support whatever interface Database::Abstraction expects.
```

##### Output

```perl
Returns C<$self> for method chaining.
```

#### Example

```perl
# Log::Any is used here as an example; any object that implements
# debug() and info() (or whichever methods your component databases
# call internally) works equally well.
use Log::Any qw($log);

my $join = Database::Join->new(databases => [$db1, $db2], join_column => 'entry');
$join->set_logger($log);
# $log is now used by $join and by $db1 and $db2
```

#### Messages

```
(croak) Usage: set_logger($logger)
    -- Called with an undefined argument.  Pass a valid logger object.
```

### Add\_Database

#### Synopsis

```perl
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
```

#### Description

Adds one more `Database::Abstraction` subclass object to the logical view
and immediately updates the column-ownership index.

After the call, all query methods return rows that include columns from the
newly added database, and criteria on those new columns are routed to it
automatically.

When a column name in the new database already exists in an earlier database,
the new database becomes the authoritative source for that column
(last-database-wins, the same rule that applies at construction time).

The join-column must be present in the new database (or declared via
`join_column`).  The logger is propagated to the new database if one is set.

`add_database` is the runtime equivalent of listing the database in the
`databases` array to `new`.  The optional `join_column` parameter is
equivalent to a `join_map` entry; the optional `filter` parameter is
equivalent to a `filters` entry.

#### Api Specification

##### Input

```perl
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
```

##### Output

```perl
Returns C<$self> to support method chaining.
```

#### Example

```perl
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
```

#### Pseudocode

```perl
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
```

#### Messages

```perl
error_invalid_db          -- argument is not a Database::Abstraction subclass
error_join_col_missing    -- join_column not found in the new database
warn_schema_type_mismatch -- (carp) the new database has a shared column whose type
                             differs from the type already in the view; use
                             collision_prefix to preserve both values
```

### Remove\_Column

#### Synopsis

```
$join->remove_column('email');

# Chainable
$join->remove_column('internal_id')->remove_column('audit_ts');
```

#### Description

Permanently hides a column from the merged view.  After this call:

- The column does not appear in `columns()` or `schema()`.
- Returned row hashrefs do not contain the column key.
- Any query criterion that references the removed column is silently dropped
(with a `carp` warning).

The `join_column` cannot be removed; attempting to do so will `croak`.
Removing a column that does not exist in any database is silently ignored
(the call is idempotent and safe).  The `columns()` and `schema()`
memoisation caches are cleared automatically.

#### Api Specification

##### Input

```perl
$col    Positional string: the column name to remove.

        DOMAIN -- EP valid:   any string; non-existent columns are silently
                              ignored (idempotent call, returns $self).
        DOMAIN -- EP invalid: join_column value => croak error_remove_join_col.
        DOMAIN -- BVA:        undef and '' are explicit no-ops (returns $self).
                              These are below the minimum meaningful string
                              length and are handled without any warning.
```

##### Output

```perl
Returns C<$self> to support method chaining.
```

#### Example

```perl
# Hide private fields immediately after construction
my $join = Database::Join->new(
    databases   => [ $customers, $loyalty ],
    join_column => 'entry',
)->remove_column('email')
 ->remove_column('internal_notes');

# Verify they are gone
my $cols = $join->columns();
# 'email' and 'internal_notes' are absent
```

#### Messages

```
error_remove_join_col -- attempt to remove the join_column itself
```

### Query

Not supported.  `Database::Join` does not implement the chained query
builder.  Calling this method will always `croak` with an explanatory message.

Use `selectall_arrayref`, `selectall_array`, `fetchrow_hashref`, or
`count` instead.

### Execute

Not supported.  Raw SQL cannot span heterogeneous backends that may use
different database engines.  Calling this method will always `croak`.

Use `selectall_arrayref` or `fetchrow_hashref` to query the joined view.

### AUTOLOAD - Column Shortcut

Calling an unknown method whose name matches a visible column name performs
a column lookup across the merged view.

#### Synopsis

```perl
# Scalar context: value from the first matching row
my $name  = $join->name(entry => 'C001');

# List context: values from every matching row
my @tiers = $join->tier();

# With a positional join-key argument (when join_column is 'entry')
my $score = $join->score('C001');
```

#### Description

AUTOLOAD routes the call to the appropriate component database by looking up
the column name in the internal column-ownership index.

When either `join_map` or `filters` is active, AUTOLOAD performs a full
join query instead of delegating directly to the owning database.  This is
necessary because:

- With `join_map`, the owning database's primary key may differ from the
canonical join key used in the call arguments.
- With `filters`, bypassing the join would return rows that the filter is
meant to exclude.

In list context, every matching merged row contributes one value to the
returned list.  In scalar context, only the first row's value is returned.

Calling a method whose name begins with `_` (a private method) via AUTOLOAD
will `croak` with a clear error message rather than being silently ignored.

#### Example

```perl
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
```

#### Pseudocode

```perl
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
```

#### Messages

```
(croak) Database::Join: cannot call private method '_NAME' via AUTOLOAD
    -- Method name begins with '_'.  Private methods must be called directly,
       not via AUTOLOAD.  This is a programming error.

(croak) Database::Join: unknown column 'NAME'
    -- Method name does not match any visible column in the merged view.
       Check spelling, or whether the column was removed with remove_column().
```

## Encoding

All text that passes through `Database::Join` at the Perl layer (column names,
criteria values, merged row values) is treated as opaque strings.
`Database::Join` does not inspect, encode, or transform string content.

- Column names

    Column names are plain ASCII strings as returned by `Database::Abstraction::columns()`.
    Non-ASCII column names are accepted but not tested; behaviour depends on the
    underlying DA and database driver.

- Criteria values and row data

    Values are passed verbatim between callers and component DAs.  Full UTF-8 is
    safe as long as the underlying `Database::Abstraction` objects and their
    database drivers handle UTF-8 correctly.  `Database::Join` neither encodes
    nor decodes any value.

- SQLite backend

    When the SQLite path is active, values are inserted into the temporary SQLite
    database via DBI placeholders (never string interpolation), so binary-safe
    round-tripping depends on `DBD::SQLite`'s character encoding settings.
    By default `DBD::SQLite` operates in UTF-8 mode, which is correct for text
    data.  Binary blobs are not explicitly tested.

- i18n messages

    All internal error and warning messages route through the `i18n` object
    (if one is supplied) via a `translate($key, @args)` call.  The translation
    dictionary controls the final encoding of those strings.

## Messages

The following messages can be produced by `Database::Join`.  All messages
can be localised by supplying an `i18n` object to `new`.

- `error_no_databases`

    **When:** The `databases` arrayref passed to `new` is empty.

    **Fix:** Pass at least one `Database::Abstraction` subclass object.

- `error_invalid_db`

    **When:** An element of the `databases` array (or the argument to
    `add_database`) is not an object, or is not a `Database::Abstraction`
    subclass.

    **Fix:** Instantiate the component database with its own `new` method before
    passing it to `Database::Join`.

- `error_join_col_missing`

    **When:** The join key column (or its `join_map` alias) does not exist in one
    of the component databases.

    **Fix:** Either add the column to the database, change `join_column` to a
    column that is present everywhere, or use `join_map` to declare the local
    alias for databases that call it something different.

- `error_remove_join_col`

    **When:** `remove_column` is called with the name of the join key column.

    **Fix:** The join key is required for the merge to work and cannot be hidden.
    Remove a different column.

- `error_invalid_prefix`

    **When:** A value in the `collision_prefix` hashref is a reference (e.g. a
    hashref or arrayref) rather than a plain string.

    **Fix:** All `collision_prefix` values must be plain strings.  A reference
    would be stringified to `HASH(0x...)` or `ARRAY(0x...)`, leaking a heap
    address into every column name returned by `columns()`, `schema()`, and all
    query results.  Pass a plain string such as `'db2'` or `'secondary'`.

- `warn_unknown_column` (carp)

    **When:** A criterion is passed for a column that does not exist in any
    component database (or has been removed with `remove_column`).

    **Fix:** Check the column name spelling.  The criterion is ignored.

- `error_query_unsupported`

    **When:** `query()` is called on a `Database::Join` object.

    **Fix:** Use `selectall_arrayref`, `selectall_array`, `fetchrow_hashref`,
    or `count` instead.

- `error_execute_unsupported`

    **When:** `execute()` is called on a `Database::Join` object.

    **Fix:** Use the Perl-level query methods instead.  Raw SQL cannot span
    heterogeneous database backends.

- `error_invalid_backend`

    **When:** The `backend` parameter passed to `new` is not one of `'array'`,
    `'sqlite'`, or `'auto'`.

    **Fix:** Use exactly one of those three strings.  The check is case-sensitive;
    `'SQLite'` or `'Auto'` will not be accepted.

- `error_sqlite_connect`

    **When:** The SQLite join backend fails to open the temporary SQLite database
    file.  Common causes: the `tmpdir` directory is not writable, the filesystem
    has no free space, or `DBD::SQLite` is not installed.

    **Fix:** Check that the directory given by `tmpdir` (or the system temp
    directory if `tmpdir` was not set) is writable and has sufficient free space.
    Verify that `DBD::SQLite` 1.70 or later is installed.

## Repository

[https://github.com/nigelhorne/Database-Join](https://github.com/nigelhorne/Database-Join)

## Support

This module is provided as-is without any warranty.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Database-Join/coverage/)
- [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

## Security Considerations

`Database::Join` is a pure in-memory routing and merge layer.  It never
generates SQL strings, never opens files, and never calls `system()`,
`exec()`, or `eval()`.  The security properties described below are
architectural guarantees, not run-time checks.

### What Database::Join Guarantees

- Criteria partition isolation

    Every criterion you pass to a query method is routed to _exactly one_
    component database (the one that owns that column), or to _all_ databases
    when the criterion is on the join key column.  A hostile value in a criterion
    for column `name` (owned by database A) will never reach database B.

- Unknown columns are rejected before reaching any database

    If a criterion column name is not present in any component database (or has
    been hidden with `remove_column`), `Database::Join` logs a `carp` warning
    and silently drops the criterion.  No database receives the hostile key.

- AUTOLOAD only accepts word-character column names

    Perl's method dispatch extracts the column name via `\w+`, which matches only
    `[A-Za-z0-9_]`.  Hostile method names with shell metacharacters, quotes, or
    spaces cannot reach the AUTOLOAD dispatch path.  Private names (starting with
    `_`) are additionally blocked with an explicit `croak`.

- No value sanitisation (by design)

    `Database::Join` does _not_ sanitise, HTML-encode, or validate the
    _values_ in criteria hashrefs.  Preventing SQL injection is the
    responsibility of the underlying `Database::Abstraction` objects (which use
    parameterised queries).  Preventing XSS or header injection is the
    responsibility of the CGI or web layer that renders the output.

- Taint-mode compatible (array path)

    The array merge path contains no `system()`, `exec()`, backtick,
    `open(PIPE)`, or `eval STRING` calls.  It neither opens files nor constructs
    shell commands.  The AUTOLOAD regex `/ :: (\w++) \z /x` uses a possessive
    quantifier (`\w++`) and a strict end-of-string anchor (`\z`) and produces
    an _untainted_ capture, so the column name used for dispatch is clean under
    `-T`.  Criteria values are passed verbatim to component `Database::Abstraction`
    objects; those objects are responsible for handling tainted values at the SQL
    parameterisation layer.

- SQLite backend: column names are quoted, values are parametrised

    When the SQLite path is active, `Database::Join` generates SQL internally.
    All column and table names are double-quoted (SQL identifier quoting) before
    being embedded in statement strings.  All row values are passed to SQLite
    exclusively through DBI prepared statement placeholders -- never by string
    interpolation.  A hostile value in a source row therefore cannot inject SQL
    into the temporary database.

    The temporary SQLite file is created by `File::Temp` using a securely random,
    unpredictable filename.  No `system()` or shell command is used to create or
    remove it.  The connection is made with `DBI->connect(..., { RaiseError => 1,
    PrintError => 0 })` and is closed before the method returns.  Column names
    in the generated SQL come from `columns()`, which is produced by
    `Database::Abstraction` at construction time -- they are not derived from
    caller-supplied criteria values.

- Operator hashref broadcast copy

    When the same join-key criterion (an operator hashref such as
    `{ '>' => 'A' }`) is broadcast to multiple component databases, each
    database receives its own _shallow copy_ of the hashref.  A component database
    that mutates the hashref's contents at the top level cannot affect what
    subsequent databases receive.

- collision\_prefix value type guard

    `_build_col_index` rejects any `collision_prefix` value that is a reference
    (hashref, arrayref, coderef, etc.) with an immediate `croak`.  A reference
    value would stringify to `"HASH(0x...)"`, leaking a heap address into every
    column name, `columns()` listing, and merged row returned to the caller.  The
    guard fires before any column name is constructed.

- Filter deep-copy isolation

    The `filters` constructor parameter and the `filter` option of
    `add_database()` are _deep-copied_ at the point of use.  The caller's
    original hashrefs are never stored; post-construction mutation of those
    hashrefs cannot widen or bypass the configured row-security constraints.

### What the Caller Is Responsible For

- Sanitise values before building criteria

    DJ passes criterion values verbatim to component databases.  If your
    application accepts user-supplied filter values (e.g. from a CGI query
    string), those values _must_ be validated or sanitised by your application
    before being passed to DJ.

- Restrict which columns the caller can filter on

    Any column in `columns()` can be used as a filter criterion.  If a column
    should not be filterable by end users (e.g. an internal status flag), hide it
    with `remove_column` so that queries on it are silently dropped.

- Do not expose the joined view directly to user-supplied criteria

    DJ is not a firewall.  It faithfully routes user input to component databases.
    Wrap DJ calls in a thin service layer that whitelists the permitted criterion
    columns and validates their values.

#### API SPECIFICATION (Security Surface)

```perl
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
```

## Formal Specification

Z calculus schemas for the key invariants and operations.
Unicode is used throughout this section as required by Z notation.

```
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
```

### Collision\_Prefix

```
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
```

### Join\_Map

```
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
```

### Security Invariants

```
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
```

### Filters

```
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
```

### Selectall\_Arrayref

```
selectall_arrayref : CRITERIA → seq MERGED_ROW
pre:  ∀ col : dom criteria • col ∈ dom self._col_db ∪ {self._join_col}
post: result = _joined_query(criteria)
      result is sorted ascending by join_col value
```

### Selectall\_Array

```perl
selectall_array : CRITERIA → seq MERGED_ROW | MERGED_ROW?
pre:  same as selectall_arrayref
post: wantarray  => result = @{ selectall_arrayref(criteria) }
      !wantarray => result = selectall_arrayref(criteria)[0]  (or undef)
```

### Fetchrow\_Hashref

```
fetchrow_hashref : CRITERIA → MERGED_ROW?
post: result = selectall_arrayref(criteria)[0]  (or undef if empty)
```

### Count

```
count : CRITERIA → ℕ
post: result = #selectall_arrayref(criteria)
```

### Columns

```
columns : → seq NAME
post: result = sort(
          (⋃ { i : 0 ‥ #dbs-1 • ran(dbs(i).columns) }
           \ dom removed_cols
           \ { local_jc(i) | i ∈ dom join_map ∧ local_jc(i) ≠ join_col })
      )
```

### Schema

```
schema : → NAME ⇸ SCHEMA_INFO
post: dom(result) = ran(columns())
      ∀ col : dom(result) •
          result(col) = (last database containing col).schema()(col)
```

### Updated

```
updated : → ℕ
post: result = max { i : 0 ‥ #dbs-1 • dbs(i).updated() }
```

### Remove\_Column

```
remove_column : NAME → Database_Join
pre:  col ≠ self._join_col
post: self'._removed_cols = self._removed_cols ∪ {col}
      self'._col_db       = self._col_db \ {col}
      self'._col_cache    = undef
      self'._schema_cache = undef
```

### Autoload

```perl
AUTOLOAD : NAME × CRITERIA → VALUE | seq VALUE
pre:  col ∈ dom self._col_db
      col does not begin with '_'
post: let rows = _joined_query(criteria)
      wantarray  => result = { r : rows • r(col) }
      !wantarray => result = rows(0)(col)  (or undef if rows is empty)
```

### Backend

```
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
```

## State Diagram

`Database::Join` objects follow three independent finite state machines (FSMs).
Each FSM is described with an ASCII diagram showing valid states (boxes), the
triggers that cause transitions (arrows), and important side-effects.

### FSM 1: Object Lifecycle

Governs the structural state of a `Database::Join` instance.
Query methods (`selectall_arrayref`, `fetchrow_hashref`, `count`,
`columns`, `schema`, `updated`) are schema-preserving (Xi-transitions) and
are not shown because they do not change state.

```perl
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
```

### FSM 2: SQLite Cache Lifecycle

Governs the temporary SQLite cache used by the `backend='sqlite'` and
`backend='auto'` join paths.  The cache does not exist until the first
query on the SQLite path.

```
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
```

### FSM 3: Column Visibility (Per Column)

Each column in the logical view independently follows a two-state machine.
Transition from VISIBLE to REMOVED is one-way: `add_database` never
restores a column that is in `_removed_cols`.

```
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
```

## Author

Nigel Horne, `<njh@nigelhorne.com>`

## License and Copyright

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
