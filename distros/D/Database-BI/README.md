## Name

Database::BI - Web-based Business Intelligence viewer for data files

## Version

0.023.1

## Description

`Database::BI` is a self-contained [Mojolicious](https://metacpan.org/pod/Mojolicious) web application that reads
and views arbitrary data (CSV, PSV, TSV, SQLite, JSON, XML, XLSX, etc.)
and presents them as styled, sortable, reorderable
HTML tables.
It has no persistent database of its own,
it reads your files on every request.

Users navigate to pick a file, open the filesystem browser to navigate anywhere
on disc, drag-and-drop files to upload, join multiple tables in memory, apply
server-side filters, and export results as CSV, SQLite, JSON, or XLSX.  Nine
D3.js v7 chart types, a pivot/crosstab table, per-column statistics, and
multi-visual saved canvases are available from the toolbar.

A tutorial in plain English is built into the application at `/tutorial`.
It is written for people who do not know Perl, and it is the place to start.

Key features:

- **File picker** -- the home page scans `data_dir` and shows a card for
every supported file.  Recently opened filesystem files appear in a
"Recently opened" section powered by `localStorage`.
- **Filesystem browser** -- `/browse` lets the user navigate the entire
filesystem and open any supported data file, not just files in `data_dir`.
- **Column sort and reorder** -- clicking a header sorts the table; headers
are draggable to reorder.  Both settings are persisted in `localStorage`
by column name and survive page reloads.  A table too long for one page is
sorted by the server (`sort=` and `dir=` in the address), every row of it,
so page 1 is the start of the sorted table and Next goes on from there.
A column sorts as dates when every cell is one, as numbers when every cell
is one (`$1,234`, `(5)` and `45%` are numbers; `T27` is not), and
otherwise as text, with case and accents ignored and the digits in it
compared as numbers, so `T3` comes before `T27`.
- **Left join** -- the "Merge data" panel on any table view lets the user
join one or more additional tables on a shared key via [Database::Join](https://metacpan.org/pod/Database%3A%3AJoin).
Every left row is kept; right-table columns are appended for matching rows.
Multiple joins can be chained.
- **Quick-filter bar** -- a column/operator/value row below the toolbar lets
the user add filter conditions without opening any panel.  Pressing Enter
applies the filter.  Each active filter chip has an individual remove (x)
button so conditions can be dropped one at a time.  Operators: `eq`,
`ne`, `contains`, `starts`, `lt`, `le`, `gt`, `ge`, `between`, `empty`,
`notempty`; and `in`, which a link can carry but the bar does not offer: any
value of a JSON list, as in `f=place:in:["Paris","Rome"]`.  Filters are
applied server-side after all joins.  `lt`, `le`,
`gt` and `ge` compare numbers, reading `$1,234.56` and `(1,234.56)` as
numbers too; a blank or a word in the cell matches none of them.
An operator that is none of these (operators are lower case) is a `400` that
lists them, and so is a filter, or a time range's `rcol=`, on a column the
view does not have (the message lists the columns): neither is taken as a
filter that keeps every row, or none.  A canvas card's own saved filters are
the exception: one on a column its dataset no longer has is ignored.
- **Combine (UNION ALL)** -- the "Combine data" panel stacks rows from a
second (or further) file beneath the current rows, using a unified column
set and leaving blanks where a source file lacks a column.
- **Charts** -- nine [HTML::D3](https://metacpan.org/pod/HTML%3A%3AD3) D3.js v7 chart types are accessible from
the toolbar: line chart (brush-to-zoom, reference lines for min/avg/max and a trend line,
multi-series interactive legend), pie chart (click-a-slice to filter,
top-N, donut mode, configurable colour scheme), heatmap (two categorical
axes, count or sum mode), bar chart (horizontal or vertical, sort,
top-N), scatter/bubble plot (optional categorical colour and numeric
size dimensions), stacked bar chart, combo bar+line chart, treemap, and
histogram (server-side binning, `?bins=N`).  All charts can be resized
by dragging the bottom-right corner grip, or from the keyboard: the grip
takes focus, the arrow keys resize the chart (Shift takes bigger steps,
Home and End go to the narrowest and widest it can be) and the size is announced
as it changes.  All chart pages include Copy-link and Export SVG/PNG/PDF buttons.
- **Maps** -- `GET /map` plots the filtered view on an OpenStreetMap map, either
from latitude and longitude columns or from a place column geocoded by a
[Geo::Coder::List](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AList) chain: [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree)'s local data first, then
OpenStreetMap's Nominatim service ([Geo::Coder::OSM](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AOSM), at most one request a
second) for the places the local data does not know.  Nominatim is asked over
https, and what it finds is also kept for a month in
`<model_dir>/geocode-cache/`, or the `cache_dir` set (see
["Where caches are kept"](#where-caches-are-kept)).  Each distinct place is
looked up once, remembered in the model store and shared by every dataset that
names it.  Rows sharing a position become one marker.
- **Pivot table** -- the "Pivot table" panel builds a crosstab from any
combination of row dimensions, column dimensions, and measures
(`sum|avg|min|max|count|count_distinct|median|stdev|first|last|range`, plus
`p<N>` for the Nth percentile).  The backend aggregates what it can;
the rest are computed in Perl from each group's values, subtotals and grand
total included, because a median is not the sum of the medians of its parts.
Supports subtotals, HAVING filters, top-N row groups, and direct export to
CSV, SQLite, JSON, or XLSX.
- **Column statistics** -- the column-stats button runs `GET /stats`, which
returns one row per column: row count, null count, distinct count, first and
last, and (for numeric columns) min, max, range, mean, median, a chosen
percentile and the sample standard deviation.  The arithmetic is the same one
the pivot's measures use.
- **Calculated fields** -- virtual columns defined by inline `?c=name:expr`
URL params or stored persistently via `POST /calc/save`.  Expressions
support arithmetic, comparison, `IF`, string, numeric, and date
functions, plus `bin(value,width)` for histogram grouping.  Calc fields
are applied before aggregation on all chart and pivot routes.
- **Relative time ranges** -- any data view, chart, pivot or saved canvas can be
limited to a named window worked out from today -- the last 24 hours, the last
7, 30 or 90 days, this or last month, quarter or year -- instead of typing
dates.  The window is resolved on every request (`?range=` with `?rcol=`),
so a bookmark or a canvas still means the same thing tomorrow, and the filter
bar disables a window the data cannot answer.
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
being packed up the page.  **Add text** in the toolbar adds a card of plain
text, for a title or an explanation, with a font, a size in points, colours and
an alignment of its own; it can hide its frame and header until it is pointed
at, and a row holding only one-row text cards is as tall as its text.  Double-click the text, or use **Edit text**, to change it or
to remove the card.  **Add current view** in the toolbar appends another
table, chart or map without leaving the canvas, and a status region announces
the card and the new visual count; when the card's script has drawn it, the
region says the chart or map has finished drawing, and if D3 or Leaflet could
not be loaded it names the missing library instead.  A scatter card can be
coloured by a column and its bubbles sized by a number there, with the same
choices as the scatter page.  A card that shows an
aggregated value picks its own function in that panel, from the vocabulary the
pivot uses and with the same names: Sum, Average, Min, Max, Count distinct,
Median, Std dev, First, Last, Range or a Percentile with its level, so a card
can show a median, a spread or a percentile where the chart pages behind it
could only sum.  Canvases support
cross-filtering, drill-through hierarchies, parameterisation, bookmarks
with undo/redo, per-visual SVG, PNG and PDF download, and print to PDF/paper.
- **Drag-and-drop upload** -- any supported data file can be dropped directly
onto the application.  The file is opened immediately; when the "Combine
data" panel is open the dropped file populates the right-table path field.
- **Export** -- the toolbar export panel writes the current logical view
(after joins, filters, and dedup) to a chosen filesystem path as CSV
(`.csv`), SQLite (`.sql`), or JSON (`.json`).
- **Print** -- the Print button, to the right of Refresh, prints the header row
and every row of the current view, not just the page on screen: the rows the
Export panel would save (after joins, filters, calculated and cross-row
columns, and dedup), read from `GET /export?format=json`, with the columns in
the order the table shows them and sorted as it is sorted.  Nothing else on
the page is printed, and the header row repeats on each printed page.  A row
deleted from the page with Delete selected is still printed; a deleted column
is not.
- **URL import** -- `/import` fetches an HTML table from any public URL and
renders it in the browser without saving to disc.
- **Redis data source** (optional) -- when the `Redis` or `Redis::Fast` module
is installed, any Redis hash store can be opened as a read-only data table by
entering a `redis:tablename|redis://host:port` spec in the path field or in a
join/combine panel.  Redis keys must follow the `tablename:entry` convention
used by [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction).  Because `Redis` is an optional dependency,
the application works fully without it; Redis support activates automatically
when the module is available.

    **MariaDB and MySQL data source** (optional) -- a table on a server named in the
    `mariadb_servers` configuration opens as `mariadb:server/table`, read-only, with
    the columns in the table's own order and a page read with `LIMIT`.  See
    ["MariaDB and MySQL servers"](#mariadb-and-mysql-servers).

### UTF-8 and Encoding

All file data is returned as Perl character strings.  CSV/PSV/TSV files are
read by [Text::xSV::Slurp](https://metacpan.org/pod/Text%3A%3AxSV%3A%3ASlurp) or [DBD::CSV](https://metacpan.org/pod/DBD%3A%3ACSV), both of which pass bytes
through without re-encoding; the application serves the resulting page as
`text/html; charset=UTF-8`, so full Unicode is displayed correctly as
long as the source file itself is UTF-8.  A UTF-8 byte-order mark at the
start of a CSV, TSV, PSV or JSON file (Excel's "CSV UTF-8" writes one) is
read past, so it is not part of the first column's name.

Filter values (`f=col:op:val`) are decoded from the URL by Mojolicious
before reaching the controller and are compared against cell values as
Perl character strings.  Unicode characters in filter values are therefore
supported transparently.

URL-imported HTML tables are fetched with [Database::BI::SafeUA](https://metacpan.org/pod/Database%3A%3ABI%3A%3ASafeUA) (see
["Which addresses it may fetch"](#which-addresses-it-may-fetch));
[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) uses the page's own charset declaration to decode
the body.  If the remote page declares an incorrect charset, cell values
may contain mojibake -- this is a limitation of the source data, not the
application.

## Synopsis

**Start the development server (restarts automatically when you edit a file):**

```
script/database-bi
```

`morbo -l http://127.0.0.1:3000 script/database-bi` does the same thing (a bare
`morbo script/database-bi` listens on every interface, so it starts only with a
password set), and
`script/database-bi daemon` starts a plain server with no file watcher; any
other Mojolicious command word (`routes`, `get`, ...) is passed to the
application.

**Start it showing one database:**

```
script/database-bi data/store.db
```

The home address then shows that database, and its Home link leads to the usual
list.  Only one can be named: more than one is an error (exit status 2), because
a join cannot be given on the command line, so open one and use Merge or Combine
in the browser.  A file that is missing, cannot be read or is of an unsupported
type is the same error, before the server starts.  A remote path, Redis spec or
MariaDB spec is accepted as it would be by `/open`, and is checked when it is first shown.
It listens on port 3000 of this machine only (`http://127.0.0.1:3000`); see
["Who can reach the server"](#who-can-reach-the-server) to change the port or open it to other machines.
A plain server does the same with
`BI_OPEN=/full/path/store.db script/database-bi daemon`; a file named after
`daemon` is ignored.

**Start the production server:**

```
hypnotoad script/database-bi      # start, or restart with no downtime
hypnotoad -s script/database-bi   # stop
```

It listens on port 8080 of this machine only and ignores `MOJO_LISTEN`; set the
port and anything else in `database_bi.conf`, under
`hypnotoad => { listen => ['http://*:8080'] }` (`*` opens it to every machine).
It keeps its process id in `script/hypnotoad.pid` unless `pid_file` says
otherwise.  It takes no database on its command line: use
`BI_OPEN=/full/path/store.db hypnotoad script/database-bi`.

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

**American spelling:** a browser that asks for English (United States) gets the
pages from `templates/web/en-us/`; set `language => 'en-us'` to make that
the default for every browser that names no other English.

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

    When the server was started with the name of a database (see ["SYNOPSIS"](#synopsis)), a
    request from outside the application is redirected to `/open` for that
    database.  A request whose `Referer` is this server, such as the Home link, gets
    the card grid, so a browser that withholds `Referer` always sees the database.

- `GET /tutorial`

    Renders the tutorial that is part of the application.  The chapters are data
    in [Database::BI::Tutorial](https://metacpan.org/pod/Database%3A%3ABI%3A%3ATutorial), not in this POD.

- `GET /login`, `POST /login`, `POST /logout`

    The login, when `password_hash` is set (see ["Logging in"](#logging-in)).  `GET /login`
    shows the form (with `return=`, the page to go back to: a path on this site),
    `POST /login` takes `password=` and `return=`, and `POST /logout` ends the
    session.  With no password set, `/login` says there is nothing to log in to.

- `GET /preferences`

    Sets the reader's preferences: the theme, one of light, dark or the same as the
    device (the default), and the rows a table or pivot shows on a page (25, 50,
    100, 200 -- the default -- or All).  The theme is kept in the browser's
    `localStorage` and the page size in its cookie `bi_per_page`, because the
    server reads it (a value other than 25, 50, 100, 200 or 0 is ignored, and the
    page is 200 rows); neither is stored on the server, and both apply to every page.
    Saved charts, printed pages and embedded canvases stay light.  The Preferences
    link at the top of each page passes `back=` (that page), so the breadcrumb
    here leads back to it.

- `GET /view/:table`

    Opens the named table from `data_dir`.  Accepts `?f=col:op:val`
    (repeatable) to pre-filter results, and `?range=name&rcol=column` to keep
    only a relative window of rows (see ["Relative time ranges"](#relative-time-ranges)).

    A long table is shown a page at a time: `?page=` is the page, and
    `?per_page=` its size (else the reader's preference, else 200; up to 2000;
    `0` is every row on one page, and then `page=` is ignored).  The page says
    "Page 2 of 7", and its Rows per page list (25, 50, 100, 200, All) changes the
    size, keeping the first row on screen.  A pivot pages its row groups the same
    way.

    `?f=col:between:lo:hi` keeps the rows whose `col` lies from `lo` to `hi`,
    both included, whichever bound is written first.  Two numbers (a range of
    years, `Year:between:1880:1900`) compare as numbers; two dates or timestamps
    compare as times (`when:between:2026-11-01T09:00:00:2026-11-01T17:00:00`
    splits at the colon between them); any other pair compares as text, ignoring
    case.  The filter row offers it for date columns (two
    date boxes) and number columns (two number boxes).

    A name that is not a table in `data_dir` is a `404` page that says so ("There
    is no table called ..."), with the breadcrumb and site navigation; it does not
    show the data directory.

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
    c=<spec>               table to stack after the joins (repeatable; see /combine)
    f=<col>:<op>:<val>     result filter (repeatable)
    range=<name>           relative time range, with rcol=<column> (see below)
    ```

    Spec formats:

    ```
    table:name                         named table from data_dir
    table:file/table                   a table inside a multi-table SQLite file
                                       (or a list in a JSON file) in data_dir
    path:/abs/path/to/file.csv         absolute local path
    path:/abs/path/to/file.db#table    one table of such a file anywhere else;
                                       a file whose own name has a # is that file
    /../hostname/dir/file.csv          remote file via SFTP
    redis:tablename|redis://host:port  Redis hash store (requires Redis module)
    mariadb:server/table               a table on a server in mariadb_servers
    mariadb:server                     lists that server's tables
    ```

- `GET /api/columns`

    Returns `{ "columns": [...] }` for a table (`?table=name` or
    `?table=file/table` for a table inside a multi-table SQLite file) or file
    (`?path=/abs/path`, or `?spec=path:/abs/path#table` for one of its tables).  Used by the join UI to populate the right-key
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
    data grid.  A URL that leads to this machine or a private network is refused
    (see ["Which addresses it may fetch"](#which-addresses-it-may-fetch)).  An optional `?t=` parameter (zero-based integer) selects
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
    j=<spec>|<lk>|<rk>    join step applied to the left table first (repeatable)
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
    span=<n><unit>     bucket x into time buckets (optional; see "Time buckets")
    agg=<fn>           aggregate y per bucket, which is what makes this a
                       timechart (optional; default: one point per row)
    series=<col>       one line per value of this column (optional)
    back=<url>         URL for the second breadcrumb link (optional; default "/")
    back2=<url>        URL for the outermost breadcrumb link when three levels are
                       needed (optional; e.g. /tables?l=... for the schema browser)
    back2_label=<text> Label for the back2 link (optional; default "Back")
    j=, f=, d=         pipeline params (same as /join)
    ```

    A one-line chart offers check boxes above it for reference lines: Min, Avg,
    Max, and Trend, the straight line closest to the points (least squares, by
    [Statistics::LineFit](https://metacpan.org/pod/Statistics%3A%3ALineFit)), labelled with its slope per point and its R squared
    (a flat series is slope 0 and R squared 1: the line passes through every
    point).
    The points are evenly spaced along the axis, so the fit is of Y against each
    point's place, not its label.  After a zoom, every line is worked out again
    from the points in view.  None is offered on a chart with `series=`, and Trend
    needs two points.

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
    m=col:fn:alias       measure spec, repeatable (fn: sum|avg|min|max|count|count_distinct
                         for the aggregates the backend computes, median|stdev|first|last|range
                         for those computed in Perl from the group's values, or p<N> for
                         the Nth percentile -- p50 is the median, and p1 to p100 are accepted)
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
    count, distinct count, first and last, and (for numeric columns) min, max,
    range, mean, median, the percentile named by `p=N` and sample standard
    deviation.  Parameters: `l=<spec>` (required), `f=` filters and
    `p=N` for the percentile column (1 to 100, default 95).

- `GET /scatter`

    D3.js v7 scatter/bubble plot.  Parameters:

    ```
    l=<spec>      left table (required)
    x=<col>       X-axis column (required; numeric)
    y=<col>       Y-axis column (required; numeric)
    series=<col>  categorical colour dimension (optional)
    size=<col>    numeric bubble-radius dimension (optional)
    scheme=<name> colour scheme when series= is set: tableau10 (default),
                  category10, set2, set3 or paired; any other is a 400
    min_r=N       smallest bubble radius in px with size= (1-40, default 3)
    max_r=N       largest bubble radius in px with size= (1-40, default 15)
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
    scheme=<name>  bar and line colours: the first two of tableau10,
                   category10, set2, set3 or paired (optional; steel blue and
                   red without it, and for any other name)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=             result filters (repeatable)
    ```

- `GET /treemap`

    D3.js v7 treemap.  Parameters:

    ```
    l=<spec>      left table (required)
    group=<col>   tile label column (required; cat= is a backwards-compatible alias)
    size=<col>    tile area column, summed (optional, counting rows without it;
                  val= is a backwards-compatible alias)
    topn=N        keep only the top-N tiles; remainder merged into "Other"
    scheme=<name> colour scheme (optional)
    color=<col>   shade each tile by this column instead (optional), folded
                  over the tile's rows; "Other" is folded over the rows it holds
    color_agg=F   how color= is folded: avg (default), sum, min, max, median or
                  any other aggregate function; an unknown one is a 400
    color_scheme=S  scale for color=: YlOrRd (default), Blues, Greens, Purples,
                  RdPu or YlGnBu; any other name is YlOrRd
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

- `GET /histogram`

    D3.js v7 histogram with server-side binning.  Parameters:

    ```
    l=<spec>   left table (required)
    col=<col>  numeric column to bin (required)
    bins=N     bin count (default 10; clamped to range 1--200)
    scheme=S   bar colour: the first colour of tableau10, category10, set2,
               set3 or paired (optional; steelblue without it, and for any
               other name)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=         result filters (repeatable)
    ```

- `GET /wordcloud`

    Word cloud of a text column, drawn with HTML::TagCloud.  Each row contributes
    its words once, so a word's size is the number of rows that use it rather than
    the number of times one long note repeats it.  Common English words are
    removed.  Parameters:

    ```
    l=<spec>     left table (required)
    col=<col>    text column to read (required)
    topn=N       number of different words to show (default 50; range 1--500)
    minlen=N     shortest word kept (default 3; range 1--64)
    stop=<words> extra words to ignore, comma or space separated (optional)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=           result filters (repeatable)
    ```

    With `back=`, each word links to the rows that contain it.

    The same cloud is available as a card on a saved canvas: `POST
    /api/analyses/:id/visuals` takes `kind => wordcloud` with `encode.col`,
    and the card counts the words of its own rows -- its filters, the page's
    cross-filter and its own options -- so a canvas that is narrowed to one
    region shows the words of that region.

- `GET /map`

    OpenStreetMap map of the filtered view, drawn with HTML::OSM.  A row's position
    comes from a location column that is geocoded (`loc=`, one lookup per distinct
    value, remembered once in the model store and shared with every dataset that
    names it) or from coordinate columns (`lat=` and `lon=`).  Rows sharing a
    position become one marker.  When some rows cannot be plotted, the note that
    says so counts them by reason (empty, not a place name, not found, or not looked
    up yet), links to all of them in the table, and opens onto a list of their
    places, each with its number of rows, why it was not plotted and a link to
    those rows.  Markers are clustered with
    Leaflet.markercluster, so a dense map draws a count at low zoom and splits it
    as it is zoomed in.  Clustering is always on.  The map has a scale bar, opens
    on every marker unless `zoom=` is given, and draws its key (colours, and
    bubble sizes) on the map; the colours listed are those of the markers in view,
    so the key changes as the map is zoomed and moved.

    Places that are not in the cache yet are looked up after the page is shown.
    The map draws what the cache already knows, and a progress bar names each
    place as it is looked up ("Looking up 5 of 10: 10 Downing St, London").  Each
    answer is saved at once, through `POST /geo/lookup`, and the map is drawn
    again when the last one is in.  Cancel stops the lookups and draws the map with
    the places found so far.  The places left are listed as not looked up yet, with
    a link to look them up.  Without JavaScript, or for a client that is not a
    browser, the page waits for the lookups instead (`geocode=wait`).  Parameters:

    ```
    l=<spec>       left table (required)
    loc=<col>      column of places to geocode (required unless lat= and lon= are);
                   repeat it for a place written across columns, which are joined
                   with ", " in that order (loc=Address&loc=Country)
    loc_text=<text> text added to the end of each place before it is looked
                   up, after ", " (loc=County&loc_text=Virginia, USA looks up
                   "Accomack, Virginia, USA"); one line, at most 200 characters;
                   a row with no place is still not looked up
    lat=<col>      latitude column, -90..90
    lon=<col>      longitude column, -180..180
    popup=<col>    column shown in the marker popup (repeatable; default every
                   column but the place or coordinates)
    max=N          markers to draw (default map_max_markers, 2000)
    zoom=N         initial zoom 0..19 (default: fit the markers)
    max_zoom=N     tile layer maxZoom 0..28 (default: map_max_zoom, if set)
    tiles=<name>   named tile source from the tile_sources config key
    heat=1         add a heatmap layer over the markers
    bounds=<level> draw the outline of the area around each marker: country,
                   state, county, city, town or neighbourhood
    weight=<col>   numeric heatmap intensity column (normalised to 0..1)
    size=<col>     numeric bubble-radius column; markers become circles
    color=<col>    colour markers from a column
    color_rule=<op>:<value>:<colour>  repeatable; op is gt, ge, lt, le, eq or ne
    color_default=<colour>  fallback colour (default #3388ff)
    series=<col>   colour markers by category (not with color=)
    scheme=<name>  palette for series=: tableau10, category10, set2, set3, paired
    geocode=wait   look up the places not cached yet before the page is sent
                   (the default for a client that is not a browser)
    geocode=cached look nothing up: plot what the cache knows (where Cancel leads)
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

    With `bounds=` (the map panel's "Show boundaries"), the map draws the outline
    of the area each marker is in, with a checkbox on the map to hide them.  The
    level says how large an area:

    ```
    country        the country
    state          a US or Indian state, a Canadian province, a New Zealand
                   region, England or Scotland
    county         the division below a state; see below
    city           a city, or the district named after it: Toronto, Manchester,
                   the district of Canterbury, Hamilton City in New Zealand.
                   Where OpenStreetMap has no city round a point, or has it only
                   as a point (York, Pune), the authority at the county's rank
    town           a town or a city ward: Margate, Toronto Centre
    neighbourhood  a neighbourhood, suburb or civil parish
    ```

    OpenStreetMap has a shape for every country, state and county, but not for
    every smaller place: many towns and most suburbs are mapped as a single point
    (Cliftonville and Garlinge in Margate are), and a marker there has no outline at
    that level.  The list under the map says which markers those are.  Larger areas
    are simplified more, so an outline is a few kilobytes at any level.

    ```perl
    The outlines come from Nominatim's reverse lookup, which is sent each
      marker's position rounded to three decimal places (about 110 metres), and only
      when C<map_geocode_online> allows it.  Each outline is remembered under
      C<model_dir> (C<boundary-cache>), with the points found in it, so a point inside
      an outline already known costs no lookup; each level is remembered apart.  A
      county is the division of a
      country below its states, whose place rank in Nominatim depends on the country:
      12 (a US county or independent city, an English county, a German Landkreis), or
      10 for India, Bangladesh, China and Spain (district, prefecture, province), or 8
      for Kenya.  Australia, Brazil and Japan have nothing at that level.  Config
      C<map_bounds_ranks> (C<< { lk => 10 } >>: two-letter codes, ranks 8, 10 or 12)
      adds or changes countries for the county level; startup refuses anything else.  Each reply names its
      country, so a point is asked at the rank of the last country seen, and again
      at its own when that differs.
      Outlines not known yet are looked up as places are: by the progress bar, through
      C<POST /geo/boundary>, or in the request for C<geocode=wait>; at most
      C<map_geocode_online_max> in one request.  The checkbox needs L<HTML::OSM> 0.15;
      with 0.14 the outlines are always shown.
    ```

    With `heat=1` as well, each outline is coloured by what is in it: the
    `weight=` column summed over every row inside it (or its rows counted, with no
    `weight=`), from green for the smallest total to red for the largest.  The
    colour follows the size of the total on a logarithmic scale: each step up the
    colours is the same multiple, so totals close in size share a colour and skewed
    totals (one county with 500 times the people of another) still spread across
    the scale.  When a total is zero or less the colours go by rank instead.  With
    one outline, or totals all alike, there is nothing to compare, so the outlines
    stay grey.  Each outline's popup gives its total, and the line under the title
    says what the colours mean.  The checkbox, the key and that line call an
    outline what its country does (a district in India, a province in Spain, an
    area when the map mixes them).  With [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM)
    0.16 a key in the map's bottom right corner lists each colour, highest first,
    with the totals it covers, rounded to two figures ("30,000 to 37,000"); it hides with the outlines'
    checkbox.

    When the markers are coloured (`color=`), the outlines take their colours
    instead, with or without `heat=1`, so a border never disagrees with the
    markers inside it.  With [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) 0.17 each coloured outline, here and on the heat scale, is
    drawn just inside its own edge, so where two counties of different colours
    meet the border is a line twice as wide, one colour on each side.  An outline
    whose markers differ gets a line of each of their colours, side by side, the
    colour most of its markers have outermost.  An older HTML::OSM draws each
    outline along its edge in that first colour alone, one over another where they
    meet.  Outlines are simplified to about 100 metres one at a time, so zoomed
    well in, neighbours' lines can part or overlap a little.  The markers' key explains the colours, so the outlines have none of
    their own.

    A map can have fewer outlines than markers, and a list under it says why: each
    outline that holds more than one marker, with the places in it, and the markers
    in no outline at all, each with a link to its rows in the table.  Often that is
    as it should be (several shops in one county).  Where the places were looked up
    by name it can also be a wrong answer, since a name may be ambiguous, and the
    list says so; `loc_text=`, or latitude and longitude columns, make a lookup
    surer.  The list names at most 50 outlines, the fullest first.  While some
    places have no outline yet (not looked up, or OpenStreetMap did not answer),
    the note above the map links to their rows and, for those not looked up, to
    the map again to look them up.

    Outlines are written into the page, about 7 KB each before compression, so a
    map of a state's counties is well under a megabyte, and one of every county in
    a large country would be very large: filter the rows first.

    `shade=<column>` (Colour shade, in the map panel) fills each outline in a
    shade of one colour, the darker the larger that column's total over the rows
    inside it, as a census map is drawn.  There are five shades, placed on the same
    logarithmic scale, from a light tint up to the colour itself: `shade_color=`
    (a colour name or `#rrggbb`) chooses it, orange by default.  A key lists each
    shade in use, darkest first, with the totals it covers, as filled boxes with
    [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) 0.18 (lines before), and each outline's popup, which now opens from
    anywhere inside it, gives its total.  The lines stay grey, or take the markers'
    colours: with a shade the heat layer no longer colours them, since the fill
    says the same.  With one outline, or totals all alike, nothing is filled.

    When the markers are coloured (`color=`) and no `shade_color=` is given, each
    outline is shaded in its own markers' colour instead, each colour a scale of its
    own: the further a total is into what the colour stands for, the stronger the
    shade.  For a rule on the shaded column that reads "less than" (`lt`, `le`)
    that means the smaller total: with `color_rule=lt:20000:green` a county of
    2,000 is a stronger green than one of 19,000, while under
    `color_rule=gt:100000:red` the largest county is the strongest red.  The key
    lists every shade by size, the largest totals at the top, so it runs from the
    strongest red down to the strongest green.  It then stands for the markers'
    colours as well, so the markers' own key of those colours is left out while the outlines are
    shown.  With [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) 0.19 it comes back when the reader hides the outlines
    with their checkbox, and goes again when they are shown; an older HTML::OSM
    leaves it out throughout.  The markers' key always stays when the shade is of
    another column or of one colour, where nothing else says what the marker
    colours mean.  Give `shade_color=` to shade
    every outline in one colour as before.

    A marker stands for every row at its place, and its popup lists them all: a
    value every row shares is shown once ("Person: Valentin Puntar"), and the
    columns that differ are a small table, one line a row.  The table shows at most
    `map_popup_rows` rows (default 10) in a box that scrolls, so a busy place does
    not cover the map; the rest are counted, with a link to them in the table the
    map came from.

    An unknown `tiles=` or `scheme=` is a 400, as is an unknown column, `color=`
    together with `series=`, or a transposed lat/lon pair.  The page never shows
    the [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) Nominatim search box (`search => 0` is always passed), so
    nothing typed on the map is sent anywhere.  With `loc=`, a place the local
    data does not know is sent to Nominatim, as the place name alone; set
    `map_geocode_online` to 0 to keep every lookup local.  [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) 0.14 or
    later is the renderer; an older optional install still returns the page with a
    warning.

- `GET /line`

    Alias for `GET /graph`.  All `/graph` parameters accepted.

- `GET /canvases`

    Lists the saved canvases, as cards that open them, with Import canvas.  It is
    the main navigation's Canvases link; the home page shows the same list,
    without Import canvas.  With
    no canvases, the page says how to make one.  A canvas's breadcrumb leads back
    here unless its `back=` names another page.

- `GET /a/:id`

    Renders a saved canvas (analysis) as a full multi-visual page.  Accepts
    cross-filter params `?cf=<col>&cv=<val>`, drill-through
    params `?dd=<col>&dl=<level>`, parameter overrides
    `?p.<name>=<value>`, and a relative time range
    `?range=<name>&rcol=<column>` that narrows every card on the
    canvas (see ["Relative time ranges"](#relative-time-ranges)).

- `GET /api/analyses`

    Returns `{ analyses: [{id, name, datasets, updated}] }`.

- `POST /api/analyses`

    Creates a new analysis from a JSON request body.  Required fields: `name`
    and `datasets` (array; each entry must have a `spec` starting with
    `table:`, `path:`, `url:` or `redis:`, or being `mariadb:server/table`).
    Returns `201 { id, created: 1 }`.

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

- `POST /api/analyses/:id/visuals`

    Appends one visual to a saved canvas.  Body: `{ kind, encode, options,
    title, query }`, with `kind` one of `table`, `bar`, `pie`, `line`,
    `graph`, `scatter`, `heatmap`, `stacked`, `combo`, `treemap`,
    `histogram`, `wordcloud`, `map` or `text`.  A `text` card reads no data, and
    its `options` are `text` (required, up to 20,000 characters), `font`
    (`arial`, `georgia`, `times`, `verdana`, `trebuchet` or `courier`), `size`
    (8 to 96 points), `colour` and `background` (`#rrggbb`; leaving out `colour`
    follows the theme), `align` (`left`, `center` or `right`), `bold`, `italic`
    and `plain`.  The text is shown as plain text, never as markup.  A map's `encode` names either `loc` (a place column
    to geocode) or `lat` and `lon`.  A `wordcloud` card's `encode` names the
    text column to read in `col`, and its `options` take the same `topn`,
    `minlen` and `stop` the `GET /wordcloud` page takes, so the two count and
    rank words with one function.  A `scatter` card's `encode` names `x`
    and `y`, and optionally `series` (colour by value) and `size` (bubble size); its
    `options` take `scheme`, `min_r` and `max_r` as `GET /scatter` does,
    except that an unknown `scheme` draws the default colours.  A `line`
    or `graph` card's `encode` takes an optional `series`, one line per value.
    A `histogram` card's `options` take `bins` and `scheme` as `GET /histogram`
    does.  A `treemap` card's `encode` takes an optional `color`, with
    `options` `color_agg` and `color_scheme` as `GET /treemap`'s `color=`,
    `color_agg=` and `color_scheme=`; an unknown function is the card's error.
    A `combo` card's `options` take `scheme` as `GET /combo` does.
    The optional `query` is the canvas page's
    query string: `cf` (cross-filter), `c` (calculated columns) and
    `p.<name>` (bound parameter values) are read from it, so a card added
    while the canvas is filtered or parameterised is drawn through the same state
    as the cards already on screen.  The visual is rendered against the canvas's
    datasets, joins and calculated fields before it is stored, so an unknown
    column or an undrawable visual is rejected with `400` and nothing is appended.
    Returns `201 { id, visual, kind, title, html, head, nonce, cf_col }`, where
    `visual` is the new visual's index, `head` is any stylesheet and script the
    page must add once to draw the card (Leaflet, for a map), `nonce` is the
    Content-Security-Policy nonce the scripts in `html` carry (the canvas page
    runs only those, giving each its own nonce), and `cf_col` is the
    column the card's marks cross-filter by.  The card is left unplaced in
    `layout`; it is auto-placed after the saved cards until the reader moves or
    resizes it.

    A `kind` that aggregates a value column -- `bar`, `pie`, `stacked`,
    `treemap`, `heatmap` and `combo` -- reads an optional `encode.agg`: the
    function its value column is aggregated with.  It takes `sum` (the default),
    `avg`, `min`, `max`, `count_distinct`, `median`, `stdev`, `first`,
    `last`, `range`, or a percentile named `p<N>` from `p1` to `p100`
    \-- the same vocabulary and the same spelling a pivot's `m=` spec uses, so a
    card can show a median, a spread or a percentile where the chart pages it came
    from could only sum.  `count` is accepted as well: it counts rows and ignores
    the value column.  The function is checked whatever the kind is, so a misspelt
    one is a `400` rather than a chart drawn some other way, as is a function that
    needs a column (`median`, unlike `count`) when the card names no value column
    or names the value menu's "Count (no column needed)".  A combo aggregates both
    its series with the one function.  A card's derived title says which function it
    used (`median(amount) by region`); a plain sum keeps the title it has always
    had.

    A card may bring a cross-row plan of its own in `cross_row`, in the spelling
    the canvas page's `cs`, `by` and `order` use:
    `{ cs => [ _col:fn:name[:arg]_ ... ], by => _col_, order => [ _col:dir_ ... ] }`.
    The card then runs that plan instead of the page's, so one card of a canvas can
    show a running total while the cards beside it show raw rows, and
    `{ cs => [] }` is a card that runs no cross-row pass at all -- which is how a
    card opts out of the page's.  A card that sends no `cross_row` inherits the
    page's plan.  The plan is checked against the canvas's columns on every render,
    not only here, so a saved spec that no longer names a column is that card's
    error while a bad page-level `cs` is the page's `400`.

- `DELETE /api/analyses/:id/visuals/:visual`

    Removes a text card; any other kind answers `400`.  Later cards move down one
    index, and the layout and any `cv=` saved in a bookmark move with them.

- `PATCH /api/analyses/:id/visuals/:visual`

    Changes the columns of one stored visual without removing it.  Body:
    `{ encode, query }`; `encode` replaces the visual's encoding in place (for
    a map, `{ loc }` or `{ lat, lon }`), and the optional `query` is the
    canvas page's query string, read for `cf`, `c` and `p.<name>` so
    the redrawn card matches the page it is on.  The visual keeps its index, so
    its layout position, size and title are unchanged.  The replacement is
    rendered before it is stored, so an unknown column or an undrawable map is a
    `400` and the saved visual is left alone.  Returns
    `{ id, visual, kind, title, html, head, nonce, cf_col }`; `nonce` is the one
    the scripts in `html` carry, which the canvas page gives its own when it runs
    them.

- `DELETE /api/analyses/:id`

    Removes the analysis.  Returns `200 { deleted: 1 }`.

- `GET /api/analyses/:id/export`

    Downloads the analysis document as a `.json` file.

- `POST /api/analyses/import`

    Creates an analysis from an uploaded `.json` file (multipart `file`
    field) or a raw JSON request body.  Caller-supplied `id`, `created`,
    and `updated` are stripped.  "Import canvas", on `/canvases`, sends the file
    that a canvas's Share panel downloads; that panel also makes the read-only
    `/share/:id` link (`POST /api/analyses/:id/share`) and its `/embed/:id`
    code.

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
    is a newline-separated list of raw cell values).  The group column,
    `<col>_group`, appears in the table page as well as in its charts and
    exports.

- `POST /groups/delete`

    Removes a named value group.  Body: `l=&col=&group=`.

- `GET /dates/list`

    Returns `{ patterns: { col: pattern } }` for stored date-normalisation
    patterns.  Accepts `?l=<spec>`.  A column with only a date pattern is
    reported as the pattern string; one with a time part as well is reported as
    `{ date, time }`, plus `as` when the normalised value is filed under a name
    of its own.

- `POST /dates/save`

    Saves a date-normalisation pattern for a column.  Body: `l=&col=&pattern=`,
    plus optional `time=` and `as=`.  Supported patterns: `%m/%d/%Y` (US),
    `%d/%m/%Y` (EU), `%d-%b-%Y` (DD-Mon-YYYY).  With `time=` (`%H:%M` or
    `%H:%M:%S`) the column is normalised to a timestamp, `2026-10-27T14:05:00`,
    which is what `epoch()`, `span()` and a `last_24_hours` range can read;
    `as=` names the column the normalised value is written to (default: the
    column itself).  Without a time part the stored value is the date pattern
    string, unchanged, so no existing store needs migrating.

- `POST /dates/delete`

    Removes a date-normalisation pattern.  Body: `l=&col=`.
    Omit `col=` to clear all patterns for the spec.

- `GET /lookups/list`

    Returns `{ lookups: { name: { file, key, col, fields, default } } }` for the
    stored lookups of `?l=<spec>`; `col`, `fields` and `default` appear
    only when they were given.  See ["Stored lookups"](#stored-lookups).

- `POST /lookups/save`

    Saves a lookup.  Body: `l=&name=&file=&key=`, plus optional `col=`,
    `fields=` and `default=`.  The file is read when it is saved, so a bad one is
    a 400 at once.

- `POST /lookups/delete`

    Removes a lookup.  Body: `l=&name=`.  Omit `name=` to remove every lookup of
    the spec.

- `GET /extract/list`

    Returns `{ extractions: { name: { col, pattern, fields } } }` for the stored
    field extractions of `?l=<spec>`.  See ["Field extraction"](#field-extraction).

- `POST /extract/save`

    Saves an extraction.  Body: `l=&name=&col=&pattern=`, plus optional
    `fields=`.  The pattern is compiled when it is saved, so a bad one is a 400 at
    once.  The reply names the columns it will add: `{ ok: 1, fields: [...] }`.

- `POST /extract/delete`

    Removes an extraction.  Body: `l=&name=`.  Omit `name=` to remove every
    extraction of the spec.

- `GET /geo/list`

    Returns `{ columns: { col: { kind: "lat"|"lon"|"location"|"location_suffix" } } }`
    for the saved coordinate-column preferences of the given `l=` spec, with
    `loc_text` when the text added to each place is remembered too.

- `POST /geo/save`

    Saves a coordinate-column preference.  Body: `l=&col=&kind=`,
    where `kind` is `lat`, `lon`, `location` or `location_suffix`.  `col=` and
    `kind=` may repeat in pairs, so a latitude and a longitude are saved in one
    request, and `replace=1` forgets the spec's saved columns first.  `loc_text=`
    remembers the text added to each place (as `loc_text=` on `/map`, and refused
    as it would be there).  The map panel's "Remember columns" sends all of them,
    so a new choice replaces the old one; its "Forget remembered columns" calls
    `/geo/delete`.

- `POST /geo/delete`

    Removes a coordinate-column preference.  Body: `l=&col=`.
    Omit `col=` to clear all preferences for the spec, and its `loc_text`.

- `POST /geo/lookup`

    Looks up one place for the map page's progress bar, and saves the answer in
    the shared place cache at once.  Body: `place=&sig=`, where `sig` is the
    signature the map page gave the place (any other place is refused with 403),
    plus `online=0` to keep the lookup on this machine.  Returns
    `{ place, status, stored, online_failed, messages }`, where `status` is
    `found`, `not_found`, `held` (not looked up now, and not remembered) or
    `refused`.  See ["Maps"](#maps).

- `POST /geo/boundary`

    Finds the outline of the area around one point, for the map page's progress
    bar, and remembers it at once.  Body: `point=&level=&sig=`, where `level` is
    one that `bounds=` takes,
    `point` is `lat,lon` rounded to three places and `sig` the signature the map
    page gave it (any other point is refused with 403), plus `online=0` to ask
    nothing.  Returns `{ point, status, stored, online_failed, name }`, where
    `status` is `found`, `nowhere` (no such area there, such as the sea) or `held`
    (not settled now, and not remembered).

- `GET /insights`

    Automatic statistical insights for a dataset.  Runs the same pipeline as
    `/join` then detects outliers (Tukey IQR fence), period-over-period deltas,
    top movers, and seasonality (lag-1 autocorrelation).  No LLM or network call
    is made.  Every insight links to a chart or stats view that shows it.
    Parameters: `l=<spec>` (required), repeatable `f=` filters.

- `POST /api/ask`

    Natural language to analysis spec (Phase 5.1).  Body params: `l=<spec>`
    (required), `q=<question>` (required), repeatable `f=` filters.
    Returns `{ spec, url, valid => 1 }` on success.  The model receives only
    column names and types -- never raw row data or file paths.  Returns 503 when
    `ai_api_key` is not configured; 400 for missing params or a question over 500
    characters; 422 for an unparseable or invalid-column spec; 502 for a provider
    error; 429 once the hour's provider calls are used up (`ai_calls_per_hour`,
    below).

    Every call spends `ai_api_key`, so each server process makes at most
    `ai_calls_per_hour` provider calls (default 60; `0` for no limit) in any
    hour, counting `/api/ask` and `/api/summary` together.  Like the other
    routes, both need the login when `password_hash` is set.

- `POST /api/summary`

    Narrative summary of an analysis (Phase 5.3).  Body params: `l=<spec>`
    (required), repeatable `f=` filters, `ai=1` (optional, honours
    `ai_api_key` config).  Returns `{ text, source, cached }`.  Two paths:
    deterministic template sentences (always available, works offline) and
    optional LLM-polished prose when `ai=1` is passed and `ai_api_key` is
    set.  Only aggregate insight facts are sent to the LLM.  Results are cached
    in-process for one hour keyed on the analysis fingerprint.  Once the hour's
    provider calls are used up (`ai_calls_per_hour`), `ai=1` gives the template
    text with `source => 'template_limited'`, not cached.

### Breadcrumbs and Missing Pages

Every page shows where it is: Home, then each page between Home and this one,
then this page, which is not a link.  The trail is read from the page's own
URL -- a chart's `back=`, drilled rows' `back2=`, a file's folder -- and each
step is named from its own URL ("Bar chart: amount by region", "sales (region
&#x3d; North)").  Text from the URL is shown only if it is short and has no markup,
a `back=` to another site or scheme is not followed, and a chain of `back=`
links stops after eight steps.

An address that matches no route, a missing table (`/view/:table`) and a
missing canvas (`/a/:id`) answer `404` with an HTML page that keeps the
breadcrumb and the site navigation.  The JSON API (`/api/...`) still answers
a `404` with a JSON body.

A request that is refused -- a chart of a column the view does not have, a
calculated field that does not compile -- answers `400` with the reason as
plain text.  When a browser asked for the page (a `GET` whose `Accept` names
`text/html`), the reason is shown on the same page as a missing one instead,
with the breadcrumb back to the table and a Back button.  Scripts, `fetch()`
and `/api/...` routes still get plain text or JSON.

### Saved Columns That Cannot Be Applied

Calculated fields, lookups and extractions are saved for a dataset and applied
to every page of it.  When the file changes under one -- a lookup file is
deleted, a column an extraction reads is dropped -- its charts and exports
refuse with the reason.  The table page (`/view`, `/open`, `/join`,
`/combine`) is still drawn: without that dataset's saved calculated fields,
lookups and extractions, with a note that names the one at fault and buttons
that open the panels to correct or delete it.  A mistake in the request's own
`c=` is still a `400`.

### Relative Time Ranges

Every data route accepts a named window in place of a pair of dates:

```
GET /view/sales?range=last_30_days&rcol=sale_date
GET /a/mycanvas?range=this_quarter&rcol=order_date
```

`range=` names the window and `rcol=` names the column it applies to.  The
window is worked out when the request arrives, so a link, a bookmark or a
saved canvas keeps meaning the same thing whenever it is opened rather than the
dates it happened to resolve to when it was written.  The vocabulary is

```
last_24_hours   the 24 hours ending now, to the second
today, yesterday
last_7_days, last_30_days, last_90_days     including today
this_month, last_month
this_quarter, last_quarter
this_year, last_year
```

A `this` period ends today; the completed one is `last_month`,
`last_quarter` and so on.

The range is applied as two ordinary filters on that column --
`col:ge:lo` and `col:le:hi` -- so the table view, every chart, the
pivot, the column statistics, the insights page, the exports and a saved canvas
all show the same rows, and one chip in the toolbar names the window with an
`x` to remove it.  Filters the reader wrote are untouched: the range travels in
the URL as itself, so submitting a panel form or reopening a link does not turn
it into frozen dates.

The table page offers Time range in its filter bar only when one of the columns
on the page holds dates or date-times (`YYYY-MM-DD`, the same with a time after
`T` or a space, or `M/D/YYYY`) in every non-empty cell, and its column menu
lists only those columns.  A range already in force stays in the bar, so it can
be changed or removed.

A window narrower than a day (`last_24_hours`) is compared to the second, so
it is exact only on a column that holds a time as well as a date.  A
day-granular window compared against a column of timestamps covers each day it
reaches in full, which is what a date filter does on its own as well.

The filter bar offers the same windows: choose one and the column it applies
to.  Entries whose window falls entirely outside the data are disabled, with the
column's own earliest and latest value -- from `GET /api/range` -- in the
tooltip, so a window that can only show nothing says so before it is chosen.
An unknown `range=` is a 400 rather than a silently unfiltered view, and a
range with no `rcol=` is a 400 as well.

On a saved canvas the range narrows every card, and a card added while one is
active is drawn through it: `query` in `POST /api/analyses/:id/visuals`
carries `range=`/`rcol=` as it carries `cf=`.

### Time Buckets

The aggregating routes bucket the dimension they already take:

```
GET /bar?l=table:sales&cat=at&val=amount&span=1h
GET /pivot?l=table:sales&rows=at&m=amount:sum:total&span=1mon
GET /view/sales?span=1d&tcol=at
GET /graph?l=table:sales&x=at&y=amount&span=1h&agg=sum&series=region
```

The chart and pivot panels carry a `Time bucket` menu for it, and the line
graph panel an `Aggregate` menu beside it and a `Lines by` menu, which
sends `series=`.

`span=` takes a count and one of `s`, `m`, `h`, `d`, `w`, `mon`, `q`
or `y` -- `15m`, `6h`, `2d`, `3mon`, `1q` -- and is refused, naming the
interval and the parameter, when the count is zero or the unit is not one of
those.  It expands into the calculated field a reader could have typed,
`<col>_span:span(<col>,'1h')`, so there is one pipeline and one set of
semantics; `tcol=` names the column where the route has no single dimension or
names more than one, and `as=` names the bucket column.  `tcol=` without a
`span=`, an unknown column, a name that is already a column and a `span=` that
disagrees with the reader's own calculated field are each a 400.

Labels are ISO at the bucket's own resolution -- `2026-10-27T14:00:00`,
`2026-10-27`, `2026-10-01` -- so they sort chronologically as strings and a
bucketed chart comes out in the right order with no second sort.  `d`, `w`,
`mon`, `q` and `y` are computed from the local calendar, so a daylight-saving
day is one bucket and a leap day is its own date; `s`, `m` and `h` floor the
interval out of the epoch.  A value that cannot be read as a time lands in one
visible `(unparseable)` bucket rather than disappearing.

`agg=` on `/graph` is the timechart: one point per bucket, aggregated with
the measure vocabulary a pivot's `m=` uses (`sum`, `avg`, `min`, `max`,
`count`, `count_distinct`, `median`, `stdev`, `first`, `last`,
`range`, `p<N>`).  Without `agg=` every row is still plotted.

The same bucket is available by hand, because it is a calculated field:
`?c=hour:span(at,'1h')`.  The timestamp functions are `epoch(v[, fmt])`,
`hour(v)`, `minute(v)`, `second(v)` and `span(v, interval)`; see
[Database::BI::Calc](https://metacpan.org/pod/Database%3A%3ABI%3A%3ACalc) for the shapes each reads and the local-time rule.

### Cross-Row Columns

Every data route, `/export` and a saved canvas accept a cross-row plan: a
column worked out from many rows and written beside each one.

```
cs=<column>:<function>:<alias>[:<count>]   repeatable
by=<column>[,<column>...]                  partition (optional)
order=<column>[:asc|desc]                  the order the rows are read in
```

`pct_of_total`, `rank` and `zscore` need no order.  `running_total`,
`running_count`, `running_pct`, `window_sum`, `window_avg`, `lag`,
`delta` and `pct_change` need `order=`; only `window_sum` and
`window_avg` take the `count`, the width of the window.  The pass runs after
the filters and before pagination, so page 2 continues page 1's running total.
An unknown function or column, or a parameter where none is taken, is a 400.
A calculated field can read the new column, as in
`c=half:ytd/2`, and `cs=` can read a calculated field or a time bucket, as in
`span=1mon&tcol=at&order=at_span&cs=amount:running_total:ytd`.  A filter runs
before the pass, so a window is over the rows it leaves, unless it names a
column the pass writes: `f=ytd:gt:50` runs last, and selects rows without
changing their totals.  On a canvas, a card's own filters and a cross-filter
follow the same rule.
The table page's Cross-row panel builds the same parameters.  See
["Cross-row columns" in Database::BI::Controller::Dashboard](https://metacpan.org/pod/Database%3A%3ABI%3A%3AController%3A%3ADashboard#Cross-row-columns) for the full rules.

### Stored Lookups

A lookup adds columns to every row of a dataset from a second file, matched on
one key: a shop code in the orders gains the shop's city and region.

```
POST /lookups/save  l=table:orders&name=shops&file=lookups/shops.csv
                    &key=code&col=shop&fields=city,region&default=unknown
```

`file=` is a data file under `data_dir` (a relative path is read from there),
of at most 8 MiB; a file outside it, a symlink that leads outside it, a URL and
a remote path are refused.  `key=` is the lookup file's key column and `col=`
the dataset's (default: the same name).  `fields=` lists the columns to add
(default: all but the key).  Keys are compared as text after trimming spaces,
and case matters.  When the file has a key twice, the first row is used and the
log says so.  A row whose key is not in the file gets `default=`, or nothing.

A field keeps its own name unless the dataset already has a column of that
name; it is then called `<name>_<field>` (`shops_region`).  A
source column is never overwritten.

The table page's Lookups panel saves, lists and deletes them, and can skip one
in the current view.  Stored lookups apply on every route, a canvas and
`/export`, before calculated fields and filters, so either can read the new
columns.  A total
grouped or filtered by one is worked out in Perl, never sent to SQL.  For one request,
`nolk=<name>` skips a stored lookup, and `lk=<name>` applies
a lookup stored for another dataset.  Both repeat, and the panels carry them on.
A lookup is not a join: for more than one key, or rows that match many rows,
use Merge.

### Accelerated Datasets

A large CSV, TSV, PSV, XLSX or XML file can be read from a SQLite copy of
itself, an _extract_, which is faster to page through and lets totals be
worked out in SQL.  `script/bi-extract --spec table:sales` marks the dataset
accelerated and builds the extract under `<model_dir>/extracts/`, or in
the cache directory set (see ["Where caches are kept"](#where-caches-are-kept)).

An extract is used only while it matches the file: its name is a fingerprint
of the spec and the file's modification time and size.  Once the file changes,
the file itself is read, and the table page says the extract is stale and how
to rebuild it.  Stale numbers are never shown.  The table page also says when
a dataset is read from its extract, and when that was built.

An extract is a cache.  Deleting its folder loses nothing: each accelerated
dataset reads its file until the next build.  Nothing is written under
`data_dir`, and a `model_dir` inside it is refused.  Only a `table:` or
`path:` spec naming a local file can be accelerated; a SQLite file is one
already.  `table:sales` and `path:/data/sales.csv` are separate datasets, each
accelerated on its own.

### Field Extraction

A regular expression can pull values out of a column.  For one value, use
`rx()` in a calculated field:

```
c=country:rx(ref,'^([A-Z]{2})-','1')
```

To make several columns from one pattern, store an extraction.  Each named
group, `(?<name>...)`, becomes a column:

```
POST /extract/save  l=table:invoices&name=parts&col=ref
                    &pattern=^(?<country>[A-Z]{2})-(?<year>\d{4})-
```

`fields=country` keeps only the groups it names.  The table page's Extract
fields panel saves, lists and deletes them.  Stored extractions apply on
every route, a canvas and `/export`, after the lookups and before calculated
fields and filters, so either can read the new columns.  A row the pattern does
not match gets `(unparseable)` in each column, as a calculated field's row
does, so those rows group visibly instead of vanishing; they are not blank.  A
group that took no part in a match is empty.  Columns are named as a lookup's
are: the group's own name, or `<name>_<group>` when the
dataset has a column of that name.  A capture is cut to 200 characters.

A pattern is refused when it is over 200 characters, when it does not compile,
or when it uses `(?{`, `(??{`, `(?p` or `(*`, which run code or steer the
engine.  These checks are not a sandbox.  Perl's regular expressions have no
timeout, so a pathological pattern such as `(a+)+$` stalls the request that
uses it.  Patterns are entered by whoever runs the server, never by a remote
party.  See ["Regular expressions" in Database::BI::Calc](https://metacpan.org/pod/Database%3A%3ABI%3A%3ACalc#Regular-expressions).

## Configuration

Place a `database_bi.conf` file in the application root to override
defaults:

```perl
{
    data_dir => 'data',   # directory scanned for data files on the home page
    uploads_dir => '.uploads',  # staging directory for uploaded files
    platform => 'web',    # VWF template dimension
    language => 'en',     # VWF template dimension

    # Browser-side libraries.  d3_url overrides the chart and canvas
    # script; the leaflet_* keys override the map assets, and tile_url
    # overrides the tile server.  See "Self-hosting D3 and Leaflet"
    # below.
    d3_url => 'https://cdnjs.cloudflare.com/ajax/libs/d3/7.9.0/d3.min.js',
}
```

`uploads_dir` is where `POST /upload` stages the files a user drags onto the
page, and the directory `POST /uploads/clear` empties.  It defaults to
`.uploads` under the application home.  A relative value resolves against the
application home, an absolute one is used as given, so a deployment whose
application directory is read-only can stage uploads somewhere writable:

```perl
{ uploads_dir => '/var/tmp/database-bi-uploads' }
```

### Where Caches Are Kept

The places OpenStreetMap found for maps, the extracts of accelerated datasets
(see ["Accelerated datasets"](#accelerated-datasets)), the page cache when `page_cache_dir` turns it
on, and the table cache when `cache => { driver => 'File' }` (or
`FastMmap`) asks for one, are kept on disc.  Each object that keeps one
chooses its directory when it is made ([Database::BI::CacheDir](https://metacpan.org/pod/Database%3A%3ABI%3A%3ACacheDir)), from the
first of these that is set:

- 1. `cache_dir` through [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure), for the class making the
cache: its config files, then the environment variable
`<Class>__cache_dir` (`Database__BI__Model__Geocode__cache_dir` for
the places, `Database__BI__Extract__cache_dir` for the extracts,
`Database__BI__cache_dir` for the page and table caches);
- 2. `$ENV{CACHEDIR}`;
- 3. `$ENV{CACHE_DIR}`;
- 4. `cache_dir` here (relative: under the application home):

    ```perl
    { cache_dir => '/var/cache/database-bi' }
    ```

- 5. `<model_dir>/geocode-cache` for the places,
`<model_dir>/extracts` for the extracts, `page_cache_dir` for the
page cache, `<model_dir>/cache` for the table cache.

Caches sharing a directory each keep to their own namespace in it; the
extracts go in its `database-bi-extracts/` folder.  A cache directory inside
`data_dir` is not used for the extracts, which then stay in `model_dir`: each
is a `.db` file the home page would list.  `page_cache_dir` still decides
whether pages are cached at all (see ["Compression and the page cache"](#compression-and-the-page-cache)): a
cache directory set only says where.  A `cache => { root_dir }` names the
table cache's directory outright.  `script/bi-geocode` and
`script/bi-extract` read the same settings, and `database_bi.conf` from
`MOJO_CONFIG` or the current folder (`bi-extract` through the application).

### Who Can Reach the Server

A server started by `script/database-bi` (with no arguments, a database, or
`daemon` or `prefork`) listens on `http://127.0.0.1:3000`, so only this
machine can reach it: unless a password is set (see ["Logging in"](#logging-in)), there
is no login, and Mojolicious on its own would listen on every interface.
`listen` changes that:

```perl
{ listen => 'http://127.0.0.1:8000' }             # another port, still this machine only
{ listen => 'http://*:3000' }                     # every machine that can reach this one
{ listen => ['http://127.0.0.1:3000', 'http://[::1]:3000'] }  # IPv6 loopback too
```

It takes a location, several separated by commas, or a list.  A location
that is not `http://` or `https://` stops the start.  `MOJO_LISTEN` and the
`-l` option of `daemon` and `prefork` still win over it.
`morbo script/database-bi` opens its port before it loads the application, so
it does not read `listen`; give it `-l`, or run `script/database-bi`.

Anywhere but this machine needs a password: a `listen` (or `MOJO_LISTEN`, or
`-l`, or under hypnotoad its own `listen`) that is not loopback stops the start
unless `password_hash` is set (see ["Logging in"](#logging-in)).  The message says what to
change.  The defaults are loopback, so they start as before.

`hypnotoad` reads its own `hypnotoad => { listen }`, which defaults to
`http://127.0.0.1:8080`, this machine only:

```perl
{ hypnotoad => { listen => ['http://*:8080'] } }  # every machine
```

Behind a reverse proxy on the same machine, leave both at their defaults.  The
proxy can still bring other machines' requests in, so without a password a
request from an address that is not loopback is refused (`403`), including one
a trusted proxy names in `X-Forwarded-For`.  For the public, set a password.

**This machine is not one person.**  Loopback keeps other machines out, not
other people on this one: any account on the same machine, or a container that
shares its network, can reach `127.0.0.1:3000`, and read, list and save files
as the account running the server.  On a machine with other users, set a
password even when it listens on this machine only.

### Which Folders It May Use

`/browse`, `/open`, the Export panel's folder list (`/api/dirs`), a `path:`
data source anywhere (a table, a chart, a merge, a canvas card) and
`POST /export` reach the whole filesystem, as far as the account running the
server can.  `file_roots` fences them in:

```perl
{ file_roots => ['/srv/reports', 'shared'] }   # 'shared' is under the application home
```

`data_dir` and `uploads_dir` are always among them.  Browsing starts at the
home folder if it is inside, else at the first root, and stops at the roots.  A
folder or file outside is refused (`403`, or a `path:` source is not found),
whether or not it is there, so the refusal says nothing about what is outside;
a link inside that leads outside is outside.  A path that climbs out with `..`
past what exists is refused too.  A root that is not a folder that exists stops
the start.  Remote files (`/../host/...`), Redis and MariaDB are not files on
this machine, and are not affected; neither are the command-line tools.

Saving is the riskier half: an export replaces a `.csv`, `.json` or `.sql`
file of the same name, and some such files are settings another program obeys
(a project's `package.json` names commands that `npm` runs).  A server other
people use keeps exports to folders of their own, so with `password_hash` set,
`export_dirs` is required, and the start stops without it:

```perl
{ export_dirs => ['/srv/reports/exports'] }   # a relative one is under the application home
```

`POST /export` then saves only in them (or below them), and the Export panel
opens on the first and lists no other.  Reading is unaffected: that is
`file_roots`.  An export folder that does not exist, is outside `file_roots`
or is a dot-folder stops the start.  Whatever is set, an export never replaces
a link, a folder or anything else that is not a plain file, so a link inside
the allowed folders cannot carry it outside them; it is written beside its name
and renamed into place, so nobody reads half a file, and a file it replaces
keeps its permissions.

### Requests From Other Sites

Unless a password is set (see ["Logging in"](#logging-in)), there is no login: whatever can
reach the server can read any file it can (`/open`) and write exports into
any folder it can (`POST /export`).  Even with one, a logged-in reader's
browser carries the login to every request it sends here.  Listening
on this machine only keeps other machines out, but not the pages of other
sites open in the reader's browser.  So every request is checked first, and
refused with `403` when another site's page made it:

- A write (any method but `GET`, `HEAD` and `OPTIONS`) is refused when
the browser's `Sec-Fetch-Site` says it came from another site, or, without
that header, when its `Origin` is not this server.  A form posted from
another site needs no permission from this one, so this is what stops it.  A
script such as `curl` sends neither header and is let through.
- Any request is refused when its `Host` is a name other than
`localhost` or `*.localhost`, and is not an IP address.  A page whose own
name has been made to resolve to `127.0.0.1` (DNS rebinding) counts as this
server to the browser, but it still sends its own name.  To reach the server
by a name, list it:

    ```perl
    { allowed_hosts => ['bi.example.com', '*.corp.example'] }   # '*' for any name
    ```

    Behind a trusted reverse proxy, the `Host` is whatever the proxy sends, so it
    is checked only when `allowed_hosts` is set; set it there too.

`POST /export` also refuses a folder or file whose name starts with a dot
(`~/.config`, `.vscode/settings.json`), since those hold other programs'
settings.  The folder list in the Export panel leaves them out already.

### Which Addresses It May Fetch

`/import` and a `url:` data source make the server fetch a URL, so a page
could point it at what only the server can reach: a service on this machine, a
database on the office network, or a cloud's metadata service on
`169.254.169.254`, which hands out its credentials.  So the server refuses a
URL that leads to this machine, a private or shared network
(`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10`,
`fc00::/7`), link-local addresses, multicast or a reserved range.

It is what the name _resolves to_ that counts, not how the URL reads:
`http://localtest.me/` and `http://127.0.0.1.nip.io/` are names whose DNS
answers `127.0.0.1`, and `http://2130706433/` or `http://0x7f000001/` are
`127.0.0.1` written another way; all are refused.  An address is looked up
once, checked, and that address is the one connected to, so a name that answers
differently the second time (DNS rebinding) gains nothing.  Each redirect is
checked the same way, and at most 5 are followed.  Over `https` the
certificate must still be the site's.  The refusal says why, for example
`localtest.me is 127.0.0.1, which is this machine`.

To read from an intranet site, name it:

```perl
{ url_private_hosts => ['reports.corp.example', '*.corp.example'] }
```

Those names may resolve to a private address; every other name is still
checked, and an address written as such (`http://10.1.2.3/`) is never let
through.  A name that is not a host name, or `*` alone, stops the start.
This check is not a firewall: where the server's machine can reach something it
should not, rules on outgoing connections are the stronger defence.

### Logging In

With `password_hash` set, every page asks for a password first.  A server
other machines can reach must have one (see ["Who can reach the server"](#who-can-reach-the-server)); on
this machine alone it is optional.  Make the line with

```
script/database-bi password
```

which asks for the password twice (without showing it) and prints

```perl
password_hash => 'pbkdf2-sha256$200000$...',
```

to put in `database_bi.conf`.  Only the hash is kept: PBKDF2-HMAC-SHA256 with
a random salt ([Database::BI::Password](https://metacpan.org/pod/Database%3A%3ABI%3A%3APassword)).  A plain password there stops the
start, so it is never left in the file by mistake.  To change the password,
make a new line; every session is then logged out.

There is one password, not one per person.  A browser asking for a page is
sent to `/login` and, once the password is right, back to that page; any other
request (a script, a panel's request, a download) gets `401` until it carries a
logged-in session.  `POST /logout`, the Log out button at the top of each page,
ends it.  `/share/:id` and `/embed/:id` need no login: their signed, expiring
token is their permission, so anyone holding the link sees that canvas, and
only that one, for 30 days.  The canvas itself (`/a/:id`) and the rest still
ask for the password.

The token is signed with `share_secret` when it is set (at least 16
characters), else with a key derived from `secrets`.  Without either, the key
is new at each start, so a restart ends every share link, and the Share panel
says so; set `secrets` (which keeps logins too) or `share_secret` to keep
them.  Changing either ends the links made with the old one.  Before 0.021.0 a
missing `share_secret` meant a fixed key, the same on every install, with which
anyone could sign a link to any canvas; that key in `share_secret` stops the
start.

```perl
{
    password_hash    => 'pbkdf2-sha256$200000$...',
    export_dirs      => ['/srv/reports/exports'],   # required with a password
    login_expiration => 8 * 60 * 60,   # seconds idle before logging out; the default
    secrets          => ['a long random string'],  # or each restart logs everyone out
}
```

The session is a cookie signed with `secrets`: `HttpOnly`, `SameSite=Lax`,
and `Secure` whenever the request came over https (directly, or through a
trusted proxy that says so), so it is never sent back over plain http.  Over
plain http anyone on the network path can read the password and the cookie: a
server other machines reach should be behind https.  Ten wrong passwords from
one address within 15 minutes lock that address out for the rest of the 15
minutes (`429`); each server process counts its own.

### MariaDB and MySQL Servers

A server is opened by name.  Each entry of `mariadb_servers` is one database:

```perl
{
    mariadb_servers => {
        shop => {
            host     => 'db.example.com',  # default: localhost
            port     => 3306,              # optional
            database => 'shop',            # required
            username => 'bi_reader',
            password => 'secret',
        },
    },
}
```

The home page then has a card for each name, leading to the list of its tables.
`mariadb:shop/orders` opens one anywhere a source is taken: the path field, `l=`,
`j=`, `c=` and a canvas's `datasets`.  `mariadb:shop` lists them.

The spec holds a name and no more, because a spec travels in URLs, bookmarks,
shared links, saved canvases and server logs.  So the password stays in the
configuration file, which should be readable only by the account that runs the
application, and no request can point the application at another server.

[DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) is recommended; [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) serves if it is the one installed.
Without either, opening a server says so and the rest of the application is
unaffected.  Rows are read from the server each time, and never cached.  The tests
are `t/mariadb.t`, which mocks the server, and `t/mariadb_live.t`, which runs when
`MARIADB_SERVER` is set, for example to `mariadb://user:pass@host/test`, and which
creates its own tables and drops them.

### Compression and the Page Cache

Every response goes through [Mojolicious::Plugin::Buffer](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer): it is compressed
(gzip or Brotli, as the browser accepts), HTML whitespace is minified (inline
scripts and styles are left alone), and a `200` to `GET` or `HEAD` carries
an `ETag`, so a repeat request can be answered `304 Not Modified`.  There
is no `Last-Modified`: the plugin would date a page by the code, not the data,
which lets a browser reuse a stale reply without asking.  File
downloads (`/export` as CSV, SQLite or JSON, the pivot as XLSX, and a canvas
card's data from `/a/:id/visual/:n/:fmt`) opt out and are sent as they are.

Two optional keys keep finished pages on disc:

```perl
{
    page_cache_dir      => '/var/cache/database-bi',  # relative: under the application home
    page_cache_duration => '5 minutes',               # the default
}
```

When `page_cache_dir` is set, `/catalog` and `/tutorial` are stored in a
[CHI](https://metacpan.org/pod/CHI) File cache there (or in the cache directory set: see
["Where caches are kept"](#where-caches-are-kept)), one copy per `Accept-Language`, and served from it
until they expire.  No other page is cached, because the rest read data files
that can change between requests.  Without the key nothing is cached.

### Self-Hosting D3 and Leaflet

The chart pages load D3 from a public CDN by default, and the map pages load
Leaflet and leaflet.markercluster from unpkg.  A deployment with no outbound
network access, or one that prefers to serve its own assets, sets the URLs in
`database_bi.conf`:

```perl
{
    d3_url                          => '/static/d3/d3.min.js',
    leaflet_js_url                  => '/static/leaflet/leaflet.js',
    leaflet_css_url                 => '/static/leaflet/leaflet.css',
    leaflet_cluster_js_url          => '/static/leaflet/leaflet.markercluster.js',
    leaflet_cluster_css_url         => '/static/leaflet/MarkerCluster.css',
    leaflet_cluster_default_css_url => '/static/leaflet/MarkerCluster.Default.css',
    tile_url                        => 'https://tiles.internal/{z}/{x}/{y}.png',
}
```

An absolute path is served like any other static file: put the library under
the application's `public/` directory, so `/static/d3/d3.min.js` is
`public/static/d3/d3.min.js`.  The five Leaflet keys may be set on their own;
any left out keeps [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM)'s pinned CDN URL.  Use a path beginning with
`/`, or a full URL; a path without the leading slash is relative to the page.  The versions to copy are the
ones the defaults name: D3 7.9.0, Leaflet 1.9.4, and leaflet.markercluster 1.5.3.
`tile_url` points the map layer at a self-hosted tile server instead of
OpenStreetMap.  It keeps Leaflet's `{z}`, `{x}` and `{y}` placeholders, and
`{s}` too if the server uses subdomains.  Set it, and `map_geocode_online`
to 0, and every request needed to draw a map can stay on the local network.  The OpenStreetMap attribution stays
on the map, since it is the usual credit for OSM-derived tiles.  There is no
in-page place search: [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) is always constructed with `search => 0`,
so nothing typed on a map page is sent anywhere.

Map-specific config keys: `map_geocode_max` (new geocoder lookups per request,
default 500), `map_geocode_online` (0 keeps geocoding on this machine: a place
the local data does not know is not sent to OpenStreetMap's Nominatim, nor a
marker's position for its outline; default 1), `map_geocode_online_max`
(places, and outlines, asked of Nominatim per request, default 20;
at one a second, the rest are left for the next request or for
`script/bi-geocode`; the map page's progress bar asks one place a request, so
it reaches every place), `secrets` (a list; the first signs the places a map
page lists for `POST /geo/lookup`.  Without it each start makes a random one), `map_max_markers` (markers per request, default 2000), `map_popup_rows`
(rows listed in one marker's popup, default 10),
`map_region` (a two-letter country hint for ambiguous places),
`map_bounds_ranks` (the place rank that is a county, by country; see above), `map_max_zoom`
(the default tile-layer maxZoom) and `tile_sources` (a hashref of named tile
sources, each `{ url => ... }`, selected with `tiles=`).

**Map colour rules.**  `color=` names the column and `color_rule=` supplies
`<op>:<value>:<colour>` rules; they are tried in
the order given and the first match wins.  The operators are `gt`, `ge`,
`lt`, `le`, `eq` and `ne`; a comparison is numeric when both the cell and
the rule's value look like numbers, and otherwise only `eq`/`ne` are
meaningful (case-insensitive).  A colour is `#rgb`, `#rrggbb` or a CSS name
such as `red` or `teal`.  A value that matches no rule gets `color_default=`,
which the legend shows as "Other".  `series=` is the categorical
alternative: each distinct value takes the next colour from `scheme=`,
cycling through the palette, and the legend lists the categories.  `color=`
and `series=` are mutually exclusive.

### Content-Security-Policy

Every HTML page is sent with a `Content-Security-Policy` header.  The pages
show cells from files this application did not write, so the policy backs up
the escaping.  Scripts, stylesheets and images may come only from this site
and from the hosts that `d3_url`, the `leaflet_*_url` keys, `tile_url` and
`tile_sources` name.  The defaults allow cdnjs.cloudflare.com, unpkg.com and
OpenStreetMap's tile servers.  A page's scripts may talk only to this site
(`connect-src 'self'`), and no other site may show a page in a frame
(`frame-ancestors 'self'`).  JSON replies and downloads carry no policy.

Every HTML page also carries `X-Frame-Options: SAMEORIGIN`, whatever the
policy keys below say.  A report-only policy only reports `frame-ancestors`,
a policy written out in full may leave it out, and older browsers read only
this header, so framing by another site is refused in each of those cases.

Every reply carries `Referrer-Policy: strict-origin-when-cross-origin`.  A
request a page starts sends its whole URL to this site, only the origin to
another, and nothing from https to http.  Specs, filter values and share
tokens travel in the query string, and an older browser's default would send
all of it to the CDNs, the tile servers and any site a reader follows a link
to.  It is not `no-referrer`, because OpenStreetMap's tile policy asks pages
for a `Referer`.

Every reply also carries `X-Content-Type-Options: nosniff`, so a browser
takes it for what its `Content-Type` says and never guesses.  A guess could
read a CSV export, or text from a data file, as HTML or script.  A
self-hosted library under `public/` keeps working, because Mojolicious names
`.js` and `.css` files for what they are; one served some other way must be
sent as `text/javascript` or `text/css`, or the browser will not load it.

Every page carries `Cross-Origin-Opener-Policy: same-origin`: a window that
another site opened, or that a page opened on another site, gets no handle on
the page through `window.opener`.  No page opens a window or reads an
opener, and every link to a new window is `rel="noopener"`.
`cross_origin_opener_policy` sets another of `same-origin`,
`same-origin-allow-popups`, `noopener-allow-popups` and `unsafe-none`, or
`''` or `0` for none; any other value stops the application at startup.  No
`Cross-Origin-Embedder-Policy` is sent: it would refuse the libraries and
tiles the CDNs and OpenStreetMap serve, and nothing here needs the isolation
it gives.

Every reply carries a `Permissions-Policy` that turns off the browser
features no page uses: the camera, the microphone, location, payment, USB,
serial and HID devices, screen capture, full screen, reading the clipboard and
the rest, for this site and any frame it holds.  Writing to the clipboard
stays (`clipboard-write=(self)`), for the Copy link buttons.  A script that
got in cannot ask the reader for any of them.  `permissions_policy` replaces
the value (`''` or `0` for none); one that cannot be a header value stops
the application at startup:

```perl
{ permissions_policy => 'camera=(), geolocation=(self)' }
```

A reply to a request that came over https carries
`Strict-Transport-Security: max-age=31536000`, so the browser comes back over
https for a year.  It binds this host only; set `strict_transport_security`
to add `includeSubDomains` or `preload`, which reach every site of the
domain and are hard to take back, or to `''` or `0` to send none.  A value
a browser would not read stops the application at startup:

```perl
{ strict_transport_security => 'max-age=63072000; includeSubDomains' }
```

Over http no such header is sent, since a browser ignores it there, and none
is sent to `localhost` or to an IP address: it binds the host, not the port,
so from `https://localhost:8443` it would send every other server on that
machine to https, and browsers ignore it for an address.  Behind a proxy that
ends TLS, a request is https only when Mojolicious is told to trust the proxy
(`MOJO_REVERSE_PROXY=1`, or `hypnotoad => { proxy => 1 }`) and the proxy
sends `X-Forwarded-Proto: https`; otherwise the proxy must send the header
itself.

An inline script runs only if it carries the request's nonce, a random value
made for each request and named in the policy (`'nonce-...'`).  Every
`<script>` the templates write carries it, and so do those that
[HTML::D3](https://metacpan.org/pod/HTML%3A%3AD3) (0.30 or later) and [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) (0.14 or later) write, because
the application passes it to them.  A script that came in with a cell's text
cannot know it, so it does not run; nor does an `onclick` or `onerror`
attribute, which no nonce can cover, so the pages use none.  Style attributes
are still allowed (`style-src 'unsafe-inline'`).

A canvas card added without a reload arrives as JSON with the nonce its
scripts were written with.  The page runs only the scripts that carry it, and
gives each the page's own nonce.  A page kept in the page cache is stored with
its header, so the nonce in each still matches when it is served again.

Two keys change the policy:

```perl
{
    content_security_policy_report_only => 1,  # report breaches, block nothing
    content_security_policy => "default-src 'self'; script-src 'self' 'nonce-{nonce}'",
}
```

`content_security_policy` is the whole policy, sent as written except that
`{nonce}` becomes the request's nonce; without it no inline script runs.  Set
to `''` or `0` it sends no header.  A policy written out in full is not
updated when the library keys change.

#### Embedding a Canvas on Another Site

By default only pages of this site may show `/embed/:id` in a frame.
`embed_frame_ancestors` names other sites that may:

```perl
{ embed_frame_ancestors => [ 'https://intranet.example.com', 'https://*.corp.example' ] }
```

Each entry is an origin: `http` or `https`, a host (a `*` may stand for its
first label only) and an optional port, with no path.  Anything else stops the
application at startup, because a security setting that does not do what it
says should not be dropped quietly.  The sites are added to that page's
`frame-ancestors`, and to no other page's.  With a report-only policy, with
none, or with one written out without `frame-ancestors`, the page carries a
second, enforced policy of `frame-ancestors` alone, so naming one site never
lets every site in.  A policy written out with its own `frame-ancestors` is
left to say who may.  `X-Frame-Options: SAMEORIGIN` stays: browsers that know
`frame-ancestors` follow it instead, and those that know only the older
header refuse the frame.  The canvas's Share panel names the sites its embed
code works on.

## Methods

### Startup

Called once by Mojolicious when the application is loaded, by
`script/database-bi`, `morbo`, `hypnotoad` or `Test::Mojo->new('Database::BI')`.
It is not called directly.

#### Api Specification

##### Input

```perl
    $self   # the Database::BI application object
```

Configuration comes from `database_bi.conf` in the application home, if it is
there (see ["CONFIGURATION"](#configuration)), or from the hashref given to
`Test::Mojo->new('Database::BI', { ... })`.  Unset keys default to
`data_dir => 'data'`, `platform => 'web'`, `language => 'en'` and the
public D3 URL.

##### Output

Nothing useful is returned.  By the time it returns, the application has:

- the login session ([Database::BI::Sessions](https://metacpan.org/pod/Database%3A%3ABI%3A%3ASessions)), and `require_login` in
front of every route but the login, share and embed links (see
["Logging in"](#logging-in)); a `password_hash` that is not a hash, or a `login_expiration`
under 60 seconds, croaks; so does a `listen` other machines could reach when
there is no password, and a password without `export_dirs`;
- a `file_roots` that is not a list of folders that exist croaks (see
["Which folders it may use"](#which-folders-it-may-use)); so does a `url_private_hosts` that is not a
list of host names (see ["Which addresses it may fetch"](#which-addresses-it-may-fetch));
- the `before_dispatch` hook that refuses requests from other sites (see
["Requests from other sites"](#requests-from-other-sites)); an `allowed_hosts` that is not a list of host
names croaks;
- `MOJO_LISTEN` set from `listen` (default `http://127.0.0.1:3000`) when it
was unset, and `hypnotoad => { listen }` defaulted to `http://127.0.0.1:8080`
(see ["Who can reach the server"](#who-can-reach-the-server)); a `listen` that is not a location croaks;
- a 50 MiB limit on request bodies (an upload over it is answered `413`);
- Template Toolkit registered as handler `tt`, and the Buffer plugin
(see ["Compression and the page cache"](#compression-and-the-page-cache));
- the CHI cache for tables (the `Memory` driver unless `cache => { driver }`
names another; a `File` or `FastMmap` one is kept where ["Where caches are kept"](#where-caches-are-kept)
says), and the page cache when `page_cache_dir` is set;
- the `before_dispatch` hooks for relative time ranges, cross-row plans and
the view context, and the `before_render` hook that sets the breadcrumb, the help link
and the HTML 404 page;
- every route in ["ROUTES"](#routes).

A configuration file that does not parse makes the `Config` plugin croak, and
the application does not start.

## Command-Line Tools

The scripts in `script/` are installed with the distribution, each with a
manual page (`man bi-extract`, `man bi-geocode`, `man bi-alert`,
`man database-bi`).  The maintenance scripts use the same data and model
directories as the web application, found from the folder they are run in or
given with `--data-dir` and `--model-dir`, and are safe to run from cron.

### Script/Database-Bi Password

Asks for a password (twice, without echo, at a terminal; once from a pipe) and
prints the `password_hash` line for `database_bi.conf`.  See ["Logging in"](#logging-in).

### Script/Bi-Geocode

Warms the shared geocode cache for one column, so later map requests make no
lookups:

```
./script/bi-geocode --spec table:customers --col city \
                    [--text TEXT] [--data-dir DIR] [--model-dir DIR] \
                    [--openaddr PATH] [--region CC] [--dry-run] [--verbose]
```

`--text` is the map panel's _Add to each place_ (`loc_text=`): with
`--col county --text 'Virginia, USA'` it looks up `Accomack, Virginia, USA`,
the place the map then asks for.

It is idempotent: a second run against a warm cache resolves nothing and says
so.  Exit status is 0 on success, 1 when the column is missing or no rows load,
and 2 on bad arguments or an unopenable source.

### Script/Bi-Extract

Builds the extracts of accelerated datasets (see ["Accelerated datasets"](#accelerated-datasets)):

```
./script/bi-extract --spec table:sales [--spec ...]   # accelerate, and build
./script/bi-extract --all                             # rebuild every one
./script/bi-extract --remove --spec table:sales       # stop, and remove its extract
./script/bi-extract --list
                    [--data-dir DIR] [--model-dir DIR]
```

It prints a line for each extract it builds: the rows, the columns, the file
and the time.  Exit status is 0 on success, 1 when an extract could not be built
(the others still are), and 2 on bad arguments.  Run `--all` from cron after
the data files are refreshed.

### Script/Bi-Alert

Reports one or more saved analyses, and turns a crossed threshold into a
non-zero exit status so cron can act on it:

```
./script/bi-alert --analysis ID [--analysis ID ...] \
                  [--threshold MEASURE:OP:VALUE] \
                  [--threshold ANALYSIS:MEASURE:OP:VALUE ...] \
                  [--suppress DURATION] [--state-file PATH] [--recovery] \
                  [--notify-cmd COMMAND] \
                  [--data-dir DIR] [--model-dir DIR] [--dry-run]
```

The digest goes to STDOUT and nothing leaves the machine unless
`--notify-cmd` says where: otherwise pipe it into mail, a webhook or a ticket
creator yourself.  Exit status is 0 when nothing is announced, 1 when a
threshold is crossed and announced, 2 on error, and 3 when a crossing that was
announced has ended and `--recovery` was asked to announce that.  `--dry-run`
reports without recording anything against the throttle and without running the
delivery command.

Both of those options may be repeated, so one run can watch several analyses
and several measures:

```
./script/bi-alert --analysis abc123 --analysis def456 \
                  --threshold count:gt:1000 \
                  --threshold def456:sum:lt:50 --suppress 1h
```

A threshold with no analysis prefix belongs to the first `--analysis`; the
`ANALYSIS:MEASURE:OP:VALUE` form names another of those listed.  Each analysis
is reported in full, and each (analysis, threshold) pair is a check of its own:
it prints its own line, keeps its own entry in the state file, and is throttled
and recovered on its own schedule.  One crossing never silences, recovers or
delivers another.  When a run announces both a crossing and a recovery it exits
1, so a threshold that is still crossed is not reported as an all-clear.

`--suppress` throttles a threshold that stays crossed, so a condition that is
still true on the next cron run is not reported as news again: it takes a
duration (`30s`, `15m`, `6h`, `2d`, `1w`, or a bare number of seconds), the
first crossing is announced, and repeats inside the period are not.  The
throttle is one small JSON file, `alerts-state.json` in the model directory
unless `--state-file` names elsewhere, keyed by analysis and threshold and
written atomically.  It is kept only when `--suppress` is used or such a file
already exists, so with no `--suppress` the script is as stateless as it has
always been and writes nothing.

A run inside the period prints `THRESHOLD SUPPRESSED` and exits 0: it is not
announcing anything, so a cron wrapper keyed on the exit status stays quiet.
When the crossing ends the run prints `THRESHOLD CLEARED` once and drops its
entry, which means the next crossing is announced immediately instead of
waiting out a period that belonged to an incident that is over.  A state file
that cannot be read is reported and treated as empty, so a damaged file costs
one repeated alert rather than silence, and `--dry-run` records nothing, so a
rehearsal cannot use up the alert a real run depends on.

`--recovery` announces that ending instead of merely reporting it: the run
prints `THRESHOLD RECOVERED` and exits 3, so a wrapper that mails on any
non-zero status mails the all-clear as well as the alert, and a wrapper that
should not is a wrapper that does not pass `--recovery`.  The recovery goes
through the same state file, which is what makes it possible: an entry is the
record of a crossing that was announced, so finding one is what tells the run
that an incident has ended rather than that a threshold was never crossed.  It
is therefore said once per crossing and only for a crossing somebody was told
about, which is also why `--recovery` keeps that file even with no `--suppress`
to throttle.  The recovery names both dates -- `crossed since` and `cleared`.

`--notify-cmd` delivers the announcement itself, so a cron line is one command
rather than a shell wrapper around this one:

```
./script/bi-alert --analysis abc123 --threshold count:gt:1000 --suppress 1h \
    --recovery --notify-cmd 'mail -s "$BI_ALERT_SUBJECT" oncall@example.com'
```

The command runs once per run, through the shell, and only when something is
announced: a crossing (exit 1), or its end with `--recovery` (exit 3).  A
suppressed repeat, an uncrossed threshold, an error and a `--dry-run` run it
not at all, and twenty checks still send one mail.  The whole run's text arrives
on standard input, and three variables say what it is -- `BI_ALERT_EVENT`
(`crossed` if any crossing was announced, otherwise `recovery`),
`BI_ALERT_SUBJECT` (the verdict line when one thing was announced, otherwise a
count such as `2 threshold crossings, 1 recovery`) and
`BI_ALERT_MESSAGE_FILE` (the same text in a file, for a command that has to
post a body: `curl -d @$BI_ALERT_MESSAGE_FILE ...`).  A delivery that fails is
reported on STDERR and leaves the exit status alone, but the announcements are
not recorded, so the next run announces them again rather than the alert being
lost for the rest of the period.

`script/database-bi` is the web application launcher: run with no arguments it
starts the reloading development server, with the name of one database it does
the same and shows that database, with a command word it runs that command, and `hypnotoad script/database-bi` starts a preforking server (see
["SYNOPSIS"](#synopsis)).

## Common Pitfalls

- **The launcher's shebang must name perl, not morbo**

    morbo starts the application as `perl script/database-bi daemon`, and perl
    hands a script whose `#!` line does not mention perl to the interpreter that
    line names.  With a `morbo` shebang every worker therefore started another
    morbo: the chain grew a process a second, kept the listening port, and only
    stopped when the environment copied to each child was too large for `exec`
    (`Argument list too long`).  The shebang is perl and the script starts the
    server itself when it is given no arguments.

- **The launcher's last statement must be its call to start\_app**

    `hypnotoad` loads the launcher instead of running it, with no arguments, and
    takes the value of its last statement as the application.  So the launcher must
    start the development server only when `MOJO_APP_LOADER` is not set, and must
    not end in `1;`.  Otherwise `hypnotoad script/database-bi` hangs in a
    development server or refuses to start.

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
    the first of `export_dirs` (if set, as its real path), `~/Downloads` (if it exists), then
    `$HOME`, then the system temp directory.
    This value is fixed for the life of the process.  Renaming or creating
    `~/Downloads` after the server starts has no effect.  To force a different
    default, set it before starting:

    ```perl
    { data_dir => 'data' }   # and create ~/Downloads before starting the server
    ```

- **Adding a new language requires a template directory, not just a config change**

    Setting `language => 'de'` in `database_bi.conf` tells the controller
    to look for templates in `templates/web/de/`.  If that directory does not
    exist, the controller automatically falls back to the default language, and
    the same fallback applies when a browser asks for a language no directory
    serves.  To add German support: (1) create `templates/web/de/`, (2) copy and
    translate the `.html.tt` files from `templates/web/en/`, then (3) set the
    config.

    A directory may also name a region, as `templates/web/en-us/` does: a browser
    whose Accept-Language asks for that region (`en-US`) gets it, and every other
    request for the language (`en-GB`, `en-CA`, plain `en`) gets
    `templates/web/en/`.  `language => 'en-us'` makes it the default.

    The distribution ships `en` (British English) and `en-us` (American
    English).  `en-us` is not edited by hand: it is made from `en` by
    `author/make-en-us`, which respells the prose (colour, centre, summarise) and
    leaves the names the code reads alone.  Run it after changing an `en`
    template; `t/en-us.t` fails until the two agree.

    The server's messages (errors, warnings, refusals) follow the same choice.
    [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) picks the language from the request's `Accept-Language`, or,
    for the command-line scripts, from the locale (`LANG=en_US.UTF-8`), and
    [Database::BI::I18N](https://metacpan.org/pod/Database%3A%3ABI%3A%3AI18N) gives each message in it.  A translation is a module,
    [Database::BI::I18N::en\_us](https://metacpan.org/pod/Database%3A%3ABI%3A%3AI18N%3A%3Aen_us) for American English, listing only the messages
    that read differently; `t/i18n.t` fails when a British message needs an
    American spelling it does not list.  The tutorial's text is still in British
    English.

- **Supported data file extensions are: csv, db, sql, sqlite, sqlite3, xml, psv, tsv, xlsx, json**

    The application recognises `.csv`, `.db`, `.sql`, `.sqlite`, `.sqlite3`,
    `.xml`, `.psv`, `.tsv`, `.xlsx` and `.json` files.  All three SQLite extensions
    (`.sql`, `.sqlite`, `.sqlite3`) are treated identically -- `inventory.sqlite`
    and `inventory.sqlite3` are both opened as SQLite databases without renaming.
    Excel `.xlsx` files are read by [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction), using
    `Spreadsheet::ParseXLSX`.

    A `.json` file is a table when it is a list of objects (each one a row), an
    object of objects (each key a row, shown in a column `id`, or `key` when the
    rows have an `id` of their own), or an object holding lists of objects, as a
    report does: `{"tool": "scan", "findings": [...], "hosts": [...]}`.  Each
    such list is a table, as a SQLite file's tables are: a file with more than one
    opens on `/tables`, with a card for each, and other values beside the lists
    (a date, a count, an object of totals) are left out.  A cell holding an object
    or a list shows as its JSON text, `true` and `false` as words and `null` as
    an empty cell, and the columns are in the order the file first names them.  A
    file of another format with the same name in the same folder is the one read.

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

- The login is one shared password.  There are no accounts, so every reader who
knows it can do everything, and the log cannot say who did what.
- Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.
- A MariaDB table is read, never written, but the application does not enforce
that on the server: give it an account with only `SELECT`.  Anyone who can reach
the application can open any table that account can read.
- Only a page of an unfiltered table is read with `LIMIT`.  A filter, Merge, Combine
or an export reads the whole MariaDB table into memory, so a very large table is
better opened through a view that narrows it.
- A MariaDB table or view whose name holds anything but letters, digits and
underscores cannot be opened.  `/tables` shows it with a `CREATE VIEW` statement
that gives it a usable name.
- A relative time range is resolved against the server's clock.  An ISO
timestamp, `YYYY-MM-DDTHH:MM:SS` (a space instead of the `T`, no seconds, a
fraction of a second, and a trailing `Z` or offset such as `+01:00` are all
accepted), is read as written: the zone is not applied, so
`2026-11-06T13:00:00Z` and `2026-11-06T13:00:00+05:00` are the same time to
a filter.  A non-ISO timestamp is read as far as its `YYYY-MM-DD` prefix, so
`last_24_hours` is exact only for ISO timestamps in the server's zone.
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

Features planned for future releases (post-0.019.0).  Items are ordered by
priority.  Items shipped before this release (XLSX export, the copy-link
button, the column statistics panel, folder filter/join propagation, the
aggregate/measure layer and the `between` and `in` filter operators) are no
longer listed.

- **Multi-sheet XLSX** (Medium) -- `_detect_file_info` reads only the
first worksheet.  A `?sheet=` URL param with a sheet-name picker would
expose the full workbook.
- **SSE streaming for large join results** (Low) -- The join pipeline
blocks the HTTP response until all rows are assembled.  Mojolicious supports
server-sent events, which could progressively stream rows to a JS table
renderer, giving visible progress on slow joins.
- **Boundary overlay on maps** (Low) -- `HTML::OSM` can draw GeoJSON and
choropleth layers.  A `gj=<path>` parameter would overlay a local
GeoJSON file, optionally shaded by an aggregated measure.  This is the one
Phase 6 item not implemented: it is optional in the phase spec, and no boundary
data is shipped or downloaded.

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
