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

our $VERSION = '0.016.0';

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

0.016.0

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
(C<sum|avg|min|max|count|count_distinct>).  Supports subtotals, HAVING
filters, top-N row groups, and direct export to CSV, SQLite, JSON, or XLSX.

=item *

B<Column statistics> -- the column-stats button runs C<GET /stats>, which
returns one row per column: row count, null count, distinct count, and
(for numeric columns) min, max, mean, and median.

=item *

B<Calculated fields> -- virtual columns defined by inline C<?c=name:expr>
URL params or stored persistently via C<POST /calc/save>.  Expressions
support arithmetic, comparison, C<IF>, string, numeric, and date
functions, plus C<bin(value,width)> for histogram grouping.  Calc fields
are applied before aggregation on all chart and pivot routes.

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
not be loaded it names the missing library instead.  Canvases support
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

    morbo script/database-bi

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
(repeatable) to pre-filter results.

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
  f=<col>:<op>:<val>     result filter (repeatable)

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
  c=<spec>               additional table to stack (repeatable)
  f=<col>:<op>:<val>     result filter applied after combining (repeatable)

=item C<GET /graph>

Renders a D3.js v7 zoomable line chart of any two columns.  Parameters:

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
  m=col:fn:alias       measure spec, repeatable (fn: sum|avg|min|max|count|count_distinct)
  totals=1             include subtotals column and grand-total row
  topn=N               keep only the top-N row groups
  topn_col=<alias>     measure alias to rank by (required when topn= is set)
  max_cols=N           collapse tail column combos beyond top-N into "Other"
  format=csv|sqlite|json|xlsx  stream result as a download
  back=<url>           URL for the back breadcrumb link
  f=                   result filters applied before aggregating (repeatable)

=item C<GET /stats>

Per-column statistics view.  Returns one row per column: row count, null
count, distinct count, and (for numeric columns) min, max, mean, and median.
Parameters: C<l=E<lt>specE<gt>> (required) and C<f=> filters.

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

=item C<GET /map>

OpenStreetMap map of the filtered view, drawn with HTML::OSM.  A row's position
comes from a location column that is geocoded (C<loc=>, one lookup per distinct
value, remembered once in the model store and shared with every dataset that
names it) or from coordinate columns (C<lat=> and C<lon=>).  Rows sharing a
position become one marker.  Markers are clustered with
Leaflet.markercluster, so a dense map draws a count at low zoom and splits it
as it is zoomed in.  Parameters:

  l=<spec>      left table (required)
  loc=<col>     column of places to geocode (required unless lat= and lon= are)
  lat=<col>     latitude column, -90..90
  lon=<col>     longitude column, -180..180
  popup=<col>   column shown in the marker popup (repeatable)
  max=N         markers to draw (default map_max_markers, 2000)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=            result filters (repeatable)

=item C<GET /line>

Alias for C<GET /graph>.  All C</graph> parameters accepted.

=item C<GET /a/:id>

Renders a saved canvas (analysis) as a full multi-visual page.  Accepts
cross-filter params C<?cf=E<lt>colE<gt>&cv=E<lt>valE<gt>>, drill-through
params C<?dd=E<lt>colE<gt>&dl=E<lt>levelE<gt>>, and parameter overrides
C<?p.E<lt>nameE<gt>=E<lt>valueE<gt>>.

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
C<histogram> or C<map>.  A map's C<encode> names either C<loc> (a place column
to geocode) or C<lat> and C<lon>.  The optional C<query> is the canvas page's
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
patterns.  Accepts C<?l=E<lt>specE<gt>>.

=item C<POST /dates/save>

Saves a date-normalisation pattern for a column.  Body: C<l=&col=&pattern=>.
Supported patterns: C<%m/%d/%Y> (US), C<%d/%m/%Y> (EU), C<%d-%b-%Y> (DD-Mon-YYYY).

=item C<POST /dates/delete>

Removes a date-normalisation pattern.  Body: C<l=&col=>.
Omit C<col=> to clear all patterns for the spec.

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

=head1 CONFIGURATION

