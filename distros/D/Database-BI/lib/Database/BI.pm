package Database::BI;

use strict;
use warnings;

use Mojo::Base 'Mojolicious', -strict, -signatures;

use Carp qw(croak);
use CHI	();
use File::Spec ();
use Readonly;

use Database::BI::Model::DataSource;
use Database::BI::Tutorial;

use version; our $VERSION = version->declare('0.018.0');

# Default config values used by the Config plugin and referenced explicitly
# in startup() so callers always get a resolved value.
Readonly my $DEFAULT_DATA_DIR     => 'data';
Readonly my $DEFAULT_PLATFORM     => 'web';
Readonly my $DEFAULT_LANGUAGE     => 'en';
Readonly my $DEFAULT_CACHE_TTL_URL => '15 min';

# The browser-side chart library is fetched from a CDN unless the deployment
# self-hosts it.  This is the pinned version the pages were tested with; the
# URL is a config seam (d3_url), and the Leaflet assets have their own keys
# (leaflet_*_url), so an offline installation can point them at its own copies.
Readonly my $DEFAULT_D3_URL => 'https://cdnjs.cloudflare.com/ajax/libs/d3/7.9.0/d3.min.js';

# Transport-layer upload size cap (bytes).  Mojolicious enforces this before
# the request body is read into memory, so an oversized upload never reaches
# the controller.  Must match $MAX_UPLOAD_BYTES in Dashboard.pm.
Readonly my $MAX_REQUEST_SIZE  => 50 * 1_048_576;	# 50 MiB
Readonly my $UPLOAD_MAX_AGE_S  => 24 * 3600;		# evict uploads older than 24 h

=head1 NAME

Database::BI - Web-based Business Intelligence viewer for data files

=head1 VERSION

0.018.0

=head1 DESCRIPTION

C<Database::BI> is a self-contained L<Mojolicious> web application that reads
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

A tutorial in plain English is built into the application at C</tutorial>.
It is written for people who do not know Perl, and it is the place to start.

Key features:

=over 4

=item *

B<File picker> -- the home page scans C<data_dir> and shows a card for
every supported file.  Recently opened filesystem files appear in a
"Recently opened" section powered by C<localStorage>.

=item *

B<Filesystem browser> -- C</browse> lets the user navigate the entire
filesystem and open any supported data file, not just files in C<data_dir>.

=item *

B<Column sort and reorder> -- clicking a header sorts the table; headers
are draggable to reorder.  Both settings are persisted in C<localStorage>
by column name and survive page reloads.

=item *

B<Left join> -- the "Merge data" panel on any table view lets the user
join one or more additional tables on a shared key via L<Database::Join>.
Every left row is kept; right-table columns are appended for matching rows.
Multiple joins can be chained.

=item *

B<Quick-filter bar> -- a column/operator/value row below the toolbar lets
the user add filter conditions without opening any panel.  Pressing Enter
applies the filter.  Each active filter chip has an individual remove (x)
button so conditions can be dropped one at a time.  Operators: C<eq>,
C<ne>, C<contains>, C<starts>, C<lt>, C<le>, C<gt>, C<ge>, C<empty>,
C<notempty>.  Filters are applied server-side after all joins.

=item *

B<Combine (UNION ALL)> -- the "Combine data" panel stacks rows from a
second (or further) file beneath the current rows, using a unified column
set and leaving blanks where a source file lacks a column.

=item *

B<Charts> -- nine L<HTML::D3> D3.js v7 chart types are accessible from
the toolbar: line chart (brush-to-zoom, reference lines for min/avg/max,
multi-series interactive legend), pie chart (click-a-slice to filter,
top-N, donut mode, configurable colour scheme), heatmap (two categorical
axes, count or sum mode), bar chart (horizontal or vertical, sort,
top-N), scatter/bubble plot (optional categorical colour and numeric
size dimensions), stacked bar chart, combo bar+line chart, treemap, and
histogram (server-side binning, C<?bins=N>).  All charts can be resized
by dragging the bottom-right corner grip, or from the keyboard: the grip
takes focus, the arrow keys resize the chart (Shift takes bigger steps,
Home and End go to the narrowest and widest it can be) and the size is announced
as it changes.  All chart pages include Copy-link and Export SVG/PNG buttons.

=item *

B<Maps> -- C<GET /map> plots the filtered view on an OpenStreetMap map, either
from latitude and longitude columns or from a place column geocoded locally
with L<Geo::Coder::Free> (one lookup per distinct place, remembered in the
model store and shared by every dataset that names it).  Rows sharing a
position become one marker.

=item *

B<Pivot table> -- the "Pivot table" panel builds a crosstab from any
combination of row dimensions, column dimensions, and measures
(C<sum|avg|min|max|count|count_distinct|median|stdev|first|last|range>, plus
C<pE<lt>NE<gt>> for the Nth percentile).  The backend aggregates what it can;
the rest are computed in Perl from each group's values, subtotals and grand
total included, because a median is not the sum of the medians of its parts.
Supports subtotals, HAVING filters, top-N row groups, and direct export to
CSV, SQLite, JSON, or XLSX.

=item *

B<Column statistics> -- the column-stats button runs C<GET /stats>, which
returns one row per column: row count, null count, distinct count, first and
last, and (for numeric columns) min, max, range, mean, median, a chosen
percentile and the sample standard deviation.  The arithmetic is the same one
the pivot's measures use.

=item *

B<Calculated fields> -- virtual columns defined by inline C<?c=name:expr>
URL params or stored persistently via C<POST /calc/save>.  Expressions
support arithmetic, comparison, C<IF>, string, numeric, and date
functions, plus C<bin(value,width)> for histogram grouping.  Calc fields
are applied before aggregation on all chart and pivot routes.

=item *

B<Relative time ranges> -- any data view, chart, pivot or saved canvas can be
limited to a named window worked out from today -- the last 24 hours, the last
7, 30 or 90 days, this or last month, quarter or year -- instead of typing
dates.  The window is resolved on every request (C<?range=> with C<?rcol=>),
so a bookmark or a canvas still means the same thing tomorrow, and the filter
bar disables a window the data cannot answer.

=item *

B<Saved canvases> -- the "Save as Canvas" panel saves the current data
configuration as a named multi-visual canvas (C</a/:id>).  Visuals are
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
being packed up the page.  B<Add current view> in the toolbar appends another
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

=item *

B<Drag-and-drop upload> -- any supported data file can be dropped directly
onto the application.  The file is opened immediately; when the "Combine
data" panel is open the dropped file populates the right-table path field.

=item *

B<Export> -- the toolbar export panel writes the current logical view
(after joins, filters, and dedup) to a chosen filesystem path as CSV
(C<.csv>), SQLite (C<.sql>), or JSON (C<.json>).

=item *

B<URL import> -- C</import> fetches an HTML table from any public URL and
renders it in the browser without saving to disc.

=item *

B<Redis data source> (optional) -- when the C<Redis> or C<Redis::Fast> module
is installed, any Redis hash store can be opened as a read-only data table by
entering a C<redis:tablename|redis://host:port> spec in the path field or in a
join/combine panel.  Redis keys must follow the C<tablename:entry> convention
used by L<Database::Abstraction>.  Because C<Redis> is an optional dependency,
the application works fully without it; Redis support activates automatically
when the module is available.

=back

=head2 UTF-8 and Encoding

All file data is returned as Perl character strings.  CSV/PSV/TSV files are
read by L<Text::xSV::Slurp> or L<DBD::CSV>, both of which pass bytes
through without re-encoding; the application serves the resulting page as
C<text/html; charset=UTF-8>, so full Unicode is displayed correctly as
long as the source file itself is UTF-8.

Filter values (C<f=col:op:val>) are decoded from the URL by Mojolicious
before reaching the controller and are compared against cell values as
Perl character strings.  Unicode characters in filter values are therefore
supported transparently.

URL-imported HTML tables are fetched with L<LWP::UserAgent::Cached>;
L<Database::Abstraction> uses the page's own charset declaration to decode
the body.  If the remote page declares an incorrect charset, cell values
may contain mojibake -- this is a limitation of the source data, not the
application.

=head1 SYNOPSIS

B<Start the development server (restarts automatically when you edit a file):>

    script/database-bi

C<morbo script/database-bi> does the same thing, and
C<script/database-bi daemon> starts a plain server with no file watcher; any
other Mojolicious command word (C<routes>, C<get>, ...) is passed to the
application.

B<Start the production server:>

    hypnotoad script/database-bi

B<Use a different data directory:>

    # In database_bi.conf (create this file in the same folder as script/):
    { data_dir => '/home/user/data' }

B<Change the language used for templates:>

    # In database_bi.conf:
    { data_dir => 'data', language => 'fr', platform => 'web' }
    # Then create templates/web/fr/ and put your French .html.tt files there.

B<Run the test suite to verify everything is working:>

    make test

B<Generate the Makefile for the first time or after editing Makefile.PL:>

    perl Makefile.PL

=head1 ROUTES

=over 4

=item C<GET />

Scans C<data_dir>, renders a card grid of available tables.

=item C<GET /tutorial>

Renders the tutorial that is part of the application.  The chapters are data
in L<Database::BI::Tutorial>, not in this POD.

=item C<GET /view/:table>

Opens the named table from C<data_dir>.  Accepts C<?f=col:op:val>
(repeatable) to pre-filter results, and C<?range=name&rcol=column> to keep
only a relative window of rows (see L</Relative time ranges>).

