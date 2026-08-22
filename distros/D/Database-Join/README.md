# NAME

Database::Join - Read-only combined view across two or more Database::Abstraction objects

# VERSION

Version 0.001.0

# SYNOPSIS

**Basic two-database join**

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

**Hiding internal columns**

    my $join = Database::Join->new(
        databases      => [ $customers, $loyalty ],
        join_column    => 'entry',
        remove_columns => [ 'internal_id', 'audit_ts' ],
    );
    # 'internal_id' and 'audit_ts' never appear in results or columns()

**join\_map: when the key column has different names in each database**

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

**filters: permanently restrict a database's visible rows**

    # Only show orders placed more than 60 days ago, without repeating
    # the criterion on every query call.
    my $join = Database::Join->new(
        databases   => [ $customers, $orders ],
        join_column => 'entry',
        filters     => { 1 => { age_days => { '>' => 60 } } },
    );

    my $rows = $join->selectall_arrayref();                 # all old orders
    my $vip  = $join->selectall_arrayref(tier => 'gold');   # old + gold tier

**Inner and outer join types**

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

**Building the view incrementally with add\_database**

    my $join = Database::Join->new(
        databases   => [ $customers ],
        join_column => 'entry',
    );

    $join->add_database($loyalty)
         ->add_database($scores, remove_columns => ['raw_score']);

**AUTOLOAD column shortcut**

    # Returns the 'name' value for entry 'C001' (scalar context)
    my $name = $join->name(entry => 'C001');

    # Returns all 'tier' values (list context)
    my @tiers = $join->tier();

# DESCRIPTION

`Database::Join` merges two or more [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) objects into a
single logical, read-only view.  Each component database is queried
independently through its own `Database::Abstraction` interface.  The results
are combined in Perl memory using a shared key column (`join_column`).

The module exposes the same read-only API as `Database::Abstraction`:
`selectall_arrayref`, `selectall_array`, `fetchrow_hashref`, `count`,
`columns`, `schema`, `updated`, `set_logger`, and the AUTOLOAD column
shortcut.  Callers do not need to know how many underlying databases are
involved.

Think of it as a virtual database table that is assembled on demand from
several real tables, one per component database.

## Join semantics

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

## Column ownership and routing

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
_last_ database in the `databases` array wins: its value overwrites earlier
ones in merged rows.

# LIMITATIONS

- In-memory join only

    All matching rows from every component database are fetched into memory before
    the merge.  This is not suitable for very large result sets.

- No chained builder or raw SQL

    `query()` and `execute()` are not implemented.  Use `selectall_arrayref`
    or `fetchrow_hashref` instead.

- Single-column equi-join only

    Joining on more than one column simultaneously, or on expressions, is not
    supported.  When the join key has different names in different databases,
    use `join_map` to declare each database's local column name.

- Sort order

    Results are sorted by the `join_column` value only.  Caller-specified
    `ORDER BY` is not propagated to the component databases.

- count() fetches all rows

    `count()` executes the full join and counts the resulting rows in Perl.  It
    does not push a `COUNT(*)` query down to the databases.

# COMMON PITFALLS

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

- Duplicate column names: last database wins

    When two component databases each have a column called `notes`, the second
    database's value silently overwrites the first in every merged row.  Use
    `remove_columns` (or `remove_column`) to drop the unwanted duplicate.

# METHODS

## new

### SYNOPSIS

    my $join = Database::Join->new(
        databases      => [ $db1, $db2 ],
        join_column    => 'entry',
        join_type      => 'left',
        join_map       => { 1 => 'local_col' },
        filters        => { 1 => { score => { '>' => 60 } } },
        remove_columns => [ 'email', 'internal_id' ],
        logger         => $log,
        i18n           => $locale,
    );

### DESCRIPTION

Constructs and returns a new `Database::Join` object.

Each element of `databases` must be an already-instantiated subclass of
`Database::Abstraction`.  The constructor calls `columns()` on every
database to build an internal column-routing table and verifies that
`join_column` (or its local alias from `join_map`) is present in each one.

Columns listed in `remove_columns` are hidden immediately: they do not appear
in `columns()`, `schema()`, or any returned row hashref.  This is equivalent
to calling `remove_column` once per name after construction.

