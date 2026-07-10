# NAME

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

# VERSION

Version 0.36

# DESCRIPTION

`Database::Abstraction` is a read-only ORM for Perl that gives a uniform
interface over CSV, PSV, XML, SQLite, and BerkeleyDB files — without writing
any SQL.

Key features:

- **No SQL required.**  Use plain Perl method calls for simple lookups and
scans; switch storage formats without changing application code.
- **Rich query criteria.**  Pass plain values, SQL wildcards, `undef` (IS NULL),
comparison operators (`>` `<` `>=` `<=` `!=`), pattern
operators (`-like`, `-not_like`), set operators (`-in`, `-not_in`,
`-between`), and logical groupings (`-or`, `-and`).
- **Automatic joins.**  Add a `join` parameter to any select method to
combine tables with INNER, LEFT, RIGHT, FULL, or CROSS joins.
- **Chained query builder.**  The `query()` method returns a
[Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) object for fluent, composable queries:
`$db->query->where(…)->order_by(…)->limit(…)->all()`.
- **Schema introspection.**  `columns()` lists column names; `schema()`
returns full type/nullability metadata, using native driver introspection
(`PRAGMA table_info` for SQLite, `column_info` for others).
- **DSN portability.**  Pass a `dsn` (plus optional `username`/`password`)
to connect to any DBI-supported database (SQLite, PostgreSQL, MySQL, …)
instead of pointing at a local file.
- **Performance.**  Small files are slurped into a RAM hash for sub-millisecond
lookups.  All DBI statement handles are cached with `prepare_cached()`.
A CHI-compatible cache layer is also supported.