A name that is not a table in C<data_dir> is a C<404> page that says so ("There
is no table called ..."), with the breadcrumb and site navigation; it does not
show the data directory.

=item C<GET /browse>

Filesystem navigator.  Accepts C<?path=> to set the starting directory
(defaults to C<$HOME>).

=item C<GET /open>

Opens any supported file by absolute path (C<?path=>).  Accepts C<?f=>
filters.  When the file is a multi-table SQLite database, passing
C<?it=E<lt>tableE<gt>> selects a specific internal table instead of the
auto-detected first one.

=item C<GET /join>

Performs one or more left joins and renders the merged table.  Parameters:

  l=<spec>               left table spec (see below)
  j=<spec>|<lk>|<rk>    join step (repeatable): right-spec, left key, right key
  c=<spec>               table to stack after the joins (repeatable; see /combine)
  f=<col>:<op>:<val>     result filter (repeatable)
  range=<name>           relative time range, with rcol=<column> (see below)

Spec formats:

  table:name                         named table from data_dir
  table:file/table                   a table inside a multi-table SQLite file
  path:/abs/path/to/file.csv         absolute local path
  /../hostname/dir/file.csv          remote file via SFTP
  redis:tablename|redis://host:port  Redis hash store (requires Redis module)

=item C<GET /api/columns>

Returns C<{ "columns": [...] }> for a table (C<?table=name> or
C<?table=file/table> for a table inside a multi-table SQLite file) or file
(C<?path=/abs/path>).  Used by the join UI to populate the right-key
dropdown without a page reload.

=item C<GET /export>

Exports the current logical view (same C<l=>, C<j=>, C<f=> parameters as
C</join>) as a file download.  Additional parameter:

  format=csv      (default) - RFC 4180 CSV; UTF-8; CRLF line endings
  format=sqlite   - SQLite 3 database with a single table named "data"

The download filename is derived from the left table label with
non-alphanumeric characters replaced by underscores.

=item C<POST /export>

Writes the current logical view to a chosen filesystem path.
Body params: C<l=>, C<j=>, C<f=> (same as GET), plus
C<dir=> (target directory) and C<filename=> (name including extension;
extension determines format: C<.csv> or C<.sql>).
Returns JSON C<{ saved: "/abs/path" }> or C<{ error: "..." }>.

=item C<GET /api/dirs>

Returns a JSON directory listing (subdirectories only) for the export
panel's inline directory browser.  Accepts C<?path=> (defaults to
C<$HOME>).  Returns C<{ path, parent, dirs: [{name, path}] }>.

=item C<GET /api/stat>

Returns filesystem metadata for a file path (C<?path=>).
Returns C<{ exists, path, mtime, size }>.  For SQLite files
(C<.sql>, C<.sqlite>, C<.sqlite3>, C<.db>) an additional C<table_count>
integer is included when the file is a valid SQLite database; the field
is omitted for Berkeley DB or other non-SQLite payloads.
If the file does not exist, C<exists> is C<false> and the remaining
fields are absent (HTTP 200).  Returns HTTP 400 when C<path> is missing.

=item C<POST /upload>

Accepts a multipart file upload (field name: C<file>), validates the
extension, saves to a managed C<.uploads/> subdirectory under the app
home, and returns JSON C<{ url, path }>.

=item C<GET /import>

Fetches an HTML table from a public URL (C<?url=>) and renders it as a
data grid.  An optional C<?t=> parameter (zero-based integer) selects
which HTML table on the page to display when the page contains multiple
tables.

=item C<GET /tables>

Schema browser for multi-table SQLite databases.  Accepts C<?l=E<lt>specE<gt>>
(same C<table:name> or C<path:/abs/path> spec as C</join>).  Returns a card
grid listing every internal table with its columns; each card links to
C</open?path=...&it=E<lt>tableE<gt>>.  Redirects to 404 when the spec is
absent, invalid, or the resolved file is not a multi-table SQLite database.

=item C<GET /combine>

Stacks rows from two or more tables vertically (UNION ALL) into a unified
view.  All columns from all sources appear as headers; cells are blank
where a source file lacks a column.  Parameters:

  l=<spec>               left table: "table:name" or "path:/abs/path"
  j=<spec>|<lk>|<rk>    join step applied to the left table first (repeatable)
  c=<spec>               additional table to stack (repeatable)
  f=<col>:<op>:<val>     result filter applied after combining (repeatable)

=item C<GET /graph>

Renders a D3.js v7 zoomable line chart of any two columns.  Parameters:

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

=item C<GET /pie>

Renders a D3.js v7 animated pie chart grouped by a category column.
Clicking a slice or legend entry navigates to the table view filtered to
that category.  Parameters:

  l=<spec>           left table (required)
  cat=<col>          category column to group by (required)
  val=<col>          numeric column to sum per category (required)
  donut=1            show a hole in the centre (optional)
  back=<url>         URL for the second breadcrumb link (optional; default "/")
  back2=<url>        URL for the outermost breadcrumb link (optional)
  back2_label=<text> Label for the back2 link (optional; default "Back")
  f=                 result filters applied before aggregating (repeatable)

=item C<GET /heatmap>

Renders a D3.js v7 grid heatmap with two categorical axes.  Each cell
colour encodes a summed or counted numeric value.  Parameters:

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

=item C<GET /bar>

Renders a D3.js v7 bar chart grouped by a categorical column.  Parameters:

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

=item C<GET /folder>

Hierarchical folder view.  Groups a data table by the letter-prefix of an
order-number column (e.g. A10, CT4, B3) and shows one card per prefix group.
Clicking a card with sub-prefixes drills down; clicking a leaf shows the
matching data rows.  Parameters:

  l=<spec>     left table (required)
  col=<col>    order-code column (auto-detected when absent)
  prefix=<str> current drill-down prefix (top level when absent)
  back=<url>   URL for the back link (optional)
  f=           result filters (repeatable)

=item C<POST /uploads/clear>

Deletes every file from the C<.uploads/> staging directory.  Returns JSON
C<{ "freed": <bytes>, "count": <n> }>.  No request body is needed.

=item C<GET /pivot>

Renders a pivot/crosstab table.  Parameters:

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

=item C<GET /stats>

Per-column statistics view.  Returns one row per column: row count, null
count, distinct count, first and last, and (for numeric columns) min, max,
range, mean, median, the percentile named by C<p=N> and sample standard
deviation.  Parameters: C<l=E<lt>specE<gt>> (required), C<f=> filters and
C<p=N> for the percentile column (1 to 100, default 95).

=item C<GET /scatter>

D3.js v7 scatter/bubble plot.  Parameters:

  l=<spec>      left table (required)
  x=<col>       X-axis column (required; numeric)
  y=<col>       Y-axis column (required; numeric)
  series=<col>  categorical colour dimension (optional)
  size=<col>    numeric bubble-radius dimension (optional)
  scheme=<name> colour scheme when series= is set (optional)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=            result filters (repeatable)

=item C<GET /stacked>

D3.js v7 stacked bar chart.  Parameters:

  l=<spec>      left table (required)
  cat=<col>     X-axis categories (required)
  series=<col>  stack segments (required; seg= is a backwards-compatible alias)
  val=<col>     measure column (optional; omit to count rows)
  scheme=<name> colour scheme (optional)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=            result filters (repeatable)

=item C<GET /combo>

D3.js v7 combo bar+line chart.  Parameters:

  l=<spec>       left table (required)
  cat=<col>      X-axis categories (required; x= is a backwards-compatible alias)
  bar_val=<col>  bar measure column (required)
  line_val=<col> line measure column (required)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=             result filters (repeatable)

=item C<GET /treemap>

D3.js v7 treemap.  Parameters:

  l=<spec>      left table (required)
  group=<col>   tile label column (required; cat= is a backwards-compatible alias)
  size=<col>    tile area column (required; val= is a backwards-compatible alias)
  topn=N        keep only the top-N tiles; remainder merged into "Other"
  scheme=<name> colour scheme (optional)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=            result filters (repeatable)

=item C<GET /histogram>

D3.js v7 histogram with server-side binning.  Parameters:

  l=<spec>   left table (required)
  col=<col>  numeric column to bin (required)
  bins=N     bin count (default 10; clamped to range 1--200)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=         result filters (repeatable)

=item C<GET /wordcloud>

Word cloud of a text column, drawn with HTML::TagCloud.  Each row contributes
its words once, so a word's size is the number of rows that use it rather than
the number of times one long note repeats it.  Common English words are
removed.  Parameters:

  l=<spec>     left table (required)
  col=<col>    text column to read (required)
  topn=N       number of different words to show (default 50; range 1--500)
  minlen=N     shortest word kept (default 3; range 1--64)
  stop=<words> extra words to ignore, comma or space separated (optional)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=           result filters (repeatable)

With C<back=>, each word links to the rows that contain it.

The same cloud is available as a card on a saved canvas: C<POST
/api/analyses/:id/visuals> takes C<< kind => wordcloud >> with C<encode.col>,
and the card counts the words of its own rows -- its filters, the page's
cross-filter and its own options -- so a canvas that is narrowed to one
region shows the words of that region.

=item C<GET /map>