### API SPECIFICATION

#### Input

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

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names to hide from the merged view.
                      #
                      # DOMAIN -- EP valid:   arrayref of any strings; non-existent columns
                      #                       are silently ignored (idempotent).
                      # DOMAIN -- EP invalid: join_column itself => croak remove_join_col.
                      # DOMAIN -- BVA:        [] empty arrayref is a safe no-op.

    logger         => { type => 'object',   optional => 1 }
                      # Logger object propagated to all component databases.

    i18n           => { type => 'object',   optional => 1 }
                      # Localisation object with a translate($key, @args) method.

#### Output

    A blessed Database::Join object.

### EXAMPLE

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

### PSEUDOCODE

    validate all parameters with validate_strict
    croak if databases is empty
    croak if any element of databases is not a Database::Abstraction subclass
    bless the object with all fields initialised
    call _build_col_index to map every column to its owning database
        and verify join_column presence in each database
    for each column in remove_columns: call remove_column
    return the new object

### MESSAGES

    error_no_databases     -- databases arrayref was empty
    error_invalid_db       -- an element of databases is not a D::A subclass
    error_join_col_missing -- join_column (or its join_map alias) not found in a database

## join\_map - joining on differently-named columns

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

    cities table  : entry (the city name) | statecode
    stnames table : entry (the state code) | state

Here you want to join cities.statecode to stnames.entry.  You choose
`join_column => 'statecode'` as the canonical name, but stnames calls
that same concept `entry`, so you declare:

    join_map => { 1 => 'entry' }  # stnames (index 1) calls it 'entry'

**Example**

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

**Using add\_database instead**

If you build the join incrementally with `add_database`, pass
`join_column` directly to that call instead of using `join_map`:

    my $join = Database::Join->new(
        databases   => [ $cities ],
        join_column => 'statecode',
    );
    $join->add_database($stnames, join_column => 'entry');

This is exactly equivalent to the `join_map` form above.

## filters - permanent per-database row filters

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

When using `add_database`, pass `filter` (singular) to set the base
criteria for the new database:

    $join->add_database($orders, filter => { age_days => { '>' => 60 } });

## selectall\_arrayref

### SYNOPSIS

    my $rows = $join->selectall_arrayref();
    my $rows = $join->selectall_arrayref(tier  => 'gold');
    my $rows = $join->selectall_arrayref(score => { '>' => 80 });
    my $rows = $join->selectall_arrayref('C001');  # positional: entry => 'C001'

### DESCRIPTION

Returns an arrayref of hashrefs representing the merged view of all component
databases, optionally filtered by the given criteria.

Criteria for columns that live in different databases are routed
automatically: each database is queried with only the criteria that apply to
its own columns.  The results are combined in memory using `join_column`.

Accepts the same criteria syntax as `Database::Abstraction::selectall_arrayref`.
A single plain scalar argument is interpreted as the `join_column` value
(equivalent to `entry => 'C001'` when `join_column` is `'entry'`).

### API SPECIFICATION

#### Input

    Calling conventions (in order of precedence):
      1. No arguments             -- returns all rows
      2. One plain scalar         -- shorthand for join_column => $scalar
      3. Key-value pairs or
         a criteria hashref       -- routed per-database

    Values may be:
      Plain scalar                -- exact match
      Hashref of operators        -- e.g. { '>' => 80 }

#### Output

    Arrayref of hashrefs; one hashref per qualifying merged row,
    sorted ascending by join_column value.
    Returns a reference to an empty array when no rows match.

### EXAMPLE

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

## selectall\_array

### SYNOPSIS

    my @rows = $join->selectall_array(tier => 'gold');

    # Scalar context: only the first matching row
    my $first = $join->selectall_array(entry => 'C001');

### DESCRIPTION

In list context returns a list of merged hashrefs -- the same rows that
`selectall_arrayref` would return, just as a flat list rather than an
arrayref.

In scalar context returns only the first matching hashref (or `undef` if
nothing matches).

### API SPECIFICATION

#### Input

    Same as selectall_arrayref.

#### Output

    List context:   list of hashrefs (may be empty).
    Scalar context: single hashref or undef.

