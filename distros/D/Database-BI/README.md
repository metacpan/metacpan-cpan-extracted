## Name

Database::BI - Web-based Business Intelligence viewer for data files

## Version

0.014.0

## Description

`Database::BI` is a self-contained [Mojolicious](https://metacpan.org/pod/Mojolicious) web application that reads
and views arbitrary flat data (CSV, PSV, TSV, SQLite, XML, XLSX, etc.)
and presents them as styled, sortable, reorderable
HTML tables.
It has no persistent database of its own,
it reads your files on every request.

Users navigate to pick a file, open the filesystem browser to navigate anywhere
on disc, drag-and-drop files to upload, join multiple tables in memory, apply
server-side filters, and export results as CSV, SQLite, JSON, or XLSX.  Nine
D3.js v7 chart types, a pivot/crosstab table, per-column statistics, and
multi-visual saved canvases are available from the toolbar.

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
- **Charts** -- nine [HTML::D3](https://metacpan.org/pod/HTML%3A%3AD3) D3.js v7 chart types are accessible from
the toolbar: line chart (brush-to-zoom, reference lines for min/avg/max,
multi-series interactive legend), pie chart (click-a-slice to filter,
top-N, donut mode, configurable colour scheme), heatmap (two categorical
axes, count or sum mode), bar chart (horizontal or vertical, sort,
top-N), scatter/bubble plot (optional categorical colour and numeric
size dimensions), stacked bar chart, combo bar+line chart, treemap, and
histogram (server-side binning, `?bins=N`).  All charts can be resized
by dragging the bottom-right corner grip, or from the keyboard: the grip
takes focus, the arrow keys resize the chart (Shift takes bigger steps,
Home and End go to the narrowest and widest it can be) and the size is announced
as it changes.  All chart pages include Copy-link and Export SVG/PNG buttons.
- **Maps** -- `GET /map` plots the filtered view on an OpenStreetMap map, either
from latitude and longitude columns or from a place column geocoded locally
with [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) (one lookup per distinct place, remembered in the
dataset's model store).  Rows sharing a position become one marker.
- **Pivot table** -- the "Pivot table" panel builds a crosstab from any
combination of row dimensions, column dimensions, and measures
(`sum|avg|min|max|count|count_distinct`).  Supports subtotals, HAVING
filters, top-N row groups, and direct export to CSV, SQLite, JSON, or XLSX.
- **Column statistics** -- the column-stats button runs `GET /stats`, which
returns one row per column: row count, null count, distinct count, and
(for numeric columns) min, max, mean, and median.
- **Calculated fields** -- virtual columns defined by inline `?c=name:expr`
URL params or stored persistently via `POST /calc/save`.  Expressions
support arithmetic, comparison, `IF`, string, numeric, and date
functions, plus `bin(value,width)` for histogram grouping.  Calc fields
are applied before aggregation on all chart and pivot routes.
- **Saved canvases** -- the "Save as Canvas" panel saves the current data
configuration as a named multi-visual canvas (`/a/:id`).  Visuals are
arranged on a 12-column grid: drag a card by its header to any free cell
(the header also takes focus, and the arrow keys move the card a cell at a
time, Shift going to the edge), and resize it from the corner handle.  A
card's width and height can also be set without a drag from the Size menu in
its header: full, half, a third or a quarter of the width, and one, two,
three or six rows high.  The size the card is sits on the card itself, beside
that menu, so a width the corner grip left it at reads without the menu being
opened.  Each move is announced -- the column and row the
card landed in, and any card the move pushed down -- and saved as you go.  The whole position and size is
saved with the canvas, so a card put in row 4 stays in row 4 rather than
being packed up the page.  Canvases support
cross-filtering, drill-through hierarchies, parameterisation, bookmarks
with undo/redo, per-visual PNG download, and print to PDF/paper.
- **Drag-and-drop upload** -- any supported data file can be dropped directly
onto the application.  The file is opened immediately; when the "Combine
data" panel is open the dropped file populates the right-table path field.
- **Export** -- the toolbar export panel writes the current logical view
(after joins, filters, and dedup) to a chosen filesystem path as CSV
(`.csv`), SQLite (`.sql`), or JSON (`.json`).
- **URL import** -- `/import` fetches an HTML table from any public URL and
renders it in the browser without saving to disc.
- **Redis data source** (optional) -- when the `Redis` or `Redis::Fast` module
is installed, any Redis hash store can be opened as a read-only data table by
entering a `redis:tablename|redis://host:port` spec in the path field or in a
join/combine panel.  Redis keys must follow the `tablename:entry` convention
used by [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction).  Because `Redis` is an optional dependency,
the application works fully without it; Redis support activates automatically
when the module is available.

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
    filters.  When the file is a multi-table SQLite database, passing
    `?it=<table>` selects a specific internal table instead of the
    auto-detected first one.

- `GET /join`

    Performs one or more left joins and renders the merged table.  Parameters:

    ```
    l=<spec>               left table spec (see below)
    j=<spec>|<lk>|<rk>    join step (repeatable): right-spec, left key, right key
    f=<col>:<op>:<val>     result filter (repeatable)
    ```

    Spec formats:

    ```
    table:name                         named table from data_dir
    path:/abs/path/to/file.csv         absolute local path
    /../hostname/dir/file.csv          remote file via SFTP
    redis:tablename|redis://host:port  Redis hash store (requires Redis module)
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
    Returns `{ exists, path, mtime, size }`.  For SQLite files
    (`.sql`, `.sqlite`, `.sqlite3`, `.db`) an additional `table_count`
    integer is included when the file is a valid SQLite database; the field
    is omitted for Berkeley DB or other non-SQLite payloads.
    If the file does not exist, `exists` is `false` and the remaining
    fields are absent (HTTP 200).  Returns HTTP 400 when `path` is missing.

- `POST /upload`

    Accepts a multipart file upload (field name: `file`), validates the
    extension, saves to a managed `.uploads/` subdirectory under the app
    home, and returns JSON `{ url, path }`.

- `GET /import`

    Fetches an HTML table from a public URL (`?url=`) and renders it as a
    data grid.  An optional `?t=` parameter (zero-based integer) selects
    which HTML table on the page to display when the page contains multiple
    tables.

- `GET /tables`

    Schema browser for multi-table SQLite databases.  Accepts `?l=<spec>`
    (same `table:name` or `path:/abs/path` spec as `/join`).  Returns a card
    grid listing every internal table with its columns; each card links to
    `/open?path=...&it=<table>`.  Redirects to 404 when the spec is
    absent, invalid, or the resolved file is not a multi-table SQLite database.

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
    l=<spec>           left table (required)
    x=<col>            X-axis column name (required; any type, shown as labels)
    y=<col>            Y-axis column name (required; must be numeric after stripping
                       currency symbols and commas; accounting-notation negatives
                       like (1,234.56) are handled automatically)
    back=<url>         URL for the second breadcrumb link (optional; default "/")
    back2=<url>        URL for the outermost breadcrumb link when three levels are
                       needed (optional; e.g. /tables?l=... for the schema browser)
    back2_label=<text> Label for the back2 link (optional; default "Back")
    j=, f=, d=         pipeline params (same as /join)
    ```

- `GET /pie`

    Renders a D3.js v7 animated pie chart grouped by a category column.
    Clicking a slice or legend entry navigates to the table view filtered to
    that category.  Parameters:

    ```
    l=<spec>           left table (required)
    cat=<col>          category column to group by (required)
    val=<col>          numeric column to sum per category (required)
    donut=1            show a hole in the centre (optional)
    back=<url>         URL for the second breadcrumb link (optional; default "/")
    back2=<url>        URL for the outermost breadcrumb link (optional)
    back2_label=<text> Label for the back2 link (optional; default "Back")
    f=                 result filters applied before aggregating (repeatable)
    ```

- `GET /heatmap`

    Renders a D3.js v7 grid heatmap with two categorical axes.  Each cell
    colour encodes a summed or counted numeric value.  Parameters:

    ```
    l=<spec>           left table (required)
    x=<col>            X-axis column name (required; categorical)
    y=<col>            Y-axis column name (required; categorical)
    val=<col>          numeric column to sum per cell (optional; omit to count rows)
    scheme=<name>      colour scheme: YlOrRd Blues Greens Purples RdPu YlGnBu
                       (optional; default YlOrRd)
    show_val=1         print the value inside each cell (optional)
    back=<url>         URL for the second breadcrumb link (optional; default "/")
    back2=<url>        URL for the outermost breadcrumb link (optional)
    back2_label=<text> Label for the back2 link (optional; default "Back")
    j=, f=, d=         pipeline params (same as /join)
    ```

- `GET /bar`

    Renders a D3.js v7 bar chart grouped by a categorical column.  Parameters:

    ```perl
    l=<spec>           left table (required)
    cat=<col>          category (X-axis) column (required)
    val=<col>          numeric column to sum per category; omit or use __count__
                       to count rows instead of summing (optional)
    orient=h           horizontal bars (default: vertical)
    sort=value|label   sort bars by descending value or ascending label
    max=N              collapse bars beyond the top-N into an "Other" bar
    back=<url>         URL for the second breadcrumb link (optional; default "/")
    back2=<url>        URL for the outermost breadcrumb link (optional)
    back2_label=<text> Label for the back2 link (optional; default "Back")
    j=, f=, d=         pipeline params (same as /join)
    ```

- `GET /folder`

    Hierarchical folder view.  Groups a data table by the letter-prefix of an
    order-number column (e.g. A10, CT4, B3) and shows one card per prefix group.
    Clicking a card with sub-prefixes drills down; clicking a leaf shows the
    matching data rows.  Parameters:

    ```
    l=<spec>     left table (required)
    col=<col>    order-code column (auto-detected when absent)
    prefix=<str> current drill-down prefix (top level when absent)
    back=<url>   URL for the back link (optional)
    f=           result filters (repeatable)
    ```

- `POST /uploads/clear`

    Deletes every file from the `.uploads/` staging directory.  Returns JSON
    `{ "freed": <bytes`, "count": &lt;n> }>.  No request body is needed.

- `GET /pivot`

    Renders a pivot/crosstab table.  Parameters:

    ```
    l=<spec>             left table (required)
    rows=col1,col2       row-dimension column names (required)
    cols=col3            column-dimension names (optional)
    m=col:fn:alias       measure spec, repeatable (fn: sum|avg|min|max|count|count_distinct)
    totals=1             include subtotals column and grand-total row
    topn=N               keep only the top-N row groups
    topn_col=<alias>     measure alias to rank by (required when topn= is set)
    max_cols=N           collapse tail column combos beyond top-N into "Other"
    format=csv|sqlite|json|xlsx  stream result as a download
    back=<url>           URL for the back breadcrumb link
    f=                   result filters applied before aggregating (repeatable)
    ```

- `GET /stats`

    Per-column statistics view.  Returns one row per column: row count, null
    count, distinct count, and (for numeric columns) min, max, mean, and median.
    Parameters: `l=<spec>` (required) and `f=` filters.

- `GET /scatter`

    D3.js v7 scatter/bubble plot.  Parameters:

    ```
    l=<spec>      left table (required)
    x=<col>       X-axis column (required; numeric)
    y=<col>       Y-axis column (required; numeric)
    series=<col>  categorical colour dimension (optional)
    size=<col>    numeric bubble-radius dimension (optional)
    scheme=<name> colour scheme when series= is set (optional)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

- `GET /stacked`

    D3.js v7 stacked bar chart.  Parameters:

    ```
    l=<spec>      left table (required)
    cat=<col>     X-axis categories (required)
    series=<col>  stack segments (required; seg= is a backwards-compatible alias)
    val=<col>     measure column (optional; omit to count rows)
    scheme=<name> colour scheme (optional)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

- `GET /combo`

    D3.js v7 combo bar+line chart.  Parameters:

    ```
    l=<spec>       left table (required)
    cat=<col>      X-axis categories (required; x= is a backwards-compatible alias)
    bar_val=<col>  bar measure column (required)
    line_val=<col> line measure column (required)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=             result filters (repeatable)
    ```

- `GET /treemap`

    D3.js v7 treemap.  Parameters:

    ```
    l=<spec>      left table (required)
    group=<col>   tile label column (required; cat= is a backwards-compatible alias)
    size=<col>    tile area column (required; val= is a backwards-compatible alias)
    topn=N        keep only the top-N tiles; remainder merged into "Other"
    scheme=<name> colour scheme (optional)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

- `GET /histogram`

    D3.js v7 histogram with server-side binning.  Parameters:

    ```
    l=<spec>   left table (required)
    col=<col>  numeric column to bin (required)
    bins=N     bin count (default 10; clamped to range 1--200)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=         result filters (repeatable)
    ```

- `GET /map`

    OpenStreetMap map of the filtered view, drawn with HTML::OSM.  A row's position
    comes from a location column that is geocoded (`loc=`, one lookup per distinct
    value, remembered in the dataset's model store) or from coordinate columns
    (`lat=` and `lon=`).  Rows sharing a position become one marker.  Parameters:

    ```
    l=<spec>      left table (required)
    loc=<col>     column of places to geocode (required unless lat= and lon= are)
    lat=<col>     latitude column, -90..90
    lon=<col>     longitude column, -180..180
    popup=<col>   column shown in the marker popup (repeatable)
    max=N         markers to draw (default map_max_markers, 2000)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

- `GET /line`

    Alias for `GET /graph`.  All `/graph` parameters accepted.

- `GET /a/:id`

    Renders a saved canvas (analysis) as a full multi-visual page.  Accepts
    cross-filter params `?cf=<col>&cv=<val>`, drill-through
    params `?dd=<col>&dl=<level>`, and parameter overrides
    `?p.<name>=<value>`.

- `GET /api/analyses`

    Returns `{ analyses: [{id, name, datasets, updated}] }`.

- `POST /api/analyses`

    Creates a new analysis from a JSON request body.  Required fields: `name`
    and `datasets` (array; each entry must have a `spec` starting with
    `table:`, `path:`, `url:`, or `redis:`).  Returns `201 { id, created: 1 }`.

- `GET /api/analyses/:id`

    Returns the full analysis document.

- `PUT /api/analyses/:id`

    Full replacement of an analysis document.

- `PATCH /api/analyses/:id`

    Partial update; merges the supplied top-level keys.  `id` and `created`
    are immutable.  The `layout` key places the visuals on the canvas grid: an
    array of `{ visual, x, y, w, h }`, where `visual` indexes the `visuals`
    array and `x`, `y`, `w` and `h` are 1-based grid columns and rows (the
    grid is 12 columns wide, `x + w - 1` cannot exceed 12, and one visual may
    span at most 6 rows).  Positions are
    stored as given - a gap is a gap - but two visuals may not share a cell, so
    an overlapping set is rejected with `400` and the stored layout is left
    alone.

- `DELETE /api/analyses/:id`

    Removes the analysis.  Returns `200 { deleted: 1 }`.

- `GET /api/analyses/:id/export`

    Downloads the analysis document as a `.json` file.

- `POST /api/analyses/import`

    Creates an analysis from an uploaded `.json` file (multipart `file`
    field) or a raw JSON request body.  Caller-supplied `id`, `created`,
    and `updated` are stripped.

- `GET /calc/list`

    Returns `{ fields: { name: expr } }` for stored virtual calc fields
    for a given spec.  Accepts `?l=<spec>`.

- `POST /calc/save`

    Saves a named calc field to `.bi/models.json`.  Body:
    `l=<spec>&name=<ident>&expr=<expression>`.
    Returns `{ saved: 1 }` or `{ error: "..." }` (400 for hostile input).

- `POST /calc/delete`

    Removes a named calc field.  Body:
    `l=<spec>&name=<ident>`.

- `GET /groups/list`

    Returns `{ groups: { label: [vals] } }` for named value groups for
    a column.  Accepts `?l=<spec>&col=<col>`.

- `POST /groups/save`

    Saves a named value group.  Body: `l=&col=&group=&values=` (values
    is a newline-separated list of raw cell values).

- `POST /groups/delete`

    Removes a named value group.  Body: `l=&col=&group=`.

- `GET /dates/list`

    Returns `{ patterns: { col: pattern } }` for stored date-normalisation
    patterns.  Accepts `?l=<spec>`.

- `POST /dates/save`

    Saves a date-normalisation pattern for a column.  Body: `l=&col=&pattern=`.
    Supported patterns: `%m/%d/%Y` (US), `%d/%m/%Y` (EU), `%d-%b-%Y` (DD-Mon-YYYY).

- `POST /dates/delete`

    Removes a date-normalisation pattern.  Body: `l=&col=`.
    Omit `col=` to clear all patterns for the spec.

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
    file on disc must therefore also be lowercase (`sales.csv`, not
    `Sales.csv`).

- **Redis support requires the Redis or Redis::Fast module**

    Redis data source access is an optional feature.  If neither `Redis` nor
    `Redis::Fast` is installed, entering a `redis:...` spec returns a 404.
    To enable Redis support, install either module:

    ```
    cpanm Redis::Fast   # recommended -- C bindings, faster
    cpanm Redis         # pure-Perl fallback
    ```

    Redis keys must follow the `tablename:entry` convention: each key is the
    table name, a colon, and an entry identifier; the value is a Redis hash
    whose fields become the row columns.  For example:

    ```
    HSET players:row1 name Alice score 10
    HSET players:row2 name Bob   score 20
    ```

    Opening `redis:players|redis://localhost:6379` then displays a two-row table
    with columns `entry`, `name`, and `score`.

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

Features planned for future releases (post-0.013.0).  Items are ordered by
priority.

- **Folder view filter/join propagation** (Medium) -- The folder view
panel does not carry forward active `j=` and `f=` params when building
the `/folder` URL.  Users who have filtered or joined a table and then
click "Folder view" silently lose their filter context.
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