OpenStreetMap map of the filtered view, drawn with HTML::OSM.  A row's position
comes from a location column that is geocoded (C<loc=>, one lookup per distinct
value, remembered once in the model store and shared with every dataset that
names it) or from coordinate columns (C<lat=> and C<lon=>).  Rows sharing a
position become one marker.  Markers are clustered with
Leaflet.markercluster, so a dense map draws a count at low zoom and splits it
as it is zoomed in.  Clustering is always on.  Parameters:

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

An unknown C<tiles=> or C<scheme=> is a 400, as is an unknown column, C<color=>
together with C<series=>, or a transposed lat/lon pair.  The page never shows
the L<HTML::OSM> Nominatim search box (C<search =E<gt> 0> is always passed), so
nothing typed on the map is sent anywhere.  L<HTML::OSM> 0.12 or later is the
renderer; an older optional install still returns the page with a warning.

=item C<GET /line>

Alias for C<GET /graph>.  All C</graph> parameters accepted.

=item C<GET /a/:id>

Renders a saved canvas (analysis) as a full multi-visual page.  Accepts
cross-filter params C<?cf=E<lt>colE<gt>&cv=E<lt>valE<gt>>, drill-through
params C<?dd=E<lt>colE<gt>&dl=E<lt>levelE<gt>>, parameter overrides
C<?p.E<lt>nameE<gt>=E<lt>valueE<gt>>, and a relative time range
C<?range=E<lt>nameE<gt>&rcol=E<lt>columnE<gt>> that narrows every card on the
canvas (see L</Relative time ranges>).

=item C<GET /api/analyses>

Returns C<{ analyses: [{id, name, datasets, updated}] }>.

=item C<POST /api/analyses>

Creates a new analysis from a JSON request body.  Required fields: C<name>
and C<datasets> (array; each entry must have a C<spec> starting with
C<table:>, C<path:>, C<url:>, or C<redis:>).  Returns C<201 { id, created: 1 }>.

=item C<GET /api/analyses/:id>

Returns the full analysis document.

=item C<PUT /api/analyses/:id>

Full replacement of an analysis document.

=item C<PATCH /api/analyses/:id>

Partial update; merges the supplied top-level keys.  C<id> and C<created>
are immutable.  The C<layout> key places the visuals on the canvas grid: an
array of C<{ visual, x, y, w, h }>, where C<visual> indexes the C<visuals>
array and C<x>, C<y>, C<w> and C<h> are 1-based grid columns and rows (the
grid is 12 columns wide, C<x + w - 1> cannot exceed 12, and one visual may
span at most 6 rows).  Positions are
stored as given - a gap is a gap - but two visuals may not share a cell, so
an overlapping set is rejected with C<400> and the stored layout is left
alone.

=item C<POST /api/analyses/:id/visuals>

Appends one visual to a saved canvas.  Body: C<{ kind, encode, options,
title, query }>, with C<kind> one of C<table>, C<bar>, C<pie>, C<line>,
C<graph>, C<scatter>, C<heatmap>, C<stacked>, C<combo>, C<treemap>,
C<histogram>, C<wordcloud> or C<map>.  A map's C<encode> names either C<loc> (a place column
to geocode) or C<lat> and C<lon>.  A C<wordcloud> card's C<encode> names the
text column to read in C<col>, and its C<options> take the same C<topn>,
C<minlen> and C<stop> the C<GET /wordcloud> page takes, so the two count and
rank words with one function.  The optional C<query> is the canvas page's
query string: C<cf> (cross-filter), C<c> (calculated columns) and
C<p.E<lt>nameE<gt>> (bound parameter values) are read from it, so a card added
while the canvas is filtered or parameterised is drawn through the same state
as the cards already on screen.  The visual is rendered against the canvas's
datasets, joins and calculated fields before it is stored, so an unknown
column or an undrawable visual is rejected with C<400> and nothing is appended.
Returns C<201 { id, visual, kind, title, html, head, cf_col }>, where
C<visual> is the new visual's index, C<head> is any stylesheet and script the
page must add once to draw the card (Leaflet, for a map), and C<cf_col> is the
column the card's marks cross-filter by.  The card is left unplaced in
C<layout>; it is auto-placed after the saved cards until the reader moves or
resizes it.

A C<kind> that aggregates a value column -- C<bar>, C<pie>, C<stacked>,
C<treemap>, C<heatmap> and C<combo> -- reads an optional C<encode.agg>: the
function its value column is aggregated with.  It takes C<sum> (the default),
C<avg>, C<min>, C<max>, C<count_distinct>, C<median>, C<stdev>, C<first>,
C<last>, C<range>, or a percentile named C<pE<lt>NE<gt>> from C<p1> to C<p100>
-- the same vocabulary and the same spelling a pivot's C<m=> spec uses, so a
card can show a median, a spread or a percentile where the chart pages it came
from could only sum.  C<count> is accepted as well: it counts rows and ignores
the value column.  The function is checked whatever the kind is, so a misspelt
one is a C<400> rather than a chart drawn some other way, as is a function that
needs a column (C<median>, unlike C<count>) when the card names no value column
or names the value menu's "Count (no column needed)".  A combo aggregates both
its series with the one function.  A card's derived title says which function it
used (C<median(amount) by region>); a plain sum keeps the title it has always
had.

A card may bring a cross-row plan of its own in C<cross_row>, in the spelling
the canvas page's C<cs>, C<by> and C<order> use:
C<< { cs => [ I<col:fn:name[:arg]> ... ], by => I<col>, order => [ I<col:dir> ... ] } >>.
The card then runs that plan instead of the page's, so one card of a canvas can
show a running total while the cards beside it show raw rows, and
C<< { cs => [] } >> is a card that runs no cross-row pass at all -- which is how a
card opts out of the page's.  A card that sends no C<cross_row> inherits the
page's plan.  The plan is checked against the canvas's columns on every render,
not only here, so a saved spec that no longer names a column is that card's
error while a bad page-level C<cs> is the page's C<400>.

=item C<PATCH /api/analyses/:id/visuals/:visual>

Changes the columns of one stored visual without removing it.  Body:
C<{ encode, query }>; C<encode> replaces the visual's encoding in place (for
a map, C<{ loc }> or C<{ lat, lon }>), and the optional C<query> is the
canvas page's query string, read for C<cf>, C<c> and C<p.E<lt>nameE<gt>> so
the redrawn card matches the page it is on.  The visual keeps its index, so
its layout position, size and title are unchanged.  The replacement is
rendered before it is stored, so an unknown column or an undrawable map is a
C<400> and the saved visual is left alone.  Returns
C<{ id, visual, kind, title, html, head, cf_col }>.

=item C<DELETE /api/analyses/:id>

Removes the analysis.  Returns C<200 { deleted: 1 }>.

=item C<GET /api/analyses/:id/export>

Downloads the analysis document as a C<.json> file.

=item C<POST /api/analyses/import>

Creates an analysis from an uploaded C<.json> file (multipart C<file>
field) or a raw JSON request body.  Caller-supplied C<id>, C<created>,
and C<updated> are stripped.

=item C<GET /calc/list>

Returns C<{ fields: { name: expr } }> for stored virtual calc fields
for a given spec.  Accepts C<?l=E<lt>specE<gt>>.

=item C<POST /calc/save>

Saves a named calc field to C<.bi/models.json>.  Body:
C<l=E<lt>specE<gt>&name=E<lt>identE<gt>&expr=E<lt>expressionE<gt>>.
Returns C<{ saved: 1 }> or C<{ error: "..." }> (400 for hostile input).

=item C<POST /calc/delete>

Removes a named calc field.  Body:
C<l=E<lt>specE<gt>&name=E<lt>identE<gt>>.

=item C<GET /groups/list>

Returns C<{ groups: { label: [vals] } }> for named value groups for
a column.  Accepts C<?l=E<lt>specE<gt>&col=E<lt>colE<gt>>.

=item C<POST /groups/save>

Saves a named value group.  Body: C<l=&col=&group=&values=> (values
is a newline-separated list of raw cell values).

=item C<POST /groups/delete>

Removes a named value group.  Body: C<l=&col=&group=>.

=item C<GET /dates/list>

Returns C<{ patterns: { col: pattern } }> for stored date-normalisation
patterns.  Accepts C<?l=E<lt>specE<gt>>.  A column with only a date pattern is
reported as the pattern string; one with a time part as well is reported as
C<{ date, time }>, plus C<as> when the normalised value is filed under a name
of its own.

=item C<POST /dates/save>

Saves a date-normalisation pattern for a column.  Body: C<l=&col=&pattern=>,
plus optional C<time=> and C<as=>.  Supported patterns: C<%m/%d/%Y> (US),
C<%d/%m/%Y> (EU), C<%d-%b-%Y> (DD-Mon-YYYY).  With C<time=> (C<%H:%M> or
C<%H:%M:%S>) the column is normalised to a timestamp, C<2026-10-27T14:05:00>,
which is what C<epoch()>, C<span()> and a C<last_24_hours> range can read;
C<as=> names the column the normalised value is written to (default: the
column itself).  Without a time part the stored value is the date pattern
string, unchanged, so no existing store needs migrating.

=item C<POST /dates/delete>

Removes a date-normalisation pattern.  Body: C<l=&col=>.
Omit C<col=> to clear all patterns for the spec.

=item C<GET /geo/list>

Returns C<{ columns: { col: { kind: "lat"|"lon"|"location" } } }> for the
saved coordinate-column preferences of the given C<l=> spec.

=item C<POST /geo/save>