### EXAMPLE

    my @all = $join->selectall_array();
    print scalar @all, " rows\n";

    # First gold-tier customer only
    my $first_vip = $join->selectall_array(tier => 'gold');
    print $first_vip->{name}, "\n" if defined $first_vip;

## fetchrow\_hashref

### SYNOPSIS

    my $row = $join->fetchrow_hashref(entry => 'C001');
    my $row = $join->fetchrow_hashref('C001');   # positional shorthand

### DESCRIPTION

Returns a single merged hashref for the first row matching the given
criteria, or `undef` when nothing matches.

Equivalent to calling `selectall_arrayref` and taking only the first element.
All the same criteria conventions apply.

### API SPECIFICATION

#### Input

    Same as selectall_arrayref.

#### Output

    Hashref, or undef when no row matches.

### EXAMPLE

    my $row = $join->fetchrow_hashref(entry => 'C001');
    if (defined $row) {
        print "Name: $row->{name}, Tier: $row->{tier}\n";
    } else {
        print "No record for C001\n";
    }

    # Positional: works when join_column is 'entry'
    my $row2 = $join->fetchrow_hashref('C001');

## count

### SYNOPSIS

    my $total  = $join->count();
    my $active = $join->count(tier => 'gold');

### DESCRIPTION

Returns the number of merged rows that satisfy the given criteria.

The full join is performed and the resulting rows are counted in Perl; no
`COUNT(*)` is pushed down to the component databases.

### API SPECIFICATION

#### Input

    Same criteria syntax as selectall_arrayref.

#### Output

    Non-negative integer.

### EXAMPLE

    my $total   = $join->count();
    my $gold    = $join->count(tier => 'gold');
    my $high    = $join->count(score => { '>' => 90 });

    printf "%d total, %d gold-tier, %d high-scorers\n",
        $total, $gold, $high;

## columns

### SYNOPSIS

    my $cols = $join->columns();

### DESCRIPTION

Returns an arrayref of all column names visible in the merged view,
deduplicated and sorted alphabetically.

The `join_column` appears exactly once, even if it exists under different
local names in some databases (see `join_map`).  Columns that have been
hidden with `remove_column` or `remove_columns` do not appear.

The result is memoised: repeated calls are cheap.

### API SPECIFICATION

#### Input

    None.

#### Output

    Arrayref of column name strings, sorted alphabetically.

### EXAMPLE

    my $cols = $join->columns();
    print join(', ', @{$cols}), "\n";
    # e.g. "entry, name, score, tier"

## schema

### SYNOPSIS

    my $schema = $join->schema();

### DESCRIPTION

Returns a merged schema hashref for all visible columns across all component
databases.  Each key is a column name; each value is the schema metadata
hashref returned by `Database::Abstraction::schema()` for that column
(typically `{ type, nullable, default, pk }`).

When the same column name appears in more than one database the _last_
database's metadata is used.  Columns hidden with `remove_column` are not
included.

The result is memoised.

### API SPECIFICATION

#### Input

    None.

#### Output

    Hashref: column_name => { type => ..., nullable => ..., default => ..., pk => ... }.

### EXAMPLE

    my $schema = $join->schema();
    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%-15s type=%-10s nullable=%s\n",
            $col, $info->{type}, $info->{nullable} ? 'yes' : 'no';
    }

## updated

### SYNOPSIS

    my $ts = $join->updated();

### DESCRIPTION

Returns the Unix timestamp of the most recent modification across all
component databases.  This is the maximum of all individual `updated()`
return values.

Use this to implement simple cache-invalidation logic: if `updated()`
has advanced since your last snapshot, re-query.

### API SPECIFICATION

#### Input

    None.

#### Output

    Unix timestamp (positive integer).

### EXAMPLE

    my $last_modified = $join->updated();
    if ($last_modified > $my_cache_timestamp) {
        $my_cache = $join->selectall_arrayref();
        $my_cache_timestamp = $last_modified;
    }

## set\_logger

### SYNOPSIS

    $join->set_logger($log);

### DESCRIPTION

Attaches a new logger object to the join and propagates it to every component
database.  The logger is used for diagnostic output by all component databases.

