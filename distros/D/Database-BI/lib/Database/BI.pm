package Database::BI;

use strict;
use warnings;

use Mojo::Base 'Mojolicious', -strict, -signatures;

use Carp qw(croak);
use Mojo::File ();
use Mojo::URL;
use Database::BI::I18N ();
use Database::BI::Sessions;
use CHI	();
use File::Spec ();
use Readonly;

use Database::BI::Model::DataSource;
use Database::BI::Tutorial;

# version->declare here alone: this is VERSION_FROM, and with it MakeMaker
# writes 0.023.0 into META; a plain dotted string becomes v0.023.0 there.
use version; our $VERSION = version->declare('0.023.0');

# The roadmap after 0.021.0, from its gap analysis (2026-11-06).
#
# Features:
# TODO: Time zones.  A timestamp's Z or offset is accepted and ignored (times
#	are compared as written).  Normalise to UTC or a configured zone, with
#	Time range and span= buckets aware of it.
# TODO: More JSON: JSON Lines (.jsonl, .ndjson); optional dot-path flattening
#	of nested objects (address.city) instead of JSON text; reading a large
#	file as a stream rather than all at once.
# TODO: Ranges for historical data: windows anchored to the data rather than
#	to today ("the first decade in the data"), and decade and century span=
#	buckets for year columns.
# TODO: Multi-sheet XLSX: ?sheet= and a sheet picker, through the /tables
#	cards that JSON and SQLite use.
# TODO: A better Print: a heading naming the view's filters and range, a
#	"print the rows shown" mode, and a server-side PDF for views too large
#	for the browser to lay out (Print asks first past 10,000 rows).
# TODO: Encoding on upload: detect Windows-1252 (a BOM is read past since
#	0.021.0) and say which encoding was used.
# TODO: Alerts in the app: a canvas panel to set bi-alert's thresholds and
#	see recent alerts, so they do not need cron.
# TODO: More databases: PostgreSQL through Database::Join::Catalog, as MariaDB
#	is, and a columnar backend (DuckDB or Parquet) for files too large for
#	SQLite extracts.
#
# Technical debt:
# TODO: Dashboard.pm is over 15,000 lines.  Split it by area (charts, canvas,
#	model stores, export and access, geo) into controllers of their own;
#	the routes stay here.
# TODO: One validated filter representation.  f= is split in _filter_request,
#	_apply_filter_spec, _filter_specs_to_criteria, _fetch_page and the
#	canvas, each with its own rules; parse it once into a typed form at the
#	boundary.
# TODO: One date reader.  _is_iso_date, _to_iso_date, _date_key,
#	_time_columns, Calc::date_normalise and the browser's biDetectColType
#	each recognise dates differently (the browser takes DD-Mon-YYYY, the
#	server's filter does not).  Share one definition.
# TODO: Move dashboard.html.tt's inline script into static files (allowed by
#	script-src 'self') so it can be unit-tested, not only run in Playwright.
# TODO: Loading Dashboard.pm during the compile phase runs Sub::Protected's
#	CHECK, which alone turned the SQL path's sums into JSON strings
#	(t/time-bucket.t).  The server never loads it that way; find which
#	protected sub is responsible.
# TODO: Async work: long joins and geocoding block a worker.  Use
#	Mojo::IOLoop->subprocess, or the server-sent-events streaming, for
#	progress and free workers.
# TODO: Generated CI: the Windows cpanm retry, and the cache that never fills
#	on Windows (installs go into Perl's own site folder), belong in App::GHGen's
#	template, not in perl-ci.yml, which it overwrites.

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

# Where HTML::OSM fetches Leaflet and its tiles when the config names no
# other.  Only their origins matter: they go into the Content-Security-Policy.
Readonly my $DEFAULT_LEAFLET_URL => 'https://unpkg.com/';
Readonly my $DEFAULT_TILE_URL    => 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

# How long a login lasts after the last request: a working day.
Readonly my $DEFAULT_LOGIN_EXPIRATION => 8 * 60 * 60;

# Where a server started without -l or MOJO_LISTEN listens: this machine only.
# Config listen (morbo, daemon, prefork) and hypnotoad => { listen } (hypnotoad)
# change the port, or open it to other machines with 'http://*:3000'.
Readonly my $DEFAULT_LISTEN           => 'http://127.0.0.1:3000';
Readonly my $DEFAULT_HYPNOTOAD_LISTEN => 'http://127.0.0.1:8080';

# What a Content-Security-Policy nonce may be made of (base64 or base64url);
# anything else reaching the policy is dropped.
Readonly my $NONCE_RE => qr{\A[A-Za-z0-9+/_=-]+\z};

# The Referer a page sends: the whole URL to this site, only the origin to
# another, and nothing from https to http.  Specs, filter values and share
# tokens travel in the query string, and an older browser's default sends all
# of it to the CDNs, the tile servers and any site a reader follows a link to.
# OpenStreetMap's tile policy asks pages for a Referer, so it is not none.
Readonly my $REFERRER_POLICY => 'strict-origin-when-cross-origin';

# Permissions-Policy: every powerful browser feature off, for this site and
# any frame it holds, but writing to the clipboard, which the Copy link
# buttons do.  Only names Chromium knows: it logs an error for any other.
Readonly my @PERMISSIONS_DENIED => qw(
	accelerometer autoplay browsing-topics camera clipboard-read display-capture
	encrypted-media fullscreen gamepad geolocation gyroscope hid
	identity-credentials-get idle-detection local-fonts magnetometer microphone
	midi otp-credentials payment picture-in-picture publickey-credentials-create
	publickey-credentials-get screen-wake-lock serial storage-access usb
	window-management xr-spatial-tracking
);
Readonly my $DEFAULT_PERMISSIONS_POLICY =>
	join(', ', (map { "$_=()" } @PERMISSIONS_DENIED), 'clipboard-write=(self)');

# Cross-Origin-Opener-Policy for a page: a window another site opened, or a
# window a page opens on another site, gets no handle on the page.  No page
# opens a window or reads window.opener; links out are rel="noopener" anyway.
Readonly my $DEFAULT_COOP => 'same-origin';
Readonly my %COOP_VALUES  => map { $_ => 1 } qw(same-origin same-origin-allow-popups noopener-allow-popups unsafe-none);

# Strict-Transport-Security, sent on replies to https requests: a year, and
# this host only.  includeSubDomains and preload reach other sites of the same
# domain, and are hard to take back, so they are for the configuration to add.
Readonly my $DEFAULT_HSTS => 'max-age=31536000';
Readonly my $HSTS_RE      => qr{\Amax-age=\d{1,10}(?:\s*;\s*includeSubDomains)?(?:\s*;\s*preload)?\z}i;

# Transport-layer upload size cap (bytes).  Mojolicious enforces this before
# the request body is read into memory, so an oversized upload never reaches
# the controller.  Must match $MAX_UPLOAD_BYTES in Dashboard.pm.
Readonly my $MAX_REQUEST_SIZE  => 50 * 1_048_576;	# 50 MiB
Readonly my $UPLOAD_MAX_AGE_S  => 24 * 3600;		# evict uploads older than 24 h

# CHI drivers that keep the table cache on disc, and so need a directory.
Readonly my %DISC_CACHE_DRIVER => map { ($_ => 1) } qw(File FastMmap);

=head1 NAME

Database::BI - Web-based Business Intelligence viewer for data files

=head1 VERSION

0.023.0

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
by column name and survive page reloads.  A table too long for one page is
sorted by the server (C<sort=> and C<dir=> in the address), every row of it,
so page 1 is the start of the sorted table and Next goes on from there.
A column sorts as dates when every cell is one, as numbers when every cell
is one (C<$1,234>, C<(5)> and C<45%> are numbers; C<T27> is not), and
otherwise as text, with case and accents ignored and the digits in it
compared as numbers, so C<T3> comes before C<T27>.

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
C<ne>, C<contains>, C<starts>, C<lt>, C<le>, C<gt>, C<ge>, C<between>, C<empty>,
C<notempty>; and C<in>, which a link can carry but the bar does not offer: any
value of a JSON list, as in C<f=place:in:["Paris","Rome"]>.  Filters are
applied server-side after all joins.  C<lt>, C<le>,
C<gt> and C<ge> compare numbers, reading C<$1,234.56> and C<(1,234.56)> as
numbers too; a blank or a word in the cell matches none of them.
An operator that is none of these (operators are lower case) is a C<400> that
lists them, and so is a filter, or a time range's C<rcol=>, on a column the
view does not have (the message lists the columns): neither is taken as a
filter that keeps every row, or none.  A canvas card's own saved filters are
the exception: one on a column its dataset no longer has is ignored.

=item *

B<Combine (UNION ALL)> -- the "Combine data" panel stacks rows from a
second (or further) file beneath the current rows, using a unified column
set and leaving blanks where a source file lacks a column.

=item *

B<Charts> -- nine L<HTML::D3> D3.js v7 chart types are accessible from
the toolbar: line chart (brush-to-zoom, reference lines for min/avg/max and a trend line,
multi-series interactive legend), pie chart (click-a-slice to filter,
top-N, donut mode, configurable colour scheme), heatmap (two categorical
axes, count or sum mode), bar chart (horizontal or vertical, sort,
top-N), scatter/bubble plot (optional categorical colour and numeric
size dimensions), stacked bar chart, combo bar+line chart, treemap, and
histogram (server-side binning, C<?bins=N>).  All charts can be resized
by dragging the bottom-right corner grip, or from the keyboard: the grip
takes focus, the arrow keys resize the chart (Shift takes bigger steps,
Home and End go to the narrowest and widest it can be) and the size is announced
as it changes.  All chart pages include Copy-link and Export SVG/PNG/PDF buttons.

=item *

B<Maps> -- C<GET /map> plots the filtered view on an OpenStreetMap map, either
from latitude and longitude columns or from a place column geocoded by a
L<Geo::Coder::List> chain: L<Geo::Coder::Free>'s local data first, then
OpenStreetMap's Nominatim service (L<Geo::Coder::OSM>, at most one request a
second) for the places the local data does not know.  Nominatim is asked over
https, and what it finds is also kept for a month in
C<E<lt>model_dirE<gt>/geocode-cache/>, or the C<cache_dir> set (see
L</Where caches are kept>).  Each distinct place is
looked up once, remembered in the model store and shared by every dataset that
names it.  Rows sharing a position become one marker.

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
being packed up the page.  B<Add text> in the toolbar adds a card of plain
text, for a title or an explanation, with a font, a size in points, colours and
an alignment of its own; it can hide its frame and header until it is pointed
at, and a row holding only one-row text cards is as tall as its text.  Double-click the text, or use B<Edit text>, to change it or
to remove the card.  B<Add current view> in the toolbar appends another
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

=item *

B<Drag-and-drop upload> -- any supported data file can be dropped directly
onto the application.  The file is opened immediately; when the "Combine
data" panel is open the dropped file populates the right-table path field.

=item *

B<Export> -- the toolbar export panel writes the current logical view
(after joins, filters, and dedup) to a chosen filesystem path as CSV
(C<.csv>), SQLite (C<.sql>), or JSON (C<.json>).

=item *

B<Print> -- the Print button, to the right of Refresh, prints the header row
and every row of the current view, not just the page on screen: the rows the
Export panel would save (after joins, filters, calculated and cross-row
columns, and dedup), read from C<GET /export?format=json>, with the columns in
the order the table shows them and sorted as it is sorted.  Nothing else on
the page is printed, and the header row repeats on each printed page.  A row
deleted from the page with Delete selected is still printed; a deleted column
is not.

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

B<MariaDB and MySQL data source> (optional) -- a table on a server named in the
C<mariadb_servers> configuration opens as C<mariadb:server/table>, read-only, with
the columns in the table's own order and a page read with C<LIMIT>.  See
L</MariaDB and MySQL servers>.

=back

=head2 UTF-8 and Encoding

All file data is returned as Perl character strings.  CSV/PSV/TSV files are
read by L<Text::xSV::Slurp> or L<DBD::CSV>, both of which pass bytes
through without re-encoding; the application serves the resulting page as
C<text/html; charset=UTF-8>, so full Unicode is displayed correctly as
long as the source file itself is UTF-8.  A UTF-8 byte-order mark at the
start of a CSV, TSV, PSV or JSON file (Excel's "CSV UTF-8" writes one) is
read past, so it is not part of the first column's name.

Filter values (C<f=col:op:val>) are decoded from the URL by Mojolicious
before reaching the controller and are compared against cell values as
Perl character strings.  Unicode characters in filter values are therefore
supported transparently.

URL-imported HTML tables are fetched with L<Database::BI::SafeUA> (see
L</Which addresses it may fetch>);
L<Database::Abstraction> uses the page's own charset declaration to decode
the body.  If the remote page declares an incorrect charset, cell values
may contain mojibake -- this is a limitation of the source data, not the
application.

=head1 SYNOPSIS

B<Start the development server (restarts automatically when you edit a file):>

    script/database-bi

C<morbo -l http://127.0.0.1:3000 script/database-bi> does the same thing (a bare
C<morbo script/database-bi> listens on every interface, so it starts only with a
password set), and
C<script/database-bi daemon> starts a plain server with no file watcher; any
other Mojolicious command word (C<routes>, C<get>, ...) is passed to the
application.

B<Start it showing one database:>

    script/database-bi data/store.db