Saves a coordinate-column preference.  Body: C<l=&col=&kind=>,
where C<kind> is C<lat>, C<lon>, or C<location>.

=item C<POST /geo/delete>

Removes a coordinate-column preference.  Body: C<l=&col=>.
Omit C<col=> to clear all preferences for the spec.

=item C<GET /insights>

Automatic statistical insights for a dataset.  Runs the same pipeline as
C</join> then detects outliers (Tukey IQR fence), period-over-period deltas,
top movers, and seasonality (lag-1 autocorrelation).  No LLM or network call
is made.  Every insight links to a chart or stats view that shows it.
Parameters: C<l=E<lt>specE<gt>> (required), repeatable C<f=> filters.

=item C<POST /api/ask>

Natural language to analysis spec (Phase 5.1).  Body params: C<l=E<lt>specE<gt>>
(required), C<q=E<lt>questionE<gt>> (required), repeatable C<f=> filters.
Returns C<{ spec, url, valid =E<gt> 1 }> on success.  The model receives only
column names and types -- never raw row data or file paths.  Returns 503 when
C<ai_api_key> is not configured; 400 for missing params; 422 for an
unparseable or invalid-column spec; 502 for a provider error.

=item C<POST /api/summary>

Narrative summary of an analysis (Phase 5.3).  Body params: C<l=E<lt>specE<gt>>
(required), repeatable C<f=> filters, C<ai=1> (optional, honours
C<ai_api_key> config).  Returns C<{ text, source, cached }>.  Two paths:
deterministic template sentences (always available, works offline) and
optional LLM-polished prose when C<ai=1> is passed and C<ai_api_key> is
set.  Only aggregate insight facts are sent to the LLM.  Results are cached
in-process for one hour keyed on the analysis fingerprint.

=back

=head2 Breadcrumbs and missing pages

Every page shows where it is: Home, then each page between Home and this one,
then this page, which is not a link.  The trail is read from the page's own
URL -- a chart's C<back=>, drilled rows' C<back2=>, a file's folder -- and each
step is named from its own URL ("Bar chart: amount by region", "sales (region
= North)").  Text from the URL is shown only if it is short and has no markup,
a C<back=> to another site or scheme is not followed, and a chain of C<back=>
links stops after eight steps.

An address that matches no route, a missing table (C</view/:table>) and a
missing canvas (C</a/:id>) answer C<404> with an HTML page that keeps the
breadcrumb and the site navigation.  The JSON API (C</api/...>) still answers
a C<404> with a JSON body.

=head2 Relative time ranges

Every data route accepts a named window in place of a pair of dates:

    GET /view/sales?range=last_30_days&rcol=sale_date
    GET /a/mycanvas?range=this_quarter&rcol=order_date

C<range=> names the window and C<rcol=> names the column it applies to.  The
window is worked out when the request arrives, so a link, a bookmark or a
saved canvas keeps meaning the same thing whenever it is opened rather than the
dates it happened to resolve to when it was written.  The vocabulary is

    last_24_hours   the 24 hours ending now, to the second
    today, yesterday
    last_7_days, last_30_days, last_90_days     including today
    this_month, last_month
    this_quarter, last_quarter
    this_year, last_year

A C<this> period ends today; the completed one is C<last_month>,
C<last_quarter> and so on.

The range is applied as two ordinary filters on that column --
C<< col:ge:lo >> and C<< col:le:hi >> -- so the table view, every chart, the
pivot, the column statistics, the insights page, the exports and a saved canvas
all show the same rows, and one chip in the toolbar names the window with an
C<x> to remove it.  Filters the reader wrote are untouched: the range travels in
the URL as itself, so submitting a panel form or reopening a link does not turn
it into frozen dates.

A window narrower than a day (C<last_24_hours>) is compared to the second, so
it is exact only on a column that holds a time as well as a date.  A
day-granular window compared against a column of timestamps covers each day it
reaches in full, which is what a date filter does on its own as well.

The filter bar offers the same windows: choose one and the column it applies
to.  Entries whose window falls entirely outside the data are disabled, with the
column's own earliest and latest value -- from C<GET /api/range> -- in the
tooltip, so a window that can only show nothing says so before it is chosen.
An unknown C<range=> is a 400 rather than a silently unfiltered view, and a
range with no C<rcol=> is a 400 as well.

On a saved canvas the range narrows every card, and a card added while one is
active is drawn through it: C<query> in C<POST /api/analyses/:id/visuals>
carries C<range=>/C<rcol=> as it carries C<cf=>.

=head2 Time buckets

The aggregating routes bucket the dimension they already take:

    GET /bar?l=table:sales&cat=at&val=amount&span=1h
    GET /pivot?l=table:sales&rows=at&m=amount:sum:total&span=1mon
    GET /view/sales?span=1d&tcol=at
    GET /graph?l=table:sales&x=at&y=amount&span=1h&agg=sum&series=region

The chart and pivot panels carry a C<Time bucket> menu for it, and the line
graph panel an C<Aggregate> menu beside it.

C<span=> takes a count and one of C<s>, C<m>, C<h>, C<d>, C<w>, C<mon>, C<q>
or C<y> -- C<15m>, C<6h>, C<2d>, C<3mon>, C<1q> -- and is refused, naming the
interval and the parameter, when the count is zero or the unit is not one of
those.  It expands into the calculated field a reader could have typed,
C<< <col>_span:span(<col>,'1h') >>, so there is one pipeline and one set of
semantics; C<tcol=> names the column where the route has no single dimension or
names more than one, and C<as=> names the bucket column.  C<tcol=> without a
C<span=>, an unknown column, a name that is already a column and a C<span=> that
disagrees with the reader's own calculated field are each a 400.

Labels are ISO at the bucket's own resolution -- C<2026-10-27T14:00:00>,
C<2026-10-27>, C<2026-10-01> -- so they sort chronologically as strings and a
bucketed chart comes out in the right order with no second sort.  C<d>, C<w>,
C<mon>, C<q> and C<y> are computed from the local calendar, so a daylight-saving
day is one bucket and a leap day is its own date; C<s>, C<m> and C<h> floor the
interval out of the epoch.  A value that cannot be read as a time lands in one
visible C<(unparseable)> bucket rather than disappearing.

C<agg=> on C</graph> is the timechart: one point per bucket, aggregated with
the measure vocabulary a pivot's C<m=> uses (C<sum>, C<avg>, C<min>, C<max>,
C<count>, C<count_distinct>, C<median>, C<stdev>, C<first>, C<last>,
C<range>, C<pE<lt>NE<gt>>).  Without C<agg=> every row is still plotted.

The same bucket is available by hand, because it is a calculated field:
C<?c=hour:span(at,'1h')>.  The timestamp functions are C<epoch(v[, fmt])>,
C<hour(v)>, C<minute(v)>, C<second(v)> and C<span(v, interval)>; see
L<Database::BI::Calc> for the shapes each reads and the local-time rule.

=head2 Cross-row columns

Every data route, C</export> and a saved canvas accept a cross-row plan: a
column worked out from many rows and written beside each one.

  cs=<column>:<function>:<alias>[:<count>]   repeatable
  by=<column>[,<column>...]                  partition (optional)
  order=<column>[:asc|desc]                  the order the rows are read in

C<pct_of_total>, C<rank> and C<zscore> need no order.  C<running_total>,
C<running_count>, C<running_pct>, C<window_sum>, C<window_avg>, C<lag>,
C<delta> and C<pct_change> need C<order=>; only C<window_sum> and
C<window_avg> take the C<count>, the width of the window.  The pass runs after
the filters and before pagination, so page 2 continues page 1's running total.
An unknown function or column, or a parameter where none is taken, is a 400.
The table page's Cross-row panel builds the same parameters.  See
L<Database::BI::Controller::Dashboard/Cross-row columns> for the full rules.

=head1 CONFIGURATION

Place a C<database_bi.conf> file in the application root to override
defaults:

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

C<uploads_dir> is where C<POST /upload> stages the files a user drags onto the
page, and the directory C<POST /uploads/clear> empties.  It defaults to
C<.uploads> under the application home.  A relative value resolves against the
application home, an absolute one is used as given, so a deployment whose
application directory is read-only can stage uploads somewhere writable:

    { uploads_dir => '/var/tmp/database-bi-uploads' }

=head2 Compression and the page cache