### API SPECIFICATION

#### Input

    $log    Positional: a logger object (required).
            Must support whatever interface Database::Abstraction expects.

#### Output

    Returns C<$self> for method chaining.

### EXAMPLE

    # Log::Any is used here as an example; any object that implements
    # debug() and info() (or whichever methods your component databases
    # call internally) works equally well.
    use Log::Any qw($log);

    my $join = Database::Join->new(databases => [$db1, $db2], join_column => 'entry');
    $join->set_logger($log);
    # $log is now used by $join and by $db1 and $db2

## add\_database

### SYNOPSIS

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

### DESCRIPTION

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

### API SPECIFICATION

#### Input

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

    remove_columns => { type => 'arrayref', optional => 1 }
                      # Column names from this database to hide.

#### Output

    Returns C<$self> to support method chaining.

### EXAMPLE

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

### PSEUDOCODE

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

### MESSAGES

    error_invalid_db       -- argument is not a Database::Abstraction subclass
    error_join_col_missing -- join_column not found in the new database

## remove\_column

### SYNOPSIS

    $join->remove_column('email');

    # Chainable
    $join->remove_column('internal_id')->remove_column('audit_ts');

### DESCRIPTION

Permanently hides a column from the merged view.  After this call:

- The column does not appear in `columns()` or `schema()`.
- Returned row hashrefs do not contain the column key.
- Any query criterion that references the removed column is silently dropped
(with a `carp` warning).

The `join_column` cannot be removed; attempting to do so will `croak`.
Removing a column that does not exist in any database is silently ignored
(the call is idempotent and safe).  The `columns()` and `schema()`
memoisation caches are cleared automatically.

### API SPECIFICATION

#### Input

    $col    Positional string: the column name to remove.

            DOMAIN -- EP valid:   any string; non-existent columns are silently
                                  ignored (idempotent call, returns $self).
            DOMAIN -- EP invalid: join_column value => croak error_remove_join_col.
            DOMAIN -- BVA:        undef and '' are explicit no-ops (returns $self).
                                  These are below the minimum meaningful string
                                  length and are handled without any warning.

#### Output

    Returns C<$self> to support method chaining.

### EXAMPLE

    # Hide private fields immediately after construction
    my $join = Database::Join->new(
        databases   => [ $customers, $loyalty ],
        join_column => 'entry',
    )->remove_column('email')
     ->remove_column('internal_notes');

    # Verify they are gone
    my $cols = $join->columns();
    # 'email' and 'internal_notes' are absent

### MESSAGES

    error_remove_join_col -- attempt to remove the join_column itself

## query

Not supported.  `Database::Join` does not implement the chained query
builder.  Calling this method will always `croak` with an explanatory message.

Use `selectall_arrayref`, `selectall_array`, `fetchrow_hashref`, or
`count` instead.

## execute

Not supported.  Raw SQL cannot span heterogeneous backends that may use
different database engines.  Calling this method will always `croak`.

Use `selectall_arrayref` or `fetchrow_hashref` to query the joined view.

## AUTOLOAD - column shortcut

Calling an unknown method whose name matches a visible column name performs
a column lookup across the merged view.

### SYNOPSIS

    # Scalar context: value from the first matching row
    my $name  = $join->name(entry => 'C001');

    # List context: values from every matching row
    my @tiers = $join->tier();

    # With a positional join-key argument (when join_column is 'entry')
    my $score = $join->score('C001');

### DESCRIPTION

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

### EXAMPLE

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

### PSEUDOCODE

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

# MESSAGES

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

# REPOSITORY