# SYNOPSIS

    # 1. Create a thin subclass for your table (e.g. Database/Foo.pm)
    package Database::Foo;
    use parent 'Database::Abstraction';

    # 2. Open the database — file is auto-detected from the class name
    #    (looks for foo.sql / foo.psv / foo.csv / foo.xml / foo.db)
    my $db = Database::Foo->new(directory => '/path/to/data');

    # 3. Simple lookups -----------------------------------------------

    # Fetch one row
    my $row = $db->fetchrow_hashref(entry => 'key1');

    # Fetch all rows matching a criterion
    my $rows = $db->selectall_arrayref(status => 'active');

    # Column shortcut via AUTOLOAD
    my $name = $db->name(entry => 'key1');

    # 4. Rich criteria ------------------------------------------------

    # Comparison operators
    my $high = $db->selectall_arrayref(score => { '>' => 90 });

    # Set membership
    my $selected = $db->selectall_arrayref(
        name => { -in => ['Alice', 'Bob'] }
    );

    # Range
    my $mid = $db->selectall_arrayref(
        score => { -between => [60, 80] }
    );

    # OR grouping
    my $either = $db->selectall_arrayref(
        -or => [
            { status => 'active'    },
            { score  => { '>' => 95 } },
        ]
    );

    # 5. Joins --------------------------------------------------------

    my $joined = $db->selectall_arrayref(
        join => { table => 'dept', on => 'foo.dept_id = dept.id', type => 'LEFT' }
    );

    # 6. Chained query builder ----------------------------------------

    my $results = $db->query
        ->where(status => 'active')
        ->where(score  => { '>=' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    my $first = $db->query->where(name => 'Alice')->first();
    my $count = $db->query->where(status => 'active')->count();

    # 7. Connect via DSN (PostgreSQL, MySQL, SQLite, …) ---------------

    my $db2 = Database::Foo->new(
        dsn      => 'dbi:Pg:dbname=mydb;host=db.example.com',
        username => 'myuser',
        password => 's3cret',
    );

    # 8. Schema introspection -----------------------------------------

    my $cols   = $db->columns();  # ['entry', 'name', 'score', …]
    my $schema = $db->schema();   # { name => { type=>'TEXT', nullable=>1, … }, … }

# QUICK START EXAMPLE

If `/var/dat/foo.csv` contains:

    "customer_id","name"
    "plugh","John"
    "xyzzy","Jane"

Create a driver in `.../Database/foo.pm`:

    package Database::foo;
    use parent 'Database::Abstraction';

    # Regular CSV: no entry column, comma-separated
    sub new {
        my ($class, %args) = @_;
        return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

Then query it:

    my $foo = Database::foo->new(directory => '/var/dat');

    # Prints "John"
    print 'Customer: ', $foo->name(customer_id => 'plugh'), "\n";

    # Returns { customer_id => 'xyzzy', name => 'Jane' }
    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');

# FILE FORMATS

The module probes the `directory` for files in this priority order:

- 1. `SQLite`

    File ending `.sql`

- 2. `PSV`

    Pipe-separated file, ending `.psv`

- 3. `CSV`

    Comma (or custom) separated file, ending `.csv` or `.db`; can be
    gzipped.  **Note:** the default separator is `!` not `,` for historical
    reasons — pass `sep_char => ','` for standard CSVs.

- 4. `XML`

    File ending `.xml`

- 5. `BerkeleyDB`

    Binary key-value file ending `.db`

Pass `dsn` to bypass file detection entirely and connect via any DBI driver.

# QUERY CRITERIA

All select methods (`selectall_arrayref`, `selectall_array`,
`fetchrow_hashref`, `count`) accept the same criteria syntax.

## Plain value

    status => 'active'          # status = 'active'
    name   => undef             # name IS NULL

Values containing `%` or `_` are matched with `LIKE`:

    name => 'A%'                # name LIKE 'A%'

## Comparison operator hashref

    score => { '>'  => 90  }   # score > 90
    score => { '<'  => 50  }   # score < 50
    score => { '>=' => 80  }   # score >= 80
    score => { '<=' => 100 }   # score <= 100
    score => { '!=' => 0   }   # score != 0

Multiple operators on one column are ANDed:

    score => { '>' => 60, '<' => 90 }   # 60 < score < 90

## Pattern matching

    name => { -like     => 'A%'  }   # name LIKE 'A%'
    name => { -not_like => 'Z%'  }   # name NOT LIKE 'Z%'

## Set membership

    name => { -in     => ['Alice', 'Bob'] }   # name IN (…)
    name => { -not_in => ['Alice', 'Bob'] }   # name NOT IN (…)

## Range

    score => { -between => [60, 90] }   # score BETWEEN 60 AND 90

## Logical groupings

`-or` and `-and` take an arrayref of condition hashrefs:

    -or => [
        { status => 'active'        },
        { score  => { '>' => 95 }   },
    ]

    -and => [
        { status => 'active'        },
        { score  => { '>=' => 80 }  },
    ]

## Joins

Any select method accepts a `join` key with a hashref (or arrayref of
hashrefs) describing the join:

    join => {
        table => 'dept',
        on    => 'employees.dept_id = dept.id',
        type  => 'LEFT',    # INNER (default) | LEFT | RIGHT | FULL | CROSS
    }

    # Multiple joins
    join => [
        { table => 'dept',    on => 'e.dept_id   = dept.id'   },
        { table => 'country', on => 'e.country_id = country.id' },
    ]

# SUBROUTINES/METHODS

## init

Initializes the abstraction class and its subclasses with optional arguments for configuration.

    Database::Abstraction::init(directory => '../data');

See the documentation for new to see what variables can be set.

Returns a reference to a hash of the current values.
Therefore when given with no arguments you can get the current default values:

    my $defaults = Database::Abstraction::init();
    print $defaults->{'directory'}, "\n";

## import

The module can be initialised by the `use` directive.

    use Database::Abstraction 'directory' => '/etc/data';

or

    use Database::Abstraction { 'directory' => '/etc/data' };

## new

Create an object pointing to a read-only database.

Accepts arguments as a hash, a hashref, or — as a shortcut — a single bare
string which is taken to be `directory`.

### Connection parameters

- `directory`

    Directory containing the data files.  The module probes this directory for
    files named after the subclass (see ["FILE FORMATS"](#file-formats)).  Required unless
    `dsn` is given.

- `dsn`

    A DBI data-source string (e.g. `dbi:SQLite:dbname=/path/to/db` or
    `dbi:Pg:dbname=mydb;host=db.example.com`).  When present, file detection
    is skipped entirely and the DSN is used directly.  The SQL dialect is
    inferred from the DSN prefix (`sqlite`, `postgres`, `mysql`).

- `username`

    Database username.  Used only with `dsn`; ignored for file-based backends.

- `password`

    Database password.  Used only with `dsn`; ignored for file-based backends.

- `dbname`

    Override the filename stem searched in `directory` (default: the table
    name derived from the class name).

- `filename`

    Override the full filename (relative to `directory`).  Takes precedence
    over `dbname`.

### Behaviour parameters

- `no_entry`

    Set to `1` when the table has no key column (standard CSVs, for example).
    Default is `0` (keyed on `entry`).

- `id`

    Name of the key column.  Default is `entry`.

- `sep_char`

    Field separator for CSV/PSV files.  Default is `!` — pass `sep_char => ','`
    for standard comma-separated files.

- `max_slurp_size`

    Files smaller than this (in bytes) are loaded entirely into memory for fast
    lookups.  Default is 16 KB.  Set to `0` to force SQL mode for all sizes.

- `no_fixate`

    Set to `1` to return mutable arrays.  Default is `0` (arrays are made
    read-only via [Data::Reuse](https://metacpan.org/pod/Data%3A%3AReuse)).

- `auto_load`

    Set to `0` to disable the AUTOLOAD column shortcut.  Default is `1`
    (enabled).

### Caching and logging

- `cache`

    A [CHI](https://metacpan.org/pod/CHI)-compatible cache object.  When set, query results are stored and
    retrieved from the cache.

- `cache_duration` / `expires_in`

    TTL for cached results.  Default is `'1 hour'`.  `expires_in` is a
    synonym for compatibility with [CHI](https://metacpan.org/pod/CHI).

- `logger`

    An object that understands `warn()` and `trace()` (e.g.
    [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), [Log::Any](https://metacpan.org/pod/Log%3A%3AAny)), a code reference, or a filename.

- `config_file`

    Path to a YAML, XML, or INI configuration file whose keys are merged into
    the constructor arguments.  Loaded via [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

### Notes

- If no arguments are set, class-level defaults set via `init()` or `use`
are used.
- Slurp mode assumes the key column (`entry`) is unique.  If it is not,
searches will be incomplete — disable slurp mode by setting
`max_slurp_size => 0`.
- Passing an existing object as `$class` clones it, merging any new
arguments.

## set\_logger

Sets the class, code reference, or file that will be used for logging.

## selectall\_arrayref

Returns a reference to an array of hash references for every row that
matches the given criteria, or `undef` when there are no matches.

    my $rows = $db->selectall_arrayref();                    # all rows
    my $rows = $db->selectall_arrayref(status => 'active');  # exact match
    my $rows = $db->selectall_arrayref(score => { '>' => 8 });  # operator

The full criteria syntax is described in ["QUERY CRITERIA"](#query-criteria).

Pass a `join` key to combine with another table:

    my $rows = $db->selectall_arrayref(
        dept_name => 'Engineering',
        join      => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Results are returned in the cache (if configured) and the returned array
reference is made read-only unless `no_fixate` was set.

**Note:** because this returns an array reference, no `LIMIT` is applied.
Use ["selectall\_array"](#selectall_array) in scalar context, or ["query"](#query) with `->limit()`,
when you want `LIMIT 1`.

### PSEUDOCODE

    1. Parse criteria; extract and build any JOIN clause.
    2. If data is slurped AND no joins AND criteria are simple:
       a. No criteria → return all rows as arrayref.
       b. entry-only lookup → return [$data{entry}].
       c. Otherwise → scan rows in-memory with _match_criterion.
    3. Otherwise build SQL: SELECT * FROM table [JOIN] [WHERE] ORDER BY id.
    4. Check cache; return cached arrayref on HIT.
    5. prepare_cached + execute; fetch all rows.
    6. Store result in cache; fixate the array; return arrayref.

## selectall\_hashref

Deprecated alias for ["selectall\_arrayref"](#selectall_arrayref).  Use `selectall_arrayref` in
new code.

## selectall\_array

Similar to ["selectall\_arrayref"](#selectall_arrayref) but returns a list of hash references
rather than a reference to an array.

    my @rows = $db->selectall_array(status => 'active');

In **scalar context** it applies `LIMIT 1` and returns just the first
matching hash reference — making it more efficient than `selectall_arrayref`
when you only need one row.  In **list context** all matching rows are returned.

Accepts the same criteria and `join` parameter as ["selectall\_arrayref"](#selectall_arrayref).

## selectall\_hash

Deprecated alias for ["selectall\_array"](#selectall_array).  Use `selectall_array` in new
code.

## count

Returns the number of rows matching the given criteria.

    my $total  = $db->count();
    my $active = $db->count(status => 'active');
    my $high   = $db->count(score  => { '>' => 90 });

Accepts the full criteria syntax described in ["QUERY CRITERIA"](#query-criteria).

## fetchrow\_hashref

Returns a hash reference for the first row matching the given criteria,
or `undef` when there is no match.  Always applies `LIMIT 1`.

    my $row = $db->fetchrow_hashref(entry => 'key1');
    my $row = $db->fetchrow_hashref(score => { '>=' => 10 });

When `no_entry` is **not** set you may pass a single bare value and it is
used as the `entry` key:

    my $row = $db->fetchrow_hashref('key1');    # same as entry => 'key1'

Accepts the full criteria syntax described in ["QUERY CRITERIA"](#query-criteria), including
the `join` parameter:

    my $row = $db->fetchrow_hashref(
        name => 'Alice',
        join => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Pass `table => $other_table` to query a table other than the one
derived from the class name.

## execute

Execute a raw SQL query on the underlying database.

    # Scalar context: returns the first row as a hashref
    my $row = $db->execute(query => 'SELECT * FROM foo WHERE id = 1');

    # List context: returns all rows as a list of hashrefs
    my @rows = $db->execute(query => 'SELECT * FROM foo WHERE score > ?',
                            args  => [80]);

The `FROM <table>` clause is appended automatically if omitted.

On CSV tables without `no_entry` it may help to add
`WHERE entry IS NOT NULL AND entry NOT LIKE '#%'` to filter comment rows.

If the data have been slurped into memory this method still hits the actual
database file directly.

`args` is an arrayref of bind values (see ["execute" in DBI](https://metacpan.org/pod/DBI#execute)).

## updated

Returns the Unix timestamp of the last database update (mtime for
file-based backends, or the time of the most recent `new()` call for
DSN-based connections).

## columns

Returns an array reference of column names for the current table.

    my $cols = $db->columns();    # e.g. ['entry', 'name', 'score', 'status']

The column list is determined by the backend:

- **Slurp mode** — sorted keys of the first row in memory.
- **SQLite / other DBI** — a zero-row `SELECT *` exposes the driver's
`NAME` attribute.
- **BerkeleyDB** — always returns `['entry', 'value']`.

The result is cached inside the object after the first call.

## schema

Returns a hash reference describing the schema of the current table.
Each key is a column name; each value is a hash reference with these keys:

- `type` — data type string (e.g. `TEXT`, `INTEGER`, `REAL`)
- `nullable` — `1` if the column may be NULL, `0` if NOT NULL
- `default` — default value string, or `undef`
- `pk` — `1` if this column is (part of) the primary key, `0` otherwise

    my $schema = $db->schema();

    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%s  %s  %s\n",
            $col,
            $info->{type},
            $info->{nullable} ? 'NULL' : 'NOT NULL';
    }

The schema is determined by the backend:

- **SQLite** — `PRAGMA table_info(table)`
- **Other DBI drivers** — `$dbh->column_info(...)`
- **Slurp mode** — inferred from the first row (all columns typed as `TEXT`)
- **BerkeleyDB** — always returns `entry` (pk) and `value`

The result is cached inside the object after the first call.

## query

Returns a new [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) builder object bound to this
database instance, for fluent method-chaining queries.

    # All active rows with high scores, newest first, max 10
    my $rows = $db->query
        ->where(status => 'active')
        ->where(score  => { '>' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    # Single row
    my $row = $db->query->where(name => 'Alice')->first();

    # Just a count
    my $n = $db->query->where(status => 'active')->count();

See [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) for the full API.

## AUTOLOAD — column shortcut

Calling an unknown method whose name matches a column name performs a column
lookup.  The method name is the column you want; the arguments are criteria.

    # Scalar context: return the first match
    my $name = $db->name(entry => 'key1');

    # List context: return all matching values
    my @names = $db->name();

    # Shortcut when the table has an 'entry' key column
    my $name = $db->name('key1');    # same as name(entry => 'key1')

    # Unique/distinct values
    my @statuses = $db->status(distinct => 1);

**In list context** the full column is returned (all rows), ordered by the
column value.  **In scalar context** only the first match is returned
(`LIMIT 1`).

Results come from the slurp cache when available.

Throws an error if the column does not exist (slurp mode) or if AUTOLOAD
has been disabled with `auto_load => 0`.

### PSEUDOCODE

    1. Extract column name from $AUTOLOAD; guard on DESTROY.
    2. Croak if auto_load => 0.
    3. Validate $column against /^[a-zA-Z_][a-zA-Z0-9_]*$/.
    4. If data is slurped:
       a. List context, no params → map column over all rows (exists guard).
       b. entry-only param → direct hash lookup (exists guard).
       c. No params, scalar → first value in hash.
       d. no_entry set → scan array for matching key/value pair.
       e. Other params → scan keyed hash for matching column.
    5. If not slurped, build SQL:
       - List:   SELECT column FROM table [WHERE ...] ORDER BY column
       - Scalar: SELECT DISTINCT column FROM table [WHERE ...] LIMIT 1
    6. Check cache; return on HIT.
    7. prepare_cached + execute; fetch result.
    8. Store in cache; fixate; return.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-database-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# MESSAGES

The table below lists every error that the module can croak or carp, what
triggers it, and how to resolve it.

- `_Class_: abstract class`

    Direct instantiation of `Database::Abstraction` was attempted.
    Create a subclass and instantiate that instead.

- `_Class_: where are the files?`

    Neither `directory` nor `dsn` was supplied to `new()`.

- `_Class_: _/path_ is not a directory`

    The `directory` argument exists on disk but is not a directory.

- `_Class_: cannot connect: _$DBI::errstr_`

    DBI failed to connect to the given `dsn`.  Check credentials and host.

- `Can't find a file called '_name_' for the table _T_ in _dir_`

    None of the probe extensions (`.sql`, `.psv`, `.csv`, `.db`, `.xml`)
    matched in `directory`.

- `_Class_: prepare failed: _$errstr_`

    `prepare_cached()` returned false.  Usually a syntax error in an internally
    built query; file a bug if you see this from a normal API call.

- `_build_where_conditions: unsafe column name '_name_'`

    A criteria key contained characters outside `[A-Za-z0-9_.]`.
    This is a SQL-injection guard.  Use only valid SQL identifier characters.

- `join: missing "table"` / `join: missing "on" condition`

    A join spec hashref is incomplete.  Both `table` and `on` are required.

- `Invalid JOIN type: _TYPE_`

    `type` in a join spec was not one of `INNER LEFT RIGHT FULL CROSS`.

- `_Class_: Unknown column _col_` / `_Class_: AUTOLOAD disabled`

    An AUTOLOAD call was made for a column that does not exist, or AUTOLOAD
    was disabled with `auto_load => 0`.

- `Usage: set_logger(logger => $logger)`

    `set_logger()` was called without a `logger` argument.

- `Usage: execute(query => $query)`

    `execute()` was called without a `query` argument.

- `XML slurp: _..._ is not yet supported`

    The XML file structure is too complex for slurp mode.
    Use `max_slurp_size => 0` to force the DBI/XMLSimple SQL path.

- `_Class_: _method_ is meaningless on a NoSQL database`

    A relational method (`selectall_arrayref`, `count`, `execute`, etc.)
    was called on a BerkeleyDB backend, which only supports key-value lookup
    via `fetchrow_hashref`.

# KNOWN LIMITATIONS

- **Read-only.**  No INSERT, UPDATE, or DELETE is provided.  `execute()`
runs raw read-only SQL.
- **Default CSV separator is `!`**, not `,`, for historical reasons.
Pass `sep_char => ','` for standard RFC 4180 files.
- **Primary-key column is named `entry`**, not `key`, because `key`
is a SQL reserved word.  Override with the `id` parameter.
- **XML slurp is limited.**  Only simple flat XML structures are supported
in slurp mode.  Multi-key or deeply nested documents will croak.
Force SQL mode with `max_slurp_size => 0` if slurp fails.
- **Unique key assumption in slurp mode.**  Duplicate values in the key
column silently overwrite earlier rows.  Disable slurp with
`max_slurp_size => 0` if duplicates are expected.
- **BerkeleyDB does not support joins or the chained query builder.**
- **Column names must be valid SQL identifiers** (letters, digits,
underscores, and a single dot for `table.column` join notation).
Other characters will cause a croak.
- **count() cache is opportunistic.**  Count results are served from cache
only when a prior `selectall_arrayref()` or `count()` call with the
same criteria has already populated it.

# SEE ALSO

- [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) — chained query builder
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Database-Abstraction/coverage/)

# LICENSE AND COPYRIGHT

Copyright 2015-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