Every response goes through L<Mojolicious::Plugin::Buffer>: it is compressed
(gzip or Brotli, as the browser accepts), HTML whitespace is minified (inline
scripts and styles are left alone), and a C<200> to C<GET> or C<HEAD> carries
an C<ETag>, so a repeat request can be answered C<304 Not Modified>.  File
downloads (C</export> as CSV, SQLite or JSON, the pivot as XLSX, and a canvas
card's data from C</a/:id/visual/:n/:fmt>) opt out and are sent as they are.

Two optional keys keep finished pages on disc:

    {
        page_cache_dir      => '/var/cache/database-bi',  # relative: under the application home
        page_cache_duration => '5 minutes',               # the default
    }

When C<page_cache_dir> is set, C</catalog> and C</tutorial> are stored in a
L<CHI> File cache there, one copy per C<Accept-Language>, and served from it
until they expire.  No other page is cached, because the rest read data files
that can change between requests.  Without the key nothing is cached.

=head2 Self-hosting D3 and Leaflet

The chart pages load D3 from a public CDN by default, and the map pages load
Leaflet and leaflet.markercluster from unpkg.  A deployment with no outbound
network access, or one that prefers to serve its own assets, sets the URLs in
C<database_bi.conf>:

    {
        d3_url                          => '/static/d3/d3.min.js',
        leaflet_js_url                  => '/static/leaflet/leaflet.js',
        leaflet_css_url                 => '/static/leaflet/leaflet.css',
        leaflet_cluster_js_url          => '/static/leaflet/leaflet.markercluster.js',
        leaflet_cluster_css_url         => '/static/leaflet/MarkerCluster.css',
        leaflet_cluster_default_css_url => '/static/leaflet/MarkerCluster.Default.css',
        tile_url                        => 'https://tiles.internal/{z}/{x}/{y}.png',
    }

An absolute path is served like any other static file: put the library under
the application's C<public/> directory, so C</static/d3/d3.min.js> is
C<public/static/d3/d3.min.js>.  The five Leaflet keys may be set on their own;
any left out keeps L<HTML::OSM>'s pinned CDN URL.  Use a path beginning with
C</>, or a full URL; a path without the leading slash is relative to the page.  The versions to copy are the
ones the defaults name: D3 7.9.0, Leaflet 1.9.4, and leaflet.markercluster 1.5.3.
C<tile_url> points the map layer at a self-hosted tile server instead of
OpenStreetMap.  It keeps Leaflet's C<{z}>, C<{x}> and C<{y}> placeholders, and
C<{s}> too if the server uses subdomains.  Set it and every request needed to
draw a map can stay on the local network.  The OpenStreetMap attribution stays
on the map, since it is the usual credit for OSM-derived tiles.  There is no
in-page place search: L<HTML::OSM> is always constructed with C<search =E<gt> 0>,
so nothing typed on a map page is sent anywhere.

Map-specific config keys: C<map_geocode_max> (new geocoder lookups per request,
default 500), C<map_max_markers> (markers per request, default 2000),
C<map_region> (a two-letter country hint for ambiguous places), C<map_max_zoom>
(the default tile-layer maxZoom) and C<tile_sources> (a hashref of named tile
sources, each C<< { url =E<gt> ... } >>, selected with C<tiles=>).

B<Map colour rules.>  C<color=> names the column and C<color_rule=> supplies
C<< E<lt>opE<gt>:E<lt>valueE<gt>:E<lt>colourE<gt> >> rules; they are tried in
the order given and the first match wins.  The operators are C<gt>, C<ge>,
C<lt>, C<le>, C<eq> and C<ne>; a comparison is numeric when both the cell and
the rule's value look like numbers, and otherwise only C<eq>/C<ne> are
meaningful (case-insensitive).  A colour is C<#rgb>, C<#rrggbb> or a CSS name
such as C<red> or C<teal>.  A value that matches no rule gets C<color_default=>,
which the legend shows as "Other".  C<series=> is the categorical
alternative: each distinct value takes the next colour from C<scheme=>,
cycling through the palette, and the legend lists the categories.  C<color=>
and C<series=> are mutually exclusive.

=head1 METHODS

=head2 startup

Called once by Mojolicious when the application is loaded, by
C<script/database-bi>, C<morbo>, C<hypnotoad> or C<< Test::Mojo->new('Database::BI') >>.
It is not called directly.

=head3 API SPECIFICATION

=head4 INPUT

	$self   # the Database::BI application object

Configuration comes from C<database_bi.conf> in the application home, if it is
there (see L</CONFIGURATION>), or from the hashref given to
C<< Test::Mojo->new('Database::BI', { ... }) >>.  Unset keys default to
C<< data_dir => 'data' >>, C<< platform => 'web' >>, C<< language => 'en' >> and the
public D3 URL.

=head4 OUTPUT

Nothing useful is returned.  By the time it returns, the application has:

=over 4

=item * a 50 MiB limit on request bodies (an upload over it is answered C<413>);

=item * Template Toolkit registered as handler C<tt>, and the Buffer plugin
(see L</Compression and the page cache>);

=item * the CHI cache for tables (the C<Memory> driver unless C<cache =E<gt> { driver }>
names another), and the page cache when C<page_cache_dir> is set;

=item * the C<before_dispatch> hooks for relative time ranges, cross-row plans and
the view context, and the C<before_render> hook that sets the breadcrumb, the help link
and the HTML 404 page;

=item * every route in L</ROUTES>.

=back

A configuration file that does not parse makes the C<Config> plugin croak, and
the application does not start.

=head1 COMMAND-LINE TOOLS

Two maintenance scripts ship in C<script/>; both use the same data and model
directories as the web application and are safe to run from cron.

=head2 script/bi-geocode

Warms the shared geocode cache for one column, so later map requests make no
lookups:

    ./script/bi-geocode --spec table:customers --col city \
                        [--data-dir DIR] [--model-dir DIR] \
                        [--openaddr PATH] [--region CC] [--dry-run] [--verbose]

It is idempotent: a second run against a warm cache resolves nothing and says
so.  Exit status is 0 on success, 1 when the column is missing or no rows load,
and 2 on bad arguments or an unopenable source.

=head2 script/bi-alert

Reports one or more saved analyses, and turns a crossed threshold into a
non-zero exit status so cron can act on it:

    ./script/bi-alert --analysis ID [--analysis ID ...] \
                      [--threshold MEASURE:OP:VALUE] \
                      [--threshold ANALYSIS:MEASURE:OP:VALUE ...] \
                      [--suppress DURATION] [--state-file PATH] [--recovery] \
                      [--notify-cmd COMMAND] \
                      [--data-dir DIR] [--model-dir DIR] [--dry-run]

The digest goes to STDOUT and nothing leaves the machine unless
C<--notify-cmd> says where: otherwise pipe it into mail, a webhook or a ticket
creator yourself.  Exit status is 0 when nothing is announced, 1 when a
threshold is crossed and announced, 2 on error, and 3 when a crossing that was
announced has ended and C<--recovery> was asked to announce that.  C<--dry-run>
reports without recording anything against the throttle and without running the
delivery command.

Both of those options may be repeated, so one run can watch several analyses
and several measures:

    ./script/bi-alert --analysis abc123 --analysis def456 \
                      --threshold count:gt:1000 \
                      --threshold def456:sum:lt:50 --suppress 1h

A threshold with no analysis prefix belongs to the first C<--analysis>; the
C<ANALYSIS:MEASURE:OP:VALUE> form names another of those listed.  Each analysis
is reported in full, and each (analysis, threshold) pair is a check of its own:
it prints its own line, keeps its own entry in the state file, and is throttled
and recovered on its own schedule.  One crossing never silences, recovers or
delivers another.  When a run announces both a crossing and a recovery it exits
1, so a threshold that is still crossed is not reported as an all-clear.

C<--suppress> throttles a threshold that stays crossed, so a condition that is
still true on the next cron run is not reported as news again: it takes a
duration (C<30s>, C<15m>, C<6h>, C<2d>, C<1w>, or a bare number of seconds), the
first crossing is announced, and repeats inside the period are not.  The
throttle is one small JSON file, C<alerts-state.json> in the model directory
unless C<--state-file> names elsewhere, keyed by analysis and threshold and
written atomically.  It is kept only when C<--suppress> is used or such a file
already exists, so with no C<--suppress> the script is as stateless as it has
always been and writes nothing.

A run inside the period prints C<THRESHOLD SUPPRESSED> and exits 0: it is not
announcing anything, so a cron wrapper keyed on the exit status stays quiet.
When the crossing ends the run prints C<THRESHOLD CLEARED> once and drops its
entry, which means the next crossing is announced immediately instead of
waiting out a period that belonged to an incident that is over.  A state file
that cannot be read is reported and treated as empty, so a damaged file costs
one repeated alert rather than silence, and C<--dry-run> records nothing, so a
rehearsal cannot use up the alert a real run depends on.

C<--recovery> announces that ending instead of merely reporting it: the run
prints C<THRESHOLD RECOVERED> and exits 3, so a wrapper that mails on any
non-zero status mails the all-clear as well as the alert, and a wrapper that
should not is a wrapper that does not pass C<--recovery>.  The recovery goes
through the same state file, which is what makes it possible: an entry is the
record of a crossing that was announced, so finding one is what tells the run
that an incident has ended rather than that a threshold was never crossed.  It
is therefore said once per crossing and only for a crossing somebody was told
about, which is also why C<--recovery> keeps that file even with no C<--suppress>
to throttle.  The recovery names both dates -- C<crossed since> and C<cleared>.

C<--notify-cmd> delivers the announcement itself, so a cron line is one command
rather than a shell wrapper around this one:

    ./script/bi-alert --analysis abc123 --threshold count:gt:1000 --suppress 1h \
        --recovery --notify-cmd 'mail -s "$BI_ALERT_SUBJECT" oncall@example.com'

The command runs once per run, through the shell, and only when something is
announced: a crossing (exit 1), or its end with C<--recovery> (exit 3).  A
suppressed repeat, an uncrossed threshold, an error and a C<--dry-run> run it
not at all, and twenty checks still send one mail.  The whole run's text arrives
on standard input, and three variables say what it is -- C<BI_ALERT_EVENT>
(C<crossed> if any crossing was announced, otherwise C<recovery>),
C<BI_ALERT_SUBJECT> (the verdict line when one thing was announced, otherwise a
count such as C<2 threshold crossings, 1 recovery>) and
C<BI_ALERT_MESSAGE_FILE> (the same text in a file, for a command that has to
post a body: C<curl -d @$BI_ALERT_MESSAGE_FILE ...>).  A delivery that fails is
reported on STDERR and leaves the exit status alone, but the announcements are
not recorded, so the next run announces them again rather than the alert being
lost for the rest of the period.

C<script/database-bi> is the web application launcher: run with no arguments it
starts the reloading development server, with a command word it runs that
command, and C<hypnotoad script/database-bi> starts a preforking server (see
L</SYNOPSIS>).

=head1 COMMON PITFALLS

=over 4

=item B<The launcher's shebang must name perl, not morbo>

morbo starts the application as C<perl script/database-bi daemon>, and perl
hands a script whose C<#!> line does not mention perl to the interpreter that
line names.  With a C<morbo> shebang every worker therefore started another
morbo: the chain grew a process a second, kept the listening port, and only
stopped when the environment copied to each child was too large for C<exec>
(F<Argument list too long>).  The shebang is perl and the script starts the
server itself when it is given no arguments.

=item B<The configuration file is optional but must be valid Perl if present>

C<database_bi.conf> is loaded by C<Mojolicious::Plugin::Config>, which
evaluates it as a Perl data structure.  If the file exists but contains a
syntax error, the application will refuse to start.  If the file does not
exist, built-in defaults are used and no error occurs.  The file must return
a hashref:

    # database_bi.conf -- correct
    { data_dir => 'data', platform => 'web', language => 'en' }

    # WRONG -- missing braces
    data_dir => 'data'

=item B<data_dir is relative to the application home directory, not the process cwd>

Setting C<data_dir =E<gt> 'data'> looks for a folder called C<data/> in the
same directory as the C<script/database-bi> launcher, regardless of where you
run the server from.  An absolute path works on any system:

    { data_dir => '/var/db/mydata' }

=item B<The download_dir default is computed once at startup>

When the application starts, it picks the export directory in this order:
C<~/Downloads> (if it exists), then C<$HOME>, then the system temp directory.
This value is fixed for the life of the process.  Renaming or creating
C<~/Downloads> after the server starts has no effect.  To force a different
default, set it before starting:

    { data_dir => 'data' }   # and create ~/Downloads before starting the server

=item B<Adding a new language requires a template directory, not just a config change>

Setting C<language =E<gt> 'de'> in C<database_bi.conf> tells the controller
to look for templates in C<templates/web/de/>.  If that directory does not
exist, the controller automatically falls back to the default language, and
the same fallback applies when a browser asks for a language no directory
serves.  To add German support: (1) create C<templates/web/de/>, (2) copy and
translate the C<.html.tt> files from C<templates/web/en/>, then (3) set the
config.

=item B<Supported data file extensions are: csv, db, sql, sqlite, sqlite3, xml, psv, tsv, xlsx>

The application recognises C<.csv>, C<.db>, C<.sql>, C<.sqlite>, C<.sqlite3>,
C<.xml>, C<.psv>, C<.tsv>, and C<.xlsx> files.  All three SQLite extensions
(C<.sql>, C<.sqlite>, C<.sqlite3>) are treated identically -- C<inventory.sqlite>
and C<inventory.sqlite3> are both opened as SQLite databases without renaming.
Excel C<.xlsx> files are read directly via C<Spreadsheet::ParseXLSX>.

URLs will work.
For example enter
L<https://worldpopulationreview.com/country-rankings/immigration-by-country>
into the C<Import from a web page> field on the dashboard.

=item B<The open_table helper lowercases the table name>

When the router matches C<GET /view/Sales> or C<GET /view/SALES>, the table
name is lowercased to C<sales> before being passed to the helper.  The data
file on disc must therefore also be lowercase (C<sales.csv>, not
C<Sales.csv>).

=item B<Redis support requires the Redis or Redis::Fast module>

Redis data source access is an optional feature.  If neither C<Redis> nor
C<Redis::Fast> is installed, entering a C<redis:...> spec returns a 404.
To enable Redis support, install either module:

    cpanm Redis::Fast   # recommended -- C bindings, faster
    cpanm Redis         # pure-Perl fallback

Redis keys must follow the C<tablename:entry> convention: each key is the
table name, a colon, and an entry identifier; the value is a Redis hash
whose fields become the row columns.  For example:

    HSET players:row1 name Alice score 10
    HSET players:row2 name Bob   score 20

Opening C<redis:players|redis://localhost:6379> then displays a two-row table
with columns C<entry>, C<name>, and C<score>.

=back

=head1 LIMITATIONS

=over 4

=item *

Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.

=item *

A relative time range is resolved against the server's clock and compares the
column as a string, like every other filter.  A column holding a time zone
offset or a non-ISO timestamp is read as far as its C<YYYY-MM-DD> prefix, so
C<last_24_hours> is exact only for a column whose values are ISO
C<YYYY-MM-DDTHH:MM:SS> (a space instead of the C<T> is accepted too).

=item *

Multi-table left joins are performed in memory by L<Database::Join>.  All
component tables are fetched into RAM before the merge; this is not
suitable for files that do not fit in the process's available memory.

=item *

Upload staging is managed automatically.  On every server startup,
C<Database::BI> evicts upload subdirectories whose modification time is
older than 24 hours.  The "Clear upload cache" button (C<POST
/uploads/clear>) triggers an immediate full purge regardless of age.

=item *

C<Sub::Protected>/:Protected enforcement relies on the CHECK compilation
phase.  When a module is loaded dynamically at test time (e.g. via
C<Test::Mojo->new(...)>), the CHECK phase has already passed and the
"Too late to run CHECK block" warning is emitted -- the access
restriction is not enforced in that test context.  This does not affect
production (morbo/hypnotoad) deployments where modules are compiled on
startup.  Unlike the former C<Sub::Private> approach, C<Sub::Protected>
does not delete stash entries, so OO dispatch C<< $self->_method() >>
works correctly in production without any special workarounds.

=back

=head1 ROADMAP

Features planned for future releases (post-0.018.0).  Items are ordered by
priority.  Items shipped before this release (XLSX export, the copy-link
button, the column statistics panel, folder filter/join propagation and the
aggregate/measure layer) are no longer listed.

=over 4

=item * B<Multi-sheet XLSX> (Medium) -- C<_detect_file_info> reads only the
first worksheet.  A C<?sheet=> URL param with a sheet-name picker would
expose the full workbook.

=item * B<C<between> and C<in (a,b,c)> filter operators> (Low) -- Would
reduce multi-filter chains for common range and set queries.

=item * B<SSE streaming for large join results> (Low) -- The join pipeline
blocks the HTTP response until all rows are assembled.  Mojolicious supports
server-sent events, which could progressively stream rows to a JS table
renderer, giving visible progress on slow joins.

=item * B<Boundary overlay on maps> (Low) -- C<HTML::OSM> can draw GeoJSON and
choropleth layers.  A C<gj=E<lt>pathE<gt>> parameter would overlay a local
GeoJSON file, optionally shaded by an aggregated measure.  This is the one
Phase 6 item not implemented: it is optional in the phase spec, and no boundary
data is shipped or downloaded.

=back

=cut

# =============================================================================
# KNOWN GAPS & ROADMAP
# =============================================================================
#
# Items marked [NEW 0.010.0] were identified during the 0.010.0 gap analysis.
# Items completed in 0.012.0:
#   A. Pagination -- done: /view, /open, /join, /combine, /export all paginate.
#   1. dbi_source() proxy -- done: DataSource::dbi_source() delegating method added.
#   2. limit/offset plumbing -- done: /join, /combine, /export thread pagination.
#   3. order_by delegation -- done: ?sort=col&dir=asc|desc on /join and /combine.
#   4. Filter pushdown -- done: _filter_specs_to_criteria translates f= specs to
#      SQL criteria for SQLite sources; _grouped_totals and _fetch_page both use it.
#   5. Schema warnings UI -- done: every route that builds a join compares the
#      declared types at each step (DataSource::schema, _schema_type_warnings),
#      and the join page shows a banner.  The chart/export pipeline records the
#      same warnings; /export returns them in the X-BI-Warnings header.
#      Database::Join's own warn_schema_type_mismatch cannot fire here, because
#      these joins always pass a collision_prefix for the right table.
#   6. updated() in DataSource -- done: DataSource::updated() delegates to inner DA.
#
# ---- POST-RELEASE FEATURE ROADMAP ----
#
# Completed since 0.010.0, so no longer listed here: XLSX export (B), the
# copy-link button on chart pages (C), the column statistics panel (D), and
# folder-view filter/join propagation (F).  The same list lives in the POD
# ROADMAP above; keep the two in step.
#
# E. [NEW 0.010.0] Multi-sheet XLSX (Medium priority)
#    _detect_file_info reads only worksheet index 0.  A ?sheet= URL param
#    with a sheet-name picker would expose the full workbook.
#
# G. [NEW 0.010.0] between / in(a,b,c) filter operators (Low priority)
#    Would reduce multi-f= chains for common range and set queries.  The
#    operator allowlist in _apply_filter_spec is the only required change.
#
# H. [NEW 0.010.0] SSE streaming for large join results (Low priority)
#    The join pipeline blocks the HTTP response until all rows are assembled.
#    Mojolicious write_chunk / finish can progressively stream rows, giving
#    visible progress on slow multi-table joins.
#
# ---- OPEN INTEGRATION GAPS ----
#
# I. parallel => 1 for multi-step join chains
#    --------------------------------------------
#    When the user chains three or more j= join steps, Database::BI creates a
#    single Database::Join object with multiple secondary databases.  Enabling
#    parallel => 1 on that object would issue the secondary DA fetches
#    concurrently when the threads module is available.  However: DataSource is
#    not thread-safe (it holds a CHI cache handle and open file handles).  Before
#    enabling parallel, DataSource must be audited for thread safety -- at minimum
#    the CHI driver must be confirmed re-entrant, or a separate DataSource clone
#    created per thread.
#    Short-term: do not enable parallel => 1; add a FIXME comment to the join
#    route noting why it is disabled.  Longer-term: implement DataSource::clone()
#    that creates an independent handle per thread.
#
# J. per-table filters => on the join pipeline
#    --------------------------------------------
#    The /join route accepts f=col:op:val filters that are applied as post-join
#    in-memory filtering in the template.  Database::Join 0.007.0's filters =>
#    constructor parameter applies per-database criteria at spill time on the
#    SQLite backend, which is far cheaper for large tables.  When a filter column
#    is known to belong to a specific source table (i.e. it appears in
#    $join->columns() but also in one component DA's columns()), the join route
#    could partition filters by owning database and pass them as filters => to
#    the Database::Join constructor.  Filters on the merged view (post-join
#    computed columns) must remain as template-side filtering.
#
# K. collision_prefix exposure in the join UI
#    --------------------------------------------
#    When two joined tables share a column name, Database::Join's default
#    last-table-wins behaviour silently discards one table's value.  The join
#    UI (the "Merge data" panel) could offer a "rename duplicate columns from
#    right table" text field so users can configure collision_prefix without
#    writing code.  The entered prefix would be passed as
#    collision_prefix => { 1 => $prefix } when constructing Database::Join.
# =============================================================================

sub startup ($self) {
	$self->plugin('Config', {
		default => {
			data_dir => $DEFAULT_DATA_DIR,
			platform => $DEFAULT_PLATFORM,
			language => $DEFAULT_LANGUAGE,
			d3_url   => $DEFAULT_D3_URL,
		}
	});

	# Cap inbound request body size.  When the limit fires, Mojolicious sets
	# req->is_limit_exceeded and still dispatches to the controller (with partial
	# content in the upload asset).  The controller checks is_limit_exceeded and
	# returns 413 before writing to disc.
	$self->max_request_size($MAX_REQUEST_SIZE);

	# Default export/save directory: ~/Downloads when it exists, else HOME,
	# else system tmpdir.  Resolved once per process and stored as a stash
	# default so every action can read $self->stash('download_dir').
	my $home   = $ENV{HOME} // '';
	my $dl_dir = ($home && -d "$home/Downloads") ? "$home/Downloads"
	           : ($home || File::Spec->tmpdir());
	$self->defaults(download_dir => $dl_dir);

	# Register the TT plugin as 'tt' (not the default 'tt2') so that template
	# files keep the .html.tt extension and handler => 'tt' in render() calls
	# resolves correctly via Template::Provider::Mojo.  TT options must live
	# under the 'template' key; top-level keys are plugin options only.
	$self->plugin('TemplateToolkit', {
		name     => 'tt',
		template => {
			POST_CHOMP => 1,
			TRIM       => 1,
		},
	});

	# Response compression (gzip/Brotli), ETag/304 handling, and HTML
	# whitespace minification.  Level 1 leaves <script>/<style> content
	# alone; level 2 runs aggressive JS minification and is not safe with
	# the inline JavaScript in the dashboard and home templates.
	# vary_by adds Accept-Language to the cache key so VWF language
	# detection stores one copy per language.
	my $page_cache_dir = $self->config->{page_cache_dir};
	my $page_chi;
	if ($page_cache_dir) {
		my $dir = Mojo::File->new($page_cache_dir);
		$dir = $self->home->child($page_cache_dir) unless $dir->is_abs;
		$dir->make_path;
		$page_chi = CHI->new(
			driver    => 'File',
			root_dir  => $dir->to_string,
			namespace => 'Database::BI::Pages',
		);
	}
	$self->plugin('Buffer', {
		optimise_content => 1,
		vary_by          => ['accept-language'],
		($page_chi ? (
			cache          => $page_chi,
			cache_duration => $self->config->{page_cache_duration} // '5 minutes',
		) : ()),
	});

	# A relative time range named in the URL (?range=last_30_days&rcol=when)
	# becomes the f= filters every data route already applies, so the table
	# view, every chart, the pivot, stats, insights, the exports and a saved
	# canvas all narrow to the same rows without any per-route code.  It runs
	# before dispatch because the range has to be part of the request's filter
	# list by the time a route reads it, and a range that cannot be honoured
	# answers 400 here rather than filtering the wrong rows.
	$self->hook(before_dispatch => sub {
		my $c = shift;

		require Database::BI::Controller::Dashboard;
		return Database::BI::Controller::Dashboard::_time_range_request($c);
	});

	# Cross-row columns (?cs=/by=/order=) are part of the view: the table page
	# draws a chip for each one and its panel edits them, and every chart panel
	# carries them to its route, which runs the same pass over the same rows.
	# It is a hook rather than four stash lines in each of the seven actions that
	# render the dashboard, so a new action cannot silently lose them.
	$self->hook(before_dispatch => sub {
		my $c = shift;

		require Database::BI::Controller::Dashboard;
		$c->stash(Database::BI::Controller::Dashboard::_cross_row_ui_state($c));
	});

	# The rest of the view a request carries -- the join type, the reader's
	# filters, the files stacked in with c= and de-duplication -- for the same
	# reason: the dashboard's panels pass it on through one macro, and every
	# chart page names it under its breadcrumb, so a chart never looks like
	# the whole file when it is drawn from part of it.
	$self->hook(before_dispatch => sub {
		my $c = shift;

		my $jtype = $c->param('jtype') // '';
		$c->stash(
			view_join_type => ($jtype =~ /\A(?:left|inner|outer)\z/ ? $jtype : ''),
			view_filters   => [ grep { length } @{ $c->every_param('f') } ],
			view_combines  => [ grep { /\A(?:path|table|url|redis):/i } @{ $c->every_param('c') } ],
			view_dedup     => ($c->param('d') ? 1 : 0),
		);
	});

	# Every page names the tutorial chapter that helps with it.  The layout
	# turns this into a "Help: ..." link beside the main Tutorial link, so a
	# reader on the pie chart screen lands on the pie chart chapter.  It lives
	# here rather than in every action: a new action is one entry in the action
	# map in Database::BI::Tutorial, and t/tutorial.t checks it is there.
	$self->hook(before_render => sub {
		my ($c, $args) = @_;

		# AI availability flag used by dashboard and insights templates.
		$c->stash(ai_available => (length($c->app->config('ai_api_key') // '') ? 1 : 0))
			unless defined $c->stash('ai_available');

		# The chart pages and canvases read this from the stash.  Resolving it
		# per request rather than once at startup means a deployment (and a
		# test) can point D3 at a local copy by changing the config.
		my $d3_url = $c->app->config('d3_url');
		$c->stash(d3_url =>
			(defined $d3_url && !ref $d3_url && length $d3_url)
				? $d3_url : $DEFAULT_D3_URL);

		# Mojolicious's own 404 page has no navigation and no breadcrumb; an
		# HTML one is drawn from our not_found template instead.  Its first
		# try is "not_found.<mode>", so that is the one replaced.  JSON
		# replies and exceptions keep the defaults.
		# The language is the one the action already chose, if it got that far
		# (_resolve_template is protected, so it cannot be asked from here).
		if (($args->{template} // '') =~ /\Anot_found\.\w+\z/
			&& ($args->{format} // $c->stash('format') // 'html') eq 'html') {
			my $conf     = $c->app->config;
			my $platform = $conf->{platform} // 'web';
			my $language = $c->stash('language') // '';
			$language = $conf->{language} // 'en'
				unless $language =~ /\A[a-z]{2}(?:[-_][A-Za-z]{2})?\z/
					&& -d $c->app->home->child("templates/$platform/$language");
			$args->{template} = "$platform/$language/not_found";
			$args->{handler}  = 'tt';
			$c->stash(title => 'Page not found', language => $language);
		}

		# The breadcrumb trail (layouts/breadcrumb.html.tt), worked out from the
		# request's own URL, so every page has one and a new page gets one
		# without code of its own.
		if (!defined $c->stash('trail')) {
			require Database::BI::Controller::Dashboard;
			$c->stash(trail => Database::BI::Controller::Dashboard::_breadcrumb_trail($c));
		}

		return if defined $c->stash('tutorial_chapter');

		my $chapter = Database::BI::Tutorial->chapter_for_action($c->stash('action'));
		return unless $chapter;

		$c->stash(
			tutorial_chapter       => $chapter->{id},
			tutorial_chapter_title => $chapter->{title},
		);
	});

	# Factory helper: opens any named table from the configured data directory.
	# The directory=> option overrides the default so open_file and upload_file
	# can open tables from arbitrary filesystem paths.
	#
	# Joins are handled by Database::Join in the controller pipeline;
	# open_table returns a single DataSource per table.
	#
	# Resolved with the rule the controller's _data_dir_for applies: a relative
	# value is relative to the application home, an absolute one is used as
	# given.  Mojo::File->child appends an absolute path instead of replacing
	# the base, so home->child($absolute) named a directory that cannot exist,
	# and /view - which opens its table without a directory of its own - read
	# from it and served an empty page.
	my $configured = $self->config->{data_dir} // 'data';
	my $data_path  = Mojo::File->new($configured);
	$data_path = $self->home->child($configured) unless $data_path->is_abs;
	my $data_dir = $data_path->to_string;

	# In-process CHI cache: shared across all requests in the same worker process.
	# The Memory driver needs no external services and works out of the box.
	# Set global => 1 so the same namespace is reused across multiple open_table
	# calls within one process rather than creating separate isolated caches.
	my $cache_conf    = $self->config->{cache} // {};
	my $cache_ttl_url = $cache_conf->{ttl_url} // $DEFAULT_CACHE_TTL_URL;
	my $chi = CHI->new(
		driver    => $cache_conf->{driver} // 'Memory',
		global    => 1,
		namespace => 'Database::BI',
	);

	$self->helper(open_table => sub($c, $table, %opts) {
		# URL mode: fetch a remote HTML table directly via Database::Abstraction's
		# URL backend (LWP::UserAgent + HTML::TableExtract).
		if (exists $opts{url}) {
			return Database::BI::Model::DataSource->new(
				url           => $opts{url},
				cache         => $chi,
				cache_ttl_url => $cache_ttl_url,
				exists $opts{html_table_index}
					? (html_table_index => $opts{html_table_index})
					: (),
			);
		}
		# Redis mode: connect to a Redis server via Database::Abstraction's
		# Redis backend (Redis::Fast or Redis).
		if (exists $opts{redis}) {
			return Database::BI::Model::DataSource->new(
				table         => $table,
				redis         => $opts{redis},
				cache         => $chi,
				cache_ttl_url => $cache_ttl_url,
			);
		}
		my $dir = exists $opts{directory} ? $opts{directory} : $data_dir;
		Database::BI::Model::DataSource->new(
			directory      => $dir,
			table          => $table,
			cache          => $chi,
			cache_ttl_url  => $cache_ttl_url,
			exists $opts{host}           ? (host           => $opts{host})           : (),
			exists $opts{file_ext}       ? (file_ext       => $opts{file_ext})       : (),
			exists $opts{internal_table} ? (internal_table => $opts{internal_table}) : (),
		);
	});

	my $r = $self->routes();
	$r->get('/')->to('Dashboard#index');
	$r->get('/tutorial')->to('Dashboard#tutorial');
	$r->get('/view/:table')->to('Dashboard#view');
	$r->get('/browse')->to('Dashboard#browse');
	$r->get('/open')->to('Dashboard#open_file');
	$r->get('/join')->to('Dashboard#join_tables');
	$r->get('/api/columns')->to('Dashboard#columns_api');
	$r->get('/api/range')->to('Dashboard#range_api');
	$r->get('/import')->to('Dashboard#import_url');
	$r->get('/combine')->to('Dashboard#combine_tables');
	$r->get('/export')->to('Dashboard#export_data');
	$r->post('/export')->to('Dashboard#export_write');
	$r->get('/api/dirs')->to('Dashboard#dirs_api');
	$r->get('/api/stat')->to('Dashboard#stat_api');
	$r->post('/upload')->to('Dashboard#upload_file');
	$r->post('/uploads/clear')->to('Dashboard#clear_uploads');
	$r->get('/graph')->to('Dashboard#graph_view');
	$r->get('/pie')->to('Dashboard#pie_view');
	$r->get('/heatmap')->to('Dashboard#heatmap_view');
	$r->get('/bar')->to('Dashboard#bar_view');
	$r->get('/folder')->to('Dashboard#folder_view');
	$r->get('/tables')->to('Dashboard#tables_view');
	$r->get('/pivot')->to('Dashboard#pivot_view');
	$r->get('/stats')->to('Dashboard#stats_view');
	$r->post('/calc/save')    ->to('Dashboard#calc_save');
	$r->post('/calc/delete')  ->to('Dashboard#calc_delete');
	$r->get('/calc/list')     ->to('Dashboard#calc_list');
	$r->post('/groups/save')  ->to('Dashboard#groups_save');
	$r->post('/groups/delete')->to('Dashboard#groups_delete');
	$r->get('/groups/list')   ->to('Dashboard#groups_list');
	$r->post('/dates/save')   ->to('Dashboard#dates_save');
	$r->post('/dates/delete') ->to('Dashboard#dates_delete');
	$r->get('/dates/list')    ->to('Dashboard#dates_list');
	$r->post('/geo/save')     ->to('Dashboard#geo_save');
	$r->post('/geo/delete')   ->to('Dashboard#geo_delete');
	$r->get('/geo/list')      ->to('Dashboard#geo_list');
	$r->get('/scatter')       ->to('Dashboard#scatter_view');
	$r->get('/stacked')       ->to('Dashboard#stacked_view');
	$r->get('/combo')         ->to('Dashboard#combo_view');
	$r->get('/treemap')       ->to('Dashboard#treemap_view');
	$r->get('/histogram')     ->to('Dashboard#histogram_view');
	$r->get('/wordcloud')     ->to('Dashboard#wordcloud_view');
	$r->get('/map')           ->to('Dashboard#map_view');
	$r->get('/line')          ->to('Dashboard#graph_view');	# alias for /graph
	$r->post('/api/ask')       ->to('Dashboard#ask_api');
	$r->get('/insights')      ->to('Dashboard#insights_view');
	$r->post('/api/summary')  ->to('Dashboard#summary_api');

	# Saved analyses
	# /api/analyses/import must be registered BEFORE /api/analyses/:id so that the
	# literal segment "import" is matched before the :id placeholder captures it.
	$r->get('/a/:id')                   ->to('Dashboard#canvas_render');
	$r->get('/api/analyses')            ->to('Dashboard#analyses_list');
	$r->post('/api/analyses')           ->to('Dashboard#analyses_create');
	$r->post('/api/analyses/import')    ->to('Dashboard#analyses_import');
	$r->get('/api/analyses/:id')        ->to('Dashboard#analyses_get');
	$r->put('/api/analyses/:id')        ->to('Dashboard#analyses_update');
	$r->patch('/api/analyses/:id')      ->to('Dashboard#analyses_patch');	$r->delete('/api/analyses/:id')      ->to('Dashboard#analyses_delete');
	$r->post('/api/analyses/:id/visuals')->to('Dashboard#analyses_add_visual');
	$r->patch('/api/analyses/:id/visuals/:visual')->to('Dashboard#analyses_update_visual');
	$r->get('/api/analyses/:id/export') ->to('Dashboard#analyses_export');

	# extracts, catalog, sharing, embedding, per-visual downloads
	$r->get('/catalog')                       ->to('Dashboard#catalog_view');
	$r->get('/share/:id')                     ->to('Dashboard#share_view');
	$r->get('/embed/:id')                     ->to('Dashboard#embed_view');
	$r->get('/a/:id/visual/:n/:fmt')          ->to('Dashboard#visual_download');
	$r->post('/api/analyses/:id/share')       ->to('Dashboard#analyses_share');

	# Evict stale upload subdirectories on every startup so the cache cannot
	# grow unboundedly across server restarts.  Only entries whose mtime is
	# older than $UPLOAD_MAX_AGE_S seconds are removed; recent uploads that
	# were made while the previous server process was running are preserved.
	_evict_old_uploads($self->_uploads_dir, $UPLOAD_MAX_AGE_S);
}

# _uploads_dir() -> Mojo::File
#
# Purpose: The one place that decides where POST /upload stages its files.
# Entry:   $self->config->{uploads_dir} may be unset (the default), a path
#          relative to the application home, or an absolute path.
# Exit:    A Mojo::File; the directory may not exist yet.
#
# upload_file, clear_uploads and the startup eviction all resolve the
# directory through here, so a configured staging directory is written to and
# purged as one.  Resolving it per call rather than once in startup() is what
# lets a caller - a test in particular - point one application instance at its
# own directory without touching the shared <home>/.uploads that another
# process may be clearing at the same moment.
sub _uploads_dir ($self) {
	my $dir = $self->config->{uploads_dir};
	return $self->home->child('.uploads')
		unless defined $dir && !ref $dir && length $dir;

	my $path = Mojo::File->new($dir);
	return $path->is_abs ? $path : $self->home->child($dir);
}

# _evict_old_uploads( $uploads_dir, $max_age_s ) -> void
#
# Purpose: Remove upload subdirectory trees whose mtime is older than $max_age_s
#          seconds.  Runs at startup and is also called by clear_uploads (via the
#          Dashboard controller) when the user explicitly requests a purge.
# Entry:   $uploads_dir is a Mojo::File.  $max_age_s is a positive integer.
# Exit:    Silent on success.  Individual remove_tree failures are non-fatal.
sub _evict_old_uploads {
	my ($uploads_dir, $max_age_s) = @_;
	return unless -d $uploads_dir;

	my $cutoff = time() - $max_age_s;

	$uploads_dir->list({ dir => 1 })->each(sub {
		my ($entry) = @_;
		my $mtime = (stat $entry)[9] // 0;
		return if $mtime >= $cutoff;	# still fresh -- keep it
		if (-d $entry) {
			$entry->remove_tree;
		} elsif (-f $entry) {
			unlink $entry->to_string;
		}
	});
}

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-BI/coverage/>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Database-BI>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
