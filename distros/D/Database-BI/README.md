## Name

Database::BI - Web-based Business Intelligence viewer for data files

## Version

0.018.0

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
model store and shared by every dataset that names it).  Rows sharing a
position become one marker.
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
being packed up the page.  **Add current view** in the toolbar appends another
table, chart or map without leaving the canvas, and a status region announces
the card and the new visual count; when the card's script has drawn it, the
region says the chart or map has finished drawing, and if D3 or Leaflet could
not be loaded it names the missing library instead.  A card that shows an
aggregated value picks its own function in that panel, from the vocabulary the
pivot uses and with the same names: Sum, Average, Min, Max, Count distinct,
Median, Std dev, First, Last, Range or a Percentile with its level, so a card
can show a median, a spread or a percentile where the chart pages behind it
could only sum.  Canvases support
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
script/database-bi
```

`morbo script/database-bi` does the same thing, and
`script/database-bi daemon` starts a plain server with no file watcher; any
other Mojolicious command word (`routes`, `get`, ...) is passed to the
application.

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

- `GET /tutorial`

    Renders the tutorial that is part of the application.  The chapters are data
    in [Database::BI::Tutorial](https://metacpan.org/pod/Database%3A%3ABI%3A%3ATutorial), not in this POD.

- `GET /view/:table`

    Opens the named table from `data_dir`.  Accepts `?f=col:op:val`
    (repeatable) to pre-filter results, and `?range=name&rcol=column` to keep
    only a relative window of rows (see ["Relative time ranges"](#relative-time-ranges)).

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
    path:/abs/path/to/file.csv         absolute local path
    /../hostname/dir/file.csv          remote file via SFTP
    redis:tablename|redis://host:port  Redis hash store (requires Redis module)
    ```

- `GET /api/columns`

    Returns `{ "columns": [...] }` for a table (`?table=name` or
    `?table=file/table` for a table inside a multi-table SQLite file) or file
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
    position become one marker.  Markers are clustered with
    Leaflet.markercluster, so a dense map draws a count at low zoom and splits it
    as it is zoomed in.  Clustering is always on.  Parameters:

    ```
    l=<spec>       left table (required)
    loc=<col>      column of places to geocode (required unless lat= and lon= are)
    lat=<col>      latitude column, -90..90
    lon=<col>      longitude column, -180..180
    popup=<col>    column shown in the marker popup (repeatable)
    max=N          markers to draw (default map_max_markers, 2000)
    zoom=N         initial zoom 0..19 (default: fit the markers)
    max_zoom=N     tile layer maxZoom 0..28 (default: map_max_zoom, if set)
    tiles=<name>   named tile source from the tile_sources config key
    heat=1         add a heatmap layer over the markers
    weight=<col>   numeric heatmap intensity column (normalised to 0..1)
    size=<col>     numeric bubble-radius column; markers become circles
    color=<col>    colour markers from a column
    color_rule=<op>:<value>:<colour>  repeatable; op is gt, ge, lt, le, eq or ne
    color_default=<colour>  fallback colour (default #3388ff)
    series=<col>   colour markers by category (not with color=)
    scheme=<name>  palette for series=: tableau10, category10, set2, set3, paired
    back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
    f=            result filters (repeatable)
    ```

    An unknown `tiles=` or `scheme=` is a 400, as is an unknown column, `color=`
    together with `series=`, or a transposed lat/lon pair.  The page never shows
    the [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) Nominatim search box (`search => 0` is always passed), so
    nothing typed on the map is sent anywhere.  [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) 0.12 or later is the
    renderer; an older optional install still returns the page with a warning.

- `GET /line`

    Alias for `GET /graph`.  All `/graph` parameters accepted.

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

- `POST /api/analyses/:id/visuals`

    Appends one visual to a saved canvas.  Body: `{ kind, encode, options,
    title, query }`, with `kind` one of `table`, `bar`, `pie`, `line`,
    `graph`, `scatter`, `heatmap`, `stacked`, `combo`, `treemap`,
    `histogram`, `wordcloud` or `map`.  A map's `encode` names either `loc` (a place column
    to geocode) or `lat` and `lon`.  A `wordcloud` card's `encode` names the
    text column to read in `col`, and its `options` take the same `topn`,
    `minlen` and `stop` the `GET /wordcloud` page takes, so the two count and
    rank words with one function.  The optional `query` is the canvas page's
    query string: `cf` (cross-filter), `c` (calculated columns) and
    `p.<name>` (bound parameter values) are read from it, so a card added
    while the canvas is filtered or parameterised is drawn through the same state
    as the cards already on screen.  The visual is rendered against the canvas's
    datasets, joins and calculated fields before it is stored, so an unknown
    column or an undrawable visual is rejected with `400` and nothing is appended.
    Returns `201 { id, visual, kind, title, html, head, cf_col }`, where
    `visual` is the new visual's index, `head` is any stylesheet and script the
    page must add once to draw the card (Leaflet, for a map), and `cf_col` is the
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

- `PATCH /api/analyses/:id/visuals/:visual`

    Changes the columns of one stored visual without removing it.  Body:
    `{ encode, query }`; `encode` replaces the visual's encoding in place (for
    a map, `{ loc }` or `{ lat, lon }`), and the optional `query` is the
    canvas page's query string, read for `cf`, `c` and `p.<name>` so
    the redrawn card matches the page it is on.  The visual keeps its index, so
    its layout position, size and title are unchanged.  The replacement is
    rendered before it is stored, so an unknown column or an undrawable map is a
    `400` and the saved visual is left alone.  Returns
    `{ id, visual, kind, title, html, head, cf_col }`.

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

