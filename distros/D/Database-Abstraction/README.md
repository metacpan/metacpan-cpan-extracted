## Name

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

## Version

Version 0.52

## Description

`Database::Abstraction` is a read-only ORM for Perl that gives a uniform
interface over CSV, PSV, TSV, JSON, XML, SQLite, DBM::Deep, BerkeleyDB, and
Excel (XLS/XLSX) files - local, remote (via SSH), or fetched from a URL -
without writing any SQL.
Effectively it allows you to access a database table, of many different
database formats, as an object.

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
`$db->query->where(...)->order_by(...)->limit(...)->all()`.
- **Aggregation.**  The `aggregate()` method and the fluent
`->group_by()->measure()->having()->all()` chain push `GROUP BY` to
SQL backends and fold rows in Perl on slurp-only backends.
- **Schema introspection.**  `columns()` lists column names; `schema()`
returns full type/nullability metadata, using native driver introspection
(`PRAGMA table_info` for SQLite, `column_info` for others).
- **DSN portability.**  Pass a `dsn` (plus optional `username`/`password`)
to connect to any DBI-supported database (SQLite, PostgreSQL, MySQL, ...)
instead of pointing at a local file.
- **Performance.**  Small files are slurped into a RAM hash for sub-millisecond
lookups.  All DBI statement handles are cached with `prepare_cached()`.
A CHI-compatible cache layer is also supported.

## Synopsis

```perl
# 1. Create a thin subclass for your table (e.g. Database/Foo.pm)
package Database::Foo;
use parent 'Database::Abstraction';

# 2. Open the database - file is auto-detected from the class name
#    (looks for foo.sql / foo.sqlite / foo.sqlite3 / foo.psv / foo.tsv / foo.csv / foo.xlsx / foo.xml / foo.json / foo.db)
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

# 7. Connect via DSN (PostgreSQL, MySQL, SQLite, ...) ---------------

my $db2 = Database::Foo->new(
    dsn      => 'dbi:Pg:dbname=mydb;host=db.example.com',
    username => 'myuser',
    password => 's3cret',
);

# 8. Schema introspection -----------------------------------------

my $cols   = $db->columns();  # ['entry', 'name', 'score', ...]
my $schema = $db->schema();   # { name => { type=>'TEXT', nullable=>1, ... }, ... }

# 9. Aggregation (GROUP BY) ----------------------------------------

# Total revenue and order count per region
my $summary = $db->aggregate(
    by       => ['region'],
    measures => [
        { col => 'amount', fn => 'sum',   as => 'revenue' },
        {                  fn => 'count', as => 'orders'  },
    ],
);

# Grand total across all rows
my $totals = $db->aggregate(
    measures => [{ col => 'amount', fn => 'sum', as => 'total' }],
)->[0];

# Fluent style with HAVING and sort
my $top = $db->query
    ->group_by('region')
    ->measure('amount', 'sum',   'revenue')
    ->measure(undef,    'count', 'orders')
    ->having(revenue => { '>' => 1000 })
    ->order_by('revenue DESC')
    ->limit(5)
    ->all();
```

## Quick Start Example

If `/var/dat/foo.csv` contains:

```
"customer_id","name"
"plugh","John"
"xyzzy","Jane"
```

Create a driver in `.../Database/foo.pm`:

```perl
package Database::foo;
use parent 'Database::Abstraction';

# Regular CSV: no entry column, comma-separated
sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
}
```

Then query it:

```perl
my $foo = Database::foo->new(directory => '/var/dat');

# Prints "John"
print 'Customer: ', $foo->name(customer_id => 'plugh'), "\n";

# Returns { customer_id => 'xyzzy', name => 'Jane' }
my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');
```

## File Formats

The module probes the `directory` for files in this priority order:

- 1. `SQLite`

    File ending `.sql`, `.sqlite`, or `.sqlite3`.
    Requires [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite).