The home address then shows that database, and its Home link leads to the usual
list.  Only one can be named: more than one is an error (exit status 2), because
a join cannot be given on the command line, so open one and use Merge or Combine
in the browser.  A file that is missing, cannot be read or is of an unsupported
type is the same error, before the server starts.  A remote path, Redis spec or
MariaDB spec is accepted as it would be by C</open>, and is checked when it is first shown.
It listens on port 3000 of this machine only (C<http://127.0.0.1:3000>); see
L</Who can reach the server> to change the port or open it to other machines.
A plain server does the same with
C<BI_OPEN=/full/path/store.db script/database-bi daemon>; a file named after
C<daemon> is ignored.

B<Start the production server:>

    hypnotoad script/database-bi      # start, or restart with no downtime
    hypnotoad -s script/database-bi   # stop

It listens on port 8080 of this machine only and ignores C<MOJO_LISTEN>; set the
port and anything else in C<database_bi.conf>, under
C<< hypnotoad => { listen => ['http://*:8080'] } >> (C<*> opens it to every machine).
It keeps its process id in F<script/hypnotoad.pid> unless C<pid_file> says
otherwise.  It takes no database on its command line: use
C<BI_OPEN=/full/path/store.db hypnotoad script/database-bi>.

B<Use a different data directory:>

    # In database_bi.conf (create this file in the same folder as script/):
    { data_dir => '/home/user/data' }

B<Change the language used for templates:>

    # In database_bi.conf:
    { data_dir => 'data', language => 'fr', platform => 'web' }
    # Then create templates/web/fr/ and put your French .html.tt files there.

B<American spelling:> a browser that asks for English (United States) gets the
pages from C<templates/web/en-us/>; set C<< language => 'en-us' >> to make that
the default for every browser that names no other English.

B<Run the test suite to verify everything is working:>

    make test

B<Generate the Makefile for the first time or after editing Makefile.PL:>

    perl Makefile.PL

=head1 ROUTES

=over 4

=item C<GET />

Scans C<data_dir>, renders a card grid of available tables.

When the server was started with the name of a database (see L</SYNOPSIS>), a
request from outside the application is redirected to C</open> for that
database.  A request whose C<Referer> is this server, such as the Home link, gets
the card grid, so a browser that withholds C<Referer> always sees the database.

=item C<GET /tutorial>

Renders the tutorial that is part of the application.  The chapters are data
in L<Database::BI::Tutorial>, not in this POD.

=item C<GET /login>, C<POST /login>, C<POST /logout>

The login, when C<password_hash> is set (see L</Logging in>).  C<GET /login>
shows the form (with C<return=>, the page to go back to: a path on this site),
C<POST /login> takes C<password=> and C<return=>, and C<POST /logout> ends the
session.  With no password set, C</login> says there is nothing to log in to.

=item C<GET /preferences>

Sets the reader's preferences: the theme, one of light, dark or the same as the
device (the default), and the rows a table or pivot shows on a page (25, 50,
100, 200 -- the default -- or All).  The theme is kept in the browser's
C<localStorage> and the page size in its cookie C<bi_per_page>, because the
server reads it (a value other than 25, 50, 100, 200 or 0 is ignored, and the
page is 200 rows); neither is stored on the server, and both apply to every page.
Saved charts, printed pages and embedded canvases stay light.  The Preferences
link at the top of each page passes C<back=> (that page), so the breadcrumb
here leads back to it.

=item C<GET /view/:table>

Opens the named table from C<data_dir>.  Accepts C<?f=col:op:val>
(repeatable) to pre-filter results, and C<?range=name&rcol=column> to keep
only a relative window of rows (see L</Relative time ranges>).

A long table is shown a page at a time: C<?page=> is the page, and
C<?per_page=> its size (else the reader's preference, else 200; up to 2000;
C<0> is every row on one page, and then C<page=> is ignored).  The page says
"Page 2 of 7", and its Rows per page list (25, 50, 100, 200, All) changes the
size, keeping the first row on screen.  A pivot pages its row groups the same
way.

C<?f=col:between:lo:hi> keeps the rows whose C<col> lies from C<lo> to C<hi>,
both included, whichever bound is written first.  Two numbers (a range of
years, C<Year:between:1880:1900>) compare as numbers; two dates or timestamps
compare as times (C<when:between:2026-11-01T09:00:00:2026-11-01T17:00:00>
splits at the colon between them); any other pair compares as text, ignoring
case.  The filter row offers it for date columns (two
date boxes) and number columns (two number boxes).

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
                                     (or a list in a JSON file) in data_dir
  path:/abs/path/to/file.csv         absolute local path
  path:/abs/path/to/file.db#table    one table of such a file anywhere else;
                                     a file whose own name has a # is that file
  /../hostname/dir/file.csv          remote file via SFTP
  redis:tablename|redis://host:port  Redis hash store (requires Redis module)
  mariadb:server/table               a table on a server in mariadb_servers
  mariadb:server                     lists that server's tables

=item C<GET /api/columns>

Returns C<{ "columns": [...] }> for a table (C<?table=name> or
C<?table=file/table> for a table inside a multi-table SQLite file) or file
(C<?path=/abs/path>, or C<?spec=path:/abs/path#table> for one of its tables).  Used by the join UI to populate the right-key
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
data grid.  A URL that leads to this machine or a private network is refused
(see L</Which addresses it may fetch>).  An optional C<?t=> parameter (zero-based integer) selects
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

A one-line chart offers check boxes above it for reference lines: Min, Avg,
Max, and Trend, the straight line closest to the points (least squares, by
L<Statistics::LineFit>), labelled with its slope per point and its R squared
(a flat series is slope 0 and R squared 1: the line passes through every
point).
The points are evenly spaced along the axis, so the fit is of Y against each
point's place, not its label.  After a zoom, every line is worked out again
from the points in view.  None is offered on a chart with C<series=>, and Trend
needs two points.

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
  scheme=<name> colour scheme when series= is set: tableau10 (default),
                category10, set2, set3 or paired; any other is a 400
  min_r=N       smallest bubble radius in px with size= (1-40, default 3)
  max_r=N       largest bubble radius in px with size= (1-40, default 15)
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
  scheme=<name>  bar and line colours: the first two of tableau10,
                 category10, set2, set3 or paired (optional; steel blue and
                 red without it, and for any other name)
  back=<url>, back2=<url>, back2_label=<text>  breadcrumb links
  f=             result filters (repeatable)

=item C<GET /treemap>

D3.js v7 treemap.  Parameters:

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

=item C<GET /histogram>

D3.js v7 histogram with server-side binning.  Parameters:

  l=<spec>   left table (required)
  col=<col>  numeric column to bin (required)
  bins=N     bin count (default 10; clamped to range 1--200)
  scheme=S   bar colour: the first colour of tableau10, category10, set2,
             set3 or paired (optional; steelblue without it, and for any
             other name)
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
position become one marker.  When some rows cannot be plotted, the note that
says so counts them by reason (empty, not a place name, not found, or not looked
up yet), links to all of them in the table, and opens onto a list of their
places, each with its number of rows, why it was not plotted and a link to
those rows.  Markers are clustered with
Leaflet.markercluster, so a dense map draws a count at low zoom and splits it
as it is zoomed in.  Clustering is always on.  The map has a scale bar, opens
on every marker unless C<zoom=> is given, and draws its key (colours, and
bubble sizes) on the map; the colours listed are those of the markers in view,
so the key changes as the map is zoomed and moved.

Places that are not in the cache yet are looked up after the page is shown.
The map draws what the cache already knows, and a progress bar names each
place as it is looked up ("Looking up 5 of 10: 10 Downing St, London").  Each
answer is saved at once, through C<POST /geo/lookup>, and the map is drawn
again when the last one is in.  Cancel stops the lookups and draws the map with
the places found so far.  The places left are listed as not looked up yet, with
a link to look them up.  Without JavaScript, or for a client that is not a
browser, the page waits for the lookups instead (C<geocode=wait>).  Parameters:

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
  bounds=county  draw the outline of the county around each marker
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

With C<bounds=county> (the map panel's "Show county boundaries"), the map draws
the outline of the county each marker is in, with a checkbox on the map to hide
them.  The outlines come from Nominatim's reverse lookup, which is sent each
marker's position rounded to three decimal places (about 110 metres), and only
when C<map_geocode_online> allows it.  Each outline is remembered under
C<model_dir> (C<boundary-cache>), with the points found in it, so a point inside
an outline already known costs no lookup.  A county is the division of a
country below its states, whose place rank in Nominatim depends on the country:
12 (a US county or independent city, an English county, a German Landkreis), or
10 for India, Bangladesh, China and Spain (district, prefecture, province), or 8
for Kenya.  Australia, Brazil and Japan have nothing at that level.  Config
C<map_bounds_ranks> (C<< { lk => 10 } >>: two-letter codes, ranks 8, 10 or 12)
adds or changes countries; startup refuses anything else.  Each reply names its
country, so a point is asked at the rank of the last country seen, and again
at its own when that differs.
Outlines not known yet are looked up as places are: by the progress bar, through
C<POST /geo/boundary>, or in the request for C<geocode=wait>; at most
C<map_geocode_online_max> in one request.  The checkbox needs L<HTML::OSM> 0.15;
with 0.14 the outlines are always shown.

With C<heat=1> as well, each outline is coloured by what is in it: the
C<weight=> column summed over every row inside it (or its rows counted, with no
C<weight=>), from green for the smallest total to red for the largest.  The
colour follows the size of the total on a logarithmic scale: each step up the
colours is the same multiple, so totals close in size share a colour and skewed
totals (one county with 500 times the people of another) still spread across
the scale.  When a total is zero or less the colours go by rank instead.  With
one outline, or totals all alike, there is nothing to compare, so the outlines
stay grey.  Each outline's popup gives its total, and the line under the title
says what the colours mean.  The checkbox, the key and that line call an
outline what its country does (a district in India, a province in Spain, an
area when the map mixes them).  With L<HTML::OSM>
0.16 a key in the map's bottom right corner lists each colour, highest first,
with the totals it covers, rounded to two figures ("30,000 to 37,000"); it hides with the outlines'
checkbox.

When the markers are coloured (C<color=>), the outlines take their colours
instead, with or without C<heat=1>, so a border never disagrees with the
markers inside it.  With L<HTML::OSM> 0.17 each coloured outline, here and on the heat scale, is
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
list says so; C<loc_text=>, or latitude and longitude columns, make a lookup
surer.  The list names at most 50 outlines, the fullest first.  While some
places have no outline yet (not looked up, or OpenStreetMap did not answer),
the note above the map links to their rows and, for those not looked up, to
the map again to look them up.

Outlines are written into the page, about 7 KB each before compression, so a
map of a state's counties is well under a megabyte, and one of every county in
a large country would be very large: filter the rows first.

C<shade=E<lt>columnE<gt>> (Colour shade, in the map panel) fills each outline in a
shade of one colour, the darker the larger that column's total over the rows
inside it, as a census map is drawn.  There are five shades, placed on the same
logarithmic scale, from a light tint up to the colour itself: C<shade_color=>
(a colour name or C<#rrggbb>) chooses it, orange by default.  A key lists each
shade in use, darkest first, with the totals it covers, as filled boxes with
L<HTML::OSM> 0.18 (lines before), and each outline's popup, which now opens from
anywhere inside it, gives its total.  The lines stay grey, or take the markers'
colours: with a shade the heat layer no longer colours them, since the fill
says the same.  With one outline, or totals all alike, nothing is filled.

When the markers are coloured (C<color=>) and no C<shade_color=> is given, each
outline is shaded in its own markers' colour instead, each colour a scale of its
own: the further a total is into what the colour stands for, the stronger the
shade.  For a rule on the shaded column that reads "less than" (C<lt>, C<le>)
that means the smaller total: with C<color_rule=lt:20000:green> a county of
2,000 is a stronger green than one of 19,000, while under
C<color_rule=gt:100000:red> the largest county is the strongest red.  The key
lists every shade by size, the largest totals at the top, so it runs from the
strongest red down to the strongest green.  It then stands for the markers'
colours as well, so the markers' own key of those colours is left out while the outlines are
shown.  With L<HTML::OSM> 0.19 it comes back when the reader hides the outlines
with their checkbox, and goes again when they are shown; an older HTML::OSM
leaves it out throughout.  The markers' key always stays when the shade is of
another column or of one colour, where nothing else says what the marker
colours mean.  Give C<shade_color=> to shade
every outline in one colour as before.

A marker stands for every row at its place, and its popup lists them all: a
value every row shares is shown once ("Person: Valentin Puntar"), and the
columns that differ are a small table, one line a row.  The table shows at most
C<map_popup_rows> rows (default 10) in a box that scrolls, so a busy place does
not cover the map; the rest are counted, with a link to them in the table the
map came from.

An unknown C<tiles=> or C<scheme=> is a 400, as is an unknown column, C<color=>
together with C<series=>, or a transposed lat/lon pair.  The page never shows
the L<HTML::OSM> Nominatim search box (C<search =E<gt> 0> is always passed), so
nothing typed on the map is sent anywhere.  With C<loc=>, a place the local
data does not know is sent to Nominatim, as the place name alone; set
C<map_geocode_online> to 0 to keep every lookup local.  L<HTML::OSM> 0.14 or
later is the renderer; an older optional install still returns the page with a
warning.

=item C<GET /line>

Alias for C<GET /graph>.  All C</graph> parameters accepted.

=item C<GET /canvases>

Lists the saved canvases, as cards that open them, with Import canvas.  It is
the main navigation's Canvases link; the home page shows the same list,
without Import canvas.  With
no canvases, the page says how to make one.  A canvas's breadcrumb leads back
here unless its C<back=> names another page.

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
C<table:>, C<path:>, C<url:> or C<redis:>, or being C<mariadb:server/table>).
Returns C<201 { id, created: 1 }>.

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
C<histogram>, C<wordcloud>, C<map> or C<text>.  A C<text> card reads no data, and
its C<options> are C<text> (required, up to 20,000 characters), C<font>
(C<arial>, C<georgia>, C<times>, C<verdana>, C<trebuchet> or C<courier>), C<size>
(8 to 96 points), C<colour> and C<background> (C<#rrggbb>; leaving out C<colour>
follows the theme), C<align> (C<left>, C<center> or C<right>), C<bold>, C<italic>
and C<plain>.  The text is shown as plain text, never as markup.  A map's C<encode> names either C<loc> (a place column
to geocode) or C<lat> and C<lon>.  A C<wordcloud> card's C<encode> names the
text column to read in C<col>, and its C<options> take the same C<topn>,
C<minlen> and C<stop> the C<GET /wordcloud> page takes, so the two count and
rank words with one function.  A C<scatter> card's C<encode> names C<x>
and C<y>, and optionally C<series> (colour by value) and C<size> (bubble size); its
C<options> take C<scheme>, C<min_r> and C<max_r> as C<GET /scatter> does,
except that an unknown C<scheme> draws the default colours.  A C<line>
or C<graph> card's C<encode> takes an optional C<series>, one line per value.
A C<histogram> card's C<options> take C<bins> and C<scheme> as C<GET /histogram>
does.  A C<treemap> card's C<encode> takes an optional C<color>, with
C<options> C<color_agg> and C<color_scheme> as C<GET /treemap>'s C<color=>,
C<color_agg=> and C<color_scheme=>; an unknown function is the card's error.
A C<combo> card's C<options> take C<scheme> as C<GET /combo> does.
The optional C<query> is the canvas page's
query string: C<cf> (cross-filter), C<c> (calculated columns) and
C<p.E<lt>nameE<gt>> (bound parameter values) are read from it, so a card added
while the canvas is filtered or parameterised is drawn through the same state
as the cards already on screen.  The visual is rendered against the canvas's
datasets, joins and calculated fields before it is stored, so an unknown
column or an undrawable visual is rejected with C<400> and nothing is appended.
Returns C<201 { id, visual, kind, title, html, head, nonce, cf_col }>, where
C<visual> is the new visual's index, C<head> is any stylesheet and script the
page must add once to draw the card (Leaflet, for a map), C<nonce> is the
Content-Security-Policy nonce the scripts in C<html> carry (the canvas page
runs only those, giving each its own nonce), and C<cf_col> is the
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

=item C<DELETE /api/analyses/:id/visuals/:visual>

Removes a text card; any other kind answers C<400>.  Later cards move down one
index, and the layout and any C<cv=> saved in a bookmark move with them.

=item C<PATCH /api/analyses/:id/visuals/:visual>

Changes the columns of one stored visual without removing it.  Body:
C<{ encode, query }>; C<encode> replaces the visual's encoding in place (for
a map, C<{ loc }> or C<{ lat, lon }>), and the optional C<query> is the
canvas page's query string, read for C<cf>, C<c> and C<p.E<lt>nameE<gt>> so
the redrawn card matches the page it is on.  The visual keeps its index, so
its layout position, size and title are unchanged.  The replacement is
rendered before it is stored, so an unknown column or an undrawable map is a
C<400> and the saved visual is left alone.  Returns
C<{ id, visual, kind, title, html, head, nonce, cf_col }>; C<nonce> is the one
the scripts in C<html> carry, which the canvas page gives its own when it runs
them.

=item C<DELETE /api/analyses/:id>

Removes the analysis.  Returns C<200 { deleted: 1 }>.

=item C<GET /api/analyses/:id/export>

Downloads the analysis document as a C<.json> file.

=item C<POST /api/analyses/import>

Creates an analysis from an uploaded C<.json> file (multipart C<file>
field) or a raw JSON request body.  Caller-supplied C<id>, C<created>,
and C<updated> are stripped.  "Import canvas", on C</canvases>, sends the file
that a canvas's Share panel downloads; that panel also makes the read-only
C</share/:id> link (C<POST /api/analyses/:id/share>) and its C</embed/:id>
code.

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
is a newline-separated list of raw cell values).  The group column,
C<E<lt>colE<gt>_group>, appears in the table page as well as in its charts and
exports.

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