- `GET /geo/list`

    Returns `{ columns: { col: { kind: "lat"|"lon"|"location" } } }` for the
    saved coordinate-column preferences of the given `l=` spec.

- `POST /geo/save`

    Saves a coordinate-column preference.  Body: `l=&col=&kind=`,
    where `kind` is `lat`, `lon`, or `location`.

- `POST /geo/delete`

    Removes a coordinate-column preference.  Body: `l=&col=`.
    Omit `col=` to clear all preferences for the spec.

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
    `ai_api_key` is not configured; 400 for missing params; 422 for an
    unparseable or invalid-column spec; 502 for a provider error.

- `POST /api/summary`

    Narrative summary of an analysis (Phase 5.3).  Body params: `l=<spec>`
    (required), repeatable `f=` filters, `ai=1` (optional, honours
    `ai_api_key` config).  Returns `{ text, source, cached }`.  Two paths:
    deterministic template sentences (always available, works offline) and
    optional LLM-polished prose when `ai=1` is passed and `ai_api_key` is
    set.  Only aggregate insight facts are sent to the LLM.  Results are cached
    in-process for one hour keyed on the analysis fingerprint.

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
graph panel an `Aggregate` menu beside it.

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
The table page's Cross-row panel builds the same parameters.  See
["Cross-row columns" in Database::BI::Controller::Dashboard](https://metacpan.org/pod/Database%3A%3ABI%3A%3AController%3A%3ADashboard#Cross-row-columns) for the full rules.

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

### Compression and the Page Cache

Every response goes through [Mojolicious::Plugin::Buffer](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer): it is compressed
(gzip or Brotli, as the browser accepts), HTML whitespace is minified (inline
scripts and styles are left alone), and a `200` to `GET` or `HEAD` carries
an `ETag`, so a repeat request can be answered `304 Not Modified`.  File
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
[CHI](https://metacpan.org/pod/CHI) File cache there, one copy per `Accept-Language`, and served from it
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
`{s}` too if the server uses subdomains.  Set it and every request needed to
draw a map can stay on the local network.  The OpenStreetMap attribution stays
on the map, since it is the usual credit for OSM-derived tiles.  There is no
in-page place search: [HTML::OSM](https://metacpan.org/pod/HTML%3A%3AOSM) is always constructed with `search => 0`,
so nothing typed on a map page is sent anywhere.

Map-specific config keys: `map_geocode_max` (new geocoder lookups per request,
default 500), `map_max_markers` (markers per request, default 2000),
`map_region` (a two-letter country hint for ambiguous places), `map_max_zoom`
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

- a 50 MiB limit on request bodies (an upload over it is answered `413`);
- Template Toolkit registered as handler `tt`, and the Buffer plugin
(see ["Compression and the page cache"](#compression-and-the-page-cache));
- the CHI cache for tables (the `Memory` driver unless `cache => { driver }`
names another), and the page cache when `page_cache_dir` is set;
- the `before_dispatch` hooks for relative time ranges, cross-row plans and
the view context, and the `before_render` hook that sets the breadcrumb, the help link
and the HTML 404 page;
- every route in ["ROUTES"](#routes).

A configuration file that does not parse makes the `Config` plugin croak, and
the application does not start.

## Command-Line Tools

Two maintenance scripts ship in `script/`; both use the same data and model
directories as the web application and are safe to run from cron.

### Script/Bi-Geocode

Warms the shared geocode cache for one column, so later map requests make no
lookups:

```
./script/bi-geocode --spec table:customers --col city \
                    [--data-dir DIR] [--model-dir DIR] \
                    [--openaddr PATH] [--region CC] [--dry-run] [--verbose]
```

It is idempotent: a second run against a warm cache resolves nothing and says
so.  Exit status is 0 on success, 1 when the column is missing or no rows load,
and 2 on bad arguments or an unopenable source.

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
starts the reloading development server, with a command word it runs that
command, and `hypnotoad script/database-bi` starts a preforking server (see
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
    exist, the controller automatically falls back to the default language, and
    the same fallback applies when a browser asks for a language no directory
    serves.  To add German support: (1) create `templates/web/de/`, (2) copy and
    translate the `.html.tt` files from `templates/web/en/`, then (3) set the
    config.

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
- A relative time range is resolved against the server's clock and compares the
column as a string, like every other filter.  A column holding a time zone
offset or a non-ISO timestamp is read as far as its `YYYY-MM-DD` prefix, so
`last_24_hours` is exact only for a column whose values are ISO
`YYYY-MM-DDTHH:MM:SS` (a space instead of the `T` is accepted too).
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

Features planned for future releases (post-0.018.0).  Items are ordered by
priority.  Items shipped before this release (XLSX export, the copy-link
button, the column statistics panel, folder filter/join propagation and the
aggregate/measure layer) are no longer listed.

- **Multi-sheet XLSX** (Medium) -- `_detect_file_info` reads only the
first worksheet.  A `?sheet=` URL param with a sheet-name picker would
expose the full workbook.
- **`between` and `in (a,b,c)` filter operators** (Low) -- Would
reduce multi-filter chains for common range and set queries.
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