- 2. `Deep`

    DBM::Deep file ending `.dbm` or `.deep`.  The entire file is slurped
    into a plain Perl hash on open; all in-memory fast-paths apply.
    Requires [DBM::Deep](https://metacpan.org/pod/DBM%3A%3ADeep) (loaded lazily).

- 3. `PSV`

    Pipe-separated file, ending `.psv`.

- 4. `TSV`

    Tab-separated file, ending `.tsv`.

- 5. `CSV`

    Comma (or custom) separated file, ending `.csv` or `.db`; can be
    gzipped (`.csv.gz` or `.db.gz`).
    **Note:** the default separator is `!` not `,` for historical
    reasons - pass `sep_char => ','` for standard CSVs.
    Requires [Text::xSV::Slurp](https://metacpan.org/pod/Text%3A%3AxSV%3A%3ASlurp) for the slurp fast-path (loaded lazily).

- 6. `Excel` (`.xls`) and `XLSX` (`.xlsx`)

    Two separate Excel backends - one per file format:

    - **.xls** - old binary format, opened via [DBD::Excel](https://metacpan.org/pod/DBD%3A%3AExcel) (which uses
    [Spreadsheet::ParseExcel](https://metacpan.org/pod/Spreadsheet%3A%3AParseExcel) internally).  All queries go through DBI/SQL;
    no in-memory slurp path.  `max_slurp_size` has no effect.
    - **.xlsx** - modern OOXML format, parsed directly via
    [Spreadsheet::ParseXLSX](https://metacpan.org/pod/Spreadsheet%3A%3AParseXLSX) and slurped into an in-memory hash (keyed mode)
    or array (`no_entry` mode).  No DBI handle is created; all queries use
    the in-memory fast-path.  Complex criteria (operator hashes, `-or`/`-and`)
    will fall through to the SQL path and croak - use simple scalar criteria.

    For both formats, each worksheet is a separate logical table; the active
    worksheet is determined by the class-derived table name (or the `table`
    constructor parameter).  Both modules are loaded lazily.

- 7. `XML`

    File ending `.xml`.
    Requires [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple) for the slurp fast-path (loaded lazily).

- 8. `JSON`

    File ending `.json`, slurped into memory via [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS) (loaded
    lazily).

    The file may contain either a JSON array of row objects:

    ```
    [
      { "entry": "key1", "col": "val1" },
      { "entry": "key2", "col": "val2" }
    ]
    ```

    or a JSON object whose keys are the primary-key values:

    ```
    {
      "key1": { "col": "val1" },
      "key2": { "col": "val2" }
    }
    ```

    In the object form, each key is injected into its row hash under the `id`
    column name (default `entry`), so all normal lookups work identically to
    the array form.

    A zero-byte or whitespace-only file is treated as empty - all query methods
    return 0 / `undef` / `[]` without throwing.
    Requires [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS) (loaded lazily).

- 9. `BerkeleyDB`

    Binary key-value file ending `.db`.

- 10. `HTML`

    HTML page fetched via a `url`.  Pass `url =` 'https://...'> instead of
    `directory`; the module fetches the page with [LWP::UserAgent::Cached](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3ACached), parses all
    `<table>` elements with [HTML::TableExtract](https://metacpan.org/pod/HTML%3A%3ATableExtract), and slurps the first (or
    `html_table_index`-selected) table into memory.  The first row of the table
    is treated as column headers.  Both modules are loaded lazily and are not
    required for other backends.

Pass `dsn` to bypass file detection entirely and connect via any DBI driver.
Pass `url` to fetch and slurp data from a remote source without a local
directory.  When the URL returns `Content-Type: application/json` or the URL
path ends in `.json`, the response is parsed as JSON (see item 8 above).
Otherwise the response is parsed as an HTML page (item 10).

Example - fetching CPAN Testers results:

```perl
package Database::cpantesters;
use parent 'Database::Abstraction';

my $db = Database::cpantesters->new(
    url      => 'https://www.cpantesters.org/show/Database-Abstraction.json',
    no_entry => 1,
);
my $passes = $db->selectall_arrayref(grade => 'PASS');
```

## Query Criteria

All select methods (`selectall_arrayref`, `selectall_array`,
`fetchrow_hashref`, `count`) accept the same criteria syntax.

### Plain Value

```perl
status => 'active'          # status = 'active'
name   => undef             # name IS NULL
```

Values containing `%` or `_` are matched with `LIKE`:

```perl
name => 'A%'                # name LIKE 'A%'
```

### Comparison Operator Hashref

```perl
score => { '>'  => 90  }   # score > 90
score => { '<'  => 50  }   # score < 50
score => { '>=' => 80  }   # score >= 80
score => { '<=' => 100 }   # score <= 100
score => { '!=' => 0   }   # score != 0
```

Multiple operators on one column are ANDed:

```perl
score => { '>' => 60, '<' => 90 }   # 60 < score < 90
```

### Pattern Matching

```perl
name => { -like     => 'A%'  }   # name LIKE 'A%'
name => { -not_like => 'Z%'  }   # name NOT LIKE 'Z%'
```

### Set Membership

```perl
name => { -in     => ['Alice', 'Bob'] }   # name IN (...)
name => { -not_in => ['Alice', 'Bob'] }   # name NOT IN (...)
```

### Range

```perl
score => { -between => [60, 90] }   # score BETWEEN 60 AND 90
```

### Logical Groupings

`-or` and `-and` take an arrayref of condition hashrefs:

```perl
-or => [
    { status => 'active'        },
    { score  => { '>' => 95 }   },
]

-and => [
    { status => 'active'        },
    { score  => { '>=' => 80 }  },
]
```

### Joins

Any select method accepts a `join` key with a hashref (or arrayref of
hashrefs) describing the join:

```perl
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
```

## Subroutines/Methods

### Init

Set class-level defaults shared by all instances.

```perl
Database::Abstraction::init(directory => '../data');
```

Accepts the same parameters as ["new"](#new).  Returns a reference to the
current defaults hash, so you can read them back:

```perl
my $defaults = Database::Abstraction::init();
print $defaults->{'directory'}, "\n";
```

### Import

The module can be initialised by the `use` directive.

```perl
use Database::Abstraction 'directory' => '/etc/data';
```

or

```perl
use Database::Abstraction { 'directory' => '/etc/data' };
```

### New

Create an object pointing to a read-only database.

Accepts arguments as a hash, a hashref, or - as a shortcut - a single bare
string which is taken to be `directory`.

#### Connection Parameters

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

- `table`

    Override the table (or worksheet) name used in SQL queries for this object.
    Default is the class-name-derived table name (e.g. `Database::Foo` =>
    `foo`).  Particularly useful for Excel workbooks where a single `.xlsx`
    file contains multiple worksheets: pass `table => 'Summary'` to query
    the `Summary` worksheet without creating a dedicated subclass.  Also works
    with SQLite/DSN connections to select a table other than the class-derived
    default.  The filename stem (`dbname`) continues to fall back to the class
    name, so the correct file is opened regardless of this override.  The value
    is validated against `$SAFE_QUALIFIED` at construction time.

- `filename`

    Override the full filename (relative to `directory`).  Takes precedence
    over `dbname`.

- `host`

    Remote hostname (or `user@host`) from which to fetch the data file(s) via
    SSH/SCP.  When present, each candidate filename is fetched with
    [File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote) into a local temporary directory; the existing
    extension-based file-type detection then runs against that directory.
    `directory` is treated as the remote path (no local canonicalization is
    applied).  Using `filename` together with `host` avoids probing multiple
    extensions and is therefore more efficient.  [File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote) must be
    installed; it is loaded lazily (only when `host` is given).

- `url`

    A URL (`http://` or `https://`) pointing to an HTML page that contains one
    or more `<table>` elements.  When present, `directory` is not required.
    The first row of the selected table is used as column headers.
    Requires [LWP::UserAgent::Cached](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3ACached) and [HTML::TableExtract](https://metacpan.org/pod/HTML%3A%3ATableExtract) (both loaded lazily).

- `database`

    A Redis connection URL in the form `redis://[password@]host[:port][/db_index]`.
    When present, `directory`, `dsn`, and `url` are not required.  Rows are
    expected to be stored as Redis Hashes at keys of the form
    `tablename:entry_value`; fields of each Hash become column values.  The
    module slurps all matching keys via `KEYS tablename:*` + `HGETALL` into the
    same in-memory structure used by the CSV and DBM::Deep backends, so all
    existing fast-paths (`selectall_arrayref`, `selectall_array`,
    `fetchrow_hashref`, `count`, `columns`, `schema`, AUTOLOAD) work without
    modification.  `no_entry` mode is supported.

    [Redis::Fast](https://metacpan.org/pod/Redis%3A%3AFast) is tried first (XS, faster); if unavailable, [Redis](https://metacpan.org/pod/Redis)
    (pure-Perl) is used as a fallback.  Both are loaded lazily - neither is
    required when using file-based or DSN-based backends.  The URL scheme is
    validated at construction time (`redis://` only; all other schemes croak).

    Use ["select"](#select) to switch the active Redis database on an already-open
    connection.

#### Behaviour Parameters

- `no_entry`

    Set to `1` when the table has no key column (standard CSVs, for example).
    Default is `0` (keyed on `entry`).

- `id`

    Name of the key column.  Default is `entry`.

- `sep_char`

    Field separator for CSV/PSV files.
    Default is `!` - pass `sep_char => ','`
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

- `html_table_index`

    Zero-based index of the HTML `<table>` to extract when the `url`
    backend is used.  Default is `0` (the first table on the page).

- `infer_types`

    Set to `1` to enable heuristic type inference in `schema()` for
    slurp-backed sources (CSV, JSON, XLSX, XML, HTML URL, DBM::Deep).
    Default is `0` (off; all columns reported as `TEXT` for backward
    compatibility).

    When enabled, `schema()` scans the first 100 rows and promotes column
    types: all-integer values => `INTEGER`; all-floating-point values =>
    `REAL`; all ISO-8601 timestamps => `TIMESTAMP`; all ISO-8601 dates =>
    `DATE`; otherwise `TEXT`.  `NULL` (`undef` or empty string) values
    are skipped during the scan.

- `base_criteria`

    A hashref of column-value pairs that is ANDed into **every** SELECT
    automatically.  Callers do not need to repeat these criteria on each
    call.  Common use cases:

    - Row-level security: `base_criteria => { tenant_id => $tid }`
    - Soft-delete filtering: `base_criteria => { deleted_at => undef }`
    - Status gates: `base_criteria => { active => 1 }`

    The hashref is shallow-copied at construction time so later mutations to
    the original do not affect the object.  Column names are validated
    against the same identifier rules as the `id` parameter.  `-or` and
    `-and` groupings are allowed as keys.

    **SQL path**: the criteria are merged into the `WHERE` clause before
    the caller-supplied criteria (caller values win on key collision).

    **Slurp/in-memory path**: the criteria are applied as an additional
    filter.  The `fetchrow_hashref` entry-key fast path checks
    `base_criteria` against the returned row before returning it.

    **Query builder**: `base_criteria` are merged into the `WHERE` clause
    generated by `_build_sql`, so `$db->query->where(...)->all()`
    also respects them.

#### Caching and Logging

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

#### Notes

- If no arguments are set, class-level defaults set via `init()` or `use`
are used.
- Slurp mode assumes the key column (`entry`) is unique.  If it is not,
searches will be incomplete - disable slurp mode by setting
`max_slurp_size => 0`.
- Passing an existing object as `$class` clones it, merging any new
arguments.

### Set\_Logger

Sets the class, code reference, or file that will be used for logging.

### Select

Select a Redis database by number (0-15).  Clears the in-memory data cache so
the next query re-slurps from the newly selected database.  Returns `$self`
for chaining.  Croaks if the object is not backed by a Redis connection.

```perl
$db->select(3);          # switch to Redis DB 3
my $count = $db->count;  # queries the new DB
```

### Selectall\_Arrayref

Returns a reference to an array of hash references for every row that
matches the given criteria, or `undef` when there are no matches.

```perl
my $rows = $db->selectall_arrayref();                    # all rows
my $rows = $db->selectall_arrayref(status => 'active');  # exact match
my $rows = $db->selectall_arrayref(score => { '>' => 8 });  # operator
```

The full criteria syntax is described in ["QUERY CRITERIA"](#query-criteria).

Pass a `join` key to combine with another table:

```perl
my $rows = $db->selectall_arrayref(
    dept_name => 'Engineering',
    join      => { table => 'dept', on => 'e.dept_id = dept.id' },
);
```

Pass `limit => N` and/or `offset => M` for pagination:

```perl
my $page = $db->selectall_arrayref(status => 'active', limit => 10, offset => 20);
```

Both values must be non-negative integers; invalid values are ignored with a
`carp` warning.  When `offset` is given without `limit` the SQL backend
uses `LIMIT -1` on SQLite (meaning "no upper bound") so the `OFFSET` clause
is legal.

Pass `sort_by => 'col'` (ascending) or `sort_by => ['col', 'DESC']`
to request a specific sort column and direction instead of the default primary-key
ordering:

```perl
my $rows = $db->selectall_arrayref(sort_by => 'name');
my $rows = $db->selectall_arrayref(sort_by => ['score', 'DESC']);
```

The column name is validated against the same identifier rules as all other
column parameters.  An unsafe name or an unrecognised direction (anything other
than `ASC` or `DESC`, case-insensitive) is ignored with a `carp` warning and
the default sort order is used instead.  Sorting is applied before
`limit`/`offset` pagination.

Pass `distinct => 1` to return only unique rows (deduplication):

```perl
my $rows = $db->selectall_arrayref(distinct => 1);
my $rows = $db->selectall_arrayref(distinct => 1, columns => [qw(status dept)]);
```

Pass `columns => \@cols` to restrict which columns appear in the returned
rows.  Column names are validated against the same identifier rules as other
parameters; invalid names are dropped with a `carp` warning.

On SQL-capable backends (SQLite, PostgreSQL, MySQL, DBD::CSV ≥ 0.64)
`distinct => 1` emits `SELECT DISTINCT`.  On the slurp (in-memory) path
`distinct` without `columns` is a no-op because each row is already unique.

**Order of operations:** sort → offset → limit → `_apply_distinct`.
This means `limit => N, distinct => 1` deduplicates the already-limited
slice, not the full result set.  If you need N distinct rows from a larger set,
omit `limit` and slice the returned arrayref yourself.

Results are returned in the cache (if configured) and the returned array
reference is made read-only unless `no_fixate` was set.

**Note:** this always returns all matching rows.  Use ["selectall\_array"](#selectall_array)
in scalar context, or `$db->query->limit(1)->all()`, to fetch just one row.

#### Pseudocode

```perl
1. Parse criteria; extract and build any JOIN clause.
   Extract distinct, columns, limit, offset, sort_by.
2. If data is slurped AND no joins AND criteria are simple:
   a. No criteria -> return all rows as arrayref.
   b. entry-only lookup -> return [$data{entry}].
   c. Otherwise -> scan rows in-memory with _match_criterion.
   In all slurp cases: sort by sort_by column (if given), then apply
   offset/limit, then _apply_distinct (columns projection + dedup).
3. Otherwise build SQL: SELECT [DISTINCT] [columns|*] FROM table
   [JOIN] [WHERE] ORDER BY sort_by [else id] [LIMIT] [OFFSET].
   All DBI backends (including DBD::CSV >= 0.64) use native SELECT DISTINCT.
4. Check cache; return cached arrayref on HIT.
5. prepare_cached + execute; fetch all rows.
6. Store result in cache; fixate the array; return arrayref.
```

#### Api Specification

##### Arguments

```perl
%criteria   # optional key-value pairs or operator hashrefs
join        => HashRef | ArrayRef  # optional join spec(s)
sort_by     => Str | ArrayRef      # optional: 'col' or ['col','DESC']
limit       => Int                 # optional: max rows
offset      => Int                 # optional: rows to skip
distinct    => Bool                # optional: deduplicate rows
columns     => ArrayRef[Str]       # optional: restrict output columns
no_fixate   => Bool                # optional: skip read-only locking
table       => Str                 # optional: override table name
```

##### Returns

```
ArrayRef[HashRef] | undef
```

An arrayref of row hashrefs on success.  Returns `undef` when no
rows match.  Each hashref is read-only unless `no_fixate` was set.

### Selectall\_Hashref

Deprecated alias for ["selectall\_arrayref"](#selectall_arrayref).  Use `selectall_arrayref` in
new code.

### Each\_Row

```perl
$db->each_row(\&callback);
$db->each_row(\&callback, status => 'active');
$db->each_row(\&callback, sort_by => 'name', limit => 100, offset => 20);
```

Iterates over matching rows one at a time, calling `\&callback` once per
row with the row hashref as the sole argument.  Uses **constant memory** on
the SQL path: rows are fetched from the database one at a time via
`fetchrow_hashref` without materialising the full result array.  On the
slurp/in-memory path data is already in RAM, so memory use is equivalent to
["selectall\_arrayref"](#selectall_arrayref).

Accepts the same criteria, `join`, `sort_by`, `limit`, and `offset`
parameters as ["selectall\_arrayref"](#selectall_arrayref).

Returns the number of rows passed to `\&callback`.

Exceptions raised inside `\&callback` abort iteration and propagate to
the caller; the DBI statement handle is left in a valid state (`finish()`
is called on exception).

**Note:** rows on the SQL path are not fixated (made read-only) because they
are discarded after each callback invocation.  Slurp-path rows are already
fixated from the initial load.

#### Api Specification

##### Arguments

```perl
CodeRef     # required: callback receiving one row hashref per call
%criteria   # optional: same criteria syntax as selectall_arrayref
join        => HashRef | ArrayRef  # optional join spec(s)
sort_by     => Str | ArrayRef      # optional sort column
limit       => Int                 # optional: max rows to visit
offset      => Int                 # optional: rows to skip
```

##### Returns

```
Int (>= 0)
```

The number of rows visited (i.e. the number of times the callback
was called).  Any exception thrown inside the callback is re-thrown
after the DBI statement handle is properly finished.

### Selectall\_Array

Similar to ["selectall\_arrayref"](#selectall_arrayref) but returns a list of hash references
rather than a reference to an array.

```perl
my @rows = $db->selectall_array(status => 'active');
```

In **scalar context** it applies `LIMIT 1` and returns just the first
matching hash reference - making it more efficient than `selectall_arrayref`
when you only need one row.  In **list context** all matching rows are returned.

Accepts the same criteria, `join`, `limit`, `offset`, and `sort_by`
parameters as ["selectall\_arrayref"](#selectall_arrayref).  When `limit` is given in scalar context
it overrides the implicit `LIMIT 1`.

### Selectall\_Hash

Deprecated alias for ["selectall\_array"](#selectall_array).  Use `selectall_array` in new
code.

### Count

Returns the number of rows matching the given criteria.

```perl
my $total  = $db->count();
my $active = $db->count(status => 'active');
my $high   = $db->count(score  => { '>' => 90 });
```

Accepts the full criteria syntax described in ["QUERY CRITERIA"](#query-criteria).

#### Api Specification

##### Arguments

```perl
%criteria   # optional: same criteria syntax as selectall_arrayref
join        => HashRef | ArrayRef  # optional join spec(s)
table       => Str                 # optional: override table name
```

##### Returns

```
Int (>= 0)
```

The number of rows that match the given criteria.  Returns `0`
when no rows match -- never `undef`.

### Fetchrow\_Hashref

Returns a hash reference for the first row matching the given criteria,
or `undef` when there is no match.  Always applies `LIMIT 1`.

```perl
my $row = $db->fetchrow_hashref(entry => 'key1');
my $row = $db->fetchrow_hashref(score => { '>=' => 10 });
```

When `no_entry` is **not** set you may pass a single bare value and it is
used as the `entry` key:

```perl
my $row = $db->fetchrow_hashref('key1');    # same as entry => 'key1'
```

Accepts the full criteria syntax described in ["QUERY CRITERIA"](#query-criteria), including
the `join` parameter:

```perl
my $row = $db->fetchrow_hashref(
    name => 'Alice',
    join => { table => 'dept', on => 'e.dept_id = dept.id' },
);
```

Pass `table => $other_table` to query a table other than the one
derived from the class name.

#### Api Specification

##### Arguments

```perl
entry       => Str    # primary-key value to look up (positional first
                      # arg when no_entry is false)
%criteria   # optional additional column filters
join        => HashRef | ArrayRef  # optional join spec(s)
no_fixate   => Bool                # optional: skip read-only locking
table       => Str                 # optional: override table name
```

##### Returns

```
HashRef | undef
```

A single row hashref when exactly one matching row is found.  Returns
`undef` when the key is not found or no row matches the criteria.
The hashref is read-only unless `no_fixate` was set.

**Note:** `fetchrow_hashref` does **not** croak when multiple rows
match the given criteria; it returns whichever row the backend
delivers first (usually the first row in file/insertion order).

### Execute

Execute a raw SQL query on the underlying database.

```perl
# Scalar context: returns the first row as a hashref
my $row = $db->execute(query => 'SELECT * FROM foo WHERE id = 1');

# List context: returns all rows as a list of hashrefs
my @rows = $db->execute(query => 'SELECT * FROM foo WHERE score > ?',
                        args  => [80]);
```

The `FROM <table>` clause is appended automatically if omitted.

On CSV tables without `no_entry` it may help to add
`WHERE entry IS NOT NULL AND entry NOT LIKE '#%'` to filter comment rows.

If the data have been slurped into memory this method still hits the actual
database file directly.

`args` is an arrayref of bind values (see ["execute" in DBI](https://metacpan.org/pod/DBI#execute)).

### Updated

Returns the Unix timestamp of the last database update.

For file-based backends (CSV, XML, SQLite via `directory`), this is the
mtime of the backing file, set at `new()` time.

For SQLite DSN connections (`dbi:SQLite:dbname=...`), the file path is
extracted from the DSN and `stat()`-ed live on every call, so callers
get a current mtime suitable for cache-invalidation even when the database
was opened via a DSN rather than a `directory`.

For all other DSN-based connections (PostgreSQL, MySQL, etc.) and for
URL-based backends, returns the Unix timestamp of the most recent
`new()` call (connection time).

### Columns

Returns an array reference of column names for the current table.

```perl
my $cols = $db->columns();    # e.g. ['entry', 'name', 'score', 'status']
```

Column names are always returned in alphabetical (lexicographic) order,
regardless of backend. This makes the result stable and portable when the
same logical table is backed by different engines (CSV => SQLite, etc.).

The source of column names varies by backend:

- **Slurp mode** - keys of the first row in memory.
- **SQLite / other DBI** - a zero-row `SELECT *` exposes the driver's
`NAME` attribute.
- **BerkeleyDB** - always returns `['entry', 'value']`.

The result is cached inside the object after the first call.

#### Api Specification

##### Arguments

None beyond the implicit invocant.  The result is cached in the
object after the first call.

##### Returns

```
ArrayRef[Str]
```

A sorted (lexicographic, ascending) arrayref of column names.  The
sort order is identical across all backends, so switching from CSV
to SQLite does not change the returned order.

### Schema

Returns a hash reference describing the schema of the current table.
Each key is a column name; each value is a hash reference with these keys:

- `type` - data type string (e.g. `TEXT`, `INTEGER`, `REAL`)
- `nullable` - `1` if the column may be NULL, `0` if NOT NULL
- `default` - default value string, or `undef`
- `pk` - `1` if this column is (part of) the primary key, `0` otherwise

```perl
my $schema = $db->schema();

for my $col (sort keys %{$schema}) {
    my $info = $schema->{$col};
    printf "%s  %s  %s\n",
        $col,
        $info->{type},
        $info->{nullable} ? 'NULL' : 'NOT NULL';
}
```

The schema is determined by the backend:

- **SQLite** - `PRAGMA table_info(table)`
- **Other DBI drivers** - `$dbh->column_info(...)`
- **Slurp mode** - inferred from the first row; all columns typed as
`TEXT` by default.  When `infer_types => 1` was passed to the
constructor, up to 100 rows are scanned per column and the type is
promoted: all-integer values => `INTEGER`; all-float values =>
`REAL`; all ISO-8601 timestamps (`YYYY-MM-DDThh:mm`) => `TIMESTAMP`;
all ISO-8601 dates (`YYYY-MM-DD`) => `DATE`; otherwise `TEXT`.
`undef` and empty-string values are treated as SQL `NULL` and skipped
during the scan.
- **BerkeleyDB** - always returns `entry` (pk) and `value`

The result is cached inside the object after the first call.

#### Api Specification

##### Arguments

```perl
infer_types => Bool  # enable heuristic type inference for slurp backends
                     # (may also be set at construction time)
```

##### Returns

```perl
HashRef[Str => HashRef]
```

A hashref keyed by column name.  Each value is a hashref with:

```perl
type     => Str          # 'TEXT', 'INTEGER', 'REAL', 'TIMESTAMP', 'DATE'
nullable => Bool         # 1 if the column may be NULL, 0 if NOT NULL
default  => Str | undef  # default value, or undef
pk       => Bool         # 1 if (part of) the primary key
```

For slurp-mode backends all columns default to type `TEXT` unless
`infer_types` is set.  The result is cached in the object after the
first call.

### Dbi\_Source

Returns a hashref `{ dbh => $dbh, table => $name }` when the backend
is a live SQLite connection, or `undef` for every other backend (slurp-mode
CSV, JSON, XLSX, HTML URL, DBM::Deep, BerkeleyDB, PostgreSQL, MySQL, ...).

The hashref is consumed by `Database::Join` to perform a zero-copy
`ATTACH DATABASE` so rows never pass through Perl.
Nested `Database::Join` objects that are themselves SQLite-backed expose themselves
as attachable sources to parent joins through the same interface.

Subclasses may override this method to expose non-SQLite DBI connections
if their join layer supports them.

#### Api Specification

##### Arguments

None beyond the implicit invocant.

##### Returns

A hashref `{ dbh => DBI::db, table => Str }` on a SQLite-backed
instance, or `undef` on all other backends.

### Aggregate

Groups matching rows and computes aggregate measures over each group.
Pushes `GROUP BY` SQL to the backend when a DBI handle is available;
otherwise folds rows in Perl (BerkeleyDB, DBM::Deep, XLSX, JSON, HTML, Redis).

```perl
my $rows = $db->aggregate(
    by       => ['region', 'month'],
    measures => [
        { col => 'amount', fn => 'sum',   as => 'revenue' },
        {                  fn => 'count', as => 'orders'  },
    ],
    status => 'active',
);

# Grand total (no 'by')
my $row = $db->aggregate(
    measures => [{ col => 'score', fn => 'avg', as => 'mean_score' }],
)->[0];
```

Reserved parameter keys (extracted before the rest is treated as WHERE criteria):
`by`, `measures`, `having`, `sort_by`, `limit`, `offset`, `table`, `join`.

Always returns an **arrayref of hashrefs** (never `undef`); returns `[]` when
no group qualifies.  Row keys are the `by` column names (in declaration order)
followed by the measure aliases.

#### Measure Specification

Each measure hashref:

```perl
{ col => 'amount', fn => 'sum',           as => 'revenue'   }
{                  fn => 'count',         as => 'orders'    }  # COUNT(*)
{ col => 'amount', fn => 'count',         as => 'paid'      }  # COUNT(col)
{ col => 'customer', fn => 'count_distinct', as => 'customers' }
```

`fn` must be one of `sum`, `avg`, `min`, `max`, `count`, `count_distinct`,
`median`, `stddev` (case-insensitive).  `col` is required for every function
except plain `count`.  `as` (the result key) must be a valid SQL identifier
and must not duplicate another alias or a `by` column name.

`median` computes the median (middle value of sorted values; average of two
middle values for even count).  `stddev` computes the sample standard deviation
(using N-1 denominator).  Both are computed in Perl (no SQL pushdown); on SQL
backends the full result set is fetched first and then folded in memory.

Empty-set normalisation: `median` and `stddev` become `undef` when no rows
are present; `stddev` on a single-row group returns `0`.

#### Having

Pass `having => { alias_or_by_col => criterion }` to filter groups
after aggregation.  Accepts the full criteria syntax.

```perl
having => { revenue => { '>' => 1000 } }
```

#### Pseudocode

```
1. _open_table; croak if JOIN requested on no-DBI backend.
2. _validate_aggregate_spec: extract/validate by/measures/having/
   sort_by/limit/offset; remainder of params is WHERE criteria.
3. Merge base_criteria.
4. SQL path (DBI handle): _build_aggregate_sql; prepare_cached+execute;
   normalise empty-set values; cache; fixate; return.
5. Perl fold: selectall_arrayref(criteria); _fold_aggregate;
   HAVING via _match_criteria; sort; offset; limit; fixate; return.
```

#### Backend Notes

On slurp-only backends all matching rows are materialised before folding.
Use a SQL backend (SQLite DSN, PostgreSQL, MySQL) for large datasets.

#### Api Specification

##### Arguments

```perl
by         => ArrayRef[Str]     # optional: GROUP BY column names
measures   => ArrayRef[HashRef] # required: one or more measure specs
having     => HashRef           # optional: post-group filter criteria
sort_by    => Str | ArrayRef    # optional: sort column (Str) or [col,dir]
limit      => Int               # optional: max rows to return
offset     => Int               # optional: rows to skip before returning
join       => HashRef | ArrayRef # optional: join spec(s) -- SQL path only
no_fixate  => Bool              # optional: skip read-only locking
%criteria                       # optional: WHERE filter before grouping
```

Each element of `measures` is a hashref with keys:

```perl
col  => Str    # column to aggregate; omit only for plain count()
fn   => Str    # one of: sum avg min max count count_distinct median stddev
as   => Str    # result key name (required; valid SQL identifier)
```

##### Returns

```
ArrayRef[HashRef]
```

An arrayref of hashrefs.  Each hashref has one key per `by` column
and one key per measure `as` alias.  Returns `[]` (empty arrayref)
when no groups match -- never `undef`.

Empty-set normalisation: `sum`/`count`/`count_distinct` become
`0`; `avg`/`min`/`max`/`median`/`stddev` become `undef` when no rows
are present.

### Query

Returns a new [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) builder object bound to this
database instance, for fluent method-chaining queries.

```perl
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
```

See [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) for the full API.

### AUTOLOAD - Column Shortcut

Calling an unknown method whose name matches a column name performs a column
lookup.  The method name is the column you want; the arguments are criteria.

```perl
# Scalar context: return the first match
my $name = $db->name(entry => 'key1');

# List context: return all matching values
my @names = $db->name();

# Shortcut when the table has an 'entry' key column
my $name = $db->name('key1');    # same as name(entry => 'key1')

# Unique/distinct values
my @statuses = $db->status(distinct => 1);
```

**In list context** the full column is returned (all rows), ordered by the
column value.  **In scalar context** only the first match is returned
(`LIMIT 1`).

Results come from the slurp cache when available.

Throws an error if the column does not exist (slurp mode) or if AUTOLOAD
has been disabled with `auto_load => 0`.

#### Pseudocode

```perl
1. Extract column name from $AUTOLOAD; guard on DESTROY.
2. Croak if auto_load => 0.
3. Validate $column against /^[a-zA-Z_][a-zA-Z0-9_]*$/.
4. If data is slurped:
   a. List context, no params -> map column over all rows (exists guard).
   b. entry-only param -> direct hash lookup (exists guard).
   c. No params, scalar -> first value in hash.
   d. no_entry set -> scan array for matching key/value pair.
   e. Other params -> scan keyed hash for matching column.
5. If not slurped, build SQL:
   - List:   SELECT column FROM table [WHERE ...] ORDER BY column
   - Scalar: SELECT DISTINCT column FROM table [WHERE ...] LIMIT 1
6. Check cache; return on HIT.
7. prepare_cached + execute; fetch result.
8. Store in cache; fixate; return.
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Support

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-database-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## Messages

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

    None of the probe extensions (`.sql`, `.sqlite`, `.sqlite3`, `.psv`, `.tsv`, `.csv`, `.xlsx`, `.db`, `.xml`)
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

- `_Class_: aggregate: 'measures' must be a non-empty arrayref`

    `aggregate()` was called without a `measures` arrayref, or with an empty one.

- `_Class_: aggregate: measure must be a hashref, got _ref_`

    An element of the `measures` arrayref is not a hashref.

- `_Class_: aggregate: unknown measure function '_fn_'`

    `fn` must be one of `sum`, `avg`, `min`, `max`, `count`, `count_distinct`,
    `median`, `stddev`.

- `_Class_: aggregate: measure column is required for function '_fn_'`

    `col` was omitted for a function that requires it.  Only plain `count` (COUNT(\*)) accepts a missing `col`.

- `_Class_: aggregate: unsafe measure column '_col_'`

    The `col` value is not a valid SQL identifier.

- `_Class_: aggregate: measure 'as' is required`

    The `as` alias was missing from a measure hashref.

- `_Class_: aggregate: unsafe measure alias '_as_'`

    The `as` value is not a valid SQL identifier.

- `_Class_: aggregate: duplicate measure alias '_as_'`

    Two measure hashrefs share the same `as` alias.

- `_Class_: aggregate: measure alias '_as_' collides with a group-by column`

    A measure alias duplicates a name in the `by` list.

- `_Class_: aggregate: 'by' must be an arrayref of column names`

    The `by` parameter was not an arrayref.

- `_Class_: aggregate: unsafe group-by column '_col_'`

    A `by` element is not a valid SQL identifier.

- `_Class_: aggregate: having key '_key_' is not a group-by column or measure alias`

    A `having` key does not match any `by` column name or measure `as` alias.

- `_Class_: aggregate: sort_by names '_name_', which is not a group-by column or measure alias`

    The `sort_by` column is not one of the `by` columns or measure aliases.

- `_Class_: aggregate: cannot aggregate a JOIN on the _backend_ backend`

    `join` was passed to `aggregate()` on a slurp-only backend that has no DBI handle.

- `Database::Abstraction::Query: count() is not available once measure() has been called`

    `count()` was called on a query builder that has measures set.  Use `all()` and check `scalar @{$rows}`.

## Common Pitfalls

The following mistakes cause unexpected behaviour in common usage.
Read this section before filing a bug report.

- **Default CSV separator is `!`, not `,`**

    For historical reasons the module defaults to bang (`!`) as the
    field separator for CSV files.  Standard RFC 4180 comma-separated
    files require you to pass `sep_char => ','` in your subclass
    constructor.

    ```perl
    sub new {
        my ($class, %args) = @_;
        return $class->SUPER::new(sep_char => ',', %args);
    }
    ```

- **Primary key column is named `entry`, not `key`**

    The default primary-key column name is `entry` because `key` is
    a reserved word in SQL.  If your data uses a different column name
    (e.g. `id`, `customer_id`), pass `id => 'customer_id'` to
    `new()`.

- **Duplicate primary keys silently overwrite earlier rows**

    In slurp mode the entire data file is loaded into a Perl hash keyed
    by the `entry` column.  If two rows share the same key value the
    second row replaces the first.  To keep duplicates either disable
    slurp with `max_slurp_size => 0` or switch to a `no_entry`
    schema.

- **Operator-hash criteria do not work on no-DBI backends**

    No-DBI backends (XLSX, DBM::Deep, JSON, HTML URL, Redis) have no SQL
    engine.  Criteria that use operator hashes (e.g.
    `score => { '>=' => 80 }`) trigger the SQL path and will croak
    with a "meaningless on a NoSQL database" error.  Use simple scalar
    criteria (`score => 80`) on these backends.

- **Read-only results: do not modify returned hashrefs**

    Unless you pass `no_fixate => 1`, every hashref returned by
    `selectall_arrayref`, `fetchrow_hashref`, and similar methods is
    made read-only by `Data::Reuse`.  Attempting to assign a value to
    a key in the returned hashref will throw an exception.  If you need
    to modify a row, either copy it first (`my %row = %{$orig_row}`) or
    construct the object with `no_fixate => 1`.

- **`where()` calls in the query builder use AND semantics**

    Each call to `$q->where(...)` adds an additional required
    condition.  Two separate `where()` calls do NOT produce OR
    semantics.  To express OR, pass `-or => [...]` inside a single
    `where()` call:

    ```perl
    # Wrong: this is AND, not OR
    $q->where(status => 'active')->where(status => 'pending');

    # Correct: OR grouping inside one where() call
    $q->where(-or => [{ status => 'active' }, { status => 'pending' }]);
    ```

- **`aggregate()` `sort_by` must name a grouped or aliased column**

    The `sort_by` parameter for `aggregate()` only accepts column names
    from the `by` list or measure `as` aliases.  You cannot sort
    aggregate results by a raw data column that is not part of the group.
    This restriction applies equally to the `->order_by()` call on a
    query builder that has `measure()` methods set.

- **`sort_by` is not an argument to the query builder's `all()`**

    When using the fluent query builder to build an aggregate query, set
    the sort column via `->order_by('col')` before calling
    `->all()`.  Passing `->all(sort_by => 'col')` has no
    effect because the `all()` terminal method ignores extra arguments.

- **`Params::Get` positional mapping with `no_entry = 0`**

    When `no_entry` is false (the default), the first positional argument
    to `selectall_arrayref` and `fetchrow_hashref` is silently mapped to
    the `entry` key.  Passing an operator-hash criteria in that position
    (e.g. `selectall_arrayref(status =` { '!=' => 'x' })>) causes
    `status` to be treated as the entry value rather than a column name,
    which will produce wrong results.  Always pass a hashref of criteria
    as a single reference, or use `no_entry =` 1> in your subclass.

## Encoding

- **Column names** must match the pattern `[a-zA-Z_][a-zA-Z0-9_.]*`.
Only ASCII letters, digits, underscores, and dots (for qualified names
such as `table.column`) are accepted.  Non-ASCII Unicode characters
in column names will cause a croak with an "unsafe column name" error.
- **Column values** (data stored in your rows) are passed through
unchanged.  Full UTF-8 strings, emoji, and any valid Perl string are
safe as values in criteria and are stored and returned as-is.  The
exact encoding depends on your backend:
    - **SQLite / DBI backends** -- DBD::SQLite stores strings as
    UTF-8 internally.  Enable `sqlite_unicode => 1` in your DSN
    or connect attributes if you want Perl to receive decoded Unicode
    scalars rather than raw UTF-8 bytes.
    - **CSV / PSV / TSV** -- Text::CSV and DBD::CSV pass bytes
    through unchanged.  If your file is UTF-8-encoded, strings are
    returned as UTF-8 byte strings.  You may need to decode them with
    `Encode::decode('UTF-8', $val)` in your application.
    - **JSON** -- JSON::MaybeXS decodes JSON strings to Perl Unicode
    scalars automatically.  UTF-8 and emoji in JSON values are fully
    supported.
    - **XML** -- XML::Simple decodes the file with the XML encoding
    declaration.  UTF-8 encoded XML (the default) produces Perl Unicode
    scalars.
    - **XLSX** -- Spreadsheet::ParseXLSX decodes strings to Perl
    Unicode scalars.  Emoji in cell values are fully supported.
    - **HTML URL** -- LWP::UserAgent fetches bytes; HTML::TableExtract
    returns them as-is.  Decode with Encode if the page is UTF-8.
- **File paths** are handled by `File::Spec::catfile` and work
on any platform.  On Linux and macOS, UTF-8 directory and file names
are fully supported.

## Known Limitations

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

## See Also

- [Database::Abstraction::Query](https://metacpan.org/pod/Database%3A%3AAbstraction%3A%3AQuery) - chained query builder
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS) - JSON backend (optional; install for `.json` support)
- [Test Dashboard](https://nigelhorne.github.io/Database-Abstraction/coverage/)

## Formal Specification

The following section uses Z-notation to describe the key state
transitions and invariants for the module.  Z is a formal
specification language based on set theory and predicate logic.
Unicode is used here as permitted by the documentation skill.

### Database Object State

```
State == [
    data       : TABLE_NAME --> (ENTRY --> ROW) | seq ROW | undef,
    dbh        : TABLE_NAME --> DBI_HANDLE | undef,
    type       : Str | undef,
    base_crit  : CRITERIA,
    _columns   : seq Str | undef,
    _schema    : NAME --> COL_INFO | undef,
    _destroyed : Bool
]

Initial state S0 == [
    data?        = undef,
    dbh?         = undef,
    type?        = undef,
    base_crit?   = {},
    _columns?    = undef,
    _schema?     = undef,
    _destroyed?  = false
]
```

### \_Open\_Table

```
_open_table ___________________________________________
DeltaState
class? : CLASS
dir?   : DIRPATH | undef
────────────────────────────────────────────────────
pre:  _destroyed = false
pre:  dbh(table) = undef AND data(table) = undef
post: (EXISTS f : FILE_FORMATS WITH f.probe(dir) = true
       IMPLIES (f.slurp? IMPLIES data'(table) != undef)
            AND (f.dbi?  IMPLIES dbh'(table)  != undef))
```

### Selectall\_Arrayref

```
selectall_arrayref __________________________________
XiState  (read-only; state unchanged except cache)
criteria? : CRITERIA
────────────────────────────────────────────────────
pre:  _destroyed = false
result == (data != undef AND simple(criteria)
           IMPLIES { r : data | match(r, criteria) }
           ELSE    dbh != undef
           IMPLIES SQL_SELECT(dbh, criteria))
post: result : seq ROW UNION {undef}
```

### Aggregate

```
aggregate ____________________________________________
XiState
by?       : seq COLNAME
measures? : seq MEASURE_SPEC
criteria? : CRITERIA
────────────────────────────────────────────────────
pre:  measures != empty
pre:  FORALL m : measures WITH m.as NOT IN by
pre:  sort_by != undef IMPLIES sort_by IN ran(by) UNION aliases(measures)
result == (dbh != undef
           IMPLIES SQL_GROUP_BY(dbh, by, measures, criteria)
           ELSE    PERL_FOLD(selectall_arrayref(criteria), by, measures))
post: result : seq ROW (keys = by UNION aliases(measures))
post: FORALL r : result WITH
          r.count != undef IMPLIES r.count >= 0
        AND r.sum = undef IMPLIES no rows in that group
```

### Destroy

```
DESTROY ______________________________________________
DeltaState
────────────────────────────────────────────────────
post: _destroyed' = true
post: dbh'      = undef  (DBI handles disconnected)
post: data'     = undef
post: _columns' = undef
post: _schema'  = undef
```

## State Diagram

The following ASCII diagram shows every valid state the object can
occupy and the transitions between them.  Transitions are labelled
with the method call or event that triggers them.  Actions are shown
in parentheses.

```
.-----------------------------------------------------------.
|                  S1: CONSTRUCTED                          |
|  dbh=undef, data=undef, type=undef                        |
'---.-------.-------.-------.-------.-----.---.-------------'
    |       |       |       |       |     |   |
    | first query call triggers _open_table()
    |       |       |       |       |     |   |
    v       v       v       v       v     v   v
.------. .------. .------. .------. .--. .--. .--.
| S2   | | S3   | | S4   | | S5   | |S6| |S7| |S8|
| DBI  | | CSV  | | XML  | | JSON | |Xls| |Bk| |Dp|
'---^--' '--^---' '--^---' '--^---' '-^-' '-^-' '-^-'
    |       |       |       |       |   |   |   |
    |       |       '-------'-------'   |   |   |
    |       |         slurp path        |   |   |
    |       '-----------+---------------'   |   |
    |                   |                   |   |
    |         (data populated,              |   |
    |          _columns/_schema undef)      |   |
    |                                       |   |
    | (dbh populated,                       |   |
    |  data undef)                          |   |
    |                                       |   |
    +-------+--------+-----------+----------+   |
            |        |           |              |
      selectall   fetchrow    aggregate      fetchrow
      count       _hashref    query->all     _hashref
      each_row    AUTOLOAD    AUTOLOAD        AUTOLOAD
            |        |           |              |
            v        v           v              v
.-----------------------------------------------------------.
|                  (result returned to caller)              |
|          state is unchanged; only cache may be updated    |
'-----------------------------------------------------------'
                            |
                DESTROY (or object goes out of scope)
                            |
                            v
.-----------------------------------------------------------.
|                  S_DEAD: DESTROYED                        |
|  _destroyed=true; all handles disconnected;               |
|  temp files unlinked; _remote_tmpdir removed              |
'-----------------------------------------------------------'

State labels:
  S1  CONSTRUCTED  - new() returned; no I/O done yet (lazy open)
  S2  DBI          - live DBI handle (SQLite file, DSN, DBD::CSV)
  S3  CSV_SLURP    - small CSV/PSV/TSV/gzip-CSV slurped into RAM hash
  S4  XML_SLURP    - XML file slurped into RAM hash
  S5  JSON_SLURP   - JSON file slurped into RAM hash
  S6  XLSX_SLURP   - XLSX file slurped (type='XLSX', no DBI handle)
  S7  BERKELEYDB   - BerkeleyDB key-value file open (berkeley flag set)
  S8  DEEP_SLURP   - DBM::Deep file slurped into plain RAM hash

Blocked transitions (croak before state changes):
  S1 -> any  if constructor arguments are invalid
             (unsafe id/table/host/url)
  S* -> S*   aggregate() with join on S3/S4/S5/S6/S7/S8
             (no DBI handle)
  S7 -> S*   join() or select()-projection on BerkeleyDB
  S8 -> S*   join() on DBM::Deep
```

## License and Copyright

Copyright 2015-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