=item C<GET /lookups/list>

Returns C<{ lookups: { name: { file, key, col, fields, default } } }> for the
stored lookups of C<?l=E<lt>specE<gt>>; C<col>, C<fields> and C<default> appear
only when they were given.  See L</Stored lookups>.

=item C<POST /lookups/save>

Saves a lookup.  Body: C<l=&name=&file=&key=>, plus optional C<col=>,
C<fields=> and C<default=>.  The file is read when it is saved, so a bad one is
a 400 at once.

=item C<POST /lookups/delete>

Removes a lookup.  Body: C<l=&name=>.  Omit C<name=> to remove every lookup of
the spec.

=item C<GET /extract/list>

Returns C<{ extractions: { name: { col, pattern, fields } } }> for the stored
field extractions of C<?l=E<lt>specE<gt>>.  See L</Field extraction>.

=item C<POST /extract/save>

Saves an extraction.  Body: C<l=&name=&col=&pattern=>, plus optional
C<fields=>.  The pattern is compiled when it is saved, so a bad one is a 400 at
once.  The reply names the columns it will add: C<{ ok: 1, fields: [...] }>.

=item C<POST /extract/delete>

Removes an extraction.  Body: C<l=&name=>.  Omit C<name=> to remove every
extraction of the spec.

=item C<GET /geo/list>

Returns C<{ columns: { col: { kind: "lat"|"lon"|"location"|"location_suffix" } } }>
for the saved coordinate-column preferences of the given C<l=> spec, with
C<loc_text> when the text added to each place is remembered too.

=item C<POST /geo/save>

Saves a coordinate-column preference.  Body: C<l=&col=&kind=>,
where C<kind> is C<lat>, C<lon>, C<location> or C<location_suffix>.  C<col=> and
C<kind=> may repeat in pairs, so a latitude and a longitude are saved in one
request, and C<replace=1> forgets the spec's saved columns first.  C<loc_text=>
remembers the text added to each place (as C<loc_text=> on C</map>, and refused
as it would be there).  The map panel's "Remember columns" sends all of them,
so a new choice replaces the old one; its "Forget remembered columns" calls
C</geo/delete>.

=item C<POST /geo/delete>

Removes a coordinate-column preference.  Body: C<l=&col=>.
Omit C<col=> to clear all preferences for the spec, and its C<loc_text>.

=item C<POST /geo/lookup>

Looks up one place for the map page's progress bar, and saves the answer in
the shared place cache at once.  Body: C<place=&sig=>, where C<sig> is the
signature the map page gave the place (any other place is refused with 403),
plus C<online=0> to keep the lookup on this machine.  Returns
C<{ place, status, stored, online_failed, messages }>, where C<status> is
C<found>, C<not_found>, C<held> (not looked up now, and not remembered) or
C<refused>.  See L</Maps>.

=item C<POST /geo/boundary>

Finds the outline of the county around one point, for the map page's progress
bar, and remembers it at once.  Body: C<point=&level=county&sig=>, where
C<point> is C<lat,lon> rounded to three places and C<sig> the signature the map
page gave it (any other point is refused with 403), plus C<online=0> to ask
nothing.  Returns C<{ point, status, stored, online_failed, name }>, where
C<status> is C<found>, C<nowhere> (no county there, such as the sea) or C<held>
(not settled now, and not remembered).

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
C<ai_api_key> is not configured; 400 for missing params or a question over 500
characters; 422 for an unparseable or invalid-column spec; 502 for a provider
error; 429 once the hour's provider calls are used up (C<ai_calls_per_hour>,
below).

Every call spends C<ai_api_key>, so each server process makes at most
C<ai_calls_per_hour> provider calls (default 60; C<0> for no limit) in any
hour, counting C</api/ask> and C</api/summary> together.  Like the other
routes, both need the login when C<password_hash> is set.

=item C<POST /api/summary>

Narrative summary of an analysis (Phase 5.3).  Body params: C<l=E<lt>specE<gt>>
(required), repeatable C<f=> filters, C<ai=1> (optional, honours
C<ai_api_key> config).  Returns C<{ text, source, cached }>.  Two paths:
deterministic template sentences (always available, works offline) and
optional LLM-polished prose when C<ai=1> is passed and C<ai_api_key> is
set.  Only aggregate insight facts are sent to the LLM.  Results are cached
in-process for one hour keyed on the analysis fingerprint.  Once the hour's
provider calls are used up (C<ai_calls_per_hour>), C<ai=1> gives the template
text with C<source =E<gt> 'template_limited'>, not cached.

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

A request that is refused -- a chart of a column the view does not have, a
calculated field that does not compile -- answers C<400> with the reason as
plain text.  When a browser asked for the page (a C<GET> whose C<Accept> names
C<text/html>), the reason is shown on the same page as a missing one instead,
with the breadcrumb back to the table and a Back button.  Scripts, C<fetch()>
and C</api/...> routes still get plain text or JSON.

=head2 Saved columns that cannot be applied

Calculated fields, lookups and extractions are saved for a dataset and applied
to every page of it.  When the file changes under one -- a lookup file is
deleted, a column an extraction reads is dropped -- its charts and exports
refuse with the reason.  The table page (C</view>, C</open>, C</join>,
C</combine>) is still drawn: without that dataset's saved calculated fields,
lookups and extractions, with a note that names the one at fault and buttons
that open the panels to correct or delete it.  A mistake in the request's own
C<c=> is still a C<400>.

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

The table page offers Time range in its filter bar only when one of the columns
on the page holds dates or date-times (C<YYYY-MM-DD>, the same with a time after
C<T> or a space, or C<M/D/YYYY>) in every non-empty cell, and its column menu
lists only those columns.  A range already in force stays in the bar, so it can
be changed or removed.

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
graph panel an C<Aggregate> menu beside it and a C<Lines by> menu, which
sends C<series=>.

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
A calculated field can read the new column, as in
C<c=half:ytd/2>, and C<cs=> can read a calculated field or a time bucket, as in
C<span=1mon&tcol=at&order=at_span&cs=amount:running_total:ytd>.  A filter runs
before the pass, so a window is over the rows it leaves, unless it names a
column the pass writes: C<f=ytd:gt:50> runs last, and selects rows without
changing their totals.  On a canvas, a card's own filters and a cross-filter
follow the same rule.
The table page's Cross-row panel builds the same parameters.  See
L<Database::BI::Controller::Dashboard/Cross-row columns> for the full rules.

=head2 Stored lookups

A lookup adds columns to every row of a dataset from a second file, matched on
one key: a shop code in the orders gains the shop's city and region.

  POST /lookups/save  l=table:orders&name=shops&file=lookups/shops.csv
                      &key=code&col=shop&fields=city,region&default=unknown

C<file=> is a data file under C<data_dir> (a relative path is read from there),
of at most 8 MiB; a file outside it, a symlink that leads outside it, a URL and
a remote path are refused.  C<key=> is the lookup file's key column and C<col=>
the dataset's (default: the same name).  C<fields=> lists the columns to add
(default: all but the key).  Keys are compared as text after trimming spaces,
and case matters.  When the file has a key twice, the first row is used and the
log says so.  A row whose key is not in the file gets C<default=>, or nothing.

A field keeps its own name unless the dataset already has a column of that
name; it is then called C<E<lt>nameE<gt>_E<lt>fieldE<gt>> (C<shops_region>).  A
source column is never overwritten.

The table page's Lookups panel saves, lists and deletes them, and can skip one
in the current view.  Stored lookups apply on every route, a canvas and
C</export>, before calculated fields and filters, so either can read the new
columns.  A total
grouped or filtered by one is worked out in Perl, never sent to SQL.  For one request,
C<nolk=E<lt>nameE<gt>> skips a stored lookup, and C<lk=E<lt>nameE<gt>> applies
a lookup stored for another dataset.  Both repeat, and the panels carry them on.
A lookup is not a join: for more than one key, or rows that match many rows,
use Merge.

=head2 Accelerated datasets

A large CSV, TSV, PSV, XLSX or XML file can be read from a SQLite copy of
itself, an I<extract>, which is faster to page through and lets totals be
worked out in SQL.  C<script/bi-extract --spec table:sales> marks the dataset
accelerated and builds the extract under C<E<lt>model_dirE<gt>/extracts/>, or in
the cache directory set (see L</Where caches are kept>).

An extract is used only while it matches the file: its name is a fingerprint
of the spec and the file's modification time and size.  Once the file changes,
the file itself is read, and the table page says the extract is stale and how
to rebuild it.  Stale numbers are never shown.  The table page also says when
a dataset is read from its extract, and when that was built.

An extract is a cache.  Deleting its folder loses nothing: each accelerated
dataset reads its file until the next build.  Nothing is written under
C<data_dir>, and a C<model_dir> inside it is refused.  Only a C<table:> or
C<path:> spec naming a local file can be accelerated; a SQLite file is one
already.  C<table:sales> and C<path:/data/sales.csv> are separate datasets, each
accelerated on its own.

=head2 Field extraction

A regular expression can pull values out of a column.  For one value, use
C<rx()> in a calculated field:

  c=country:rx(ref,'^([A-Z]{2})-','1')

To make several columns from one pattern, store an extraction.  Each named
group, C<(?E<lt>nameE<gt>...)>, becomes a column:

  POST /extract/save  l=table:invoices&name=parts&col=ref
                      &pattern=^(?<country>[A-Z]{2})-(?<year>\d{4})-

C<fields=country> keeps only the groups it names.  The table page's Extract
fields panel saves, lists and deletes them.  Stored extractions apply on
every route, a canvas and C</export>, after the lookups and before calculated
fields and filters, so either can read the new columns.  A row the pattern does
not match gets C<(unparseable)> in each column, as a calculated field's row
does, so those rows group visibly instead of vanishing; they are not blank.  A
group that took no part in a match is empty.  Columns are named as a lookup's
are: the group's own name, or C<E<lt>nameE<gt>_E<lt>groupE<gt>> when the
dataset has a column of that name.  A capture is cut to 200 characters.

