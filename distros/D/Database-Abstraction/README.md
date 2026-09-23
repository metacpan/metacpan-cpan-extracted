## Name

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

## Version

Version 0.45

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

Results are returned in the cache (if configured) and the returned array
reference is made read-only unless `no_fixate` was set.

**Note:** this always returns all matching rows.  Use ["selectall\_array"](#selectall_array)
in scalar context, or `$db->query->limit(1)->all()`, to fetch just one row.

#### Pseudocode

```
1. Parse criteria; extract and build any JOIN clause.
2. If data is slurped AND no joins AND criteria are simple:
   a. No criteria -> return all rows as arrayref.
   b. entry-only lookup -> return [$data{entry}].
   c. Otherwise -> scan rows in-memory with _match_criterion.
3. Otherwise build SQL: SELECT * FROM table [JOIN] [WHERE] ORDER BY id.
4. Check cache; return cached arrayref on HIT.
5. prepare_cached + execute; fetch all rows.
6. Store result in cache; fixate the array; return arrayref.
```

### Selectall\_Hashref

Deprecated alias for ["selectall\_arrayref"](#selectall_arrayref).  Use `selectall_arrayref` in
new code.

### Selectall\_Array

Similar to ["selectall\_arrayref"](#selectall_arrayref) but returns a list of hash references
rather than a reference to an array.

```perl
my @rows = $db->selectall_array(status => 'active');
```

In **scalar context** it applies `LIMIT 1` and returns just the first
matching hash reference - making it more efficient than `selectall_arrayref`
when you only need one row.  In **list context** all matching rows are returned.

Accepts the same criteria and `join` parameter as ["selectall\_arrayref"](#selectall_arrayref).

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

Returns the Unix timestamp of the last database update (mtime for
file-based backends, or the time of the most recent `new()` call for
DSN-based connections).

### Columns

Returns an array reference of column names for the current table.

```perl
my $cols = $db->columns();    # e.g. ['entry', 'name', 'score', 'status']
```

The column list is determined by the backend:

- **Slurp mode** - sorted keys of the first row in memory.
- **SQLite / other DBI** - a zero-row `SELECT *` exposes the driver's
`NAME` attribute.
- **BerkeleyDB** - always returns `['entry', 'value']`.

The result is cached inside the object after the first call.

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
- **Slurp mode** - inferred from the first row (all columns typed as `TEXT`)
- **BerkeleyDB** - always returns `entry` (pk) and `value`

The result is cached inside the object after the first call.

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

## License and Copyright

Copyright 2015-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