[https://github.com/nigelhorne/Database-Join](https://github.com/nigelhorne/Database-Join)

# SUPPORT

This module is provided as-is without any warranty.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Database-Join/coverage/)
- [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

# SECURITY CONSIDERATIONS

`Database::Join` is a pure in-memory routing and merge layer.  It never
generates SQL strings, never opens files, and never calls `system()`,
`exec()`, or `eval()`.  The security properties described below are
architectural guarantees, not run-time checks.

## What Database::Join guarantees

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

- Taint-mode compatible

    `Database::Join` contains no `system()`, `exec()`, backtick, `open(PIPE)`,
    or `eval STRING` calls.  It neither opens files nor constructs shell commands.
    The AUTOLOAD regex `/::(\w+)$/`  produces an _untainted_ capture, so the
    column name used for dispatch is clean under `-T`.  Criteria values are
    passed verbatim to component `Database::Abstraction` objects; those objects
    are responsible for handling tainted values at the SQL parameterisation layer.

- Operator hashref aliasing

    When the same join-key criterion (an operator hashref such as
    `{ '>' => 'A' }`) is broadcast to multiple component databases, all of
    them receive a reference to the _same_ hashref.  A malicious component
    database that mutates the hashref's contents could affect what subsequent
    databases receive.  Component databases are assumed to be trusted.

## What the caller is responsible for

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

### API SPECIFICATION (security surface)

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

# FORMAL SPECIFICATION

Z calculus schemas for the key invariants and operations.
Unicode is used throughout this section as required by Z notation.

    ─── Database_Join ─────────────────────────────────────────────────
    dbs        : seq DATABASE_ABSTRACTION
    join_col   : NAME
    join_type  : {left, inner, outer}
    join_map   : ℕ ⇸ NAME
    filters    : ℕ ⇸ CRITERIA
    col_db     : NAME ⇸ ℕ
    removed    : ℙ NAME
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
    dbs?       : seq DATABASE_ABSTRACTION
    join_col?  : NAME
    join_type? : {left, inner, outer}
    join_map?  : ℕ ⇸ NAME
    filters?   : ℕ ⇸ CRITERIA
    removed?   : ℙ NAME
    ───────────────────────────────────────────────────────────────────
    #dbs? ≥ 1
    dbs'      = dbs?
    join_col' = join_col?
    join_type'= join_type?
    join_map' = join_map?
    filters'  = filters?
    col_db'   = buildColIndex(dbs?, join_col?, join_map?)
    removed'  = removed?

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

## join\_map

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

## SECURITY INVARIANTS

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

## filters

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

## selectall\_arrayref

    selectall_arrayref : CRITERIA → seq MERGED_ROW
    pre:  ∀ col : dom criteria • col ∈ dom self._col_db ∪ {self._join_col}
    post: result = _joined_query(criteria)
          result is sorted ascending by join_col value

## selectall\_array

    selectall_array : CRITERIA → seq MERGED_ROW | MERGED_ROW?
    pre:  same as selectall_arrayref
    post: wantarray  => result = @{ selectall_arrayref(criteria) }
          !wantarray => result = selectall_arrayref(criteria)[0]  (or undef)

## fetchrow\_hashref

    fetchrow_hashref : CRITERIA → MERGED_ROW?
    post: result = selectall_arrayref(criteria)[0]  (or undef if empty)

## count

    count : CRITERIA → ℕ
    post: result = #selectall_arrayref(criteria)

## columns

    columns : → seq NAME
    post: result = sort(
              (⋃ { i : 0 ‥ #dbs-1 • ran(dbs(i).columns) }
               \ dom removed_cols
               \ { local_jc(i) | i ∈ dom join_map ∧ local_jc(i) ≠ join_col })
          )

## schema

    schema : → NAME ⇸ SCHEMA_INFO
    post: dom(result) = ran(columns())
          ∀ col : dom(result) •
              result(col) = (last database containing col).schema()(col)

## updated

    updated : → ℕ
    post: result = max { i : 0 ‥ #dbs-1 • dbs(i).updated() }

## remove\_column

    remove_column : NAME → Database_Join
    pre:  col ≠ self._join_col
    post: self'._removed_cols = self._removed_cols ∪ {col}
          self'._col_db       = self._col_db \ {col}
          self'._col_cache    = undef
          self'._schema_cache = undef

## AUTOLOAD

    AUTOLOAD : NAME × CRITERIA → VALUE | seq VALUE
    pre:  col ∈ dom self._col_db
          col does not begin with '_'
    post: let rows = _joined_query(criteria)
          wantarray  => result = { r : rows • r(col) }
          !wantarray => result = rows(0)(col)  (or undef if rows is empty)

# AUTHOR

Nigel Horne, `<njh@nigelhorne.com>`

# LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