A pattern is refused when it is over 200 characters, when it does not compile,
or when it uses C<(?{>, C<(??{>, C<(?p> or C<(*>, which run code or steer the
engine.  These checks are not a sandbox.  Perl's regular expressions have no
timeout, so a pathological pattern such as C<(a+)+$> stalls the request that
uses it.  Patterns are entered by whoever runs the server, never by a remote
party.  See L<Database::BI::Calc/Regular expressions>.

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

=head2 Where caches are kept

The places OpenStreetMap found for maps, the extracts of accelerated datasets
(see L</Accelerated datasets>), the page cache when C<page_cache_dir> turns it
on, and the table cache when C<< cache => { driver => 'File' } >> (or
C<FastMmap>) asks for one, are kept on disc.  Each object that keeps one
chooses its directory when it is made (L<Database::BI::CacheDir>), from the
first of these that is set:

=over 4

=item 1. C<cache_dir> through L<Object::Configure>, for the class making the
cache: its config files, then the environment variable
C<E<lt>ClassE<gt>__cache_dir> (C<Database__BI__Model__Geocode__cache_dir> for
the places, C<Database__BI__Extract__cache_dir> for the extracts,
C<Database__BI__cache_dir> for the page and table caches);

=item 2. C<$ENV{CACHEDIR}>;

=item 3. C<$ENV{CACHE_DIR}>;

=item 4. C<cache_dir> here (relative: under the application home):

    { cache_dir => '/var/cache/database-bi' }

=item 5. F<E<lt>model_dirE<gt>/geocode-cache> for the places,
F<E<lt>model_dirE<gt>/extracts> for the extracts, C<page_cache_dir> for the
page cache, F<E<lt>model_dirE<gt>/cache> for the table cache.

=back

Caches sharing a directory each keep to their own namespace in it; the
extracts go in its F<database-bi-extracts/> folder.  A cache directory inside
C<data_dir> is not used for the extracts, which then stay in C<model_dir>: each
is a C<.db> file the home page would list.  C<page_cache_dir> still decides
whether pages are cached at all (see L</Compression and the page cache>): a
cache directory set only says where.  A C<< cache => { root_dir } >> names the
table cache's directory outright.  C<script/bi-geocode> and
C<script/bi-extract> read the same settings, and F<database_bi.conf> from
C<MOJO_CONFIG> or the current folder (C<bi-extract> through the application).

=head2 Who can reach the server

A server started by C<script/database-bi> (with no arguments, a database, or
C<daemon> or C<prefork>) listens on C<http://127.0.0.1:3000>, so only this
machine can reach it: unless a password is set (see L</Logging in>), there
is no login, and Mojolicious on its own would listen on every interface.
C<listen> changes that:

    { listen => 'http://127.0.0.1:8000' }             # another port, still this machine only
    { listen => 'http://*:3000' }                     # every machine that can reach this one
    { listen => ['http://127.0.0.1:3000', 'http://[::1]:3000'] }  # IPv6 loopback too

It takes a location, several separated by commas, or a list.  A location
that is not C<http://> or C<https://> stops the start.  C<MOJO_LISTEN> and the
C<-l> option of C<daemon> and C<prefork> still win over it.
C<morbo script/database-bi> opens its port before it loads the application, so
it does not read C<listen>; give it C<-l>, or run C<script/database-bi>.

Anywhere but this machine needs a password: a C<listen> (or C<MOJO_LISTEN>, or
C<-l>, or under hypnotoad its own C<listen>) that is not loopback stops the start
unless C<password_hash> is set (see L</Logging in>).  The message says what to
change.  The defaults are loopback, so they start as before.

C<hypnotoad> reads its own C<< hypnotoad => { listen } >>, which defaults to
C<http://127.0.0.1:8080>, this machine only:

    { hypnotoad => { listen => ['http://*:8080'] } }  # every machine

Behind a reverse proxy on the same machine, leave both at their defaults.  The
proxy can still bring other machines' requests in, so without a password a
request from an address that is not loopback is refused (C<403>), including one
a trusted proxy names in C<X-Forwarded-For>.  For the public, set a password.

B<This machine is not one person.>  Loopback keeps other machines out, not
other people on this one: any account on the same machine, or a container that
shares its network, can reach C<127.0.0.1:3000>, and read, list and save files
as the account running the server.  On a machine with other users, set a
password even when it listens on this machine only.

=head2 Which folders it may use

C</browse>, C</open>, the Export panel's folder list (C</api/dirs>), a C<path:>
data source anywhere (a table, a chart, a merge, a canvas card) and
C<POST /export> reach the whole filesystem, as far as the account running the
server can.  C<file_roots> fences them in:

    { file_roots => ['/srv/reports', 'shared'] }   # 'shared' is under the application home

C<data_dir> and C<uploads_dir> are always among them.  Browsing starts at the
home folder if it is inside, else at the first root, and stops at the roots.  A
folder or file outside is refused (C<403>, or a C<path:> source is not found),
whether or not it is there, so the refusal says nothing about what is outside;
a link inside that leads outside is outside.  A path that climbs out with C<..>
past what exists is refused too.  A root that is not a folder that exists stops
the start.  Remote files (C</../host/...>), Redis and MariaDB are not files on
this machine, and are not affected; neither are the command-line tools.

Saving is the riskier half: an export replaces a C<.csv>, C<.json> or C<.sql>
file of the same name, and some such files are settings another program obeys
(a project's F<package.json> names commands that C<npm> runs).  A server other
people use keeps exports to folders of their own, so with C<password_hash> set,
C<export_dirs> is required, and the start stops without it:

    { export_dirs => ['/srv/reports/exports'] }   # a relative one is under the application home

C<POST /export> then saves only in them (or below them), and the Export panel
opens on the first and lists no other.  Reading is unaffected: that is
C<file_roots>.  An export folder that does not exist, is outside C<file_roots>
or is a dot-folder stops the start.  Whatever is set, an export never replaces
a link, a folder or anything else that is not a plain file, so a link inside
the allowed folders cannot carry it outside them; it is written beside its name
and renamed into place, so nobody reads half a file, and a file it replaces
keeps its permissions.

=head2 Requests from other sites

Unless a password is set (see L</Logging in>), there is no login: whatever can
reach the server can read any file it can (C</open>) and write exports into
any folder it can (C<POST /export>).  Even with one, a logged-in reader's
browser carries the login to every request it sends here.  Listening
on this machine only keeps other machines out, but not the pages of other
sites open in the reader's browser.  So every request is checked first, and
refused with C<403> when another site's page made it:

=over 4

=item * A write (any method but C<GET>, C<HEAD> and C<OPTIONS>) is refused when
the browser's C<Sec-Fetch-Site> says it came from another site, or, without
that header, when its C<Origin> is not this server.  A form posted from
another site needs no permission from this one, so this is what stops it.  A
script such as C<curl> sends neither header and is let through.

=item * Any request is refused when its C<Host> is a name other than
C<localhost> or C<*.localhost>, and is not an IP address.  A page whose own
name has been made to resolve to C<127.0.0.1> (DNS rebinding) counts as this
server to the browser, but it still sends its own name.  To reach the server
by a name, list it:

    { allowed_hosts => ['bi.example.com', '*.corp.example'] }   # '*' for any name

Behind a trusted reverse proxy, the C<Host> is whatever the proxy sends, so it
is checked only when C<allowed_hosts> is set; set it there too.

=back

C<POST /export> also refuses a folder or file whose name starts with a dot
(F<~/.config>, F<.vscode/settings.json>), since those hold other programs'
settings.  The folder list in the Export panel leaves them out already.

=head2 Which addresses it may fetch

C</import> and a C<url:> data source make the server fetch a URL, so a page
could point it at what only the server can reach: a service on this machine, a
database on the office network, or a cloud's metadata service on
C<169.254.169.254>, which hands out its credentials.  So the server refuses a
URL that leads to this machine, a private or shared network
(C<10.0.0.0/8>, C<172.16.0.0/12>, C<192.168.0.0/16>, C<100.64.0.0/10>,
C<fc00::/7>), link-local addresses, multicast or a reserved range.

It is what the name I<resolves to> that counts, not how the URL reads:
C<http://localtest.me/> and C<http://127.0.0.1.nip.io/> are names whose DNS
answers C<127.0.0.1>, and C<http://2130706433/> or C<http://0x7f000001/> are
C<127.0.0.1> written another way; all are refused.  An address is looked up
once, checked, and that address is the one connected to, so a name that answers
differently the second time (DNS rebinding) gains nothing.  Each redirect is
checked the same way, and at most 5 are followed.  Over C<https> the
certificate must still be the site's.  The refusal says why, for example
C<localtest.me is 127.0.0.1, which is this machine>.

To read from an intranet site, name it:

    { url_private_hosts => ['reports.corp.example', '*.corp.example'] }

Those names may resolve to a private address; every other name is still
checked, and an address written as such (C<http://10.1.2.3/>) is never let
through.  A name that is not a host name, or C<*> alone, stops the start.
This check is not a firewall: where the server's machine can reach something it
should not, rules on outgoing connections are the stronger defence.

=head2 Logging in

With C<password_hash> set, every page asks for a password first.  A server
other machines can reach must have one (see L</Who can reach the server>); on
this machine alone it is optional.  Make the line with

    script/database-bi password

which asks for the password twice (without showing it) and prints

    password_hash => 'pbkdf2-sha256$200000$...',

to put in C<database_bi.conf>.  Only the hash is kept: PBKDF2-HMAC-SHA256 with
a random salt (L<Database::BI::Password>).  A plain password there stops the
start, so it is never left in the file by mistake.  To change the password,
make a new line; every session is then logged out.

There is one password, not one per person.  A browser asking for a page is
sent to C</login> and, once the password is right, back to that page; any other
request (a script, a panel's request, a download) gets C<401> until it carries a
logged-in session.  C<POST /logout>, the Log out button at the top of each page,
ends it.  C</share/:id> and C</embed/:id> need no login: their signed, expiring
token is their permission, so anyone holding the link sees that canvas, and
only that one, for 30 days.  The canvas itself (C</a/:id>) and the rest still
ask for the password.

The token is signed with C<share_secret> when it is set (at least 16
characters), else with a key derived from C<secrets>.  Without either, the key
is new at each start, so a restart ends every share link, and the Share panel
says so; set C<secrets> (which keeps logins too) or C<share_secret> to keep
them.  Changing either ends the links made with the old one.  Before 0.021.0 a
missing C<share_secret> meant a fixed key, the same on every install, with which
anyone could sign a link to any canvas; that key in C<share_secret> stops the
start.

    {
        password_hash    => 'pbkdf2-sha256$200000$...',
        export_dirs      => ['/srv/reports/exports'],   # required with a password
        login_expiration => 8 * 60 * 60,   # seconds idle before logging out; the default
        secrets          => ['a long random string'],  # or each restart logs everyone out
    }

The session is a cookie signed with C<secrets>: C<HttpOnly>, C<SameSite=Lax>,
and C<Secure> whenever the request came over https (directly, or through a
trusted proxy that says so), so it is never sent back over plain http.  Over
plain http anyone on the network path can read the password and the cookie: a
server other machines reach should be behind https.  Ten wrong passwords from
one address within 15 minutes lock that address out for the rest of the 15
minutes (C<429>); each server process counts its own.

=head2 MariaDB and MySQL servers

A server is opened by name.  Each entry of C<mariadb_servers> is one database:

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

The home page then has a card for each name, leading to the list of its tables.
C<mariadb:shop/orders> opens one anywhere a source is taken: the path field, C<l=>,
C<j=>, C<c=> and a canvas's C<datasets>.  C<mariadb:shop> lists them.

The spec holds a name and no more, because a spec travels in URLs, bookmarks,
shared links, saved canvases and server logs.  So the password stays in the
configuration file, which should be readable only by the account that runs the
application, and no request can point the application at another server.

L<DBD::MariaDB> is recommended; L<DBD::mysql> serves if it is the one installed.
Without either, opening a server says so and the rest of the application is
unaffected.  Rows are read from the server each time, and never cached.  The tests
are C<t/mariadb.t>, which mocks the server, and C<t/mariadb_live.t>, which runs when
C<MARIADB_SERVER> is set, for example to C<mariadb://user:pass@host/test>, and which
creates its own tables and drops them.

=head2 Compression and the page cache

Every response goes through L<Mojolicious::Plugin::Buffer>: it is compressed
(gzip or Brotli, as the browser accepts), HTML whitespace is minified (inline
scripts and styles are left alone), and a C<200> to C<GET> or C<HEAD> carries
an C<ETag>, so a repeat request can be answered C<304 Not Modified>.  There
is no C<Last-Modified>: the plugin would date a page by the code, not the data,
which lets a browser reuse a stale reply without asking.  File
downloads (C</export> as CSV, SQLite or JSON, the pivot as XLSX, and a canvas
card's data from C</a/:id/visual/:n/:fmt>) opt out and are sent as they are.

Two optional keys keep finished pages on disc:

    {
        page_cache_dir      => '/var/cache/database-bi',  # relative: under the application home
        page_cache_duration => '5 minutes',               # the default
    }

When C<page_cache_dir> is set, C</catalog> and C</tutorial> are stored in a
L<CHI> File cache there (or in the cache directory set: see
L</Where caches are kept>), one copy per C<Accept-Language>, and served from it
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
C<{s}> too if the server uses subdomains.  Set it, and C<map_geocode_online>
to 0, and every request needed to draw a map can stay on the local network.  The OpenStreetMap attribution stays
on the map, since it is the usual credit for OSM-derived tiles.  There is no
in-page place search: L<HTML::OSM> is always constructed with C<search =E<gt> 0>,
so nothing typed on a map page is sent anywhere.

Map-specific config keys: C<map_geocode_max> (new geocoder lookups per request,
default 500), C<map_geocode_online> (0 keeps geocoding on this machine: a place
the local data does not know is not sent to OpenStreetMap's Nominatim, nor a
marker's position for its county outline; default 1), C<map_geocode_online_max>
(places, and outlines, asked of Nominatim per request, default 20;
at one a second, the rest are left for the next request or for
C<script/bi-geocode>; the map page's progress bar asks one place a request, so
it reaches every place), C<secrets> (a list; the first signs the places a map
page lists for C<POST /geo/lookup>.  Without it each start makes a random one), C<map_max_markers> (markers per request, default 2000), C<map_popup_rows>
(rows listed in one marker's popup, default 10),
C<map_region> (a two-letter country hint for ambiguous places),
C<map_bounds_ranks> (the place rank that is a county, by country; see above), C<map_max_zoom>
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

=head2 Content-Security-Policy

Every HTML page is sent with a C<Content-Security-Policy> header.  The pages
show cells from files this application did not write, so the policy backs up
the escaping.  Scripts, stylesheets and images may come only from this site
and from the hosts that C<d3_url>, the C<leaflet_*_url> keys, C<tile_url> and
C<tile_sources> name.  The defaults allow cdnjs.cloudflare.com, unpkg.com and
OpenStreetMap's tile servers.  A page's scripts may talk only to this site
(C<connect-src 'self'>), and no other site may show a page in a frame
(C<frame-ancestors 'self'>).  JSON replies and downloads carry no policy.

Every HTML page also carries C<X-Frame-Options: SAMEORIGIN>, whatever the
policy keys below say.  A report-only policy only reports C<frame-ancestors>,
a policy written out in full may leave it out, and older browsers read only
this header, so framing by another site is refused in each of those cases.

Every reply carries C<Referrer-Policy: strict-origin-when-cross-origin>.  A
request a page starts sends its whole URL to this site, only the origin to
another, and nothing from https to http.  Specs, filter values and share
tokens travel in the query string, and an older browser's default would send
all of it to the CDNs, the tile servers and any site a reader follows a link
to.  It is not C<no-referrer>, because OpenStreetMap's tile policy asks pages
for a C<Referer>.

Every reply also carries C<X-Content-Type-Options: nosniff>, so a browser
takes it for what its C<Content-Type> says and never guesses.  A guess could
read a CSV export, or text from a data file, as HTML or script.  A
self-hosted library under C<public/> keeps working, because Mojolicious names
C<.js> and C<.css> files for what they are; one served some other way must be
sent as C<text/javascript> or C<text/css>, or the browser will not load it.

Every page carries C<Cross-Origin-Opener-Policy: same-origin>: a window that
another site opened, or that a page opened on another site, gets no handle on
the page through C<window.opener>.  No page opens a window or reads an
opener, and every link to a new window is C<rel="noopener">.
C<cross_origin_opener_policy> sets another of C<same-origin>,
C<same-origin-allow-popups>, C<noopener-allow-popups> and C<unsafe-none>, or
C<''> or C<0> for none; any other value stops the application at startup.  No
C<Cross-Origin-Embedder-Policy> is sent: it would refuse the libraries and
tiles the CDNs and OpenStreetMap serve, and nothing here needs the isolation
it gives.

Every reply carries a C<Permissions-Policy> that turns off the browser
features no page uses: the camera, the microphone, location, payment, USB,
serial and HID devices, screen capture, full screen, reading the clipboard and
the rest, for this site and any frame it holds.  Writing to the clipboard
stays (C<clipboard-write=(self)>), for the Copy link buttons.  A script that
got in cannot ask the reader for any of them.  C<permissions_policy> replaces
the value (C<''> or C<0> for none); one that cannot be a header value stops
the application at startup:

    { permissions_policy => 'camera=(), geolocation=(self)' }

A reply to a request that came over https carries
C<Strict-Transport-Security: max-age=31536000>, so the browser comes back over
https for a year.  It binds this host only; set C<strict_transport_security>
to add C<includeSubDomains> or C<preload>, which reach every site of the
domain and are hard to take back, or to C<''> or C<0> to send none.  A value
a browser would not read stops the application at startup:

    { strict_transport_security => 'max-age=63072000; includeSubDomains' }

Over http no such header is sent, since a browser ignores it there, and none
is sent to C<localhost> or to an IP address: it binds the host, not the port,
so from C<https://localhost:8443> it would send every other server on that
machine to https, and browsers ignore it for an address.  Behind a proxy that
ends TLS, a request is https only when Mojolicious is told to trust the proxy
(C<MOJO_REVERSE_PROXY=1>, or C<< hypnotoad => { proxy => 1 } >>) and the proxy
sends C<X-Forwarded-Proto: https>; otherwise the proxy must send the header
itself.

An inline script runs only if it carries the request's nonce, a random value
made for each request and named in the policy (C<'nonce-...'>).  Every
C<E<lt>scriptE<gt>> the templates write carries it, and so do those that
L<HTML::D3> (0.30 or later) and L<HTML::OSM> (0.14 or later) write, because
the application passes it to them.  A script that came in with a cell's text
cannot know it, so it does not run; nor does an C<onclick> or C<onerror>
attribute, which no nonce can cover, so the pages use none.  Style attributes
are still allowed (C<style-src 'unsafe-inline'>).

A canvas card added without a reload arrives as JSON with the nonce its
scripts were written with.  The page runs only the scripts that carry it, and
gives each the page's own nonce.  A page kept in the page cache is stored with
its header, so the nonce in each still matches when it is served again.

Two keys change the policy:

    {
        content_security_policy_report_only => 1,  # report breaches, block nothing
        content_security_policy => "default-src 'self'; script-src 'self' 'nonce-{nonce}'",
    }

C<content_security_policy> is the whole policy, sent as written except that
C<{nonce}> becomes the request's nonce; without it no inline script runs.  Set
to C<''> or C<0> it sends no header.  A policy written out in full is not
updated when the library keys change.

=head3 Embedding a canvas on another site

By default only pages of this site may show C</embed/:id> in a frame.
C<embed_frame_ancestors> names other sites that may:

    { embed_frame_ancestors => [ 'https://intranet.example.com', 'https://*.corp.example' ] }

Each entry is an origin: C<http> or C<https>, a host (a C<*> may stand for its
first label only) and an optional port, with no path.  Anything else stops the
application at startup, because a security setting that does not do what it
says should not be dropped quietly.  The sites are added to that page's
C<frame-ancestors>, and to no other page's.  With a report-only policy, with
none, or with one written out without C<frame-ancestors>, the page carries a
second, enforced policy of C<frame-ancestors> alone, so naming one site never
lets every site in.  A policy written out with its own C<frame-ancestors> is
left to say who may.  C<X-Frame-Options: SAMEORIGIN> stays: browsers that know
C<frame-ancestors> follow it instead, and those that know only the older
header refuse the frame.  The canvas's Share panel names the sites its embed
code works on.

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

=item * the login session (L<Database::BI::Sessions>), and C<require_login> in
front of every route but the login, share and embed links (see
L</Logging in>); a C<password_hash> that is not a hash, or a C<login_expiration>
under 60 seconds, croaks; so does a C<listen> other machines could reach when
there is no password, and a password without C<export_dirs>;

=item * a C<file_roots> that is not a list of folders that exist croaks (see
L</Which folders it may use>); so does a C<url_private_hosts> that is not a
list of host names (see L</Which addresses it may fetch>);

=item * the C<before_dispatch> hook that refuses requests from other sites (see
L</Requests from other sites>); an C<allowed_hosts> that is not a list of host
names croaks;

=item * C<MOJO_LISTEN> set from C<listen> (default C<http://127.0.0.1:3000>) when it
was unset, and C<< hypnotoad => { listen } >> defaulted to C<http://127.0.0.1:8080>
(see L</Who can reach the server>); a C<listen> that is not a location croaks;

=item * a 50 MiB limit on request bodies (an upload over it is answered C<413>);

=item * Template Toolkit registered as handler C<tt>, and the Buffer plugin
(see L</Compression and the page cache>);

=item * the CHI cache for tables (the C<Memory> driver unless C<cache =E<gt> { driver }>
names another; a C<File> or C<FastMmap> one is kept where L</Where caches are kept>
says), and the page cache when C<page_cache_dir> is set;

=item * the C<before_dispatch> hooks for relative time ranges, cross-row plans and
the view context, and the C<before_render> hook that sets the breadcrumb, the help link
and the HTML 404 page;

=item * every route in L</ROUTES>.

=back

A configuration file that does not parse makes the C<Config> plugin croak, and
the application does not start.

=head1 COMMAND-LINE TOOLS

The scripts in C<script/> are installed with the distribution, each with a
manual page (C<man bi-extract>, C<man bi-geocode>, C<man bi-alert>,
C<man database-bi>).  The maintenance scripts use the same data and model
directories as the web application, found from the folder they are run in or
given with C<--data-dir> and C<--model-dir>, and are safe to run from cron.

=head2 script/database-bi password

Asks for a password (twice, without echo, at a terminal; once from a pipe) and
prints the C<password_hash> line for C<database_bi.conf>.  See L</Logging in>.

=head2 script/bi-geocode

Warms the shared geocode cache for one column, so later map requests make no
lookups:

    ./script/bi-geocode --spec table:customers --col city \
                        [--text TEXT] [--data-dir DIR] [--model-dir DIR] \
                        [--openaddr PATH] [--region CC] [--dry-run] [--verbose]

C<--text> is the map panel's I<Add to each place> (C<loc_text=>): with
C<--col county --text 'Virginia, USA'> it looks up C<Accomack, Virginia, USA>,
the place the map then asks for.

It is idempotent: a second run against a warm cache resolves nothing and says
so.  Exit status is 0 on success, 1 when the column is missing or no rows load,
and 2 on bad arguments or an unopenable source.

=head2 script/bi-extract

Builds the extracts of accelerated datasets (see L</Accelerated datasets>):

    ./script/bi-extract --spec table:sales [--spec ...]   # accelerate, and build
    ./script/bi-extract --all                             # rebuild every one
    ./script/bi-extract --remove --spec table:sales       # stop, and remove its extract
    ./script/bi-extract --list
                        [--data-dir DIR] [--model-dir DIR]

It prints a line for each extract it builds: the rows, the columns, the file
and the time.  Exit status is 0 on success, 1 when an extract could not be built
(the others still are), and 2 on bad arguments.  Run C<--all> from cron after
the data files are refreshed.

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
starts the reloading development server, with the name of one database it does
the same and shows that database, with a command word it runs that command, and C<hypnotoad script/database-bi> starts a preforking server (see
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

=item B<The launcher's last statement must be its call to start_app>

C<hypnotoad> loads the launcher instead of running it, with no arguments, and
takes the value of its last statement as the application.  So the launcher must
start the development server only when C<MOJO_APP_LOADER> is not set, and must
not end in C<1;>.  Otherwise C<hypnotoad script/database-bi> hangs in a
development server or refuses to start.

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
the first of C<export_dirs> (if set, as its real path), C<~/Downloads> (if it exists), then
C<$HOME>, then the system temp directory.
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

A directory may also name a region, as C<templates/web/en-us/> does: a browser
whose Accept-Language asks for that region (C<en-US>) gets it, and every other
request for the language (C<en-GB>, C<en-CA>, plain C<en>) gets
C<templates/web/en/>.  C<< language => 'en-us' >> makes it the default.

The distribution ships C<en> (British English) and C<en-us> (American
English).  C<en-us> is not edited by hand: it is made from C<en> by
C<author/make-en-us>, which respells the prose (colour, centre, summarise) and
leaves the names the code reads alone.  Run it after changing an C<en>
template; C<t/en-us.t> fails until the two agree.

The server's messages (errors, warnings, refusals) follow the same choice.
L<CGI::Lingua> picks the language from the request's C<Accept-Language>, or,
for the command-line scripts, from the locale (C<LANG=en_US.UTF-8>), and
L<Database::BI::I18N> gives each message in it.  A translation is a module,
L<Database::BI::I18N::en_us> for American English, listing only the messages
that read differently; C<t/i18n.t> fails when a British message needs an
American spelling it does not list.  The tutorial's text is still in British
English.

=item B<Supported data file extensions are: csv, db, sql, sqlite, sqlite3, xml, psv, tsv, xlsx, json>

The application recognises C<.csv>, C<.db>, C<.sql>, C<.sqlite>, C<.sqlite3>,
C<.xml>, C<.psv>, C<.tsv>, C<.xlsx> and C<.json> files.  All three SQLite extensions
(C<.sql>, C<.sqlite>, C<.sqlite3>) are treated identically -- C<inventory.sqlite>
and C<inventory.sqlite3> are both opened as SQLite databases without renaming.
Excel C<.xlsx> files are read by L<Database::Abstraction>, using
C<Spreadsheet::ParseXLSX>.

A C<.json> file is a table when it is a list of objects (each one a row), an
object of objects (each key a row, shown in a column C<id>, or C<key> when the
rows have an C<id> of their own), or an object holding lists of objects, as a
report does: C<{"tool": "scan", "findings": [...], "hosts": [...]}>.  Each
such list is a table, as a SQLite file's tables are: a file with more than one
opens on C</tables>, with a card for each, and other values beside the lists
(a date, a count, an object of totals) are left out.  A cell holding an object
or a list shows as its JSON text, C<true> and C<false> as words and C<null> as
an empty cell, and the columns are in the order the file first names them.  A
file of another format with the same name in the same folder is the one read.

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

The login is one shared password.  There are no accounts, so every reader who
knows it can do everything, and the log cannot say who did what.

=item *

Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.

=item *

A MariaDB table is read, never written, but the application does not enforce
that on the server: give it an account with only C<SELECT>.  Anyone who can reach
the application can open any table that account can read.

=item *

Only a page of an unfiltered table is read with C<LIMIT>.  A filter, Merge, Combine
or an export reads the whole MariaDB table into memory, so a very large table is
better opened through a view that narrows it.

=item *

A MariaDB table or view whose name holds anything but letters, digits and
underscores cannot be opened.  C</tables> shows it with a C<CREATE VIEW> statement
that gives it a usable name.

=item *

A relative time range is resolved against the server's clock.  An ISO
timestamp, C<YYYY-MM-DDTHH:MM:SS> (a space instead of the C<T>, no seconds, a
fraction of a second, and a trailing C<Z> or offset such as C<+01:00> are all
accepted), is read as written: the zone is not applied, so
C<2026-11-06T13:00:00Z> and C<2026-11-06T13:00:00+05:00> are the same time to
a filter.  A non-ISO timestamp is read as far as its C<YYYY-MM-DD> prefix, so
C<last_24_hours> is exact only for ISO timestamps in the server's zone.

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

Features planned for future releases (post-0.019.0).  Items are ordered by
priority.  Items shipped before this release (XLSX export, the copy-link
button, the column statistics panel, folder filter/join propagation, the
aggregate/measure layer and the C<between> and C<in> filter operators) are no
longer listed.

=over 4

=item * B<Multi-sheet XLSX> (Medium) -- C<_detect_file_info> reads only the
first worksheet.  A C<?sheet=> URL param with a sheet-name picker would
expose the full workbook.

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

# _table_cache_root($app, \%cache_conf) -> (root_dir => $dir) | ()
#
# A driver that keeps the table cache on disc (File, FastMmap) is given a
# directory: cache => { root_dir } when the config names one, else the one
# Database::BI::CacheDir chooses for this class (Object::Configure, CACHEDIR,
# CACHE_DIR, cache_dir in this config, then <model_dir>/cache).  CHI's own
# default would be a folder under the system temp directory.  The Memory
# driver keeps nothing on disc and takes no directory.
sub _table_cache_root ($app, $cache_conf) {
	my $driver = $cache_conf->{driver} // 'Memory';

	return () unless $DISC_CACHE_DRIVER{$driver};
	return (root_dir => $cache_conf->{root_dir}) if defined $cache_conf->{root_dir};

	require Database::BI::CacheDir;

	my $model_dir = Mojo::File->new($app->config('model_dir') // '.bi');
	$model_dir = $app->home->child($model_dir->to_string) unless $model_dir->is_abs;

	return (root_dir => Database::BI::CacheDir::resolve(
		class   => __PACKAGE__,
		config  => $app->config,
		home    => $app->home->to_string,
		default => $model_dir->child('cache')->to_string,
	));
}

sub startup ($self) {
	$self->plugin('Config', {
		default => {
			data_dir => $DEFAULT_DATA_DIR,
			platform => $DEFAULT_PLATFORM,
			language => $DEFAULT_LANGUAGE,
			d3_url   => $DEFAULT_D3_URL,
		}
	});

	# The key the map page signs the places it lists with (/geo/lookup checks
	# it).  Mojolicious would use the moniker, which anyone can read; a config
	# secrets => [...] keeps lists valid across restarts, and without one each
	# start makes its own.  This runs before hypnotoad forks, so every worker
	# shares it.
	# The sites that may frame /embed/.  A mistake here is a security setting
	# that does not do what it says, so it stops the start rather than being
	# dropped quietly.
	_check_embed_frame_ancestors($self->config('embed_frame_ancestors'));
	_check_strict_transport_security($self->config('strict_transport_security'));
	_check_permissions_policy($self->config('permissions_policy'));
	_check_cross_origin_opener_policy($self->config('cross_origin_opener_policy'));
	_check_allowed_hosts($self->config('allowed_hosts'));
	_check_file_roots($self->config('file_roots'), $self->home);
	_check_url_private_hosts($self->config('url_private_hosts'));
	_check_map_bounds_ranks($self->config('map_bounds_ranks'));
	_check_share_secret($self->config('share_secret'));
	_check_export_dirs($self, $self->config('export_dirs'));
	croak 'ai_calls_per_hour: give a whole number of provider calls an hour, or 0 for no limit'
		if defined $self->config('ai_calls_per_hour') && $self->config('ai_calls_per_hour') !~ /\A\d+\z/;
	_check_login($self->config('password_hash'), $self->config('login_expiration'));
	_require_export_dirs_with_password($self->config('password_hash'), $self->config('export_dirs'));

	# Only this machine can reach a server unless the configuration says
	# otherwise.  Mojolicious's own default is every interface, which put an
	# application with no login on the local network.  -l and MOJO_LISTEN still
	# win: the daemon and prefork commands read MOJO_LISTEN only when started,
	# after this, and -l replaces it.
	my @listen = _listen_locations($self->config('listen'));
	$ENV{MOJO_LISTEN} = join(',', @listen) unless length($ENV{MOJO_LISTEN} // '');
	_default_hypnotoad_listen($self->config);
	_require_password_if_open($self, $ENV{MOJO_LISTEN}, $self->config->{hypnotoad});

	# script/database-bi password makes the password_hash line.
	push @{ $self->commands->namespaces }, 'Database::BI::Command';

	my $secrets = $self->config('secrets');
	$self->secrets((ref($secrets) eq 'ARRAY' && @{$secrets})
		? $secrets : [ Mojo::Util::generate_secret() ]);

	# The login session (see "Logging in").  The cookie is signed with the
	# secrets, HttpOnly, SameSite=Lax, and Secure whenever the request came over
	# https; it lasts login_expiration seconds from the last request.  With no
	# secrets => [...] each start makes a new key, so a restart logs everyone out.
	$self->sessions(Database::BI::Sessions->new(
		cookie_name        => 'database_bi',
		default_expiration => $self->config('login_expiration') // $DEFAULT_LOGIN_EXPIRATION,
		samesite           => 'Lax',
	));

	# Cap inbound request body size.  When the limit fires, Mojolicious sets
	# req->is_limit_exceeded and still dispatches to the controller (with partial
	# content in the upload asset).  The controller checks is_limit_exceeded and
	# returns 413 before writing to disc.
	$self->max_request_size($MAX_REQUEST_SIZE);

	# Default export/save directory: ~/Downloads when it exists, else HOME,
	# else system tmpdir.  Resolved once per process and stored as a stash
	# default so every action can read $self->stash('download_dir').
	# With export_dirs, the first of them: the panel would open on a refusal.
	# Resolved as the export checks resolve it (_real_folders), so the panel
	# opens on the folder spelled as /api/dirs and the rest of the application
	# spell it (on Windows, child() joins with \, realpath gives /, and a
	# link is followed by hand).
	my $home   = $ENV{HOME} // '';
	my $dl_dir = ($home && -d "$home/Downloads") ? "$home/Downloads"
	           : ($home || File::Spec->tmpdir());
	my $exports = $self->config('export_dirs');
	if (ref($exports) eq 'ARRAY' && @{$exports}) {
		my $first = $exports->[0];
		my $dir   = File::Spec->file_name_is_absolute($first) ? Mojo::File->new($first) : $self->home->child($first);
		require Database::BI::Controller::Dashboard;
		$dl_dir   = (-e "$dir" ? Database::BI::Controller::Dashboard::_resolved_path("$dir") : undef) // "$dir";
	}
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
		# page_cache_dir turns the page cache on, and is where it goes when no
		# cache directory is set (Object::Configure, CACHEDIR, CACHE_DIR,
		# cache_dir in this config).  The pages keep to their own namespace,
		# so they can share that directory with the other caches.
		my $default = Mojo::File->new($page_cache_dir);
		$default = $self->home->child($page_cache_dir) unless $default->is_abs;
		require Database::BI::CacheDir;
		my $dir = Mojo::File->new(Database::BI::CacheDir::resolve(
			class   => __PACKAGE__,
			config  => $self->config,
			home    => $self->home->to_string,
			default => $default->to_string,
		));
		$dir->make_path;
		$page_chi = CHI->new(
			driver    => 'File',
			root_dir  => $dir->to_string,
			namespace => 'Database::BI::Pages',
		);
	}
	# No Last-Modified: the plugin's date is that of the code and templates, not
	# of the data, and with it and no Cache-Control a browser may reuse a reply
	# without asking.  A panel that reopened after a save then listed what was
	# saved before it.  The ETag alone makes every reuse a revalidation.
	$self->plugin('Buffer', {
		optimise_content => 1,
		last_modified    => 0,
		vary_by          => ['accept-language'],
		($page_chi ? (
			cache          => $page_chi,
			cache_duration => $self->config->{page_cache_duration} // '5 minutes',
		) : ()),
	});

	# The Content-Security-Policy nonce for this request.  Every <script> the
	# templates write carries it, as do those HTML::D3 and HTML::OSM write
	# (given nonce => $c->csp_nonce), and the policy runs no inline script
	# without it.  It is made before the action runs, so a template rendered
	# before anything asked for it still has one, and it is fresh for every
	# request: markup that reached a page through its data cannot know it.
	$self->hook(before_dispatch => sub {
		shift->stash(csp_nonce => _new_nonce());
	});

	# The language this request's messages are given in, chosen by CGI::Lingua
	# from its Accept-Language (Database::BI::I18N::choose), with the
	# configured language when it names none we have.  It is set with local
	# around the whole dispatch, so a message raised anywhere while the request
	# is answered - a refusal in the hook below, a model's croak - is in the
	# reader's language, and the next request starts afresh.  Every action
	# answers before it returns; one that answered later, from the event loop,
	# would need to set it again there.
	$self->hook(around_dispatch => sub {
		my ($next, $c) = @_;
		local $Database::BI::I18N::LANGUAGE = Database::BI::I18N::choose(
			accept  => scalar $c->req->headers->accept_language,
			default => $c->app->config->{language},
		);
		return $next->();
	});
	# Refuse what another site's page asks of this one through the reader's
	# browser: a form posted from there, or a page whose name was made to
	# resolve to this machine (DNS rebinding).  Nothing here asks who the
	# reader is, so this is what stands between another site and POST /export,
	# which writes files, and /open, which reads them.  A refusal is 403, as
	# JSON for a write (the panels read JSON back) and as text otherwise.
	$self->hook(before_dispatch => sub {
		my $c = shift;
		require Database::BI::Controller::Dashboard;
		my $refusal = Database::BI::Controller::Dashboard::request_refusal($c) // return;
		$c->stash(buffer => 0);
		return $c->render(json => { error => $refusal }, status => 403)
			if $c->req->method !~ /\A(?:GET|HEAD)\z/;
		$c->res->headers->content_type('text/plain; charset=utf-8');
		return $c->render(data => Mojo::Util::encode('UTF-8', $refusal), status => 403);
	});
	$self->helper(csp_nonce => sub {
		my $c = shift;
		my $nonce = $c->stash('csp_nonce');
		$c->stash(csp_nonce => ($nonce = _new_nonce())) unless defined $nonce;
		return $nonce;
	});

	# A Content-Security-Policy on every HTML reply.  The pages draw cells from
	# files nobody here wrote, so the policy is the second line behind the
	# escaping: script runs only from this site, the hosts the configuration
	# names, and inline blocks that carry this request's nonce; style and
	# images come only from this site and those hosts; nothing a page runs may
	# send data to another server, and no other site may frame a page.  Built
	# per reply from the config, as d3_url is, so a test can change it.
	#
	# Mojolicious runs after_dispatch hooks last registered first, so this runs
	# before Buffer's: a page Buffer keeps in its page cache is stored with the
	# header, and when it is served again Buffer puts back the header with the
	# body, so the nonce in each still matches the other.  The header is left
	# alone when it is already there for that reason.
	$self->hook(after_dispatch => sub {
		my $c = shift;

		my $headers = $c->res->headers;

		# On every reply, not only pages: a download opened in the browser, or
		# a JSON reply viewed there, can follow a link too.
		$headers->header('Referrer-Policy' => $REFERRER_POLICY)
			unless defined $headers->header('Referrer-Policy');

		# The browser features no page uses are turned off, so a script that
		# got in cannot ask the reader for the camera, a location or a payment.
		if (defined(my $features = _permissions_policy($c->app->config))) {
			$headers->header('Permissions-Policy' => $features)
				unless defined $headers->header('Permissions-Policy');
		}

		# Over https, the browser is told to come back only over https.  Sent on
		# every such reply, as browsers read it from any of them.
		if (defined(my $hsts = _strict_transport_security($c))) {
			$headers->header('Strict-Transport-Security' => $hsts)
				unless defined $headers->header('Strict-Transport-Security');
		}

		# A reply is what its Content-Type says, on every reply: a browser that
		# guessed could take a CSV export or an uploaded file's text for HTML or
		# script, and run what a cell holds.  Every route names its type, and
		# the static files have theirs from their extensions.
		$headers->header('X-Content-Type-Options' => 'nosniff')
			unless defined $headers->header('X-Content-Type-Options');

		return unless ($headers->content_type // '') =~ m{\Atext/html\b}i;

		# Framing is refused whatever the policy says.  frame-ancestors does
		# that in the policy, but a report-only policy only reports it, a
		# policy of the deployment's own may leave it out, and '' sends none;
		# older browsers read only this header.  Where both are sent, a
		# browser that knows frame-ancestors follows it and ignores this.
		$headers->header('X-Frame-Options' => 'SAMEORIGIN')
			unless defined $headers->header('X-Frame-Options');

		# A page keeps its window to itself: another site that opened it, or
		# that it opened, cannot reach it through window.opener.  For pages
		# only, as it is a property of the document a window shows.
		if (defined(my $coop = _cross_origin_opener_policy($c->app->config))) {
			$headers->header('Cross-Origin-Opener-Policy' => $coop)
				unless defined $headers->header('Cross-Origin-Opener-Policy');
		}

		# /embed/ stashes the other sites embed_frame_ancestors allows.
		my $framers = $c->stash('csp_frame_ancestors');
		$framers = [] unless ref $framers eq 'ARRAY';

		my $policy = _content_security_policy($c->app->config, $c->csp_nonce, $framers);
		my $report_only = $c->app->config('content_security_policy_report_only');
		my $name = $report_only ? 'Content-Security-Policy-Report-Only' : 'Content-Security-Policy';
		$headers->header($name => $policy) if defined $policy && !defined $headers->header($name);

		# Allowing other sites to frame /embed/ must never allow every site.
		# Unless an enforced policy above already says who may, a policy of
		# frame-ancestors alone is added: with report-only, no policy, or one
		# written out without it, the page would otherwise rely on
		# X-Frame-Options, which these browsers ignore once frame-ancestors is
		# anywhere.  (Browsers that know only X-Frame-Options refuse the frame.)
		if (@{$framers}) {
			my $enforced = $report_only ? undef : $policy;
			$headers->add('Content-Security-Policy' => _frame_ancestors_directive($framers))
				unless defined $enforced && $enforced =~ /(?:\A|;)\s*frame-ancestors\b/i;
		}
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

	# A filter whose operator is not one the pipeline knows is refused here,
	# for every route, rather than keeping every row and saying nothing.
	$self->hook(before_dispatch => sub {
		my $c = shift;
		return if $c->res->code;	# already answered (a range refused above)

		require Database::BI::Controller::Dashboard;
		return Database::BI::Controller::Dashboard::_filter_request($c);
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
			view_combines  => [ grep { /\A(?:path|table|url|redis|mariadb):/i } @{ $c->every_param('c') } ],
			view_dedup     => ($c->param('d') ? 1 : 0),
			# lk=/nolk= turn a stored lookup on or off for this view, as name=value
			# pairs so the macro can write them back in the order they came.
			view_lookups   => [ map { my $k = $_; map { { name => $k, value => $_ } } grep { length } @{ $c->every_param($k) } } qw(lk nolk) ],
			# Names only: the rest of an entry is credentials.
			mariadb_server_names => [ sort keys %{ $c->app->config('mariadb_servers') // {} } ],
		);
	});

	# Every page names the tutorial chapter that helps with it.  The layout
	# turns this into a "Help: ..." link beside the main Tutorial link, so a
	# reader on the pie chart screen lands on the pie chart chapter.  It lives
	# here rather than in every action: a new action is one entry in the action
	# map in Database::BI::Tutorial, and t/tutorial.t checks it is there.
	$self->hook(before_render => sub {
		my ($c, $args) = @_;

		# The language is the one the action already chose, if it got that far
		# (_resolve_template is protected, so it cannot be asked from here).
		my $page_template = sub {
			my ($name) = @_;
			my $conf     = $c->app->config;
			my $platform = $conf->{platform} // 'web';
			my $language = $c->stash('language') // '';
			$language = $conf->{language} // 'en'
				unless $language =~ /\A[a-z]{2}(?:[-_][A-Za-z]{2})?\z/
					&& -d $c->app->home->child("templates/$platform/$language");
			$c->stash(language => $language);
			return "$platform/$language/$name";
		};

		# A request refused in plain text is a dead end in a browser: no
		# navigation, and no way back but the Back button.  A page the browser
		# navigated to -- a GET whose Accept names text/html, which fetch() and
		# scripts do not send -- gets the error page instead: the trail back to
		# the table, and the reason, escaped by the template.  Everything else
		# keeps the plain text below.
		my $status = $args->{status} // 0;
		if (defined $args->{text} && ($status == 400 || $status == 403)
			&& $c->req->method eq 'GET'
			&& ($c->req->headers->accept // '') =~ m{\btext/html\b}
			&& $c->req->url->path->to_string !~ m{\A/api/}) {
			$c->stash(
				title     => $status == 403 ? 'This is not available here' : 'This page cannot be drawn',
				error_msg => delete $args->{text},
				error_400 => 1,
			);
			$args->{template} = $page_template->('not_found');
			$args->{handler}  = 'tt';
			$args->{format}   = 'html';
		}

		# Mojolicious sends render(text => ...) as text/html.  The error replies
		# that use it repeat what was asked for (a column, a range), so as HTML a
		# crafted link would run script on this site.  A template or JSON escapes
		# for itself; plain text only has to say that it is plain text.
		$args->{format} //= 'txt'
			if defined $args->{text} && !defined $c->stash('format');

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

		# Time range filters on a date or time column, so the table page
		# offers it only when the rows drawn have one (seven actions render
		# that page; this is the one place they all pass).  A range already
		# in force keeps its column, so it can be changed or removed even
		# when it leaves no rows to judge by.
		if (($args->{template} // '') =~ m{/dashboard\z}) {
			require Database::BI::Controller::Dashboard;
			my $columns = $args->{columns} // $c->stash('columns');
			my $records = $args->{records} // $c->stash('records');
			my @time = @{ Database::BI::Controller::Dashboard::_time_columns($columns, $records) };
			my $active = $c->stash('time_range');
			push @time, $active->{col}
				if ref($active) eq 'HASH' && !grep { $_ eq $active->{col} } @time;
			$args->{time_columns} = \@time;
		}

		# Mojolicious's own 404 page has no navigation and no breadcrumb; an
		# HTML one is drawn from our not_found template instead.  Its first
		# try is "not_found.<mode>", so that is the one replaced.  JSON
		# replies and exceptions keep the defaults.
		if (($args->{template} // '') =~ /\Anot_found\.\w+\z/
			&& ($args->{format} // $c->stash('format') // 'html') eq 'html') {
			$args->{template} = $page_template->('not_found');
			$args->{handler}  = 'tt';
			$c->stash(title => 'Page not found');
		}

		# The breadcrumb trail (layouts/breadcrumb.html.tt), worked out from the
		# request's own URL, so every page has one and a new page gets one
		# without code of its own.
		if (!defined $c->stash('trail')) {
			require Database::BI::Controller::Dashboard;
			$c->stash(trail => Database::BI::Controller::Dashboard::_breadcrumb_trail($c));
		}

		# The nav's Preferences link names this page with back=, so the
		# preferences page's trail leads back to it (Dashboard::_crumb_parent).
		if (!defined $c->stash('preferences_url')) {
			require Database::BI::Controller::Dashboard;
			$c->stash(preferences_url => Database::BI::Controller::Dashboard::_preferences_url($c));
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
		_table_cache_root($self, $cache_conf),
	);

	$self->helper(open_table => sub($c, $table, %opts) {
		# URL mode: fetch a remote HTML table directly via Database::Abstraction's
		# URL backend (LWP::UserAgent + HTML::TableExtract).
		if (exists $opts{url}) {
			return Database::BI::Model::DataSource->new(
				url           => $opts{url},
				cache         => $chi,
				cache_ttl_url => $cache_ttl_url,
				private_hosts => $c->app->config('url_private_hosts') // [],
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
		# MariaDB mode: connect to an entry of the mariadb_servers configuration.
		if (exists $opts{mariadb}) {
			return Database::BI::Model::DataSource->new(
				table   => $table,
				server  => $opts{mariadb},
				mariadb => ($c->app->config('mariadb_servers') // {})->{ $opts{mariadb} },
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
			exists $opts{column_order}   ? (column_order   => $opts{column_order})   : (),
		);
	});

	my $r = $self->routes();

	# Reached without logging in: the login itself, and the share and embed
	# links, whose signed, expiring token is their own permission.  Everything
	# else goes through require_login, which lets every request in when no
	# password_hash is set.
	$r->get('/login')    ->to('Dashboard#login_form');
	$r->post('/login')   ->to('Dashboard#login');
	$r->post('/logout')  ->to('Dashboard#logout');
	$r->get('/share/:id')->to('Dashboard#share_view');
	$r->get('/embed/:id')->to('Dashboard#embed_view');
	$r = $r->under('/')->to('Dashboard#require_login');

	$r->get('/')->to('Dashboard#index');
	$r->get('/tutorial')->to('Dashboard#tutorial');
	$r->get('/preferences')->to('Dashboard#preferences');
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
	$r->post('/lookups/save')  ->to('Dashboard#lookups_save');
	$r->post('/lookups/delete')->to('Dashboard#lookups_delete');
	$r->get('/lookups/list')   ->to('Dashboard#lookups_list');
	$r->post('/extract/save')  ->to('Dashboard#extract_save');
	$r->post('/extract/delete')->to('Dashboard#extract_delete');
	$r->get('/extract/list')   ->to('Dashboard#extract_list');
	$r->post('/geo/save')     ->to('Dashboard#geo_save');
	$r->post('/geo/delete')   ->to('Dashboard#geo_delete');
	$r->post('/geo/lookup')   ->to('Dashboard#geo_lookup');
	$r->post('/geo/boundary') ->to('Dashboard#geo_boundary');
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
	$r->delete('/api/analyses/:id/visuals/:visual')->to('Dashboard#analyses_delete_visual');
	$r->get('/api/analyses/:id/export') ->to('Dashboard#analyses_export');

	# extracts, catalog, sharing, embedding, per-visual downloads
	$r->get('/canvases')                      ->to('Dashboard#canvases_view');
	$r->get('/catalog')                       ->to('Dashboard#catalog_view');
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

# _cross_origin_opener_policy( \%config ) -> $value | undef
#
# Purpose: The Cross-Origin-Opener-Policy header a page carries.
# Entry:   The config.  cross_origin_opener_policy is one of %COOP_VALUES
#          ('' or 0 sends none); without it, $DEFAULT_COOP.
# Exit:    The value, or undef for none.  One changed after startup to a value
#          not in the list is not sent.
sub _cross_origin_opener_policy {
	my ($config) = @_;
	my $value = ($config // {})->{cross_origin_opener_policy};
	return $DEFAULT_COOP unless defined $value;
	return if ref $value || !length($value) || $value eq '0';
	return $COOP_VALUES{$value} ? $value : undef;
}

# _check_cross_origin_opener_policy( $value ) -> void
#
# Purpose: Refuse a cross_origin_opener_policy a browser would not read.
# Entry:   The config value.
# Exit:    Returns; croaks on anything but undef, '', 0 or a known value.
sub _check_cross_origin_opener_policy {
	my ($value) = @_;
	return if !defined $value || (!ref $value && (!length($value) || $value eq '0' || $COOP_VALUES{$value}));
	croak sprintf("cross_origin_opener_policy: '%s' is not one of %s, or 0 for none",
		ref $value ? ref $value : $value, join(', ', sort keys %COOP_VALUES));
}

# _permissions_policy( \%config ) -> $value | undef
#
# Purpose: The Permissions-Policy header every reply carries.
# Entry:   The config.  permissions_policy is the value to send, as written
#          ('' or 0 sends none); without it, $DEFAULT_PERMISSIONS_POLICY.
# Exit:    The value, or undef for none.  One changed after startup to text
#          that is not printable ASCII is not sent (_check_permissions_policy
#          refuses it at startup), so it cannot carry a line break.
sub _permissions_policy {
	my ($config) = @_;
	my $value = ($config // {})->{permissions_policy};
	return $DEFAULT_PERMISSIONS_POLICY unless defined $value;
	return if ref $value || !length($value) || $value eq '0';
	return $value =~ /\A[\x20-\x7e]+\z/ ? $value : undef;
}

# _check_permissions_policy( $value ) -> void
#
# Purpose: Refuse a permissions_policy that cannot be a header value.
# Entry:   The config value.
# Exit:    Returns; croaks on a reference or on text that is not printable
#          ASCII.  The features themselves are the browser's to judge.
sub _check_permissions_policy {
	my ($value) = @_;
	return if !defined $value || (!ref $value && $value =~ /\A(?:[\x20-\x7e]*)\z/);
	croak 'permissions_policy must be a header value, such as "camera=(), geolocation=()", or 0 for none';
}

# _strict_transport_security( $c ) -> $value | undef
#
# Purpose: The Strict-Transport-Security header for this reply, if any.
# Entry:   The controller.  Config strict_transport_security is the value to
#          send ('' or 0 sends none); without it, $DEFAULT_HSTS.
# Exit:    The value, or undef when none is to be sent.
#
# Only a request that came over https gets it: a browser ignores the header
# over http, and a reply that came through a proxy is https only when
# Mojolicious is told to trust the proxy (MOJO_REVERSE_PROXY=1, hypnotoad's
# proxy => 1) and the proxy says X-Forwarded-Proto: https.  Never for
# localhost or an IP address: the header binds the host, not the port, so
# from https://localhost:8443 it would send every other server on that
# machine, morbo included, to https; and RFC 6797 has browsers ignore it for
# an IP address.  A value the configuration changed to after startup is sent
# only if it is still well formed.
sub _strict_transport_security {
	my ($c) = @_;
	return unless $c->req->is_secure;

	my $host = lc($c->req->url->to_abs->host // '');
	return if $host eq '' || $host eq 'localhost' || $host =~ /\.localhost\z/
		|| $host =~ /\A\d{1,3}(?:\.\d{1,3}){3}\z/ || $host =~ /:/ || $host =~ /\A\[/;

	my $value = $c->app->config('strict_transport_security');
	return $DEFAULT_HSTS unless defined $value;
	return if ref $value || !length($value) || $value eq '0';
	return $value =~ $HSTS_RE ? $value : undef;
}

# _check_strict_transport_security( $value ) -> void
#
# Purpose: Refuse a strict_transport_security that a browser would not read.
# Entry:   The config value: undef, '' or 0 (none), or a header value.
# Exit:    Returns; croaks on anything else.
sub _check_strict_transport_security {
	my ($value) = @_;
	return if !defined $value || (!ref $value && (!length($value) || $value eq '0'));
	return if !ref $value && $value =~ $HSTS_RE;
	croak sprintf("strict_transport_security: '%s' is not a header value such as 'max-age=31536000'"
		. ' (optionally with includeSubDomains and preload), or 0 for none', ref $value ? ref $value : $value);
}

# _require_export_dirs_with_password( $hash, $export_dirs ) -> void
#
# Purpose: A server with a login is one other people use, so their exports
#          must be kept to folders of their own.  Anywhere else, an export can
#          replace a .json or .csv another program obeys (a project's
#          package.json names commands npm runs) as the account running the
#          server.
# Entry:   Config password_hash and export_dirs (already checked).
# Exit:    Returns; croaks when there is a password and no export_dirs.
sub _require_export_dirs_with_password {
	my ($hash, $dirs) = @_;
	return unless defined $hash && !ref $hash && length $hash;
	return if ref($dirs) eq 'ARRAY' && @{$dirs};
	croak "export_dirs: with password_hash set, other people can save exports, so keep them to folders of their own: "
		. "add export_dirs => ['/srv/reports/exports'] to database_bi.conf (see \"Which folders it may use\" in perldoc Database::BI)";
}

# _check_login( $hash, $expiration ) -> void
#
# Purpose: Refuse a login configuration that would not do what it says.
# Entry:   Config password_hash (undef or '' for no login, else a hash made by
#          script/database-bi password) and login_expiration (undef, or
#          seconds, a whole number from 60).
# Exit:    Returns; croaks otherwise.  A plain password in password_hash is
#          refused rather than hashed here, so it is never left in the file.
sub _check_login {
	my ($hash, $expiration) = @_;
	if (defined $hash && (ref $hash || length $hash)) {
		require Database::BI::Password;
		croak 'password_hash: not a hash made by "script/database-bi password" (put the line it prints in database_bi.conf, not the password itself)'
			unless Database::BI::Password::is_password_hash($hash);
	}
	croak sprintf("login_expiration: '%s' is not a number of seconds from 60", ref($expiration) || $expiration)
		if defined $expiration && (ref $expiration || $expiration !~ /\A\d+\z/ || $expiration < 60);
	return;
}

# _require_password_if_open( $app, $listen, $hypnotoad ) -> void
#
# Purpose: Refuse to start where other machines could reach the server with no
#          password: everything it can read and write would then be theirs.
# Entry:   The application, MOJO_LISTEN as startup left it, and the hypnotoad
#          settings (used instead under hypnotoad).
# Exit:    Returns when every location is loopback or a password_hash is set;
#          croaks otherwise.  The defaults (127.0.0.1, no password) start.
#
# A bare "morbo script/database-bi" listens on every interface (morbo opens
# the port before it loads the application, so config listen never reaches
# it), and now stops here; the message says to give it -l.
sub _require_password_if_open {
	my ($app, $listen, $hypnotoad) = @_;
	my $hash = $app->config('password_hash');
	return if defined $hash && length $hash;

	# Under hypnotoad (which sets HYPNOTOAD_APP) its own listen applies, and
	# MOJO_LISTEN does not.
	my @places = split /,/, $listen // '';
	@places = @{ $hypnotoad->{listen} }
		if $ENV{HYPNOTOAD_APP} && ref($hypnotoad) eq 'HASH' && ref($hypnotoad->{listen}) eq 'ARRAY';
	for my $place (@places) {
		my $host = lc(Mojo::URL->new($place)->host // '');
		next if $host eq 'localhost' || $host =~ /\A127\./ || $host eq '[::1]' || $host eq '::1';
		(my $shown = $place) =~ s/\?.*//;
		croak "listen: $shown can be reached from other machines, and there is no password. "
			. 'Set password_hash (make it with "script/database-bi password"), '
			. 'or listen on this machine only: listen => \'http://127.0.0.1:3000\' '
			. '(for hypnotoad, hypnotoad => { listen => [\'http://127.0.0.1:8080\'] }; for morbo, -l http://127.0.0.1:3000)';
	}
	return;
}

# _check_url_private_hosts( $value ) -> void
#
# Purpose: Refuse a url_private_hosts that is not a list of host names.
# Entry:   Config url_private_hosts: undef, or names ('reports.corp.example',
#          or '*.corp.example' for its subdomains) that a url: source or
#          /import may fetch although they resolve to a private address.
# Exit:    Returns; croaks otherwise.  '*' alone is refused: it would turn the
#          check off for every name, which is what egress rules are for.
sub _check_url_private_hosts {
	my ($value) = @_;
	return unless defined $value;
	croak "url_private_hosts: give a list of host names, such as ['reports.corp.example']"
		unless ref($value) eq 'ARRAY';
	for my $name (@{$value}) {
		croak sprintf("url_private_hosts: '%s' is not a host name such as 'reports.corp.example' or '*.corp.example'",
			ref($name) || $name // 'undef')
			unless defined $name && !ref $name
				&& $name =~ /\A(?:\*\.)?[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+\z/;
	}
	return;
}

# _check_map_bounds_ranks( $value ) -> void
#
# Purpose: Refuse a map_bounds_ranks that would not choose the county outlines.
# Entry:   Config map_bounds_ranks: undef, or { country code => place rank },
#          such as { lk => 10 }: the rank of Nominatim's that is a county in
#          that country, over Boundary's own list.
# Exit:    Returns; croaks on anything but a hash of two-letter codes to 8, 10
#          or 12 (Boundary->new says which entry), since a mistyped one would
#          otherwise draw no outlines, or the wrong ones, without a word.
sub _check_map_bounds_ranks {
	my ($value) = @_;
	return unless defined $value;
	croak "map_bounds_ranks: give a hash of country codes to place ranks, such as { lk => 10 }"
		unless ref($value) eq 'HASH';
	require Database::BI::Model::Boundary;
	my $ok = eval { Database::BI::Model::Boundary->check_ranks($value); 1 };
	return if $ok;
	(my $error = $@ // 'unknown error') =~ s/ at \S+ line \d+\.?\n?\z//;
	croak "map_bounds_ranks: $error";
}

# _check_share_secret( $value ) -> void
#
# Purpose: Refuse a share_secret that would not keep share links private.
# Entry:   Config share_secret: undef or '' (a key derived from secrets), or
#          the key share and embed tokens are signed with.
# Exit:    Returns; croaks on a reference, fewer than 16 characters, or the
#          fixed string versions before 0.021.0 used when none was set, which
#          anyone can read in the source.
sub _check_share_secret {
	my ($value) = @_;
	return unless defined $value && (ref $value || length $value);
	croak 'share_secret: give a string of at least 16 characters, or leave it out' if ref $value;
	croak 'share_secret: that is the default from the source, which anyone can read; choose another'
		if $value eq 'BI_DEFAULT_INSECURE_SECRET';
	croak 'share_secret: give at least 16 characters, so a share link cannot be forged by guessing it'
		if length($value) < 16;
	return;
}

# _check_file_roots( $value, $home ) -> void
#
# Purpose: Refuse a file_roots that would not fence what it says.
# Entry:   Config file_roots: undef or [] (the whole filesystem), or a list of
#          folders, each absolute or relative to the application home.
# Exit:    Returns; croaks on anything but a list of folders that exist, since
#          a mistyped root would otherwise leave readers with nothing, or a
#          list that is not one would leave them everything.
sub _check_file_roots {
	my ($value, $home) = @_;
	return unless defined $value;
	croak "file_roots: give a list of folders, such as ['/srv/data']" unless ref($value) eq 'ARRAY';
	for my $root (@{$value}) {
		croak sprintf("file_roots: '%s' is not a folder name", ref($root) || $root // 'undef')
			unless defined $root && !ref $root && length $root;
		my $dir = File::Spec->file_name_is_absolute($root) ? $root : $home->child($root)->to_string;
		croak "file_roots: '$root' is not a folder that exists" unless -d $dir;
	}
	return;
}

# _check_export_dirs( $app, $value ) -> void
#
# Purpose: Refuse an export_dirs that would not confine exports as it says.
# Entry:   Config export_dirs: undef or [] (anywhere file_roots allows), or a
#          list of folders, relative ones under the application home.
# Exit:    Returns; croaks on what is not such a list, a folder that does not
#          exist, or one outside file_roots, where nothing could be saved.
sub _check_export_dirs {
	my ($app, $value) = @_;
	return unless defined $value;
	croak "export_dirs: give a list of folders, such as ['/srv/exports']" unless ref($value) eq 'ARRAY';
	for my $dir (@{$value}) {
		croak sprintf("export_dirs: '%s' is not a folder name", ref($dir) || $dir // 'undef')
			unless defined $dir && !ref $dir && length $dir;
		my $path = File::Spec->file_name_is_absolute($dir) ? $dir : $app->home->child($dir)->to_string;
		croak "export_dirs: '$dir' is not a folder that exists" unless -d $path;
		require Database::BI::Controller::Dashboard;
		my $roots = $app->config('file_roots');
		if (ref($roots) eq 'ARRAY' && @{$roots}) {
			my @real = Database::BI::Controller::Dashboard::_real_folders($app->build_controller, $roots,
				Database::BI::Controller::Dashboard::_data_dir_for($app), $app->_uploads_dir);
			croak "export_dirs: '$dir' is outside file_roots, so nothing could be saved there"
				unless Database::BI::Controller::Dashboard::_inside_any($path, @real);
		}
		croak "export_dirs: '$dir' is a dot-folder, where exports are never saved"
			if grep { /\A\./ && $_ ne '.' && $_ ne '..' } File::Spec->splitdir(Mojo::File->new($path)->realpath->to_string);
	}
	return;
}

# _check_allowed_hosts( $value ) -> void
#
# Purpose: Refuse an allowed_hosts the request check could not use.
# Entry:   Config allowed_hosts: undef, or a list of host names, each a name
#          such as 'bi.example.com', '*.example.com' for its subdomains, or
#          '*' for every name.
# Exit:    Returns; croaks on anything else, since a list that does not say
#          what was meant either locks everyone out or lets the wrong site in.
sub _check_allowed_hosts {
	my ($value) = @_;
	return unless defined $value;
	croak "allowed_hosts: give a list of host names, such as ['bi.example.com']"
		unless ref($value) eq 'ARRAY';
	for my $name (@{$value}) {
		croak sprintf("allowed_hosts: '%s' is not a host name such as 'bi.example.com', '*.example.com' or '*'",
			ref($name) || $name // 'undef')
			unless defined $name && !ref $name
				&& $name =~ /\A(?:\*|(?:\*\.)?[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*)\z/;
	}
	return;
}

# _listen_locations( $value ) -> @locations
#
# Purpose: Where a server started without -l or MOJO_LISTEN listens.
# Entry:   Config listen: undef, a location such as 'http://*:3000', several
#          separated by commas, or an arrayref of them.
# Exit:    The locations, $DEFAULT_LISTEN when none is given; croaks on
#          anything that is not a location, since a server that listens
#          somewhere other than intended is a security setting gone wrong.
sub _listen_locations {
	my ($value) = @_;
	return ($DEFAULT_LISTEN) unless defined $value;

	my @locations = ref($value) eq 'ARRAY' ? @{$value} : ref($value) ? ($value) : split(/,/, $value);
	croak "listen: give one or more locations, such as 'http://127.0.0.1:3000' or 'http://*:3000'"
		unless @locations;
	for my $location (@locations) {
		croak sprintf("listen: '%s' is not a location such as 'http://127.0.0.1:3000' or 'http://*:3000'",
			ref($location) || $location // 'undef')
			unless defined $location && !ref $location && $location =~ m{\Ahttps?://[^\s,]+\z};
	}
	return @locations;
}

# _default_hypnotoad_listen( $config ) -> void
#
# Purpose: Make hypnotoad listen on this machine only unless told otherwise.
# Entry:   The application's config hashref.
# Exit:    hypnotoad => { listen } is $DEFAULT_HYPNOTOAD_LISTEN when it was
#          unset; a hypnotoad entry that is not a hash is left for hypnotoad.
#
# Hypnotoad reads hypnotoad => { listen } after loading the application, and
# ignores MOJO_LISTEN; without one it would listen on every interface.
sub _default_hypnotoad_listen {
	my ($config) = @_;
	my $hypnotoad = $config->{hypnotoad} //= {};
	return unless ref($hypnotoad) eq 'HASH';
	$hypnotoad->{listen} //= [$DEFAULT_HYPNOTOAD_LISTEN];
	return;
}

# _new_nonce() -> $nonce
#
# Purpose: A fresh Content-Security-Policy nonce.
# Exit:    22 base64url characters, 132 random bits.
#
# generate_secret is base64url of 128 bytes from Crypt::URandom (a weaker
# generator only when that is missing); the page writes the nonce on every
# <script>, so a prefix keeps it short while still unguessable.
sub _new_nonce {
	return substr(Mojo::Util::generate_secret(), 0, 22);
}

# _content_security_policy( \%config, $nonce, \@framers ) -> $policy | undef
#
# Purpose: The Content-Security-Policy header every HTML reply carries.
# Entry:   The application's config, the request's nonce (see csp_nonce), and
#          the other origins that may frame this reply (only /embed/ has any).
#          content_security_policy, when set to a string, is the whole policy,
#          sent as written but for {nonce}, which becomes the nonce; set to ''
#          or 0 it turns the header off.  Otherwise the policy is built from
#          d3_url, the five leaflet_*_url keys, tile_url and tile_sources.
# Exit:    The header's value, or undef for none.
#
# script-src has no 'unsafe-inline': an inline script runs only if it carries
# the nonce, so one that came in with a cell's text does not.  style-src keeps
# it, for the style attributes the templates write and the styles Leaflet and
# D3 set, which is a much smaller risk.  The hosts in script-src are what let a
# <script src> run without a nonce of its own, as the canvas page's card
# scripts load Leaflet.
#
# Leaflet's marker images are found beside its stylesheet, so the stylesheet's
# host is allowed images too.  unpkg.com stays in script-src even when the
# Leaflet keys point elsewhere: HTML::OSM loads leaflet.heat from there, and
# no key moves it.  The pins themselves are data: URIs (_marker_icon in the controller), and a
# chart export draws its copy through a data: or blob: image.
sub _content_security_policy {
	my ($config, $nonce, $framers) = @_;
	$config //= {};
	$nonce = undef unless defined $nonce && $nonce =~ $NONCE_RE;

	my $set = $config->{content_security_policy};
	if (defined $set && !ref $set) {
		return undef unless length($set) && $set ne '0';
		$set =~ s/\{nonce\}/$nonce \/\/ ''/ge;
		return $set;
	}

	my $from = sub {
		my ($key, $default) = @_;
		my $url = $config->{$key};
		$url = $default unless defined $url && !ref $url && length $url;
		return _csp_source($url);
	};

	my @script = ($from->('d3_url', $DEFAULT_D3_URL),
		map { $from->($_, $DEFAULT_LEAFLET_URL) } qw(leaflet_js_url leaflet_cluster_js_url));
	push @script, _csp_source($DEFAULT_LEAFLET_URL);
	my @style = map { $from->($_, $DEFAULT_LEAFLET_URL) }
		qw(leaflet_css_url leaflet_cluster_css_url leaflet_cluster_default_css_url);
	my $sources = $config->{tile_sources};
	my @tiles = ($from->('tile_url', $DEFAULT_TILE_URL),
		ref $sources eq 'HASH'
			? map { _csp_source(ref $_ eq 'HASH' ? $_->{url} : undef) } @{$sources}{sort keys %{$sources}}
			: ());

	my $list = sub {
		my %seen;
		return join ' ', grep { defined && !$seen{$_}++ } @_;
	};

	return join '; ',
		"default-src 'self'",
		'script-src ' . $list->("'self'", (defined $nonce ? "'nonce-$nonce'" : ()), @script),
		'style-src '  . $list->("'self'", "'unsafe-inline'", @style),
		'img-src '    . $list->("'self'", 'data:', 'blob:', @tiles, @style),
		"font-src 'self' data:",
		"connect-src 'self'",
		"object-src 'none'",
		"base-uri 'self'",
		"form-action 'self'",
		_frame_ancestors_directive($framers);
}

# _frame_ancestors_directive( \@framers ) -> $directive
#
# Purpose: frame-ancestors for a reply: this site, and the origins given.
sub _frame_ancestors_directive {
	my ($framers) = @_;
	return join ' ', 'frame-ancestors', "'self'", @{ $framers // [] };
}

# _embed_frame_ancestors( \%config ) -> @origins
#
# Purpose: The other sites that may frame /embed/, from embed_frame_ancestors.
# Entry:   The config.  The key is a list of origins, or one as a string.
# Exit:    Each as a CSP source ("https://intranet.example.com"), lower case,
#          without a trailing slash and without repeats.  An entry that is not
#          an origin is left out (startup refuses one; see
#          _check_embed_frame_ancestors), so a list changed after startup
#          cannot put anything else into the header.
sub _embed_frame_ancestors {
	my ($config) = @_;
	my $value = ($config // {})->{embed_frame_ancestors};
	my @list = ref $value eq 'ARRAY' ? @{$value} : defined $value && !ref $value ? ($value) : ();
	my %seen;
	return grep { defined && !$seen{$_}++ } map { _frame_origin($_) } @list;
}

# _check_embed_frame_ancestors( $value ) -> void
#
# Purpose: Refuse an embed_frame_ancestors that does not name origins.
# Entry:   The config value: undef, an origin, or a list of them.
# Exit:    Returns; croaks naming the first entry that is not an origin.
sub _check_embed_frame_ancestors {
	my ($value) = @_;
	return unless defined $value;
	croak 'embed_frame_ancestors must be a list of origins, such as [ \'https://intranet.example.com\' ]'
		if ref $value && ref $value ne 'ARRAY';
	for my $entry (ref $value ? @{$value} : $value) {
		next if defined _frame_origin($entry);
		croak sprintf("embed_frame_ancestors: '%s' is not an origin such as https://intranet.example.com"
			. ' (a scheme, a host and an optional port, with no path)', $entry // 'undef');
	}
	return;
}

# _frame_origin( $entry ) -> $source | undef
#
# Purpose: One embed_frame_ancestors entry as a CSP source, if it is an origin.
# Entry:   A string.
# Exit:    "scheme://host[:port]", lower case, or undef.
#
# Only http and https origins: a scheme on its own (https:), *, 'none' or
# 'self' would let far more than one site in, or say something else entirely,
# and a path would be ignored by the browser.  A wildcard is allowed as the
# first label only (https://*.example.com), which is all CSP allows.
sub _frame_origin {
	my ($entry) = @_;
	return unless defined $entry && !ref $entry;
	my ($scheme, $host, $port) = $entry =~ m{
		\A\s*(https?)://
		((?:\*\.)?[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*)
		(?::(\d{1,5}))?
		/?\s*\z
	}xi or return;
	return if defined $port && ($port == 0 || $port > 65_535);
	return lc("$scheme://$host") . (defined $port ? ":$port" : '');
}

# _csp_source( $url ) -> $source | undef
#
# Purpose: The CSP source expression that allows $url.
# Entry:   A URL from the config: absolute (http, https or scheme-relative), or
#          a path, which is this site.
# Exit:    "https://host[:port]", "'self'", or undef when it names nothing a
#          policy can allow.
#
# Only the origin is kept: a source with a path would allow that one file, and
# tile URLs carry {z}/{x}/{y}.  A placeholder in the first label of the host
# ({s}.tile.openstreetmap.org) becomes CSP's wildcard; one anywhere else cannot
# be written as a host, so the whole scheme is allowed rather than the tiles
# broken.
sub _csp_source {
	my ($url) = @_;
	return unless defined $url && !ref $url && length $url;

	if ($url !~ m{\A(?:[A-Za-z][A-Za-z0-9+.-]*:)?//}) {
		# A path on this site; any other scheme (data:, javascript:) is none.
		return $url =~ m{\A[A-Za-z][A-Za-z0-9+.-]*:} ? undef : "'self'";
	}
	my ($scheme, $authority) = $url =~ m{\A(?:([A-Za-z][A-Za-z0-9+.-]*):)?//([^/?#]*)};
	$scheme = lc($scheme // '');
	return if length $scheme && $scheme !~ /\Ahttps?\z/;
	my $prefix = length $scheme ? "$scheme://" : '';
	my $whole  = length $scheme ? "$scheme:" : undef;

	$authority =~ s/\A.*@//;
	my ($host, $port) = $authority =~ /\A([^:]+)(?::(.*))?\z/
		or return $whole;
	my @labels = split /\./, $host, -1;
	$labels[0] = '*' if @labels > 1 && $labels[0] =~ /\{/;
	for my $i (0 .. $#labels) {
		next if $i == 0 && $labels[0] eq '*';
		return $whole unless $labels[$i] =~ /\A[A-Za-z0-9-]+\z/;
	}
	if (defined $port) {
		return $whole unless $port =~ /\A(?:\d{1,5}|\{[^}]*\})\z/;
		$port = $port =~ /\{/ ? '*' : $port;
	}
	return $prefix . lc(join '.', @labels) . (defined $port ? ":$port" : '');
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
