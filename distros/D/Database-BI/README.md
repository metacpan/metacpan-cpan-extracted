## Name

Database::BI - Web-based Business Intelligence viewer for flat data files

## Version

0.009.0

## Description

`Database::BI` is a self-contained [Mojolicious](https://metacpan.org/pod/Mojolicious) web application that reads
arbitrary flat data files (CSV, PSV, TSV, SQLite, XML, XLSX, etc.) via
[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) and presents them as styled, sortable, reorderable
HTML tables.  It has no persistent database of its own -- it reads your files
on every request.

Users navigate to pick a file, open the filesystem browser to navigate anywhere
on disk, drag-and-drop files to upload, join multiple tables in memory, apply
server-side filters, and export results as CSV, SQLite, or JSON.  D3.js
visualisations (line chart, pie chart) are available from the toolbar.

Key features:

- **File picker** -- the home page scans `data_dir` and shows a card for
every supported file.  Recently opened filesystem files appear in a
"Recently opened" section powered by `localStorage`.
- **Filesystem browser** -- `/browse` lets the user navigate the entire
filesystem and open any supported data file, not just files in `data_dir`.
- **Column sort and reorder** -- clicking a header sorts the table; headers
are draggable to reorder.  Both settings are persisted in `localStorage`
by column name and survive page reloads.
- **Left join** -- the "Merge data" panel on any table view lets the user
join one or more additional tables on a shared key via [Database::Join](https://metacpan.org/pod/Database%3A%3AJoin).
Every left row is kept; right-table columns are appended for matching rows.
Multiple joins can be chained.
- **Quick-filter bar** -- a column/operator/value row below the toolbar lets
the user add filter conditions without opening any panel.  Pressing Enter
applies the filter.  Each active filter chip has an individual remove (x)
button so conditions can be dropped one at a time.  Operators: `eq`,
`ne`, `contains`, `starts`, `lt`, `le`, `gt`, `ge`, `empty`,
`notempty`.  Filters are applied server-side after all joins.
- **Combine (UNION ALL)** -- the "Combine data" panel stacks rows from a
second (or further) file beneath the current rows, using a unified column
set and leaving blanks where a source file lacks a column.
- **Charts** -- the toolbar offers a line chart ([HTML::D3](https://metacpan.org/pod/HTML%3A%3AD3)
`render_zoomable_line_chart_snippet`; brush-to-zoom, reference lines for
min/avg/max), a pie chart (`render_pie_chart_snippet`; animated,
sorted by value, capped at 12 slices, click-a-slice to filter the table),
and a heatmap (`render_heatmap_snippet`; two categorical axes, optional
value column or row count, configurable sequential colour scheme).
- **Drag-and-drop upload** -- any supported data file can be dropped directly
onto the application.  The file is opened immediately; when the "Combine
data" panel is open the dropped file populates the right-table path field.
- **Export** -- the toolbar export panel writes the current logical view
(after joins, filters, and dedup) to a chosen filesystem path as CSV
(`.csv`), SQLite (`.sql`), or JSON (`.json`).
- **URL import** -- `/import` fetches an HTML table from any public URL and
renders it in the browser without saving to disk.

### UTF-8 and Encoding

All file data is returned as Perl character strings.  CSV/PSV/TSV files are
read by [Text::xSV::Slurp](https://metacpan.org/pod/Text%3A%3AxSV%3A%3ASlurp) or [DBD::CSV](https://metacpan.org/pod/DBD%3A%3ACSV), both of which pass bytes
through without re-encoding; the application serves the resulting page as
`text/html; charset=UTF-8`, so full Unicode is displayed correctly as
long as the source file itself is UTF-8.

Filter values (`f=col:op:val`) are decoded from the URL by Mojolicious
before reaching the controller and are compared against cell values as
Perl character strings.  Unicode characters in filter values are therefore
supported transparently.

URL-imported HTML tables are fetched with [LWP::UserAgent::Cached](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3ACached);
[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) uses the page's own charset declaration to decode
the body.  If the remote page declares an incorrect charset, cell values
may contain mojibake -- this is a limitation of the source data, not the
application.

## Synopsis

**Start the development server (restarts automatically when you edit a file):**

```
morbo script/database-bi
```

**Start the production server:**

```
hypnotoad script/database-bi
```

**Use a different data directory:**

```perl
# In database_bi.conf (create this file in the same folder as script/):
{ data_dir => '/home/user/data' }
```

**Change the language used for templates:**

```perl
# In database_bi.conf:
{ data_dir => 'data', language => 'fr', platform => 'web' }
# Then create templates/web/fr/ and put your French .html.tt files there.
```

**Run the test suite to verify everything is working:**

```
make test
```

**Generate the Makefile for the first time or after editing Makefile.PL:**

```
perl Makefile.PL
```

## Routes

- `GET /`

    Scans `data_dir`, renders a card grid of available tables.

- `GET /view/:table`

    Opens the named table from `data_dir`.  Accepts `?f=col:op:val`
    (repeatable) to pre-filter results.

- `GET /browse`

    Filesystem navigator.  Accepts `?path=` to set the starting directory
    (defaults to `$HOME`).

- `GET /open`

    Opens any supported file by absolute path (`?path=`).  Accepts `?f=`
    filters.

- `GET /join`

    Performs one or more left joins and renders the merged table.  Parameters:

    ```
    l=<spec>               left table: "table:name" or "path:/abs/path"
    j=<spec>|<lk>|<rk>    join step (repeatable): right-spec, left key, right key
    f=<col>:<op>:<val>     result filter (repeatable)
    ```

- `GET /api/columns`

    Returns `{ "columns": [...] }` for a table (`?table=name`) or file
    (`?path=/abs/path`).  Used by the join UI to populate the right-key
    dropdown without a page reload.

- `GET /export`

    Exports the current logical view (same `l=`, `j=`, `f=` parameters as
    `/join`) as a file download.  Additional parameter:

    ```
    format=csv      (default) - RFC 4180 CSV; UTF-8; CRLF line endings
    format=sqlite   - SQLite 3 database with a single table named "data"
    ```

    The download filename is derived from the left table label with
    non-alphanumeric characters replaced by underscores.

- `POST /export`

    Writes the current logical view to a chosen filesystem path.
    Body params: `l=`, `j=`, `f=` (same as GET), plus
    `dir=` (target directory) and `filename=` (name including extension;
    extension determines format: `.csv` or `.sql`).
    Returns JSON `{ saved: "/abs/path" }` or `{ error: "..." }`.

- `GET /api/dirs`

    Returns a JSON directory listing (subdirectories only) for the export
    panel's inline directory browser.  Accepts `?path=` (defaults to
    `$HOME`).  Returns `{ path, parent, dirs: [{name, path}] }`.

- `GET /api/stat`

    Returns filesystem metadata for a file path (`?path=`).
    Returns `{ exists, path, mtime, size }`.  If the file does not exist,
    `exists` is `false` and the remaining fields are absent (HTTP 200).
    Returns HTTP 400 when `path` is missing.

- `POST /upload`

    Accepts a multipart file upload (field name: `file`), validates the
    extension, saves to a managed `.uploads/` subdirectory under the app
    home, and returns JSON `{ url, path }`.

- `GET /import`

    Fetches an HTML table from a public URL (`?url=`) and renders it as a
    data grid.  An optional `?t=` parameter (zero-based integer) selects
    which HTML table on the page to display when the page contains multiple
    tables.

- `GET /combine`

    Stacks rows from two or more tables vertically (UNION ALL) into a unified
    view.  All columns from all sources appear as headers; cells are blank
    where a source file lacks a column.  Parameters:

    ```
    l=<spec>               left table: "table:name" or "path:/abs/path"
    c=<spec>               additional table to stack (repeatable)
    f=<col>:<op>:<val>     result filter applied after combining (repeatable)
    ```

- `GET /graph`

    Renders a D3.js v7 zoomable line chart of any two columns.  Parameters:

    ```
    l=<spec>    left table (required)
    x=<col>     X-axis column name (required; any type, shown as labels)
    y=<col>     Y-axis column name (required; must be numeric after stripping
                currency symbols and commas; accounting-notation negatives like
                (1,234.56) are handled automatically)
    back=<url>  URL for the "Back to table" link (optional; default "/")
    j=, f=, d=  pipeline params (same as /join)
    ```

- `GET /pie`

    Renders a D3.js v7 animated pie chart grouped by a category column.
    Clicking a slice or legend entry navigates to the table view filtered to
    that category.  Parameters:

    ```
    l=<spec>    left table (required)
    cat=<col>   category column to group by (required)
    val=<col>   numeric column to sum per category (required)
    donut=1     show a hole in the centre (optional)
    back=<url>  URL for the "Back to table" link (optional; default "/")
    f=          result filters applied before aggregating (repeatable)
    ```

- `GET /heatmap`

    Renders a D3.js v7 grid heatmap with two categorical axes.  Each cell
    colour encodes a summed or counted numeric value.  Parameters:

    ```
    l=<spec>      left table (required)
    x=<col>       X-axis column name (required; categorical)
    y=<col>       Y-axis column name (required; categorical)
    val=<col>     numeric column to sum per cell (optional; omit to count rows)
    scheme=<name> colour scheme: YlOrRd Blues Greens Purples RdPu YlGnBu
                  (optional; default YlOrRd)
    show_val=1    print the value inside each cell (optional)
    back=<url>    URL for the "Back to table" link (optional; default "/")
    j=, f=, d=    pipeline params (same as /join)
    ```

- `POST /uploads/clear`

    Deletes every file from the `.uploads/` staging directory.  Returns JSON
    `{ "freed": <bytes`, "count": &lt;n> }>.  No request body is needed.

## Configuration

Place a `database_bi.conf` file in the application root to override
defaults:

```perl
{
    data_dir => 'data',   # directory scanned for data files on the home page
    platform => 'web',    # VWF template dimension
    language => 'en',     # VWF template dimension
}
```

## Common Pitfalls

- **The configuration file is optional but must be valid Perl if present**

    `database_bi.conf` is loaded by `Mojolicious::Plugin::Config`, which
    evaluates it as a Perl data structure.  If the file exists but contains a
    syntax error, the application will refuse to start.  If the file does not
    exist, built-in defaults are used and no error occurs.  The file must return
    a hashref:

    ```perl
    # database_bi.conf -- correct
    { data_dir => 'data', platform => 'web', language => 'en' }

    # WRONG -- missing braces
    data_dir => 'data'
    ```

- **data\_dir is relative to the application home directory, not the process cwd**

    Setting `data_dir => 'data'` looks for a folder called `data/` in the
    same directory as the `script/database-bi` launcher, regardless of where you
    run the server from.  An absolute path works on any system:

    ```perl
    { data_dir => '/var/db/mydata' }
    ```

- **The download\_dir default is computed once at startup**

    When the application starts, it picks the export directory in this order:
    `~/Downloads` (if it exists), then `$HOME`, then the system temp directory.
    This value is fixed for the life of the process.  Renaming or creating
    `~/Downloads` after the server starts has no effect.  To force a different
    default, set it before starting:

    ```perl
    { data_dir => 'data' }   # and create ~/Downloads before starting the server
    ```

- **Adding a new language requires a template directory, not just a config change**

    Setting `language => 'de'` in `database_bi.conf` tells the controller
    to look for templates in `templates/web/de/`.  If that directory does not
    exist, the controller automatically falls back to the default language.  To
    add German support: (1) create `templates/web/de/`, (2) copy and translate
    the `.html.tt` files from `templates/web/en/`, then (3) set the config.

- **Supported data file extensions are: csv, db, sql, sqlite, sqlite3, xml, psv, tsv, xlsx**

    The application recognises `.csv`, `.db`, `.sql`, `.sqlite`, `.sqlite3`,
    `.xml`, `.psv`, `.tsv`, and `.xlsx` files.  All three SQLite extensions
    (`.sql`, `.sqlite`, `.sqlite3`) are treated identically -- `inventory.sqlite`
    and `inventory.sqlite3` are both opened as SQLite databases without renaming.
    Excel `.xlsx` files are read directly via `Spreadsheet::ParseXLSX`.

    URLs will work.
    For example enter
    [https://worldpopulationreview.com/country-rankings/immigration-by-country](https://worldpopulationreview.com/country-rankings/immigration-by-country)
    into the `Import from a web page` field on the dashboard.

- **The open\_table helper lowercases the table name**

    When the router matches `GET /view/Sales` or `GET /view/SALES`, the table
    name is lowercased to `sales` before being passed to the helper.  The data
    file on disk must therefore also be lowercase (`sales.csv`, not
    `Sales.csv`).

## Limitations

- Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.
- Multi-table left joins are performed in memory by [Database::Join](https://metacpan.org/pod/Database%3A%3AJoin).  All
component tables are fetched into RAM before the merge; this is not
suitable for files that do not fit in the process's available memory.
- Upload staging is managed automatically.  On every server startup,
`Database::BI` evicts upload subdirectories whose modification time is
older than 24 hours.  The "Clear upload cache" button (`POST
/uploads/clear`) triggers an immediate full purge regardless of age.
- `Sub::Protected`/:Protected enforcement relies on the CHECK compilation
phase.  When a module is loaded dynamically at test time (e.g. via
`Test::Mojo-`new(...)>), the CHECK phase has already passed and the
"Too late to run CHECK block" warning is emitted -- the access
restriction is not enforced in that test context.  This does not affect
production (morbo/hypnotoad) deployments where modules are compiled on
startup.  Unlike the former `Sub::Private` approach, `Sub::Protected`
does not delete stash entries, so OO dispatch `$self->_method()`
works correctly in production without any special workarounds.

## Roadmap

Features planned for future releases (post-0.009.0).  Items are ordered by
priority.

- **Pagination / virtual scrolling** (High) -- Tables are rendered as a
single HTML blob.  Files with 100 k+ rows will time out or exhaust memory.
Add a `?page=N&limit=M` server-side slice or a JS `IntersectionObserver`
infinite-scroll to cap peak HTML size.
- **XLSX export** (High) -- `/export` supports CSV, SQLite, and JSON
but not XLSX output.  `Excel::Writer::XLSX` would close the round-trip for
users whose source data is XLSX.
- **Copy-link button on chart pages** (Medium) -- The dashboard data
view has a copy-link button when filters are active, but `/graph`, `/pie`,
`/heatmap`, and `/bar` do not, even though their URLs are fully
parameterised and users share them.
- **Column statistics panel** (Medium) -- A per-column popover showing
min, max, mean, median, and null-count.  `List::Util` is already in
`PREREQ_PM`; only `Statistics::Descriptive` (or manual computation) is
needed.
- **Multi-sheet XLSX** (Medium) -- `_detect_file_info` reads only the
first worksheet.  A `?sheet=` URL param with a sheet-name picker would
expose the full workbook.
- **`between` and `in (a,b,c)` filter operators** (Low) -- Would
reduce multi-filter chains for common range and set queries.
- **SSE streaming for large join results** (Low) -- The join pipeline
blocks the HTTP response until all rows are assembled.  Mojolicious supports
server-sent events, which could progressively stream rows to a JS table
renderer, giving visible progress on slow joins.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Database-BI/coverage/)

## Repository

[https://github.com/nigelhorne/Database-BI](https://github.com/nigelhorne/Database-BI)

## Support

This module is provided as-is without any warranty.

## Author

Nigel Horne `<njh@nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