Place a C<database_bi.conf> file in the application root to override
defaults:

    {
        data_dir => 'data',   # directory scanned for data files on the home page
        platform => 'web',    # VWF template dimension
        language => 'en',     # VWF template dimension

        # Browser-side libraries.  d3_url overrides the chart and canvas
        # script; the leaflet_* keys override the map assets, and tile_url
        # overrides the tile server.  See "Self-hosting D3 and Leaflet"
        # below.
        d3_url => 'https://cdnjs.cloudflare.com/ajax/libs/d3/7.9.0/d3.min.js',
    }

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
on the map, since it is the usual credit for OSM-derived tiles.  The in-page
place search still calls Nominatim if a reader uses it.

=head1 COMMON PITFALLS

=over 4

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
exist, the controller automatically falls back to the default language.  To
add German support: (1) create C<templates/web/de/>, (2) copy and translate
the C<.html.tt> files from C<templates/web/en/>, then (3) set the config.

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

Features planned for future releases (post-0.013.0).  Items are ordered by
priority.

=over 4

=item * B<Folder view filter/join propagation> (Medium) -- The folder view
panel does not carry forward active C<j=> and C<f=> params when building
the C</folder> URL.  Users who have filtered or joined a table and then
click "Folder view" silently lose their filter context.

=item * B<Multi-sheet XLSX> (Medium) -- C<_detect_file_info> reads only the
first worksheet.  A C<?sheet=> URL param with a sheet-name picker would
expose the full workbook.

=item * B<C<between> and C<in (a,b,c)> filter operators> (Low) -- Would
reduce multi-filter chains for common range and set queries.

=item * B<SSE streaming for large join results> (Low) -- The join pipeline
blocks the HTTP response until all rows are assembled.  Mojolicious supports
server-sent events, which could progressively stream rows to a JS table
renderer, giving visible progress on slow joins.

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
#   5. Schema warnings UI -- partial: join_tables captures and passes schema_warnings;
#      BI-side type-mismatch detection is still open.
#   6. updated() in DataSource -- done: DataSource::updated() delegates to inner DA.
#
# ---- POST-RELEASE FEATURE ROADMAP ----
#
# B. [NEW 0.010.0] XLSX export (High priority)
#    /export supports CSV, SQLite, and JSON but not XLSX output.
#    Excel::Writer::XLSX would close the round-trip for users whose source
#    data is XLSX.  The read side already uses Spreadsheet::ParseXLSX.
#
# C. [NEW 0.010.0] Copy-link button on chart pages (Medium priority)
#    /graph, /pie, /heatmap, and /bar have fully parameterised URLs but no
#    copy-link button.  The mechanism already exists in dashboard.html.tt;
#    it is a template refactor to share the component.
#
# D. [NEW 0.010.0] Column statistics panel (Medium priority)
#    Per-column popover showing min, max, mean, median, and null-count.
#    List::Util is already in PREREQ_PM; only Statistics::Descriptive (or
#    inline computation) is needed.
#
# E. [NEW 0.010.0] Multi-sheet XLSX (Medium priority)
#    _detect_file_info reads only worksheet index 0.  A ?sheet= URL param
#    with a sheet-name picker would expose the full workbook.
#
# F. [NEW 0.010.0] Folder view: propagate active filters and joins (Medium)
#    _run_export_pipeline already handles j= and f= params so /folder works
#    on joined/filtered data when the URL is crafted manually.  The folder
#    panel JS in dashboard.html.tt must carry forward the current j= and f=
#    params when building the base_url so users do not lose their filter
#    context on click.
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

	# Every page names the tutorial chapter that helps with it.  The layout
	# turns this into a "Help: ..." link beside the main Tutorial link, so a
	# reader on the pie chart screen lands on the pie chart chapter.  It lives
	# here rather than in every action: a new action is one entry in the action
	# map in Database::BI::Tutorial, and t/tutorial.t checks it is there.
	$self->hook(before_render => sub {
		my $c = shift;

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
	my $data_dir = $self->home->child($self->config->{data_dir})->to_string;

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
	$r->get('/scatter')       ->to('Dashboard#scatter_view');
	$r->get('/stacked')       ->to('Dashboard#stacked_view');
	$r->get('/combo')         ->to('Dashboard#combo_view');
	$r->get('/treemap')       ->to('Dashboard#treemap_view');
	$r->get('/histogram')     ->to('Dashboard#histogram_view');
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
	_evict_old_uploads($self->home->child('.uploads'), $UPLOAD_MAX_AGE_S);
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
