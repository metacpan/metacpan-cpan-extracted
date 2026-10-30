package Database::BI::Controller::Dashboard;

use strict;
use warnings;

our $VERSION = '0.018.0';

use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;

use Carp		qw(croak carp);
use Cwd			qw(realpath);
use List::Util		qw(min max sum);
use CGI::Info;
use CGI::Lingua;
use Database::BI::Tutorial;
use Mojo::File;
use Mojo::JSON		qw(encode_json decode_json);
use Mojo::Parameters;
use Mojo::URL;
use Mojo::Util		qw(url_escape encode xml_escape);
use File::Path		qw(remove_tree);
use File::Spec;
use File::Temp		qw(tempfile tempdir);
use Readonly;
use Socket		qw(inet_aton);
use Sub::Protected;
use version ();

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# File extensions that Database::Abstraction can probe, in probe order.
# .sql, .sqlite, and .sqlite3 are all SQLite databases; .db is Berkeley DB.
Readonly my @SUPPORTED_EXT => qw( csv db sql sqlite sqlite3 xml tsv psv xlsx );
# Use \z (absolute end-of-string) not $ (which permits a trailing \n before \z).
# A query param decoded from "file.csv%0A" has basename "sales.csv\n"; without \z
# that passes the extension guard and reaches realpath with an embedded newline.
Readonly my $EXT_RE        => do { my $p = join '|', @SUPPORTED_EXT; qr/\.(?:$p)\z/i };

# Table name safe-identifier pattern -- must match DataSource's TABLE_NAME_RE
# exactly: first character must be a letter or underscore (not a digit), so
# that every table name the controller accepts can also be opened by DataSource
# without an unhandled croak.
Readonly my $TABLE_NAME_RE => qr/\A[A-Za-z_][A-Za-z0-9_]*\z/;

# URL spec pattern shared by _open_spec and _spec_to_url.
# qr{} delimiter avoids the \/ escaping noise required by the // form.
# /s: makes . match \n so a percent-decoded newline inside a URL does not
# silently truncate the captured URL before the \z end-of-string anchor.
Readonly my $URL_SPEC_RE   => qr{\Aurl:(https?://.+)\z}si;

# Redis spec pattern: redis:tablename|redis://[password@]host[:port][/db_index]
# The pipe separates the table name from the connection URL so the URL's own
# colons and slashes do not require extra quoting.
Readonly my $REDIS_SPEC_RE => qr{\Aredis:([^|]+)\|(redis://.+)\z}si;

# Bare Redis URL -- no table name -- used to list available keys.
# Excludes '|' so it cannot match the redis:table|redis://... full spec.
Readonly my $REDIS_URL_RE  => qr{\Aredis://[^\s|]+\z}si;

# Hostname pattern accepted in /../hostname/... remote paths.
# Mirrors Database::Abstraction's own host validation regex.
# Accepts 'hostname', 'user@hostname', and IPv4 addresses (IPv6 is excluded
# because the [...] notation would be ambiguous in the path syntax).
Readonly my $REMOTE_HOST_RE => qr/\A(?:[a-zA-Z0-9][a-zA-Z0-9._-]*\@)?[a-zA-Z0-9][a-zA-Z0-9._-]*\z/;

# The tile layer HTML::OSM 0.10 hardcodes.  HTML::OSM >= 0.12 is required;
# that release introduced search => 0, max_zoom, and tile_url (0.11).
Readonly my $DEFAULT_TILE_URL => 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

# The language the distribution ships templates for.  It is what a request falls
# back to when the language it resolved has no template directory of its own;
# see _resolve_language.  Keep it equal to Database::BI's $DEFAULT_LANGUAGE.
Readonly my $DEFAULT_LANGUAGE => 'en';

# The floor this controller passes options for.  HTML::OSM validates its
# constructor arguments strictly, so an older install does not ignore the new
# keys - it croaks on them.  _map_data therefore checks the version before
# building a map, and reports a missing or old renderer instead of a 500.
Readonly my $MIN_HTML_OSM_VERSION => '0.12';

# ---------------------------------------------------------------------------
# I18N message dictionary for all user-visible strings in this controller.
# To plug in a Locale::Maketext backend, extend _i18n() below.
# ---------------------------------------------------------------------------

Readonly my %MESSAGES => (
	error_table_invalid    => 'Invalid table name "%s"',
	error_table_open       => 'Could not open table "%s": %s',
	error_table_missing    => 'There is no table called "%s".',
	error_file_open        => 'Could not open "%s": %s',
	error_no_path          => 'No path specified',
	error_not_found        => 'File or directory not found: %s',
	error_dir_not_found    => 'Directory not found: %s',
	error_write_failed     => 'Write failed: %s',
	error_ext_required     => 'Use a .csv, .sql, or .json filename extension',
	error_upload_none      => 'No file received',
	error_upload_ext       => 'Unsupported file type. Accepted: CSV, TSV, PSV, XML, SQLite (.sql, .sqlite, .sqlite3), Berkeley DB (.db), XLSX',
	error_upload_too_large => 'File too large (maximum %s MiB)',
	error_upload_save      => 'Could not save uploaded file',
	error_path_required    => '"path" parameter is required',
	error_url_required     => 'Please enter a URL',
	error_url_invalid      => '"%s" is not a valid http:// or https:// URL',
	error_url_fetch        => 'Could not load HTML table from "%s": %s',
	error_url_ssrf         => '"%s" resolves to a private or reserved address and cannot be fetched',
	warn_combine_sort      => 'Sorting is applied in memory for /combine; result order may differ from a backend sort',
	error_sort_column      => 'Unknown sort column "%s"',
	warn_measure_fallback       => 'Measure "%s" on column "%s" is not uniformly numeric; totalled in Perl',
	error_measure_column        => 'Measure column "%s" is not in the view',
	error_pivot_rows_required   => 'At least one rows= dimension is required',
	error_pivot_measure_req     => 'At least one m= measure (col:fn:as) is required',
	error_pivot_measure_invalid => 'Invalid measure spec "%s"; expected col:fn:as where fn is one of: %s, or p1 to p100 for a percentile',
	error_stats_percentile      => 'The percentile must be a whole number from 1 to 100; "%s" is not',
	error_pivot_dim_not_found   => 'Row/column dimension "%s" is not in the view',
	error_pivot_dim_comma       => 'Dimension name "%s" must not contain a comma',
	error_calc_compile          => 'Calculated field "%s": %s',
	error_calc_name             => 'Calculated field name "%s" is not a valid identifier',
	error_topn_col              => 'Top-N column "%s" is not a measure alias in this view',
	warn_calc_undef             => 'Calculated field "%s" returned undef for %d row(s)',
	error_date_pattern          => 'Unsupported date format pattern "%s"; allowed: %%m/%%d/%%Y, %%d/%%m/%%Y, %%d-%%b-%%Y',
	error_date_time_pattern     => 'Unsupported time format pattern "%s"; allowed: %%H:%%M, %%H:%%M:%%S',
	error_date_as               => 'as= must be "timestamp" or absent; "%s" is neither',
	error_analysis_not_found    => 'Analysis "%s" not found',
	error_analysis_invalid      => 'Invalid analysis spec: %s',
	error_analysis_version      => 'Unsupported analysis version %s; please upgrade the application',
	error_analysis_storage      => 'Analysis storage is not writable; use import/export instead',
	error_analysis_json         => 'Invalid JSON body: %s',
	error_analysis_id_invalid   => 'Invalid analysis id',
	error_param_range           => "Parameter '%s' is out of range (min %s, max %s)",
	error_param_type            => "Parameter '%s' must be a number",
	error_map_source            => 'A map needs loc=<column> to geocode, or both lat= and lon= coordinate columns',
	error_map_coordinates       => 'A map with lat= needs lon= as well, and a map with lon= needs lat=',
	error_map_loc_column        => 'Column "%s" is not in this view, so there is nothing to geocode',
	error_map_coordinate_range  => 'Column "%s" holds only values outside the range of %s; check that lat= and lon= are not swapped',
	error_map_coordinate_numeric => 'Columns "%s" and "%s" hold no numeric coordinate pairs; a map needs numbers, or loc=<column> to geocode places',
	error_map_no_markers        => 'No row has a location that could be plotted',
	error_map_renderer_missing  => 'Drawing a map needs HTML::OSM 0.12 or later, and it is not installed',
	error_map_renderer_old      => 'Drawing a map needs HTML::OSM 0.12 or later, but the installed HTML::OSM is %s',
	warn_join_schema_mismatch   => 'Column "%s" has type %s in %s but %s in %s; the join keeps both columns, so check which one a calculation uses',
	warn_map_coordinate_rows    => 'Plotted %d of %d rows; %d hold no usable coordinate',
	warn_map_markers_capped     => 'Showing the first %d of %d markers; add f= filters to see the rest',
	warn_map_cache_unwritten    => 'The resolved places could not be remembered in the model store, so the next request will look them up again',
	error_map_tiles_unknown     => 'Unknown tile source "%s"; define it under tile_sources in database_bi.conf',
	error_insights_no_data      => 'No data available to analyse',
	insights_insufficient_data  => 'Insufficient data for this insight type (need more rows or periods)',
	ask_unavailable    => 'Ask a question is not available: no AI provider is configured',
	ask_no_question    => 'Please enter a question',
	ask_provider_error => 'AI provider error; could not generate an analysis',
	ask_unparseable    => 'Could not parse a valid visualization from the response; please rephrase your question',
	ask_invalid_spec   => 'Generated spec contains an unknown column: %s',
	summary_consent_required    => 'AI consent is required before sending data to an external provider',
	summary_ai_unavailable      => 'AI provider not configured; using template summary',
	summary_provider_error      => 'AI provider error; using template summary',
	error_token_invalid         => 'Share token is invalid or has expired',
	error_token_missing         => 'A share token is required to view this analysis',
	freshness_stale_msg         => 'Source data has changed since this analysis was last saved',
	error_agg_fn                => 'Unknown aggregate function "%s"; expected one of: %s, or p1 to p100 for a percentile',
	error_range_name            => 'Unknown time range "%s"; expected one of: %s',
	error_range_column          => 'A time range is applied to one column: add rcol=<column> to the URL',
	error_span_interval         => 'Unknown time bucket "%s" for span=; use a count and one of s, m, h, d, w, mon, q or y, for example 1h or 15m',
	error_span_no_column        => 'A time bucket needs one column to bucket: add tcol=<column>, or name exactly one of the dimensions this page already takes',
	error_span_tcol_orphan      => 'tcol=%s names the column to bucket, but span=<interval> is missing',
	error_span_tcol_unknown     => 'Column "%s" is not in this view, so there is nothing to bucket',
	error_span_conflict         => 'The bucket column "%s" is already defined by a calculated field; add as=<name> to bucket under a name of its own',
	error_span_name             => 'Bucket column name "%s" is not a usable column name; add as=<name>',
	error_cs_spec               => 'cs=%s must be <column>:<function>:<alias>, optionally followed by :<parameter>',
	error_cs_column             => 'cs=%s names the column "%s", which is not in this view',
	error_cs_fn                 => 'Unknown cross-row function "%s"; use one of: %s',
	error_cs_alias              => 'Cross-row alias "%s" is not a usable column name',
	error_cs_conflict           => 'Cross-row alias "%s" is already a column of this view, or another cs= already writes it; choose another name',
	error_cs_arg                => 'cs=%s: %s takes a whole number greater than zero, as in %s:%s:ma7:7',
	error_cs_no_arg             => 'cs=%s: %s takes no parameter',
	error_cs_by                 => 'by=%s names "%s", which is not a column of this view',
	error_cs_order              => 'order=%s must be <column>, <column>:asc or <column>:desc',
	error_cs_order_col          => 'order=%s names "%s", which is not a column of this view',
	error_cs_order_need         => 'cs=%s needs order=: %s reads its rows in order, so the order has to be named',
);

# Maximum accepted upload body size.  Enforced both here (application layer)
# and via Mojolicious max_request_size (transport layer) set in startup().
# Must match $MAX_REQUEST_SIZE in BI.pm.
Readonly my $MAX_UPLOAD_MIB      => 50;
Readonly my $MAX_UPLOAD_BYTES    => $MAX_UPLOAD_MIB * 1_048_576;
Readonly my $DEFAULT_JOIN_MAX_ROWS => 10_000;
Readonly my $DEFAULT_MAP_GEOCODE_MAX => 500;   # new lookups per request (map_geocode_max)
Readonly my $DEFAULT_MAP_MAX_MARKERS => 2_000; # markers drawn per request (map_max_markers)
Readonly my $DEFAULT_MARKER_COLOR  => '#3388ff'; # Leaflet default blue
Readonly my %NAMED_COLORS          => map { $_ => 1 } qw(
    red orange yellow green teal cyan blue navy purple
    magenta pink brown maroon olive silver gray grey gold lime white black
);
Readonly my $MAX_PREFIX_LEN        => 20;
Readonly my $DEFAULT_PER_PAGE      => 200;
Readonly my $MAX_PER_PAGE          => 2_000;
Readonly my %SCATTER_SCHEMES       => map { $_ => 1 } qw(tableau10 category10 set2 set3 paired);

# Categorical palettes for map series colouring, matching the D3 schemes the
# chart pages offer.  The map draws per-marker icons rather than D3 marks, so
# the hexes live here instead of in a template.
Readonly my %CATEGORY_PALETTES => (
	tableau10  => [ '#4e79a7', '#f28e2c', '#e15759', '#76b7b2', '#59a14f',
	                '#edc949', '#af7aa1', '#ff9da7', '#9c755f', '#bab0ab' ],
	category10 => [ '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd',
	                '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf' ],
	set2       => [ '#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854',
	                '#ffd92f', '#e5c494', '#b3b3b3' ],
	set3       => [ '#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3',
	                '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd',
	                '#ccebc5', '#ffed6f' ],
	paired     => [ '#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99',
	                '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6', '#6a3d9a',
	                '#ffff99', '#b15928' ],
);

# add_circle_marker() accepts only hex colours, while the icon path also takes
# the named colours _parse_color() allows.  Map the names once, here.
Readonly my %NAMED_COLOR_HEX => (
	red     => '#ff0000', orange  => '#ffa500', yellow  => '#ffff00',
	green   => '#008000', teal    => '#008080', cyan    => '#00ffff',
	blue    => '#0000ff', navy    => '#000080', purple  => '#800080',
	magenta => '#ff00ff', pink    => '#ffc0cb', brown   => '#a52a2a',
	maroon  => '#800000', olive   => '#808000', silver  => '#c0c0c0',
	gray    => '#808080', grey    => '#808080', gold    => '#ffd700',
	lime    => '#00ff00', white   => '#ffffff', black   => '#000000',
);

# The aggregate function vocabulary shared by _measure, _grouped_totals, the
# /pivot measure-spec parser and the /stats view.
#
# It has two halves.  @PUSHED_MEASURE_FNS are the functions
# Database::Abstraction's aggregate() computes in the backend: adding one here
# means adding it there as well.  @PERL_MEASURE_FNS are computed by the Perl
# fold in _grouped_totals from all the values in a group, because a subtotal has
# to be recomputed from the rows rather than combined out of the cells (a median
# is not the sum of the medians of its parts), and because the app already holds
# the rows: the fold is one pass over records that are in memory, with no second
# implementation of the same statistic to agree with.  Database::Abstraction
# does accept a median and a stddev measure, computing them in Perl over rows it
# materialises itself -- close enough to be tempting, and exactly the second
# implementation to avoid, so _measure_pushable refuses to send them.
#
# A percentile is spelled p<N>, for N from 1 to 100: p90, p99, p1.  The level
# rides in the function name because the spec dialect is col:fn:as, with no
# room for a parameter in it; p50 is the median, and median is kept as its own
# name because that is what a reader looks for.
Readonly my @PUSHED_MEASURE_FNS   => qw(sum avg min max count count_distinct);
Readonly my @PERL_MEASURE_FNS     => qw(median stdev first last range);
Readonly my @MEASURE_FNS          => (@PUSHED_MEASURE_FNS, @PERL_MEASURE_FNS);
Readonly my %PUSHED_MEASURE_FN_OK => map { $_ => 1 } @PUSHED_MEASURE_FNS;
Readonly my %MEASURE_FN_OK        => map { $_ => 1 } @MEASURE_FNS;

# _measure_percentile($fn) -> $level | undef
#
# The percentile level a measure function names, or undef when it names none:
# 'p95' -> 95, 'p50' -> 50, 'percentile' -> undef, 'sum' -> undef.  A level
# outside 1..100 is not a percentile, so an unknown function still fails as an
# unknown function rather than as a percentile of -40.
sub _measure_percentile {
	my $fn = shift;
	return undef unless defined $fn && length $fn;
	my ($level) = $fn =~ /\Ap(\d{1,3})\z/;
	return undef unless defined $level;
	return ($level >= 1 && $level <= 100) ? $level + 0 : undef;
}

# _measure_fn_ok($fn) -> bool
#
# True for every function _grouped_totals can compute: the named ones and any
# percentile level.  This is the single answer to "is this a measure function?"
# for the parser, and the vocabulary the 400 message prints comes from the same
# two lists, so a message can never list a function the fold cannot compute.
sub _measure_fn_ok {
	my $fn = shift;
	return 0 unless defined $fn && length $fn;
	return 1 if $MEASURE_FN_OK{$fn};
	return defined _measure_percentile($fn) ? 1 : 0;
}

# ---------------------------------------------------------------------------
# Relative time ranges
#
# A relative time range is a named window worked out from the clock when the
# request arrives -- "the last 30 days", "this quarter" -- so a link, a
# bookmark or a saved canvas that carries one keeps meaning the same thing
# every time it is opened instead of freezing the dates it first resolved to.
#
# The range is named in the URL (?range=<name>&rcol=<column>) and resolved to
# two f= filters on that column, which every data route already applies, so the
# table view, the charts, the pivot, the stats page, the insights page, the
# exports and a saved canvas all see the same rows.
#
# The vocabulary is day-granular except last_24_hours, which is to the second.
# ---------------------------------------------------------------------------

Readonly my @TIME_RANGES => (
	{ name => 'last_24_hours', label => 'Last 24 hours', hours => 24 },
	{ name => 'today',         label => 'Today',         day   => 0 },
	{ name => 'yesterday',     label => 'Yesterday',     day   => -1 },
	{ name => 'last_7_days',   label => 'Last 7 days',   days  => 7 },
	{ name => 'last_30_days',  label => 'Last 30 days',  days  => 30 },
	{ name => 'last_90_days',  label => 'Last 90 days',  days  => 90 },
	{ name => 'this_month',    label => 'This month',    month => 0 },
	{ name => 'last_month',    label => 'Last month',    month => -1 },
	{ name => 'this_quarter',  label => 'This quarter',  quarter => 0 },
	{ name => 'last_quarter',  label => 'Last quarter',  quarter => -1 },
	{ name => 'this_year',     label => 'This year',     year  => 0 },
	{ name => 'last_year',     label => 'Last year',     year  => -1 },
);
Readonly my %TIME_RANGE => map { $_->{name} => $_ } @TIME_RANGES;

# Allowed strptime-style date format patterns for the /dates/save endpoint, and
# the two time patterns that may be given beside one of them for a column that
# holds a clock time as well as a date.
Readonly my %ALLOWED_DATE_PATTERNS => map { $_ => 1 }
	qw(%m/%d/%Y %d/%m/%Y %d-%b-%Y);
Readonly my %ALLOWED_TIME_PATTERNS => map { $_ => 1 }
	qw(%H:%M %H:%M:%S);

# Default share token lifetime: 30 days in seconds.
Readonly my $SHARE_TOKEN_TTL => 30 * 86_400;

# ---------------------------------------------------------------------------
# Protected helpers
# ---------------------------------------------------------------------------

# _pagination($self) -> ($page, $per_page, $offset)
#
# Reads ?page= and ?per_page= from the current request, clamps them to sane
# ranges, and returns the 1-based page number, the page size, and the
# 0-based row offset.  Pagination is optional: when neither param is present
# per_page defaults to DEFAULT_PER_PAGE.
sub _pagination {
	my $self = $_[0];

	my $per_page = int($self->param('per_page') || $DEFAULT_PER_PAGE);
	$per_page = 1         if $per_page < 1;
	$per_page = $MAX_PER_PAGE if $per_page > $MAX_PER_PAGE;
	my $page = int($self->param('page') || 1);
	$page = 1 if $page < 1;
	my $offset = ($page - 1) * $per_page;
	return ($page, $per_page, $offset);
}

# _i18n($self, $key, @sprintf_args) -> $string
#
# Purpose: Look up a user-visible string from %MESSAGES and apply sprintf
#          for positional arguments.  The entry point for future i18n
#          backend integration (e.g. Locale::Maketext).
# Entry:   $key must be a key in %MESSAGES; @args are sprintf positionals.
# Exit:    Returns the formatted string, or a fallback containing $key.
sub _i18n :Protected ($self, $key, @args) {
	my $tmpl = $MESSAGES{$key} // return "Internal error: unknown message key '$key'";
	return @args ? sprintf($tmpl, @args) : $tmpl;
}

# _is_safe_url($url) -> bool
#
# Purpose: SSRF guard.  Blocks the most dangerous classes of Server-Side Request
#          Forgery targets: loopback aliases (localhost, 127/8) and literal
#          private/link-local/CGNAT IPv4 addresses in the URL host component.
#
# Design rationale for scope:
#   Resolving hostnames via DNS and checking the result is ineffective: a
#   separate DNS lookup happens at LWP connect time (TOCTOU / DNS rebinding
#   window).  The authoritative defence against hostname-based SSRF is a
#   network-layer egress firewall.  This function handles the Perl-layer
#   interception for the most common patterns that operators cannot easily
#   filter at the network level: bare loopback aliases and literal private IPs
#   hard-coded by an attacker.
#
# Blocked targets:
#   localhost / 127.0.0.0/8 / 0.0.0.0 / ::1  -- loopback aliases
#   10.0.0.0/8    -- RFC 1918 private (literal IP)
#   172.16.0.0/12 -- RFC 1918 private (literal IP)
#   192.168.0.0/16-- RFC 1918 private (literal IP)
#   169.254.0.0/16-- link-local; AWS/GCP/Azure metadata endpoint (literal IP)
#   100.64.0.0/10 -- CGNAT / Tailscale shared space (literal IP)
#
# Hostname-based targets (e.g. http://internal.corp.example.com/) are allowed
# at this layer; block them with egress firewall rules instead.
sub _is_safe_url {
	my $url = $_[0];

	return 0 unless $url =~ m{\Ahttps?://([^/:?\[\]#]+)}i;
	my $host = lc $1;

	# Block well-known loopback aliases.
	return 0 if $host eq 'localhost'
	          || $host =~ /\A127\./
	          || $host eq '0.0.0.0'
	          || $host eq '::1';

	# For literal IPv4 addresses only: check private/link-local/CGNAT ranges.
	# Skipping DNS for hostname targets avoids a live network call in tests and
	# removes the TOCTOU window that makes DNS-resolved checks illusory anyway.
	return 1 unless $host =~ /\A\d{1,3}(?:\.\d{1,3}){3}\z/;

	my $packed = inet_aton($host) or return 1;
	my $n = unpack 'N', $packed;

	return 0 if ($n & 0xFF000000) == 0x0A000000;	# 10/8
	return 0 if ($n & 0xFFF00000) == 0xAC100000;	# 172.16/12
	return 0 if ($n & 0xFFFF0000) == 0xC0A80000;	# 192.168/16
	return 0 if ($n & 0xFFFF0000) == 0xA9FE0000;	# 169.254/16 (link-local / metadata)
	return 0 if ($n & 0xFFC00000) == 0x64400000;	# 100.64/10 (CGNAT)
	return 1;
}

# _safe_back_url($url) -> $url | undef
#
# Purpose: Sanitise a user-supplied back-link URL before it is passed to the
#          template and rendered inside an href="" attribute.  Template Toolkit's
#          | html filter encodes <>&" but does NOT block the javascript: or
#          data: URI schemes, so a raw param('back') = "javascript:alert(1)"
#          would be rendered verbatim inside the href and execute on click.
#
# Rule:    Only absolute http(s) URLs and root-relative paths (starting with /)
#          are permitted.  Anything else (javascript:, data:, vbscript:, empty
#          strings, undef) returns undef so the template renders no href.
#
sub _safe_back_url {
	my ($url) = @_;
	return undef unless defined $url && length($url);
	return $url if $url =~ m{\A(?:/(?!/)|https?://)}i;
	return undef;
}

# ---------------------------------------------------------------------------
# Breadcrumb trail
# ---------------------------------------------------------------------------
#
# Every page shows Home > ... > the page itself.  The trail is not passed in:
# each page's URL already names the page it was opened from (a chart's back=,
# a table's back2= when it was drilled into from a chart), and that URL names
# its own, so the whole path is recovered by following the links up.  Each
# step is named from its own URL by one function, so a crumb always reads the
# same whichever page it appears on.

# The chart and analysis routes, which name their parent with back=.
Readonly my %CRUMB_KIND => (
	graph     => 'Line graph',   line      => 'Line graph',
	pie       => 'Pie chart',    heatmap   => 'Heatmap',
	bar       => 'Bar chart',    stacked   => 'Stacked bar chart',
	scatter   => 'Scatter plot', combo     => 'Combo chart',
	treemap   => 'Treemap',      histogram => 'Histogram',
	wordcloud => 'Word cloud',   map       => 'Map',
	pivot     => 'Pivot table',  stats     => 'Column stats',
	insights  => 'Insights',     folder    => 'Folder view',
);

# How a filter reads in a crumb: "region = East".
Readonly my %CRUMB_OP => (
	eq => '=', ne => '!=', contains => 'contains', starts => 'starts with',
	lt => '<', le => '<=', gt => '>', ge => '>=', between => 'between',
	empty => 'is empty', notempty => 'is not empty',
);

# A trail is never longer than this, whatever the URLs say.
Readonly my $CRUMB_MAX_DEPTH => 8;

# A column name or filter value that a crumb will repeat.  The URL is the
# user's, so a crafted one could put any text in the trail; markup and
# over-long values are left out and the crumb names the page more generally.
Readonly my $CRUMB_TEXT_RE => qr/\A[^<>"\x00-\x1f]{1,64}\z/;

# _breadcrumb_trail($c) -> \@crumbs
#
# Purpose: The pages between Home and this one, this one last: a list of
#          { label, url }.  Home itself is not in the list; the template
#          always puts it first.
# Entry:   $c -- the controller for the request.  A plain function, called
#          from the before_render hook in Database::BI, so every page gets a
#          trail without per-action code.
# Exit:    An arrayref, empty for Home and for a controller that is not this
#          class (a 404 page rendered by Mojolicious itself).
# Notes:   A parent is followed only when _safe_back_url accepts it and it is
#          on this host; a loop or the depth cap ends the trail, so a crafted
#          URL can make it short but never wrong or endless.
sub _breadcrumb_trail {
	my ($c) = @_;
	return [] unless ref $c && $c->isa(__PACKAGE__);

	my @trail;
	my %seen;
	my $url = Mojo::URL->new($c->req->url->path_query);
	while ($url && @trail < $CRUMB_MAX_DEPTH) {
		my $key = $url->path_query;
		last if $seen{$key}++;
		my $label = $c->_crumb_label($url);
		last unless defined $label && length $label;
		unshift @trail, { label => $label, url => $key };
		$url = $c->_crumb_parent($url);
	}
	return \@trail;
}

# _crumb_local($self, $raw) -> Mojo::URL | undef
#
# A parent link as a URL on this site, or undef when there is none to follow:
# empty, refused by _safe_back_url, on another host, or Home (which the trail
# shows anyway).  Absolute links -- the panels pass window.location.href --
# are reduced to their path and query.
sub _crumb_local :Protected ($self, $raw) {
	my $safe = _safe_back_url($raw) or return undef;
	my $url  = Mojo::URL->new($safe);
	if (defined $url->host) {
		my $here = $self->req->url->to_abs;
		return undef unless lc($url->host_port // '') eq lc($here->host_port // '');
	}
	my $path = $url->path->to_string;
	return undef if $path eq '' || $path eq '/';
	return Mojo::URL->new($url->path_query);
}

# _crumb_parent($self, $url) -> Mojo::URL | undef
#
# The page $url was opened from.  A chart names it with back=.  A table page
# names it with back2= when it was drilled into from a chart, and otherwise
# has a natural parent: the left table for a merge or a combine, the schema
# page or the folder for a file, nothing for a table in data_dir.
sub _crumb_parent :Protected ($self, $url) {
	my $path = $url->path->to_string;
	my $q    = $url->query;

	if ($path =~ m{\A/([a-z]+)\z} && $CRUMB_KIND{$1}) {
		return $self->_crumb_local($q->param('back'))
			// $self->_crumb_local($self->_spec_to_url($q->param('l') // ''));
	}
	if ($path =~ m{\A/view/} || $path eq '/import') {
		return $self->_crumb_local($q->param('back2'));
	}
	if ($path eq '/join' || $path eq '/combine') {
		return $self->_crumb_local($q->param('back2'))
			// $self->_crumb_local($self->_spec_to_url($q->param('l') // ''));
	}
	if ($path eq '/open') {
		my $parent = $self->_crumb_local($q->param('back2'))
			// $self->_crumb_local($q->param('back'));
		return $parent if $parent;
		my $file = $q->param('path') // '';
		return undef unless length $file && $file !~ m{\A/\.\./};
		return Mojo::URL->new('/browse?path=' . url_escape(Mojo::File->new($file)->dirname->to_string));
	}
	if ($path eq '/tables') {
		my $spec = $q->param('l') // '';
		return undef unless $spec =~ /\Apath:(.+)\z/;
		return Mojo::URL->new('/browse?path=' . url_escape(Mojo::File->new($1)->dirname->to_string));
	}
	if ($path =~ m{\A/a/}) {
		return $self->_crumb_local($q->param('back'));
	}
	return undef;
}

# _crumb_label($self, $url) -> $text | undef
#
# What a page is called in a trail.  undef for a page that has no place in
# one, which ends the trail there.
sub _crumb_label :Protected ($self, $url) {
	my $path = $url->path->to_string;
	my $q    = $url->query;
	my $view = _crumb_view_suffix($q);

	return _crumb_spec_name("table:$1") . $view if $path =~ m{\A/view/([^/]+)\z};

	if ($path eq '/open') {
		my $name = Mojo::File->new($q->param('path') // '')->basename;
		my $it   = $q->param('it');
		$name .= ": $it" if defined $it && length $it;
		return length $name ? "$name$view" : undef;
	}
	# Either route takes both joins and combined files.
	if ($path eq '/join' || $path eq '/combine') {
		my @names = map { _crumb_spec_name($_) } grep { /\A(?:table|path|url|redis):/i }
			($q->param('l') // ''),
			(map { (split /\|/, $_, 2)[0] // '' } @{ $q->every_param('j') }),
			@{ $q->every_param('c') };
		return @names ? join(' + ', @names) . $view : undef;
	}
	if ($path eq '/import') {
		my $src = Mojo::URL->new($q->param('url') // '');
		return defined $src->host ? $src->host . $view : undef;
	}
	if ($path =~ m{\A/([a-z]+)\z} && $CRUMB_KIND{$1}) {
		my $what = _crumb_chart_subject($1, $q);
		return $CRUMB_KIND{$1} . (length $what ? ": $what" : '');
	}
	if ($path eq '/tables') {
		my $spec = $q->param('l') // '';
		return length $spec ? _crumb_spec_name($spec) . ' schema' : undef;
	}
	if ($path eq '/browse') {
		my $dir = $q->param('path') // '';
		return length $dir ? 'Files: ' . Mojo::File->new($dir)->basename : 'Files';
	}
	return 'Catalog'  if $path eq '/catalog';
	return 'Tutorial' if $path eq '/tutorial';
	if ($path =~ m{\A/a/([A-Za-z0-9_-]+)}) {
		my $a = $self->_read_analyses->{$1};
		return (ref $a eq 'HASH' && length($a->{name} // '')) ? $a->{name} : 'Canvas';
	}
	return undef;
}

# _crumb_spec_name($spec) -> $name
#
# A data source as a person would name it: "sales" for table:sales,
# "store: orders" for an internal table, the file name for path:, the host
# for a web page.
sub _crumb_spec_name {
	my ($spec) = @_;
	$spec //= '';
	return "$1: $2" if $spec =~ m{\Atable:([^/]+)/(.+)\z};
	return $1       if $spec =~ m{\Atable:(.+)\z};
	return Mojo::File->new($1)->basename if $spec =~ m{\Apath:(.+)\z};
	if ($spec =~ m{\Aurl:(.+)\z}i) {
		my $host = Mojo::URL->new($1)->host;
		return $host // $1;
	}
	return 'Redis' if $spec =~ /\Aredis:/i;
	return $spec;
}

# _crumb_view_suffix($query) -> " (region = East, last 90 days)" | ''
#
# The part of a table's view that makes it a different page from the whole
# table: its filters and its time range.  Two filters are shown; more are
# counted, so a crumb stays short.
sub _crumb_view_suffix {
	my ($q) = @_;
	my @bits;
	for my $spec (@{ $q->every_param('f') }) {
		my ($col, $op, $val) = split /:/, $spec, 3;
		next unless length($col // '') && length($op // '');
		next unless $col =~ $CRUMB_TEXT_RE;
		next if length($val // '') && $val !~ $CRUMB_TEXT_RE;
		my $word = $CRUMB_OP{$op} // $op;
		push @bits, ($op eq 'empty' || $op eq 'notempty')
			? "$col $word" : "$col $word " . (($val // '') =~ s/:/ and /r);
	}
	my $extra = @bits > 2 ? @bits - 2 : 0;
	splice @bits, 2 if $extra;
	push @bits, "+$extra more" if $extra;
	if (my $range = $TIME_RANGE{ $q->param('range') // '' }) {
		push @bits, lc $range->{label};
	}
	return @bits ? ' (' . join(', ', @bits) . ')' : '';
}

# _crumb_chart_subject($kind, $query) -> $text
#
# What a chart shows, from its own parameters: "amount by region",
# "Count by region", "amount".  Empty for the pages that are about the
# whole table (stats, insights).
sub _crumb_chart_subject {
	my ($kind, $q) = @_;
	my %p = map {
		my $v = $q->param($_) // '';
		($_ => ($v =~ $CRUMB_TEXT_RE ? $v : ''));
	} qw(x y cat val seg col rows bar_val line_val loc lat lon);

	return "$p{y} by $p{x}" if ($kind eq 'graph' || $kind eq 'line' || $kind eq 'scatter') && length $p{x} && length $p{y};
	return "$p{x} by $p{y}" if $kind eq 'heatmap' && length $p{x} && length $p{y};
	return "$p{cat} by $p{seg}" if $kind eq 'stacked' && length $p{cat} && length $p{seg};
	return $p{rows} =~ s/,/, /gr if $kind eq 'pivot';
	return length $p{loc} ? $p{loc} : (length $p{lat} ? "$p{lat}, $p{lon}" : '') if $kind eq 'map';

	my $dim     = (grep { length } @p{qw(cat x col)})[0] // '';
	my $measure = (grep { length } @p{qw(val bar_val y)})[0] // '';
	$measure = 'Count' if $measure eq '__count__';
	$measure = 'Count' if !length $measure && ($kind eq 'pie' || $kind eq 'bar' || $kind eq 'treemap');
	return length $measure && length $dim ? "$measure by $dim" : $dim;
}

# _resolve_template($self) -> ($platform, $language)
#
# Purpose: Read platform and language from config, then resolve the Accept-Language
#          header to a language code -- falling back to the config language, and
#          then to the default language, when no template directory exists for
#          the code that was resolved.
# Exit:    Returns ($platform, $language) -- both guaranteed non-empty strings.
sub _resolve_template :Protected ($self) {
	my $conf         = $self->app->config();
	my $cfg_platform = $conf->{platform} // 'web';
	my $cfg_language = $conf->{language} // 'en';

	# Detect platform from the request User-Agent via CGI::Info.
	# Falls back to the configured platform when:
	#   (a) CGI::Info is unavailable or throws, or
	#   (b) no templates/<detected>/ directory exists.
	my $platform = _detect_platform(
		$self->req->headers->user_agent // '',
		$cfg_platform,
	);
	unless (-d $self->app->home->child("templates/$platform")) {
		$platform = $cfg_platform;
	}

	my $language = $self->_resolve_language($platform, $cfg_language);
	return ($platform, $language);
}

# _detect_platform($user_agent, $fallback) -> $platform_string
#
# Purpose: Map a raw User-Agent string to a VWF platform dimension
#          ('mobile', 'tablet', or 'web') via CGI::Info.
# Entry:   $user_agent -- the raw HTTP User-Agent header value (may be empty).
#          $fallback   -- value to return if detection fails.
# Exit:    Returns 'mobile', 'tablet', 'web', or $fallback.
# Side Effects: temporarily sets $ENV{HTTP_USER_AGENT} with local().
sub _detect_platform ($user_agent, $fallback) {
	my $platform = eval {
		local $ENV{HTTP_USER_AGENT} = $user_agent;
		my $info = CGI::Info->new();
		$info->is_mobile() ? 'mobile'
		: $info->is_tablet() ? 'tablet'
		:                      'web';
	};
	return $platform // $fallback;
}

# _resolve_language($self, $platform, $default) -> $language_code
#
# Purpose: Determine the best ISO 639-1 language code for this request.
#          When Accept-Language is present, CGI::Lingua selects the best
#          match from the languages that have a template directory under
#          templates/<platform>/.  $default answers when the header is absent,
#          no templates exist for the matched language, or CGI::Lingua is
#          unavailable.  The result has a template directory whenever one
#          exists: a code without one - the configured language included -
#          becomes the default language, and only when that has no directory
#          either is the resolved code returned, so the missing template names
#          what was asked for.
# Entry:   $platform is the resolved VWF platform string.
#          $default  is a non-empty fallback language code (e.g. 'en').
# Exit:    Returns a two-letter ISO 639-1 language code string.
# Side Effects: filesystem stats for template directories;
#               temporarily sets $ENV{HTTP_ACCEPT_LANGUAGE} with local().
sub _resolve_language :Protected ($self, $platform, $default) {
	my $accept = $self->req->headers->accept_language() // '';

	my $language = $default;
	if ($accept) {
		# Discover supported languages from template directories so CGI::Lingua
		# only returns a code we can actually serve.  The configured language is
		# offered as well, so a request that asks for it gets it, whether or not
		# it can be served - the check below decides that.
		my @supported = _template_languages($self->app->home, $platform);
		push @supported, $default unless grep { $_ eq $default } @supported;

		my $chosen = eval {
			local $ENV{HTTP_ACCEPT_LANGUAGE} = $accept;
			my $lingua = CGI::Lingua->new(supported => \@supported);
			$lingua->language_code_alpha2();
		};
		$language = $chosen if defined $chosen;
	}

	# Confirm a template directory exists for the language we are about to
	# render from.  Naming a language does not give it templates, and rendering
	# a directory that is not there is a 500 rather than a translation.  This
	# covers the configured language itself and not just the one Accept-Language
	# produced: the documented fallback used to happen only when the two
	# differed, so the ordinary case - an operator setting language => 'de'
	# before adding templates/web/de/ - reached the renderer unchecked.
	my $home = $self->app->home;
	return $language      if _has_templates($home, $platform, $language);
	return $DEFAULT_LANGUAGE
		if _has_templates($home, $platform, $DEFAULT_LANGUAGE);

	# Neither exists.  Keep what was resolved, so the missing template names the
	# language the request asked for rather than one nobody configured.
	return $language;
}

# _template_languages($home, $platform) -> @codes
#
# The languages that have a template directory for the platform, sorted so that
# the answer does not depend on the order the filesystem returns entries in.
# Plain functions taking the application home rather than methods: the tests
# call _resolve_language with a mock controller, and a method call on it would
# look for the helper in the mock's package rather than this one.
sub _template_languages ($home, $platform) {
	my $base = $home->child("templates/$platform");
	return () unless -d $base;

	return sort map { Mojo::File->new($_)->basename }
		grep { -d $_ } @{ $base->list({ dir => 1 }) };
}

# _has_templates($home, $platform, $language) -> 1 | 0
#
# Whether the application can render a language: the controller builds template
# names as "<platform>/<language>/<page>", so a language without a directory
# under templates/<platform>/ cannot be served at all.
sub _has_templates ($home, $platform, $language) {
	return 0 unless defined $language && length $language;

	return -d $home->child("templates/$platform/$language") ? 1 : 0;
}

# _data_dir_for($app) -> Mojo::File
#
# The configured data directory.  A relative value is resolved against the
# application home, which is the historical behaviour; an absolute one is used
# as given, because Mojo::File->child() appends an absolute path rather than
# replacing the base.  It takes the app rather than $self because the unit
# tests call the scanning helpers with a bare controller.
sub _data_dir_for ($app) {
	my $dir  = $app->config->{data_dir} // 'data';
	my $file = Mojo::File->new($dir);
	return $file if $file->is_abs;
	return $app->home->child($dir);
}

# _scan_data_dir($self) -> \@table_list
#
# Purpose: Return an arrayref of { name, file } hashrefs for every supported
#          data file in the configured data_dir.  Used by the index action; the
#          join panel uses _scan_join_tables, which also lists internal tables.
# Entry:   None.
# Exit:    Returns [] when data_dir does not exist or contains no supported files.
# Side Effects: Filesystem directory read.
#
# Optimisation: single-pass map replaces a two-pass grep+map chain, and calls
# basename() only once per entry (the original chain called it twice: once in
# grep to check the extension and again in map to extract the stem).
# ->to_array avoids the extra flat-list expansion that ->each produced.
sub _scan_data_dir :Protected ($self) {
	my $dir = _data_dir_for($self->app);
	return [] unless -d $dir;
	return $dir->list->map(sub {
		my $base = $_->basename;
		return unless $base =~ $EXT_RE;
		(my $name = $base) =~ s/\.[^.]+\z//;
		{ name => $name, file => $base, path => $_->to_string }
	})->to_array;
}

# _scan_join_tables($self) -> \@table_list
#
# Purpose: Like _scan_data_dir, but each multi-table SQLite file contributes
#          one entry per internal table as well as the file entry.  The join
#          and combine panels need this: "table:store/customer" names a table
#          inside store.db, which a plain file name cannot do.
# Entry:   None.
# Exit:    Returns [] when data_dir does not exist or has no supported files.
#          Every entry has a spec suitable for the panel's option value.
# Side Effects: Reads data_dir and opens each SQLite file to list its tables.
sub _scan_join_tables :Protected ($self) {
	my $dir    = _data_dir_for($self->app);
	my $tables = $self->_scan_data_dir;
	my @all;

	for my $table (@$tables) {
		push @all, { %$table, spec => "table:$table->{name}" };
		next unless $table->{file} =~ /\.(?:db|sql|sqlite|sqlite3)\z/i;

		my $source = eval { $self->open_table($table->{name}, directory => $dir->to_string) };
		next unless $source;

		my $internal_tables = eval { $source->sqlite_tables };
		next unless $internal_tables && @$internal_tables > 1;

		my @internal = @$internal_tables;

		for my $name (@internal) {
			next unless $name =~ $TABLE_NAME_RE;
			push @all, {
				%$table,
				name     => "$table->{name} / $name",
				internal => $name,
				spec     => "table:$table->{name}/$name",
			};
		}
	}

	return \@all;
}

# _open_spec($self, $spec) -> ($DataSource, $label) or ()
#
# Purpose: Parse a "table:name", "table:file/table" or "path:/abs/path" spec,
#          verify the underlying file exists (Database::Abstraction creates empty objects silently for
#          missing files, so we must check ourselves), and return a live
#          DataSource object and a display label.
# Entry:   $spec is a non-empty string.
# Exit:    Returns ($datasource, $label) on success; an empty list on any failure
#          (invalid spec format, file missing, DataSource init error).
# Side Effects: Filesystem stat; DataSource construction (reads file header).
sub _open_spec :Protected ($self, $spec) {
	if ($spec =~ m{\Atable:([A-Za-z0-9_]+)(?:/([A-Za-z0-9_]+))?\z}) {
		my ($table, $internal) = ($1, $2);
		$table = lc $table;
		my $data_dir = _data_dir_for($self->app);
		return () unless grep { -f $data_dir->child("$table.$_") } @SUPPORTED_EXT;
		my $src = eval {
			$self->open_table($table, directory => $data_dir->to_string,
				defined $internal ? (internal_table => $internal) : ())
		};
		return ($src, defined $internal ? $internal : $table) if $src && !$@;
	} elsif ($spec =~ /\Apath:(.+)\z/) {
		my $path_arg = $1;
		# Remote path: /../hostname/dir/file -- delegate to DataSource with host param.
		# No EXT_RE check: security comes from REMOTE_HOST_RE.  The original
		# extension (if any) is passed as file_ext so _init_backend tries it first.
		if ($path_arg =~ m{\A/\.\./([^/]+)((?:/.+)?)/([^/]+)\z}) {
			my ($host, $dir_part, $file) = ($1, $2 // '', $3);
			$dir_part = '/' unless length $dir_part;
			return () unless $host =~ $REMOTE_HOST_RE;
			my ($table, $ext) = $file =~ /\A(.+)\.([^.]+)\z/ ? ($1, $2) : ($file, undef);
			my $src = eval { $self->open_table($table, directory => $dir_part, host => $host,
				defined $ext ? (file_ext => $ext) : ()) };
			return ($src, $file) if $src && !$@;
			return ();
		}
		my $file = eval { Mojo::File->new($path_arg)->realpath };
		if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
			my $dir = $file->dirname->to_string;
			(my $table = $file->basename) =~ s/\.[^.]+\z//;
			my $src = eval { $self->open_table($table, directory => $dir) };
			return ($src, $file->basename) if $src && !$@;
		}
	} elsif($spec =~ $URL_SPEC_RE) {
		my $url = $1;
		return () unless _is_safe_url($url);
		my $src = eval { $self->open_table('', url => $url) };
		return ($src, $src->table_name) if $src && !$@;
	} elsif($spec =~ $REDIS_SPEC_RE) {
		my ($table, $redis_url) = ($1, $2);
		my $src = eval { $self->open_table($table, redis => $redis_url) };
		return ($src, $table) if $src && !$@;
	}
	return ();
}

# _schema_type_name($entry) -> $type
#
# Purpose: Normalise one schema() entry to an upper-case type name.
# Entry:   A hashref such as { type => 'INTEGER' }, a plain string, or undef.
# Exit:    The type name, or '' when the backend did not declare one.
sub _schema_type_name {
	my ($entry) = @_;
	return '' unless defined $entry;

	my $type = ref($entry) eq 'HASH' ? $entry->{type} : $entry;
	return '' unless defined($type) && !ref($type) && length($type);

	return uc $type;
}

# _schema_type_warnings($self, $left, $right, $left_label, $right_label,
#                       $left_key, $right_key) -> @warning_text
#
# Purpose: Describe columns whose declared types disagree across one join step.
# Entry:   $left and $right are open sources; the labels name them in the message.
#          The two join keys are excluded: Database::Join itself treats their
#          types as free to differ, because the key is not a data column.
# Exit:    Zero or more formatted warning strings for the schema_warnings banner.
#
# Database::Join's warn_schema_type_mismatch cannot fire here: every join this
# controller builds passes a collision_prefix for the right table, so the
# mismatched columns are published under distinct names and the check correctly
# stays quiet.  The difference still matters to a reader - a sum over a text
# column yields nothing - so the comparison is made here, on the two sides as
# the user sees them in the join panel.
sub _schema_type_warnings :Protected ($self, $left, $right, $left_label, $right_label,
	$left_key, $right_key) {
	my $left_schema  = eval { $left->schema }  // {};
	my $right_schema = eval { $right->schema } // {};
	return () unless %{ $left_schema // {} } && %{ $right_schema // {} };

	my %is_key = map { (defined($_) && length($_)) ? ($_ => 1) : () }
		($left_key, $right_key);

	my @warnings;
	for my $col (sort keys %$right_schema) {
		next if $is_key{$col};
		next unless exists $left_schema->{$col};

		my $left_type  = _schema_type_name($left_schema->{$col});
		my $right_type = _schema_type_name($right_schema->{$col});
		next unless length($left_type) && length($right_type);
		next if $left_type eq $right_type;

		push @warnings, $self->_i18n('warn_join_schema_mismatch',
			$col, $left_type, $left_label, $right_type, $right_label);
	}

	return @warnings;
}

# _spec_to_url($self, $spec) -> $url_string
#
# Purpose: Convert a table/path spec back to a browseable URL (used for the
#          back-link on join and export views).
# Entry:   $spec is a "table:name", "table:file/table" or "path:/abs" string.
# Exit:    Returns a URL string beginning with '/'.
sub _spec_to_url :Protected ($self, $spec) {
	if ($spec =~ m{\Atable:([A-Za-z0-9_]+)(?:/([A-Za-z0-9_]+))?\z}) {
		my ($table, $internal) = ($1, $2);
		return "/view/$table" unless defined $internal;

		my $data_dir = _data_dir_for($self->app);
		for my $ext (@SUPPORTED_EXT) {
			my $file = $data_dir->child("$table.$ext");
			next unless -f $file;
			return '/open?path=' . url_escape($file->to_string) . '&it=' . url_escape($internal);
		}
		return "/view/$table";
	}
	return '/open?path=' . url_escape($1) if $spec =~ /\Apath:(.+)\z/;
	return '/import?url=' . url_escape($1) if $spec =~ $URL_SPEC_RE;
	return '/' if $spec =~ $REDIS_SPEC_RE;
	return '/';
}

# _url_attribution($self) -> ($url_string, $date_string) or (undef, undef)
#
# Purpose: Return source URL and access date for chart attribution when the
#          left table was imported from a web URL.  The date is the time of
#          the current request (which is when the data is being accessed),
#          formatted as "D Month YYYY".
# Entry:   Reads the 'l' query param.
# Exit:    ($url, $date) when the spec matches $URL_SPEC_RE; (undef, undef)
#          for table: and path: specs.
sub _url_attribution :Protected ($self) {
	my $spec = $self->param('l') // '';
	return (undef, undef) unless $spec =~ $URL_SPEC_RE;
	my $url  = $1;
	my @MON  = qw(January February March April May June July August
	              September October November December);
	my (undef, undef, undef, $mday, $mon, $year) = localtime;
	return ($url, sprintf('%d %s %d', $mday, $MON[$mon], $year + 1900));
}

# _get_columns($source, $records) -> @column_names
#
# Purpose: Return an ordered column list from a DataSource object.
#          For CSV/TSV/PSV the DataSource stores the original file-header order.
#          For SQLite/XML where no file-header order is available, the fallback
#          is: id_column first (only if it actually appears in the data), then
#          the remaining columns sorted alphabetically.
# Entry:   $source is a DataSource; $records is an arrayref of hashrefs (may be empty).
# Exit:    Returns a flat list of column-name strings (may be empty).
#
# Reduction: columns() is a pure accessor -- cache once to avoid a redundant
# method dispatch on the second reference.
sub _get_columns {
	my ($source, $records) = @_;
	my $cols = $source->columns;
	return @$cols if $cols;
	return () unless $records->[0];
	my %all = map { $_ => 1 } keys %{ $records->[0] };
	my $c   = $source->id_column;
	my $id  = ($c && $all{$c}) ? $c : (sort keys %all)[0];
	delete $all{$id};
	return ($id, sort keys %all);
}

# _apply_filter_spec($records, $spec) -> \@filtered_records
#
# Purpose: Apply one "col:op:val" filter to an arrayref of record hashrefs and
#          return a new (possibly shorter) arrayref.  The original is not mutated.
#          Value may contain colons: "col:op:val:with:colons" -- split limit 3
#          puts everything after the second colon into $val.
#          Unknown operators fall through to 1 (all rows pass) so new operators
#          added in future do not break existing callers.
# Entry:   $records is an arrayref of hashrefs; $spec is a colon-delimited string.
# Exit:    Returns filtered arrayref (same reference if spec is invalid/unparseable).
#
# Domain Constraints (operator names):
#   Operator names are CASE-SENSITIVE.  Only the exact lowercase forms below are
#   recognised; an uppercase or mixed-case name (e.g. "EQ", "Lt") falls through
#   to the default `1` branch and all rows pass unfiltered.
#   Valid operators:
#     String (value comparison is case-insensitive via lc()):
#       eq, ne, contains, starts
#     Numeric (Perl <, <=, >, >= coercion):
#       lt (strict), le (inclusive), gt (strict), ge (inclusive)
#     Unary (val is ignored):
#       empty (cell eq ''), notempty (cell ne '')
#     Range (val = lo:hi, string comparison -- correct for ISO YYYY-MM-DD dates):
#       between -- lo le cell le hi
#   Boundary rules for numeric operators:
#     le/ge include the boundary value; lt/gt exclude it.
#   contains/starts with empty val ('') match every record (index always 0).
#
# Reduction: split(/:/, $spec, 3) always produces at least one defined element,
# so "defined $col" is structurally guaranteed true and is removed.
# "$_->{$col} // ''" replaces the equivalent ternary form.
#
# Optimisation: $lval = lc($val) is computed once before the grep.  Without this
# precompute, every case-insensitive operator (eq, ne, contains, starts) would
# call lc($val) O(N) times for N records -- a pure O(N) waste since $val is
# constant within a single filter application.
# _is_iso_date($value) -> bool
#
# Purpose: Report whether a filter value names a point in time rather than a
#          plain string, so the date comparisons can be used instead of the
#          string ones.  A bare date (YYYY-MM-DD) qualifies, and so does an ISO
#          timestamp (YYYY-MM-DDTHH:MM:SS) or the same with a space separator,
#          which is what CSV exports and SQLite text columns usually hold.
sub _is_iso_date {
	return $_[0] =~ /\A\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2})?)?\z/;
}

# Convert M/D/YYYY or YYYY-MM-DD to YYYY-MM-DD; returns undef for other formats.
# A value that is already ISO is returned unchanged, including its time part: a
# timestamp cell is the caller's to compare, not this sub's to truncate.
sub _to_iso_date {
	my ($v) = @_;
	return $v if _is_iso_date($v);
	if (my ($m, $d, $y) = $v =~ m{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}) {
		return sprintf '%04d-%02d-%02d', $y, $m, $d;
	}
	return;
}

# _date_key($value, $precision) -> comparable key | undef
#
# Purpose: Put a cell and a filter bound on the same footing so that a
#          lexicographic comparison answers the question the filter asked.
#          $precision is 10 for a day and 19 for a second: a cell holding a
#          timestamp is compared at the day it falls in when the bound is a
#          day, and to the second when the bound carries a time.  A value that
#          is not date-shaped at all returns undef, and the caller keeps the
#          raw cell instead.
sub _date_key {
	my ($value, $precision) = @_;
	return undef unless defined $value;
	my ($day, $hour, $min, $sec) =
		$value =~ /\A(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?\z/;
	return undef unless defined $day;
	return $day if $precision < 19;
	return sprintf '%sT%s:%s:%s', $day, $hour // '00', $min // '00', $sec // '00';
}

# ---------------------------------------------------------------------------
# Relative time ranges
# ---------------------------------------------------------------------------

# _iso_day($epoch) -> 'YYYY-MM-DD' in local time
sub _iso_day {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02d', $lt[5] + 1900, $lt[4] + 1, $lt[3];
}

# _iso_second($epoch) -> 'YYYY-MM-DDTHH:MM:SS' in local time
sub _iso_second {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0];
}

# _midday($mday, $mon, $year) -> epoch
#
# Noon, so a boundary never lands in a daylight-saving gap, and mktime's own
# normalisation (day 0 is the last day of the previous month, month -1 is
# December, and so on) is what makes the month, quarter and year arithmetic
# below one line each.  $mon is 0-based, $year is years since 1900, matching
# localtime's own convention.
sub _midday {
	require POSIX;
	return POSIX::mktime(12, 0, 0, $_[0], $_[1], $_[2]);
}

# _time_range_bounds($preset, $now) -> ($lo, $hi)
#
# Purpose: Resolve one preset to the window it names, as two strings that the
#          filter engine can compare against: 'YYYY-MM-DD' for a day-granular
#          window, 'YYYY-MM-DDTHH:MM:SS' for last_24_hours.
# Entry:   $preset -- one entry of @TIME_RANGES.
#          $now    -- epoch second; defaults to the clock, and a caller may
#                     pass one so a test can name the day it is asking about.
# Exit:    Two-element list, or an empty list for a preset with no window.
# Notes:   "This month" and "this quarter" end today rather than at the end of
#          the period, which is what the same names mean in a search bar; the
#          completed period is last_month / last_quarter.
sub _time_range_bounds {
	my ($preset, $now) = @_;
	$now = time() unless defined $now;

	my @lt = localtime($now);
	my ($mday, $mon, $year) = @lt[3, 4, 5];	# mon is 0-based

	if ($preset->{hours}) {
		return (_iso_second($now - $preset->{hours} * 3600), _iso_second($now));
	}

	my $today = _midday($mday, $mon, $year);

	if (defined $preset->{day}) {
		my $day = _midday($mday + $preset->{day}, $mon, $year);
		return (_iso_day($day), _iso_day($day));
	}

	if (defined $preset->{days}) {
		return (_iso_day(_midday($mday - $preset->{days} + 1, $mon, $year)),
			_iso_day($today));
	}

	if (defined $preset->{month}) {
		my $m = $mon + $preset->{month};
		return $preset->{month} == 0
			? (_iso_day(_midday(1, $mon, $year)), _iso_day($today))
			: (_iso_day(_midday(1, $m, $year)), _iso_day(_midday(0, $m + 1, $year)));
	}

	if (defined $preset->{quarter}) {
		my $q = int($mon / 3) * 3 + 3 * $preset->{quarter};
		return $preset->{quarter} == 0
			? (_iso_day(_midday(1, $q, $year)), _iso_day($today))
			: (_iso_day(_midday(1, $q, $year)), _iso_day(_midday(0, $q + 3, $year)));
	}

	if (defined $preset->{year}) {
		my $y = $preset->{year}; 	# 0 = this year, -1 = last year
		my $start = _midday(1, 0, $year + $y);
		return $preset->{year} == 0
			? (_iso_day($start), _iso_day($today))
			: (_iso_day($start), _iso_day(_midday(31, 11, $year + $y)));
	}

	return ();
}

# _time_range_specs($col, $lo, $hi) -> \@specs
#
# Purpose: Express a window as the f= filters the pipeline applies.
# Notes:   Two bounds -- col:ge:lo and col:le:hi -- rather than one between
#          spec.  A between value is "lo:hi" and its separator is a colon, so
#          it cannot carry a bound with a time in it (last_24_hours ends in
#          HH:MM:SS), and a colon in a column value would end the operator
#          field early.  Two specs are inclusive at both ends exactly once,
#          whatever precision the bounds carry.
sub _time_range_specs {
	my ($col, $lo, $hi) = @_;
	return [] unless length($col // '') && length($lo // '') && length($hi // '');
	return [ "$col:ge:$lo", "$col:le:$hi" ];
}

# _time_range_preset($name) -> \%preset | undef
#
# The named entry of the vocabulary above, or undef for a name that is not in
# it.  A URL value reaches this, so it answers undef rather than croaking.
sub _time_range_preset {
	my ($name) = @_;
	return $TIME_RANGE{$name // ''};
}

# _time_range_presets($now) -> \@presets
#
# Purpose: The menu a filter bar offers, with the dates each entry currently
#          resolves to, so the page can show a range and, where it has asked
#          for the dataset's own extent, disable an entry the data cannot
#          answer.
sub _time_range_presets {
	my ($now) = @_;
	return [ map {
		my ($lo, $hi) = _time_range_bounds($_, $now);
		{ name => $_->{name}, label => $_->{label}, lo => $lo, hi => $hi }
	} @TIME_RANGES ];
}

# _apply_time_range($records, $name, $col) -> \@records
#
# Purpose: Apply a named relative range to a record set.  Used by the canvas,
#          which renders its cards from its own pipeline rather than through a
#          route's f= params.
# Entry:   $name and $col are the URL values; neither is trusted.  An unknown
#          name or an unusable column leaves the records alone, so a stale
#          bookmark shows unfiltered data rather than an error page.
sub _apply_time_range {
	my ($records, $name, $col) = @_;
	my $preset = $TIME_RANGE{$name // ''} or return $records;
	return $records unless defined $col && length $col && $col !~ /:/;
	my ($lo, $hi) = _time_range_bounds($preset);
	for my $spec (@{ _time_range_specs($col, $lo, $hi) }) {
		$records = _apply_filter_spec($records, $spec);
	}
	return $records;
}

# _time_range_request($c) -> bool
#
# Purpose: Turn the relative time range a request names -- ?range=<name> and
#          ?rcol=<column> -- into the f= filters every data route already
#          applies, and describe the range on the stash so a template can show
#          a chip and the preset menu.  Registered as a before_dispatch hook in
#          Database::BI::startup, so one implementation covers the table view,
#          every chart, the pivot, stats, insights, the exports and the canvas,
#          and a request that carries a range needs no per-route code.
# Entry:   $c -- the controller for the request.
# Exit:    Records the resolved bounds on the stash, where _filter_specs picks
#          them up for whichever pipeline the route runs, and returns true --
#          or renders 400 for a range that cannot be honoured and returns
#          false, which stops the route from running against the wrong rows.
#          The bounds are not written back into the request's f= params, so the
#          reader's own filter list -- the chips, the panel forms and the
#          filter UI -- never shows a range as dates it did not choose.
sub _time_range_request ($c) {
	my $name = $c->param('range');
	my $col  = $c->param('rcol');

	$c->stash(time_range_presets => _time_range_presets());
	$c->stash(range_specs        => []);

	return 1 unless defined $name && length $name;

	my $preset = $TIME_RANGE{$name};
	unless ($preset) {
		$c->render(
			text   => sprintf($MESSAGES{error_range_name}, $name,
				join(', ', map { $_->{name} } @TIME_RANGES)),
			status => 400,
		);
		return 0;
	}
	unless (defined $col && length $col && $col !~ /:/) {
		$c->render(text => $MESSAGES{error_range_column}, status => 400);
		return 0;
	}

	my ($lo, $hi) = _time_range_bounds($preset);
	my $specs = _time_range_specs($col, $lo, $hi);

	$c->stash(
		time_range  => {
			name  => $preset->{name},
			label => $preset->{label},
			col   => $col,
			lo    => $lo,
			hi    => $hi,
		},
		range_specs => $specs,
	);
	return 1;
}

sub _apply_filter_spec {
	my ($records, $spec) = @_;
	my ($col, $op, $val) = split /:/, $spec, 3;
	return $records unless length($col // '') && defined $op && length $op;
	$val //= '';
	my $lval    = lc $val;	# precompute once; avoids O(N) redundant lc() inside grep
	my $is_date = _is_iso_date($val)
		|| ($op eq 'between' && $val =~ /\A\d{4}-\d{2}-\d{2}:/);
	# Compare at the precision the bound names: a bound with a time in it asks
	# about the second, a bare date asks about the day.  Without this, a date
	# bound compared against a column of timestamps drops every row on the
	# boundary day, because the cell string carries more characters than the
	# bound and "2026-10-27T09:15:00" sorts after "2026-10-27".
	my $prec = ($is_date && $val =~ /\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}/) ? 19 : 10;
	my $nval = $is_date ? (_date_key($val, $prec) // $val) : $val;
	return [grep {
		my $cell  = $_->{$col} // '';
		# Normalise M/D/YYYY cells to ISO for date comparisons so that the
		# ISO values produced by <input type="date"> match against either format.
		my $ncell = $is_date
			? (_date_key(_to_iso_date($cell) // $cell, $prec) // $cell)
			: $cell;
		$op eq 'eq'       ? ($is_date ? $ncell eq $nval  : lc($cell) eq $lval) :
		$op eq 'ne'       ? ($is_date ? $ncell ne $nval  : lc($cell) ne $lval) :
		$op eq 'contains' ? index(lc($cell), $lval) != -1                      :
		$op eq 'starts'   ? index(lc($cell), $lval) == 0                       :
		$op eq 'lt'       ? ($is_date ? $ncell lt $nval  : $cell <  $val)      :
		$op eq 'le'       ? ($is_date ? $ncell le $nval  : $cell <= $val)      :
		$op eq 'gt'       ? ($is_date ? $ncell gt $nval  : $cell >  $val)      :
		$op eq 'ge'       ? ($is_date ? $ncell ge $nval  : $cell >= $val)      :
		$op eq 'empty'    ? $cell eq ''                                         :
		$op eq 'notempty' ? $cell ne ''                                         :
		$op eq 'between'  ? do {
			my ($lo, $hi) = split /:/, $val, 2;
			length($lo // '') && length($hi // '') && $ncell ge $lo && $ncell le $hi
		} :
		1
	} @$records];
}

# ---------------------------------------------------------------------------
# The cross-row pass (BI-Phase-7.md item 7.2)
# ---------------------------------------------------------------------------
#
# A measure folds a group into one number and a calculated field computes one
# row from that row.  This is the third shape: one row from many rows, written
# back onto every row -- a running total, a moving average, a rank, a share of
# the whole.  None of them can be a measure (the answer is per row, not per
# group) and none can be a calc field (it needs its neighbours), which is why
# they are a pass of their own.
#
# The functions follow Splunk's split, because it is also the natural one:
# the eventstats family is order-free (pct_of_total, rank, zscore), the
# streamstats family is incremental and therefore needs an order (running_*,
# window_*, lag, delta, pct_change).

# The same vocabulary as a menu, for the panel that adds a cross-row column.
# It is data rather than a list written into the template so the function
# names, their labels and the two facts the form needs -- whether a function
# takes a window, and whether it needs an order -- cannot drift from the
# validator above.
Readonly my @CROSS_ROW_MENU => (
	{ name => 'running_total', label => 'Running total',        arg => 0, order => 1 },
	{ name => 'running_count', label => 'Running count',        arg => 0, order => 1 },
	{ name => 'running_pct',   label => 'Running percent',      arg => 0, order => 1 },
	{ name => 'window_sum',    label => 'Moving sum',           arg => 1, order => 1 },
	{ name => 'window_avg',    label => 'Moving average',       arg => 1, order => 1 },
	{ name => 'lag',           label => 'Previous row',         arg => 0, order => 1 },
	{ name => 'delta',         label => 'Change from previous', arg => 0, order => 1 },
	{ name => 'pct_change',    label => 'Percent change',       arg => 0, order => 1 },
	{ name => 'pct_of_total',  label => 'Percent of total',     arg => 0, order => 0 },
	{ name => 'rank',          label => 'Rank, largest first',  arg => 0, order => 0 },
	{ name => 'zscore',        label => 'Z-score',              arg => 0, order => 0 },
);

Readonly my %CROSS_ROW_FNS => (
	running_total => { family => 'stream' },
	running_count => { family => 'stream' },
	running_pct   => { family => 'stream' },
	window_sum    => { family => 'stream', arg => 'count' },
	window_avg    => { family => 'stream', arg => 'count' },
	lag           => { family => 'stream' },
	delta         => { family => 'stream' },
	pct_change    => { family => 'stream' },
	pct_of_total  => { family => 'event' },
	rank          => { family => 'event' },
	zscore        => { family => 'event' },
);

# _cross_row_specs($self, \@columns, $params) -> \%plan | { error => $message } | undef
#
# Purpose: Read cs=/by=/order= and turn them into a plan the pass can run:
#          which function writes which column, partitioned by what, ordered by
#          what.  Nothing is evaluated here, so a request that names a column
#          or a function that does not exist is refused before a single row is
#          touched, and the refusal is a 400 rather than a chart of something
#          else.
# Entry:   \@columns -- the columns of this view, so a cs=/by=/order= column is
#                       checked against what the reader can actually see.
#          $params -- where the three parameters are read from, or undef for
#                     this request.  Anything with param()/every_param() will
#                     do: the canvas reads them from the canvas page's own query
#                     string, because its cards are drawn against the canvas's
#                     state rather than against whatever URL fetched them.
# Exit:    undef when the request names no cross-row column.  Otherwise
#          { specs => [ { col, fn, as, arg } ], by => [col ...],
#            order => [ { col, dir } ] }, or { error => $message } for a
#          request that cannot be honoured.
# Notes:   The streamstats family reads its rows in order, so order= is
#          required for it and refused as missing by name.  The eventstats
#          family does not care and does not require it.
sub _cross_row_specs :Protected ($self, $columns, $params = undef) {
	my $p = $params // $self;

	# The three values are the URL's spelling of a plan, read once here so the
	# parser below serves a canvas card too - a card stores its own plan as
	# { cs, by, order } rather than as a query string.
	return $self->_cross_row_specs_from($columns, {
		cs    => [ @{ $p->every_param('cs') // [] } ],
		by    => ($p->param('by') // ''),
		order => [ @{ $p->every_param('order') // [] } ],
	});
}

# _cross_row_specs_from($self, \@columns, \%raw) -> \%plan | { error } | undef
#
# Purpose: The same validation, from a plan as a saved canvas card stores it.
# Entry:   \%raw -- { cs => [spec ...], by => 'a,b', order => ['col:dir' ...] },
#                    in the spelling cs=/by=/order= use.
# Exit:    As _cross_row_specs.
sub _cross_row_specs_from :Protected ($self, $columns, $raw) {
	my @texts = grep { defined $_ && !ref $_ && length } @{ $raw->{cs} // [] };
	return undef unless @texts;

	my %col_set = map { $_ => 1 } @{ $columns // [] };
	my %taken;
	my @specs;

	for my $text (@texts) {
		my ($col, $fn, $as, $arg) = split /:/, $text, 4;
		return { error => $self->_i18n('error_cs_spec', $text) }
			unless defined $col && length $col
				&& defined $fn  && length $fn
				&& defined $as  && length $as;

		return { error => $self->_i18n('error_cs_column', $text, $col) }
			unless $col_set{$col};

		return { error => $self->_i18n('error_cs_fn', $fn, join(' ', sort keys %CROSS_ROW_FNS)) }
			unless $CROSS_ROW_FNS{$fn};

		return { error => $self->_i18n('error_cs_alias', $as) }
			unless $as =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

		return { error => $self->_i18n(q{error_cs_conflict}, $as) }
			if $col_set{$as} || $taken{$as};
		$taken{$as} = 1;

		my $decl = $CROSS_ROW_FNS{$fn};
		if ($decl->{arg}) {
			return { error => $self->_i18n('error_cs_arg', $text, $fn, $col, $fn) }
				unless defined $arg && $arg =~ /\A\d+\z/ && $arg > 0;
		}
		elsif (defined $arg && length $arg) {
			return { error => $self->_i18n('error_cs_no_arg', $text, $fn) };
		}

		push @specs, {
			col => $col,
			fn  => $fn,
			as  => $as,
			arg => (defined $arg && length $arg) ? $arg + 0 : undef,
		};
	}

	# by= is the partition.  An empty value is its own partition rather than a
	# dropped row: a windowed column has to cover every displayed row, which is
	# not the rule the pivot uses for a cell -- see the POD.
	my $by_text = (!ref $raw->{by} && defined $raw->{by}) ? "$raw->{by}" : '';
	my @by      = grep { length } map { _trim($_) } split /,/, $by_text, -1;
	for my $c (@by) {
		return { error => $self->_i18n('error_cs_by', $by_text, $c) } unless $col_set{$c};
	}

	my @order;
	for my $text (@{ $raw->{order} // [] }) {
		my $spec = _trim((!ref $text && defined $text) ? $text : '');
		next unless length $spec;
		my ($c, $dir) = split /:/, $spec, 2;
		$c = _trim($c // '');
		$dir = defined $dir && length $dir ? lc _trim($dir) : 'asc';
		return { error => $self->_i18n('error_cs_order', $spec) }
			unless length $c && $dir =~ /\A(?:asc|desc)\z/;
		return { error => $self->_i18n('error_cs_order_col', $spec, $c) }
			unless $col_set{$c};
		push @order, { col => $c, dir => $dir };
	}

	for my $spec (@specs) {
		next unless $CROSS_ROW_FNS{ $spec->{fn} }{family} eq 'stream';
		return {
			error => $self->_i18n('error_cs_order_need',
				join(':', $spec->{col}, $spec->{fn}, $spec->{as}), $spec->{fn})
		} unless @order;
	}

	return { specs => \@specs, by => \@by, order => \@order };
}

# _card_plan($raw) -> \%plan | { error }
#
# Purpose: The cross-row plan a saved canvas card carries, in the spelling
#          cs=/by=/order= use, so a card added and a card repaired store the
#          same shape and the one parser above reads them both.
# Entry:   $raw -- the request's cross_row value.  A hash that names no cs is
#          the card saying it runs no plan of its own; _cross_row_specs_from
#          reads that as no pass at all, and so does the renderer.
# Exit:    { cs => [...], by => '', order => [...] } -- only the shape is
#          checked here.  Which columns exist is a fact about the data file and
#          is checked again on every render, so a plan written today is read
#          against the columns the canvas has today.
# Notes:   A part of the plan that is the wrong kind is an error rather than a
#          silently empty list: a repair that stores nothing still answers 200,
#          and the caller would have no way to know the card had not changed.
sub _card_plan {
	my ($raw) = @_;

	for my $key (qw(cs order)) {
		next unless defined $raw->{$key};
		return { error => "cross_row.$key must be a list" }
			if ref $raw->{$key} ne 'ARRAY';
		return { error => "cross_row.$key must be a list of strings" }
			if grep { ref } @{ $raw->{$key} };
	}
	return { error => 'cross_row.by must be a column name' } if ref $raw->{by};

	return {
		cs    => [ grep { defined $_ && length } @{ $raw->{cs} // [] } ],
		by    => (defined $raw->{by} ? "$raw->{by}" : ''),
		order => [ grep { defined $_ && length } @{ $raw->{order} // [] } ],
	};
}

# _cross_row_ui_state($c) -> %stash_pairs
#
# Purpose: The cross-row state the table page shows: the specs it puts in
#          chips, the partition and order its chart panels carry, and the
#          panel's own menu.  Also the rest of the query string, because the
#          panel edits three parameters and must submit the others unchanged.
# Entry:   $c -- the controller, for its query string only.
# Exit:    A list suitable for stash(): cross_row_specs, cross_row_by,
#          cross_row_order, cross_row_menu, cross_row_hidden.
# Notes:   cs=/by=/order= are deliberately absent from cross_row_hidden.  The
#          panel writes them from its own controls, and a hidden by= as well
#          would send two values; param('by') reads the first, so the reader's
#          choice would be silently ignored in favour of the old one.
#          Only the query string is read -- never the body -- because this runs
#          before dispatch on every request, including JSON posts.
sub _cross_row_ui_state {
	my ($c) = @_;

	my $query  = $c->req->query_params;
	my @specs  = grep { length } @{ $query->every_param('cs') // [] };
	my @orders = grep { length } @{ $query->every_param('order') // [] };

	my @hidden;
	# names() is a list in some Mojo releases and an arrayref in others; taking
	# the arrayref is what both accept.
	for my $name (@{ $query->names }) {
		next if $name eq 'cs' || $name eq 'by' || $name eq 'order';
		push @hidden, map { { name => $name, value => $_ } }
			@{ $query->every_param($name) // [] };
	}

	return (
		cross_row_specs  => \@specs,
		cross_row_by     => ($query->param('by') // ''),
		cross_row_order  => \@orders,
		cross_row_menu   => \@CROSS_ROW_MENU,
		cross_row_hidden => \@hidden,
	);
}

# _apply_cross_row($self, $records, \@columns, $plan) -> ($records, \@columns)
#
# Purpose: Stage 6 of the pipeline: run every cs= spec over the rows and write
#          the answer onto each row as a column of its own.  Called from
#          _reduce_records (the routes that reduce there) and from _fetch_page
#          after its own filtering (the routes that paginate), always before
#          anything slices a page, so page 2 continues page 1's running total.
# Entry:   $records -- arrayref of hashrefs, already filtered.
#          \@columns -- the columns list, or undef where the caller has none in
#                       scope; then it is derived from the first row.
#          $plan -- an already validated plan from _cross_row_specs($columns,
#                   $params), or undef to read this request's cs=.  A canvas
#                   validates once and runs the plan once per card, on each
#                   card's own rows; re-reading cs= there would work today only
#                   because the canvas page carries it, and would silently stop
#                   working for a card redrawn by an API call.
# Exit:    ($records, \@columns) with the produced columns appended, or the
#          arguments untouched when the request names no cs=.  Croaks with an
#          i18n message when a spec cannot be honoured; the caller renders 400.
# Notes:   Rows are grouped into partitions by by=, each partition is sorted
#          once (stable, ties in arrival order, so two runs over the same file
#          agree), and each spec is then one pass over each partition.  A
#          partition total is accumulated in that pass, never per row.
#
#          The rows keep the order they arrived in: order= says which order the
#          window is read along, not which order the table is shown in.  The
#          table has its own sort controls, and a reader may well want them to
#          disagree (a ledger sorted by amount, running totals following the
#          date), so the pass writes values in place rather than reordering.
#
#          A cell that is not numeric yields undef in the produced column rather
#          than a placeholder: there is no previous row for the first row of a
#          partition, and a chart skips undef while the measure fold does too,
#          so an undef window cannot silently become a zero.
sub _apply_cross_row :Protected ($self, $records, $columns, $plan = undef) {
	my $cols = $columns;
	unless (defined $cols) {
		$cols = [ sort keys %{ $records->[0] // {} } ];
	}

	$plan //= $self->_cross_row_specs($cols);
	return ($records, $columns) unless $plan;
	croak $plan->{error} if $plan->{error};

	# Partitions, in first-appearance order so a report reads in file order.
	my (@part_keys, %parts);
	for my $i (0 .. $#$records) {
		my $row = $records->[$i] // {};
		my $key = join("\x00", map { defined $row->{$_} ? "$row->{$_}" : '' } @{ $plan->{by} });
		push @part_keys, $key unless exists $parts{$key};
		push @{ $parts{$key} }, $i;
	}

	# One sort per partition, whatever the number of specs.  The index is the
	# tie-break, so the sort is stable even where the keys are equal.
	if (my @order = @{ $plan->{order} }) {
		for my $key (@part_keys) {
			my $idx = $parts{$key};
			next unless @$idx > 1;
			$parts{$key} = [ sort {
				my $cmp = 0;
				for my $o (@order) {
					$cmp = _cross_row_cmp($records->[$a]{ $o->{col} }, $records->[$b]{ $o->{col} });
					$cmp = -$cmp if $o->{dir} eq 'desc';
					last if $cmp;
				}
				$cmp || $a <=> $b;
			} @$idx ];
		}
	}

	my @names;
	for my $spec (@{ $plan->{specs} }) {
		my ($fn, $as, $col) = @{$spec}{qw(fn as col)};
		for my $key (@part_keys) {
			my $idx  = $parts{$key};
			my @vals = map { _numeric_cell($records->[$_]{$col}) } @$idx;
			my @out  = _cross_row_values($fn, \@vals, $spec->{arg});
			for my $j (0 .. $#$idx) {
				my $i = $idx->[$j];
				$records->[$i] = _extend_row($records->[$i], $as, $out[$j]);
			}
		}
		push @names, $as;
	}

	my @extended = (@$cols, @names);
	$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
	$self->stash('_virtual_columns')->{$_} = 1 for @names;
	# The routes that paginate ask for their columns separately, after the page
	# is sliced, so the names are left where they can be picked up.
	$self->stash('_cross_row_columns' => \@names);

	return ($records, \@extended);
}

# _cross_row_values($fn, \@values, $arg) -> @values
#
# The arithmetic of one spec over one partition: @values is the source column
# of each row in order, numeric or undef, and the answer is aligned with it.
# A plain function, so the pass has one place where the functions are defined
# and the tests can drive them without a controller.
sub _cross_row_values {
	my ($fn, $vals, $arg) = @_;
	my @out;
	my $n = scalar @$vals;
	return @out unless $n;

	if ($fn eq 'running_count') {
		return map { $_ + 1 } 0 .. $n - 1;
	}

	if ($fn eq 'running_total') {
		my $run = 0;
		for my $v (@$vals) {
			$run += $v if defined $v;
			push @out, defined $v ? $run : undef;
		}
		return @out;
	}

	if ($fn eq 'running_pct') {
		my $total = 0;
		$total += $_ for grep { defined } @$vals;
		my $run = 0;
		for my $v (@$vals) {
			$run += $v if defined $v;
			push @out, ($total && defined $v) ? $run / $total : undef;
		}
		return @out;
	}

	if ($fn eq 'window_sum' || $fn eq 'window_avg') {
		for my $i (0 .. $n - 1) {
			my $lo = $i - $arg + 1;
			$lo = 0 if $lo < 0;
			my @win = grep { defined } @{$vals}[$lo .. $i];
			unless (@win) { push @out, undef; next }
			my $sum = 0;
			$sum += $_ for @win;
			push @out, $fn eq 'window_sum' ? $sum : $sum / scalar @win;
		}
		return @out;
	}

	if ($fn eq 'lag') {
		my $prev;
		for my $v (@$vals) {
			push @out, $prev;
			$prev = $v;
		}
		return @out;
	}

	if ($fn eq 'delta' || $fn eq 'pct_change') {
		my $prev;
		for my $v (@$vals) {
			my $d;
			if (defined $v && defined $prev) {
				$d = $fn eq 'delta' ? $v - $prev : ($prev ? ($v - $prev) / $prev : undef);
			}
			push @out, $d;
			$prev = $v;
		}
		return @out;
	}

	my @nums = grep { defined } @$vals;

	if ($fn eq 'pct_of_total') {
		my $total = 0;
		$total += $_ for @nums;
		for my $v (@$vals) {
			push @out, ($total && defined $v) ? $v / $total : undef;
		}
		return @out;
	}

	if ($fn eq 'rank') {
		# SQL RANK(): ties share a rank and the next rank skips, which counting
		# the values strictly greater gives for free.
		for my $v (@$vals) {
			push @out, defined $v ? 1 + scalar(grep { $_ > $v } @nums) : undef;
		}
		return @out;
	}

	if ($fn eq 'zscore') {
		my ($mean, $sd);
		if (@nums >= 2) {
			$mean = 0;
			$mean += $_ for @nums;
			$mean /= scalar @nums;
			$sd = _stdev_of(\@nums);
		}
		for my $v (@$vals) {
			push @out, (defined $v && defined $sd && $sd > 0) ? ($v - $mean) / $sd : undef;
		}
		return @out;
	}

	croak "Unknown cross-row function '$fn'";	# unreachable: validated above
}

# _cross_row_cmp($x, $y) -> -1 | 0 | 1
#
# The order= comparator: numeric when both cells are numbers, case-sensitive
# string otherwise.  Numbers sort as numbers because an order= on an amount is
# meant to put 100 after 20, and a mixed column still has to be total.
sub _cross_row_cmp {
	my ($x, $y) = @_;
	my ($nx, $ny) = (_numeric_cell($x), _numeric_cell($y));
	return $nx <=> $ny if defined $nx && defined $ny;
	return ($x // '') cmp($y // '');
}

# _trim($text) -> $text
sub _trim {
	my $s = defined $_[0] ? $_[0] : '';
	$s =~ s/\A\s+//;
	$s =~ s/\s+\z//;
	return $s;
}

# _reduce_records($self, $records, $columns, $opts) -> ($records, $columns)
#
# Purpose: The reduce half of every data pipeline, in one place: the request's
#          filters -- the reader's own f= params, then the two bounds of the
#          relative time range -- run over $records in order, with the columns
#          list threaded through so a later stage can add columns and hand back
#          the extended list.  Every route that reads rows and then filters
#          them calls this rather than writing the loop out again, so a stage
#          added here reaches all of them at once.
# Entry:   $records -- arrayref of hashrefs, after the calculated-field pass.
#          $columns -- arrayref of column names, or undef where the caller has
#                      no list in scope; a stage that adds columns needs one,
#                      so undef is only for the filters-only callers.
#          $opts    -- optional hashref.  chips_only => 1 says the caller's rows
#                      have already been reduced and it is here only for the
#                      chip list _apply_filters returns: the stage is skipped
#                      and both arguments come back as they arrived.
#                      no_cross_row => 1 runs the filters only, for a caller
#                      that wants the rows without stage 6 (_apply_filters,
#                      whose callers are after the chip list).
# Exit:    ($records, $columns), reduced -- or untouched, when chips_only is
#          set.  A malformed f= spec leaves the records alone rather than
#          croaking, as _apply_filter_spec always has.
# Notes:   This is stage 5 of the stage order in BI-Phase-7.md section 3, and
#          it is where that document's stages 6 and 7 are meant to land: the
#          cross-row pass and the second calculated-field pass.  Both belong
#          here rather than at a call site, because they have to see *filtered*
#          rows and have to run before pagination (an exported or second page
#          then carries the same numbers as the first).
#
#          Three kinds of row-reading route deliberately do not reduce here,
#          and each is a different case: the canvas builds its own per-card
#          pipeline and runs stage 6 per card, after that card's filters
#          (_canvas_render_context, _render_visual_html), /view's table action
#          filters inside _fetch_page before it paginates, and /api/ask samples
#          rows without filtering them at all.
#
#          chips_only exists for the routes that filter somewhere else and then
#          call _apply_filters for its chip list: /view, the three /open
#          branches and /join reduce inside _fetch_page, before they paginate,
#          and /combine reduces through this function before slicing its page.
#          Re-running the stage on that page would still give the right answer
#          today, because every stage in it is idempotent -- filtering a
#          filtered set changes nothing.  It stops being harmless as soon as a
#          stage is not: a cross-row pass (running totals, differences) or a
#          time-fill that adds rows would double-apply to a page that has
#          already been through it, and would do so only on non-first pages.
#          So the option is not a micro-optimisation; it is what keeps those
#          six call sites correct once such a stage lands here.
#
#          A plain function rather than a method, like _filter_specs and
#          _apply_filter_spec beside it: the tests drive the reduce stage with a
#          controller-shaped mock (build_controller), and only every_param and
#          stash are ever wanted of $self.
sub _reduce_records {
	my ($self, $records, $columns, $opts) = @_;

	# Already reduced: hand the rows and the columns back exactly as they came,
	# ahead of the first stage, so a stage that is not idempotent cannot see
	# these rows a second time.
	return ($records, $columns) if $opts && $opts->{chips_only};

	for my $s (@{ _filter_specs($self) }) {
		$records = _apply_filter_spec($records, $s);
	}

	# d=1 removes duplicate rows after the filters and before the cross-row
	# pass, the order _fetch_page uses for the table view, so a chart of a
	# de-duplicated view counts the rows the table shows.  Only callers with a
	# columns list run the whole stage; the filters-only entry point does not.
	$records = _dedup_records($records, $columns)
		if $columns && _dedup_requested($self);

	# Stage 6: the cross-row pass, and only when the request asks for one.  It
	# has to see filtered rows -- a window is over what the filters left -- and it
	# has to run before anything paginates, which is why the routes that slice
	# their own page call it again (once) inside _fetch_page.
	if (!$opts || !$opts->{no_cross_row}) {
		($records, $columns) = $self->_apply_cross_row($records, $columns)
			if length($self->param('cs') // '');
	}

	return ($records, $columns);
}

# _reduce_or_render($self, \$records, \$columns) -> $ok
#
# Purpose: Run _reduce_records and turn a cross-row spec that cannot be
#          honoured into the 400 it deserves, in the one shape every route
#          already uses for a calculated field that will not compile.
# Entry:   References to the route's own lexicals: on success they are updated
#          in place, so a call site is one line.
# Exit:    True when the records are ready.  False after rendering a 400 -- the
#          caller returns straight away, because nothing has been produced.
# Notes:   A method, unlike _reduce_records itself, because the failure needs
#          a controller to render through.  The error text is the i18n message
#          the pass croaked with, with the "at File line N" tail removed so a
#          reader sees the fault rather than the interpreter's location.
sub _reduce_or_render :Protected ($self, $recs_ref, $cols_ref) {
	my @reduced = eval { _reduce_records($self, $$recs_ref, $$cols_ref) };
	if (@reduced) {
		($$recs_ref, $$cols_ref) = @reduced;
		return 1;
	}

	(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
	$self->render(text => $e, status => 400);
	# Recorded because the callers that answer a missing table with a 404 get
	# their rows back empty here, and the 400 has already been rendered.
	$self->stash('_reduce_error' => 1);
	return 0;
}

# _apply_filters($self, $records, $opts) -> ($filtered_records, \@raw_specs, $json_string)
#
# Purpose: Read all "f=" query params, apply them in order via _apply_filter_spec,
#          and return: the filtered arrayref, the raw spec strings (for building
#          export URLs), and a script-safe JSON string for pre-populating the UI.
# Entry:   $records is an arrayref of hashrefs.  $opts is passed straight to
#          _reduce_records: chips_only => 1 for the routes whose rows are
#          already reduced and which are here only for the chips.
# Exit:    Three-element list; never croaks.  $json_string has '</' escaped to
#          '<\/' so it is safe to embed directly in a <script> block.
#
# Reduction: the original code had two sequential loops over @specs -- one to
# apply filters, one to parse them for JSON.  By Modus Ponens, _apply_filter_spec
# returns $records unchanged for a malformed spec (same guard condition), so
# skipping the call for malformed specs is equivalent.  Merging into one loop
# eliminates a full O(n) pass and the redundant split() on every spec.
sub _apply_filters :Protected ($self, $records, $opts = undef) {
	my @specs  = @{ $self->every_param('f') // [] };
	my @parsed;
	for my $s (@specs) {
		my ($col, $op, $val) = split /:/, $s, 3;
		next unless length($col // '') && defined $op && length $op;
		push @parsed, { col => $col, op => $op, val => $val // '' };
	}

	# The range joins the request's own filters here, but it is not one of them:
	# @specs -- which the page shows as chips, keeps in its panel forms and
	# offers to its filter UI -- stays the reader's own list, so a relative range
	# cannot be submitted as a frozen pair of dates and a reopened link cannot
	# narrow twice.  The application itself is _reduce_records, so this entry
	# point and the routes that call it directly cannot drift apart; the columns
	# list is not in scope here and every caller holds its own, so none is
	# threaded through.  $opts travels with the records for the same reason:
	# a caller that has already reduced asks for the chips alone here, and the
	# seam, not this wrapper, is where that is decided.
	# no_cross_row: this entry point is the chip list, and its callers either
	# skip the stage entirely (chips_only) or want the rows without stage 6.
	($records) = _reduce_records($self, $records, undef, { %{ $opts // {} }, no_cross_row => 1 });

	my $json = encode_json(\@parsed);
	$json =~ s{</}{<\\/}g;
	return ($records, \@specs, $json);
}

# _filter_specs($self) -> \@specs
#
# Purpose: Every filter that applies to this request: the f= params the reader
#          wrote, followed by the two bounds of the relative time range the
#          request names, if any.  This is the list the data pipelines fold over
#          -- charts, pivots, stats, insights and the exports as well as the
#          table view -- so a range narrows all of them through one call site
#          each, and a route that never heard of ranges still honours one.
# Entry:   $self -- the controller; it needs only every_param() and stash().
# Exit:    Returns an arrayref of "col:op:val" strings; possibly empty.
sub _filter_specs {
	my ($self) = @_;
	return [
		@{ $self->every_param('f') // [] },
		@{ $self->stash('range_specs') // [] },
	];
}

# _dedup_requested($self) -> $bool
#
# Purpose: True when the request asks for duplicate rows to be removed (d=1).
#          The SQL aggregate push paths check it too, because the backend
#          would count the duplicates the Perl fold has already dropped.
sub _dedup_requested {
	my ($self) = @_;
	return $self->param('d') ? 1 : 0;
}

# _dedup_records(\@records, \@columns) -> \@unique_records
#
# Purpose: Remove duplicate rows from $records.  Two rows are duplicates when
#          every column value is identical (string comparison, undef treated as '').
#          Preserves the order of first occurrence.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns a new arrayref; the input is not modified.
sub _dedup_records {
	my ($records, $columns) = @_;
	my (%seen, @out);
	for my $row (@$records) {
		my $key = join "\x00", map { $row->{$_} // '' } @$columns;
		push @out, $row unless $seen{$key}++;
	}
	return \@out;
}

# _filter_specs_to_criteria( \@specs, $source ) -> ( \%criteria, \@residual_specs )
#
# Purpose: Map the f= filter vocabulary onto Database::Abstraction / Database::Join
#          criteria hashrefs so the backend can apply pushable filters before
#          paginating.  Specs that cannot be safely pushed are returned as
#          @residual_specs for subsequent in-memory application.
#
# Pushdown is only performed when $source->dbi_source() confirms a SQL (SQLite)
# backend.  For CSV (slurp path), in-memory, XLSX, BerkeleyDB and URL sources
# everything is placed in @residual_specs so the existing _apply_filter_spec
# Perl path handles them.
#
# Pushable mapping (SQLite only):
#   eq / ne         -- LIKE / NOT LIKE without wildcards.  SQLite LIKE is
#                      case-insensitive for ASCII, matching the existing Perl
#                      lc() semantics.  Values containing % or _ are pushed to
#                      residual to avoid LIKE metacharacter conflicts.
#   contains        -- LIKE '%val%'.  Residual when value contains % or _.
#   starts          -- LIKE 'val%'.   Residual when value contains % or _.
#   lt / le / gt / ge -- SQL numeric comparison.  Residual when the value is
#                      not a plain number (avoids column-affinity surprises
#                      with currency or comma-formatted values).
#   empty / notempty -- Always residual.  Must match both SQL NULL and the
#                      literal empty string; cannot be expressed as a single
#                      D::A criterion without an -or grouping.
#
# Column collision: if a column already has a pushable criterion, the second
# spec for that column is placed in @residual_specs.  This keeps the AND logic
# simple and safe; callers with multiple conditions on one column (e.g. a range)
# still get correct results via the in-memory fallback.
sub _filter_specs_to_criteria {
	my ($specs, $source) = @_;

	# Only push when the source has a live SQL (SQLite) backend.
	my $is_sql = $source
		&& $source->can('dbi_source')
		&& $source->dbi_source();
	return ({}, [@$specs]) unless $is_sql;

	require Scalar::Util;
	my (%criteria, @residual);

	for my $spec (@$specs) {
		my ($col, $op, $val) = split /:/, $spec, 3;
		next unless length($col // '') && defined $op && length $op;
		$val //= '';

		# A second spec on the same column goes to residual.
		if (exists $criteria{$col}) {
			push @residual, $spec;
			next;
		}

		if ($op eq 'eq' || $op eq 'ne') {
			if ($val =~ /[%_]/) {
				push @residual, $spec;
			} else {
				$criteria{$col} = ($op eq 'eq')
					? { -like     => $val }
					: { -not_like => $val };
			}
		} elsif ($op eq 'contains') {
			if ($val =~ /[%_]/) {
				push @residual, $spec;
			} else {
				$criteria{$col} = { -like => "%${val}%" };
			}
		} elsif ($op eq 'starts') {
			if ($val =~ /[%_]/) {
				push @residual, $spec;
			} else {
				$criteria{$col} = { -like => "${val}%" };
			}
		} elsif ($op eq 'lt') {
			Scalar::Util::looks_like_number($val)
				? ($criteria{$col} = { '<'  => $val })
				: push @residual, $spec;
		} elsif ($op eq 'le') {
			Scalar::Util::looks_like_number($val)
				? ($criteria{$col} = { '<=' => $val })
				: push @residual, $spec;
		} elsif ($op eq 'gt') {
			Scalar::Util::looks_like_number($val)
				? ($criteria{$col} = { '>'  => $val })
				: push @residual, $spec;
		} elsif ($op eq 'ge') {
			Scalar::Util::looks_like_number($val)
				? ($criteria{$col} = { '>=' => $val })
				: push @residual, $spec;
		} else {
			# empty, notempty, between, unknown operator: always residual.
			push @residual, $spec;
		}
	}

	return (\%criteria, \@residual);
}

# _measure($fn, $col, $as) -> \%measure
#
# Build one measure descriptor in the vocabulary shared by Database::Abstraction
# and Database::Join (sum|avg|min|max|count|count_distinct).  $col is the
# source column name, or undef for COUNT(*).  $as is the result-row key.
# The returned hashref is consumed directly by aggregate(measures => [...]).
sub _measure {
	my ($fn, $col, $as) = @_;
	return { fn => $fn, (defined $col ? (col => $col) : ()), as => $as };
}

# _numeric_cell($v) -> $number | undef
#
# Extract a numeric value from a raw cell, handling currency prefixes
# (e.g. $1,234.56) and accounting-notation negatives ((1,234.56) -> -1234.56).
# Returns undef for empty, undef, or non-numeric input.
# Used by the Perl fold path of _grouped_totals so all four chart routes
# share one extraction function.
sub _numeric_cell {
	my $v = shift;
	return undef unless defined $v && length($v);
	my $is_acct_neg = ($v =~ /\A\s*\(/);
	(my $n = $v) =~ s/[^\d.-]//g;
	$n = "-$n" if $is_acct_neg && $n =~ /\A\d/;
	return undef unless $n =~ /\A-?\d+(?:\.\d+)?\z/;
	return $n + 0;
}

# _percentile_of(\@sorted, $level) -> $number | undef
#
# The value at the given percentile of an already sorted list of numbers, by
# linear interpolation between closest ranks (R's type 7, Excel's
# PERCENTILE.INC).  $level is 1..100.  The empty list has no percentile, so it
# returns undef rather than a made-up 0.
#
# At level 50 this is the median the column-stats view has always shown: the
# middle value when the count is odd, the mean of the two middle values when it
# is even.  That is the point of it, and the reason median is defined in terms
# of it below -- one arithmetic, so a p50 measure, a median measure and the
# median column of the stats page cannot disagree.
sub _percentile_of {
	my ($sorted, $level) = @_;
	my $n = scalar @$sorted;
	return undef unless $n;
	my $h  = ($n - 1) * $level / 100;
	my $lo = int $h;
	return $sorted->[$lo] if $h == $lo || $lo >= $n - 1;
	return $sorted->[$lo] + ($h - $lo) * ($sorted->[ $lo + 1 ] - $sorted->[$lo]);
}

# _median_of(\@sorted) -> $number | undef
sub _median_of {
	return _percentile_of($_[0], 50);
}

# _stdev_of(\@nums) -> $number | undef
#
# Sample standard deviation, the n-1 denominator: what Splunk's stdev() and
# Excel's STDEV.S report.  One value has no spread to measure, so fewer than
# two values give undef rather than a reassuring 0.
sub _stdev_of {
	my $nums = shift;
	my $n = scalar @$nums;
	return undef unless $n >= 2;
	my $mean = 0;
	$mean += $_ for @$nums;
	$mean /= $n;
	my $sum_sq = 0;
	$sum_sq += ($_ - $mean) ** 2 for @$nums;
	return sqrt($sum_sq / ($n - 1));
}

# _range_of(\@sorted) -> $number | undef
#
# Largest minus smallest, on the already sorted list: the spread a reader means
# by "range", which is not min/max in the sense the SQL backend could push.
sub _range_of {
	my $sorted = shift;
	return undef unless @$sorted;
	return $sorted->[-1] - $sorted->[0];
}

# _measure_value($fn, \@sorted_values) -> $number | undef
#
# The function from @PERL_MEASURE_FNS (or a percentile) applied to the sorted
# values of one group.  It takes the values rather than a group key so that the
# caller decides what a group is: the pivot's fold has one list per group, and
# the stats page measures a whole column with the same four functions.
sub _measure_value {
	my ($fn, $sorted) = @_;
	my $level = _measure_percentile($fn);
	return _percentile_of($sorted, $level) if defined $level;
	return _median_of($sorted)             if $fn eq 'median';
	return _stdev_of($sorted)              if $fn eq 'stdev';
	return _range_of($sorted)              if $fn eq 'range';
	return undef;
}

# _column_is_numeric($records, $col) -> bool
#
# Says whether a column can be used as a chart measure.  It samples the first
# non-empty cells rather than the whole table: the canvas needs a quick answer
# for the column picker, and a column with a non-numeric value in its first 20
# rows is not a safe measure anyway.
sub _column_is_numeric {
	my ($records, $col) = @_;
	my $seen = 0;
	for my $row (@{ $records // [] }) {
		my $v = $row->{$col};
		next unless defined $v && length $v;
		return 0 unless defined _numeric_cell($v);
		last if ++$seen >= 20;
	}
	return $seen ? 1 : 0;
}

# _measure_pushable($source, $fn, $col, \@records) -> bool
#
# Returns true when the measure can be computed by aggregate() on $source and
# the result will be identical to the Perl fold.  False means use the Perl fold.
#
# Decision table:
#   Not in the pushed vocabulary -- never pushable.  None of median, a
#                             percentile, stdev, first, last or range is a sum
#                             of its parts, and the backend would either refuse
#                             the spec or quietly answer with its own idea of
#                             the statistic (it has one for median and stddev).
#   count / count_distinct -- always pushable (no numeric coercion).
#   sum / avg / min / max  -- only when every sampled value in $col is either
#                             a plain number (looks_like_number) or empty/undef.
#                             Currency symbols or accounting parentheses in any
#                             value force the Perl fold, which strips them
#                             correctly; SQLite CAST would coerce them to 0.
#   Missing $source        -- never pushable.
#   Missing $col           -- sum/avg/min/max are not pushable without a column.
sub _measure_pushable {
	my ($source, $fn, $col, $records) = @_;
	return 0 unless $source && $source->can('aggregate');
	return 0 unless defined $fn && $PUSHED_MEASURE_FN_OK{$fn};
	return 1 if $fn eq 'count' || $fn eq 'count_distinct';
	return 0 unless defined $col;
	# For sum/avg/min/max, only push when at least one value is a plain number
	# and every non-null/non-blank value passes looks_like_number.
	#
	# Two cases where both paths must agree:
	#   - All values undef/blank: Perl fold produces no rows; SQL SUM(NULL)
	#     produces NULL, normalised to 0 by D::A -> discrepancy.  Return 0 so
	#     the Perl fold runs and yields the expected "No plottable data" result.
	#   - Currency/accounting notation (e.g. ($1,234)): _numeric_cell strips
	#     these correctly; SQL sees non-numeric text -> SUM = NULL -> 0.  Return 0
	#     so _numeric_cell is used on every value.
	require Scalar::Util;
	my $found = 0;
	for my $row (@{ $records // [] }) {
		my $v = $row->{$col};
		next unless defined $v && length($v);   # undef/blank: same effect as NULL
		return 0 unless Scalar::Util::looks_like_number($v);
		$found = 1;
	}
	return $found;    # 0 (false) when every sampled value was undef or blank
}

# _parse_measure_param($spec_str) -> \%measure | undef
#
# Parse 'col:fn:as' into { col => ..., fn => ..., as => ... }.
# Shared dialect for /pivot so it does not invent a second format.
# $fn is lower-cased first, so SUM and P90 are the same measures as sum and
# p90.  Returns undef for an invalid or unrecognised spec.
sub _parse_measure_param {
	my $str = shift;
	return undef unless defined $str && length($str);
	my ($col, $fn, $as) = split /:/, $str, 3;
	return undef unless defined $fn && defined $as && length($fn) && length($as);
	$fn = lc $fn;
	return undef unless _measure_fn_ok($fn);
	return { col => $col, fn => $fn, as => $as };
}

# _grouped_totals($self, \%pipeline, \%spec) -> \@rows
#
# Single GROUP BY entry point for all four chart routes.  Returns an arrayref
# of hashrefs, each containing the 'by' column values and the aggregate result
# under $spec->{as}.
#
# $pipeline = { source => $src_or_undef, records => \@rows }
#   source  -- a DataSource or Database::Join for the push path; undef when
#              the pipeline is a /combine union (must fold in Perl).
#   records -- the already-fetched rows (pre-filtered by the caller).
#
# $spec = { by => [...], fn => ..., val => ..., as => ..., [sort_by, having, limit, offset] }
#
# Dispatch:
#   Push path  -- $source is defined, measure is pushable (checked by
#                 _measure_pushable), and either no active f= filters or all
#                 active filters are SQL-pushable (via _filter_specs_to_criteria).
#                 Calls $source->aggregate() with pushable criteria when present.
#   Perl fold  -- Iterates $pipeline->{records} (pre-filtered by the caller)
#                 when the push path is unavailable (combine union, non-SQL
#                 source, non-pushable measure, or residual filters that cannot
#                 be expressed as SQL criteria).
#
# $ENV{BI_FORCE_PERL_AGG}: set to a true value in tests to force the Perl fold
# regardless of source type, enabling cross-backend equivalence assertions.
sub _grouped_totals :Protected ($self, $pipeline, $spec) {
	my $source  = $pipeline->{source};
	my $records = $pipeline->{records} // [];
	my $by      = $spec->{by}  // [];
	my $fn      = lc($spec->{fn}  // 'count');
	my $val_col = $spec->{val};
	my $as      = $spec->{as}  // 'value';

	# Push path: use backend aggregate() when safe.
	# When f= filters are active, _filter_specs_to_criteria translates as many
	# specs as possible to SQL criteria.  The push path is used only when ALL
	# specs are SQL-pushable (no residual); otherwise the Perl fold handles the
	# pre-filtered records the caller already passed in.
	my @f_specs    = grep { /\S/ } @{ _filter_specs($self) };
	my $has_filter = !!@f_specs;

	# SQL::Statement 1.414 (the SQL engine under DBD::CSV) uses
	# "use warnings FATAL => 'all'" and calls join("\0", @row[@keycols])
	# inside getAffectedResult without guarding against undef.  When a GROUP BY
	# column contains blank CSV cells (empty_is_undef => 1 converts them to
	# undef), the join triggers a fatal "uninitialized value" exception and the
	# execute() call dies.  The correct fix is to use
	#   map { $_ // '' } @row[@keycols]
	# in SQL::Statement::getAffectedResult, but the module has been unmaintained
	# since 2020 (21 open RT tickets as of 2026-10).
	# See: https://rt.cpan.org/Ticket/Display.html?id=181946
	# Skip the push path whenever any 'by' column has a blank or undef value so
	# DBD::CSV/SQL::Statement is never asked to GROUP BY a null key.
	# TODO: remove this guard once SQL-Statement RT#181946 is fixed (last checked: 1.414).
	my $has_null_by_key = @$by && do {
		my $found;
		KEY_SCAN: for my $row (@$records) {
			for my $col (@$by) {
				my $v = $row->{$col};
				if (!defined($v) || !length($v)) { $found = 1; last KEY_SCAN; }
			}
		}
		$found;
	};

	# When filters are active, translate them to SQL criteria for the push path.
	# If any spec has no SQL equivalent (@residual is non-empty), the push path
	# is skipped and the Perl fold uses the already-filtered $records.
	my ($push_crit, $push_residual) = ($has_filter && $source)
		? _filter_specs_to_criteria(\@f_specs, $source)
		: ({}, []);
	my $can_push_filters = !$has_filter || (!@$push_residual && %$push_crit);

	# Skip the push path when any 'by' or 'val' column is virtual (added by
	# _apply_calc_fields or named-group loader).  Virtual columns do not exist in
	# the backend and would cause a "No such column" SQL error before the fold fallback.
	my $virt        = $self->stash('_virtual_columns') // {};
	my $has_virtual = grep { $virt->{$_} }
		(@$by, (defined $val_col ? $val_col : ()));

	unless ($ENV{BI_FORCE_PERL_AGG} || _dedup_requested($self) || $has_virtual || !$can_push_filters || $has_null_by_key || !$source
		|| !_measure_pushable($source, $fn, $val_col, $records)) {
		my $m = _measure($fn, $val_col, $as);
		my $agg_rows = eval {
			$source->aggregate(
				by       => $by,
				measures => [$m],
				($has_filter && %$push_crit ? (%$push_crit) : ()),
				($spec->{sort_by} ? (sort_by => $spec->{sort_by}) : ()),
				($spec->{having}  ? (having  => $spec->{having})  : ()),
				($spec->{limit}   ? (limit   => $spec->{limit})   : ()),
				($spec->{offset}  ? (offset  => $spec->{offset})  : ()),
			)
		};
		unless ($@) {
			return $agg_rows // [];
		}
		$self->app->log->debug("aggregate() push failed: $@; falling back to Perl fold");
	}

	# Perl fold over pre-filtered records.
	#
	# The fold keeps a running total for the functions that are sums of their
	# parts (sum, avg, min, max) and the values themselves for the ones that are
	# not (median, a percentile, stdev, range), which are resolved once the group
	# is complete.  first and last are order-dependent, so they are taken as the
	# rows arrive and need no list at all.
	my (%seen_warned, %seen_key, @key_order);
	my (%totals, %count_map, %distinct_vals, %values);

	for my $row (@$records) {
		# Skip rows where any 'by' column is empty/undef (mirrors SQL GROUP BY NULL exclusion).
		# Note: calc field columns store '(unparseable)' (not undef) for failed expressions,
		# so those rows pass this guard and appear in the (unparseable) group instead.
		my @key_parts = map { $row->{$_} // '' } @$by;
		next if @$by && grep { !length($_) } @key_parts;
		my $key = join("\x00", @key_parts);

		if ($fn eq 'count') {
			push @key_order, $key unless $seen_key{$key}++;
			$totals{$key}++;
		} elsif ($fn eq 'count_distinct') {
			push @key_order, $key unless $seen_key{$key}++;
			my $dv = defined $val_col ? ($row->{$val_col} // '') : '';
			$distinct_vals{$key}{$dv}++;
		} elsif ($fn eq 'first' || $fn eq 'last') {
			# first/last read any column, not only a numeric one, and they
			# report the value as it appears: the number a cell holds when it
			# holds a number, the text it holds otherwise.  A blank cell is
			# not a value, so it is passed over -- the first row that has
			# something in the column is the first value.
			my $v = defined $val_col ? $row->{$val_col} : undef;
			next unless defined $v && length $v;
			push @key_order, $key unless $seen_key{$key}++;
			$totals{$key} = $v if $fn eq 'last' || !exists $totals{$key};
		} else {
			my $v = defined $val_col ? ($row->{$val_col} // '') : '';
			my $n = _numeric_cell($v);
			unless (defined $n) {
				unless ($seen_warned{"$fn\x01" . ($val_col // '')}++) {
					carp $self->_i18n('warn_measure_fallback', $fn, $val_col // '(none)');
				}
				next;	# skip: do NOT add key to order for non-numeric rows
			}
			push @key_order, $key unless $seen_key{$key}++;
			if    ($fn eq 'sum') { $totals{$key}  += $n                                                             }
			elsif ($fn eq 'avg') { $totals{$key}  += $n; $count_map{$key}++                                        }
			elsif ($fn eq 'min') { $totals{$key}   = (!exists $totals{$key} || $n < $totals{$key}) ? $n : $totals{$key} }
			elsif ($fn eq 'max') { $totals{$key}   = (!exists $totals{$key} || $n > $totals{$key}) ? $n : $totals{$key} }
			else                 { push @{ $values{$key} }, $n                                                       }
		}
	}

	if ($fn eq 'avg') {
		for my $k (keys %totals) {
			$totals{$k} = $count_map{$k} ? $totals{$k} / $count_map{$k} : undef;
		}
	} elsif ($fn eq 'count_distinct') {
		for my $k (@key_order) {
			$totals{$k} = scalar keys %{ $distinct_vals{$k} // {} };
		}
	} elsif (%values) {
		# median / p<N> / stdev / range: resolved from the group's values, and
		# through the same arithmetic the stats view uses for a whole column.
		for my $k (keys %values) {
			my @sorted = sort { $a <=> $b } @{ $values{$k} };
			$totals{$k} = _measure_value($fn, \@sorted);
		}
	}

	# Assemble result rows in ascending key order (matching the SQL push path)
	# unless the caller requested an explicit sort.
	unless ($spec->{sort_by}) {
		@key_order = sort @key_order;
	}
	my @result;
	for my $key (@key_order) {
		my @parts = @$by ? (split /\x00/, $key, scalar @$by) : ();
		my %row;
		for my $i (0 .. $#$by) {
			$row{$by->[$i]} = $parts[$i];
		}
		$row{$as} = $totals{$key} // ($fn =~ /\A(?:sum|count|count_distinct)\z/ ? 0 : undef);
		push @result, \%row;
	}

	return \@result;
}

# _fetch_page( $self, $source, \%params ) -> ( $records, $has_next )
#   params: per_page  -- page size (required)
#           offset    -- 0-based row offset (required)
#           dedup     -- truthy when ?d=1 dedup is requested
#           sort_col  -- column name to sort by (optional)
#           sort_dir  -- 'asc' or 'desc' (default 'asc'; ignored unless sort_col set)
#
# Purpose: Fetch and reduce one page of records from $source, honouring the
#          reduce-before-paginate ordering contract.  Two modes:
#
#   Fast path (no f= filters, no dedup): uses the N+1 trick
#     selectall_arrayref(limit => per_page+1, offset => offset).  has_next is
#     determined by the extra row before it is popped.
#
#   Reduction path (f= filters or dedup present): materialises the full result
#     in memory, applies all f= filters with _apply_filter_spec (case-insensitive),
#     applies dedup if requested, then paginates in Perl.  This guarantees that
#     the Nth page contains the Nth page of the *reduced* set, not the Nth page
#     of the raw set reduced to fewer rows.  Memory cost: the full reduced set.
#
# Sort: sort_col/sort_dir are forwarded to selectall_arrayref as
#   sort_by => [$sort_col, $sort_dir].  Both Database::Abstraction 0.49+
#   and Database::Join 0.009.0 honour this parameter natively.
#
# Returns (undef, 0) when the underlying fetch throws; the caller must handle
# $records being undef.
sub _fetch_page :Protected ($self, $source, $params) {
	my $per_page = $params->{per_page};
	my $offset   = $params->{offset};
	my $dedup    = $params->{dedup};
	my $sort_col = $params->{sort_col};
	my $sort_dir = ($params->{sort_dir} // 'asc') =~ /\Adesc\z/i ? 'desc' : 'asc';

	# sort_by args forwarded to the backend when a sort column is requested.
	# D::A 0.49+ and D::J 0.009.0 both support sort_by => [$col, $dir].
	my @sort_args = $sort_col ? (sort_by => [$sort_col, $sort_dir]) : ();

	# Collect and validate the filters, the range's bounds included.
	my @f_specs = grep {
		my ($c, $o) = split /:/, $_, 3;
		length($c // '') && defined $o && length $o;
	} @{ _filter_specs($self) };

	# Determine whether the source has a SQL backend that supports LIMIT/OFFSET.
	# DBD::CSV / SQL::Statement do not implement LIMIT/OFFSET; passing them emits
	# a "Bad limit clause" error at the D::A layer before falling back to a Perl
	# approach.  Avoid the noise by only using the N+1 fast path for SQL-backed
	# sources.  For non-SQL sources (CSV, XLSX, in-memory) the reduction path
	# below materialises the full set and paginates in Perl.
	my $is_sql = $source->can('dbi_source') && $source->dbi_source;

	# A cross-row column is a column of the whole filtered set, so a request that
	# names one cannot take the N+1 fast path: it would see one page of rows and
	# restart every running total on page 2.
	my $cross = length($self->param('cs') // '') ? 1 : 0;

	unless (@f_specs || $dedup || $cross) {
		if ($is_sql) {
			# Fast path (SQL-backed): delegate LIMIT/OFFSET to the backend N+1 trick.
			# Copy before pop: D::A may return a read-only ref to its internal cache.
			my @records = @{ $source->selectall_arrayref(
				limit => $per_page + 1, offset => $offset, @sort_args,
			) // [] };
			my $has_next = (@records > $per_page) ? 1 : 0;
			pop @records if $has_next;
			return (\@records, $has_next);
		}
		# Non-SQL fast path: fetch all, sort in Perl, then paginate.
		my $all = $source->selectall_arrayref(@sort_args) // [];
		my $has_next = (@$all > $offset + $per_page) ? 1 : 0;
		my @page = splice(@$all, $offset, $per_page);
		return (\@page, $has_next);
	}

	# Always fetch all rows in Perl and filter with _apply_filter_spec.
	# SQL criteria pushdown (passing %criteria to selectall_arrayref) is
	# intentionally avoided: on some Perl/D::A version combinations the WHERE
	# clause is silently dropped, returning the full unfiltered set.  The Perl
	# path is correct on every supported version.  Memory cost: bounded by the
	# source file size (the same as the dedup path already accepted).
	my $all = $source->selectall_arrayref(@sort_args) // [];

	# A stored date or time pattern is what makes a patterned column comparable
	# with the ISO bounds a relative time range carries, and it belongs to stage 2
	# of the pipeline -- before the filters of stage 5.  The rest of the
	# application reaches the filters through that order already; this path, which
	# filters before it paginates, is the one call site that would otherwise
	# compare the reader's format, so it normalises first, on exactly the rows the
	# specs are about to be applied to.
	$self->_apply_date_normalization($all, [_get_columns($source, $all)],
		$self->_calc_spec_key);

	$all = _apply_filter_spec($all, $_) for @f_specs;

	if ($dedup) {
		my $cols = $source->columns;
		my @dcols = $cols ? @$cols : (keys %{ $all->[0] // {} });
		$all = _dedup_records($all, \@dcols);
	}

	# Stage 6, and before the slice: a running total has to see every filtered
	# row, or page 2 would start again from zero.  A spec that cannot be honoured
	# renders its 400 here; the caller returns rather than drawing a page over it.
	if ($cross) {
		my $cols  = $source->columns;
		my @xcols = $cols ? @$cols : (sort keys %{ $all->[0] // {} });
		my ($crossed) = eval { $self->_apply_cross_row($all, \@xcols) };
		if ($@) {
			(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
			$self->render(text => $e, status => 400);
			$self->stash('_cross_row_error' => $e);
			return ();
		}
		$all = $crossed;
	}

	my $total    = scalar @$all;
	my $has_next = ($total > $offset + $per_page) ? 1 : 0;
	my @page     = splice(@$all, $offset, $per_page);

	return (\@page, $has_next);
}

# _combine_tables(\@sources) -> (\@merged_records, \@merged_columns)
#
# Purpose: Perform a vertical stack (UNION ALL equivalent) of two or more
#          record sets.  The merged column list is the union of all source
#          column lists: the first source's columns appear first (in their
#          original order), then each subsequent source contributes any new
#          column names it introduces, in order.  Where a source does not
#          have a particular column, its rows receive an empty string for
#          that column.
# Entry:   $sources is an arrayref of [$records_aref, $columns_aref] pairs.
#          At least one element is required; a single-element call returns
#          that element's data unchanged (no allocation beyond the column copy).
# Exit:    Returns (\@merged_records, \@merged_columns).
# Side Effects: None; allocates new record hashrefs (original rows are not mutated).
sub _combine_tables {
	my ($sources) = @_;

	# Build the unified column order: first source's columns first, then any
	# new columns introduced by each subsequent source in their file order.
	my (@all_cols, %seen);
	for my $src (@$sources) {
		for my $col (@{ $src->[1] }) {
			push @all_cols, $col unless $seen{$col}++;
		}
	}

	my @merged;
	for my $src (@$sources) {
		my ($recs, $cols) = @$src;
		my %has_col = map { $_ => 1 } @$cols;
		for my $row (@$recs) {
			my %new_row;
			$new_row{$_} = $has_col{$_} ? ($row->{$_} // '') : ''
				for @all_cols;
			push @merged, \%new_row;
		}
	}

	return (\@merged, \@all_cols);
}

# _csv_row(@fields) -> $csv_line_with_crlf
#
# Purpose: Format one row as an RFC 4180 CSV line.  Fields containing commas,
#          double-quotes, or newlines are enclosed in double-quotes; embedded
#          double-quotes are doubled.  The line ends with CRLF.
# Entry:   @fields may contain undef (treated as empty string).
# Exit:    Returns a string ending with "\r\n".
sub _csv_row {
	return join(',', map {
		my $f = $_ // '';
		$f =~ /[,"\r\n]/ ? do { (my $q = $f) =~ s/"/""/g; qq{"$q"} } : $f;
	} @_) . "\r\n";
}

# _build_export_url($self, $left_spec, \@join_specs, \@filter_specs) -> $url_string
#
# Purpose: Assemble a /export?l=...&j=...&f=... URL string for the current
#          logical view.  The caller must apply | html in TT to escape & as &amp;.
# Entry:   All args non-undef; spec arrays may be empty.
# Exit:    Returns a relative URL string beginning with '/export'.
sub _build_export_url :Protected ($self, $left_spec, $join_specs, $filter_specs, $combine_specs = undef, $dedup = 0, $extra = undef) {
	my $u = '/export?l=' . url_escape($left_spec);
	$u .= '&j=' . url_escape($_) for @$join_specs;
	$u .= '&c=' . url_escape($_) for @{ $combine_specs // [] };
	$u .= '&f=' . url_escape($_) for @$filter_specs;
	$u .= '&d=1' if $dedup;
	# Parameters that shape the columns rather than the rows travel with the
	# export, so the file holds the column the page shows -- a time bucket, for
	# one -- and not the raw values behind it.
	for my $key (sort keys %{ $extra // {} }) {
		my $val = $extra->{$key};
		next unless defined $val && length $val;
		$u .= "&$key=" . url_escape($val);
	}
	return $u;
}

# _list_dir($self, $dir, $want_files) -> { dirs => [...], files => [...] }
#
# Purpose: Shared directory-listing kernel used by browse (which needs files)
#          and dirs_api (which needs only subdirectories).  Hidden entries
#          (names starting with ".") are excluded.  Entries are sorted
#          case-insensitively.
# Entry:   $dir is a Mojo::File pointing to an existing readable directory.
#          $want_files: if true, populate 'files' with entries matching $EXT_RE.
# Exit:    Returns a hashref with 'dirs' and 'files' arrayrefs (files is always
#          present but empty when $want_files is false).
# Side Effects: Filesystem directory read.
sub _list_dir :Protected ($self, $dir, $want_files) {
	my (@dirs, @files);
	if (opendir my $dh, $dir->to_string) {
		while (my $entry = readdir $dh) {
			next if $entry eq '.' || $entry eq '..' || $entry =~ /\A\./;
			my $f = $dir->child($entry);
			if (-d $f) {
				push @dirs,  { name => $entry, path => $f->to_string };
			}
			elsif ($want_files && $entry =~ $EXT_RE) {
				push @files, { name => $entry, path => $f->to_string };
			}
		}
		closedir $dh;
	}
	return {
		dirs  => [ sort { lc($a->{name}) cmp lc($b->{name}) } @dirs  ],
		files => [ sort { lc($a->{name}) cmp lc($b->{name}) } @files ],
	};
}

# _write_sqlite_db($self, $records, $columns) -> $raw_bytes
#
# Purpose: Write $records to an in-process SQLite database (single table named
#          "data"; every column declared TEXT) and return the raw file bytes.
#          The temporary file is created, written, read, and then unlinked in
#          one synchronous sequence.  Used by both _render_sqlite (HTTP download)
#          and export_write (filesystem write) to eliminate code duplication.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns scalar binary string.  Croaks on any DBI error.
# Side Effects: Creates and unlinks one temporary file under system tmpdir.
sub _write_sqlite_db :Protected ($self, $records, $columns) {
	# D~ fix: an empty column list produces "CREATE TABLE data ()" which is
	# invalid SQLite syntax.  Croak before touching the filesystem.
	croak 'Cannot export SQLite: result set has no columns'
		unless @$columns;

	require DBI;
	my ($tmp_fh, $tmpfile) = tempfile(SUFFIX => '.db', UNLINK => 0);
	close $tmp_fh;

	my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$tmpfile", '', '', {
		RaiseError => 1, AutoCommit => 1,
	}) };
	# Guard both the eval-caught die ($@) and the undef-without-die edge case.
	if ($@ || !$dbh) {
		unlink $tmpfile;
		croak "DBI connect failed: $@";
	}

	# O~ fix: wrap all DBI work in eval so any mid-flight exception still
	# triggers cleanup (disconnect + unlink) before the error propagates.
	eval {
		my @quoted = map { (my $c = $_) =~ s/"/""/g; qq{"$c"} } @$columns;
		$dbh->do('CREATE TABLE "data" (' . join(', ', map { "$_ TEXT" } @quoted) . ')');
		if (@$records) {
			my $ph  = join(', ', ('?') x scalar @$columns);
			my $sth = $dbh->prepare(
				'INSERT INTO "data" (' . join(', ', @quoted) . ") VALUES ($ph)"
			);
			for my $row (@$records) {
				$sth->execute(map { $row->{$_} } @$columns);
			}
		}
		$dbh->disconnect;
	};
	if (my $err = $@) {
		eval { $dbh->disconnect };	# best-effort; may already be disconnected
		unlink $tmpfile;
		croak $err;
	}

	my $data = Mojo::File->new($tmpfile)->slurp;
	unlink $tmpfile;
	return $data;
}

# _run_pipeline_source($self) -> ($src, $records, \@columns, $left_label) or ()
#
# Purpose: Inner pipeline: opens the left spec, builds the join chain, fetches
#          all rows, and runs any c= combine step.  Does NOT apply f= filters,
#          dedup, or pagination -- that is the caller's responsibility.
#          Chart routes call this directly so they can access $src for the
#          aggregate() push path.  Row-viewing routes and export routes
#          call the thin _run_export_pipeline wrapper instead.
# Exit:    On success: ($src_or_undef, $records_aref, $columns_aref, $label).
#          $src is undef when a c= combine makes the result non-aggregatable.
#          On failure: empty list (left table not found / fetch error).
sub _run_pipeline_source :Protected ($self) {
	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return () unless $left_src;

	# Build the join chain lazily.
	my $max_rows  = $self->app->config('join_max_rows') // $DEFAULT_JOIN_MAX_ROWS;
	my $join_type = $self->param('jtype') // 'left';
	$join_type    = 'left' unless $join_type =~ /\A(?:left|inner|outer)\z/;
	my $src = $left_src;
	my (@schema_warnings, @joined, @combined);
	for my $jspec (@{ $self->every_param('j') }) {
		my ($right_spec, $left_key, $right_key) = split /\|/, $jspec, 3;
		next unless defined $right_spec && defined $left_key && defined $right_key;

		my $cur_cols = $src->columns;
		next unless $cur_cols;
		next unless +{ map { $_ => 1 } @$cur_cols }->{$left_key};

		my ($right_src, $right_label) = $self->_open_spec($right_spec);
		next unless $right_src;

		my $right_cols = $right_src->columns;
		next unless $right_cols;
		next unless +{ map { $_ => 1 } @$right_cols }->{$right_key};

		# Types are compared while the two sides are still separate sources;
		# after the join is built the mismatched columns are already published
		# under different names.  See _schema_type_warnings.
		push @schema_warnings, $self->_schema_type_warnings(
			$src, $right_src, $left_label, $right_label, $left_key, $right_key);

		require Database::Join;
		local $SIG{__WARN__} = sub { push @schema_warnings, $_[0] };
		$src = Database::Join->new(
			databases        => [$src, $right_src],
			join_column      => $left_key,
			backend          => 'auto',
			max_array_rows   => $max_rows,
			join_type        => $join_type,
			($left_key ne $right_key ? (join_map         => {1 => $right_key})   : ()),
			($right_label             ? (collision_prefix => {1 => $right_label}) : ()),
		);
		push @joined, { label => $right_label, left_key => $left_key, right_key => $right_key };
	}

	$self->stash(schema_warnings => \@schema_warnings) if @schema_warnings;

	my $records = eval { $src->selectall_arrayref };
	return () if $@;
	$records //= [];
	my @columns = _get_columns($src, $records);

	# Combine (vertical stack): sets $src = undef since the result is a union
	# with no single aggregatable object.
	my @cspecs = @{ $self->every_param('c') // [] };
	if (@cspecs) {
		my @sources = ([$records, \@columns]);
		for my $cspec (@cspecs) {
			my ($csrc, $clabel) = $self->_open_spec($cspec);
			next unless $csrc;
			my $crecs = eval { $csrc->fetch_all } // [];
			next if $@;
			my @ccols = _get_columns($csrc, $crecs);
			push @sources,  [$crecs, \@ccols];
			push @combined, { label => $clabel };
		}
		if (@sources > 1) {
			($records, my $new_cols) = _combine_tables(\@sources);
			@columns = @$new_cols;
			$src = undef;	# union: no single aggregatable source
		}
	}

	# What was actually joined and stacked, for the page that shows the rows.
	$self->stash(pipeline_joined => \@joined, pipeline_combined => \@combined);

	return ($src, $records, \@columns, $left_label);
}

# _calc_spec_key($self) -> $spec
#
# Purpose: The key the stored calc fields, groups and date patterns are filed
#          under for this request: the l= spec, or the table a /view route is
#          addressed by, which names its spec explicitly because it has no l=.
sub _calc_spec_key :Protected ($self) {
	my $l = $self->param('l') // '';
	return $l if length $l;
	my $table = $self->stash('table');
	return (defined $table && $table =~ /$TABLE_NAME_RE/) ? "table:$table" : '';
}

# _span_calc_spec($self, \@columns, @dimension_params) -> \%span | undef
#
# Purpose: Turn span=/tcol=/as= into the c= calculated field a reader could have
#          typed, so bucketing a dimension is one code path with one set of
#          semantics (Calc.pm's span()) rather than a second pipeline of its
#          own, and so a bucket works on every route at once.
# Entry:   \@columns -- the source's columns, so the column to bucket and the
#                       name of the bucket are both checked before anything is
#                       evaluated.
#          @dimension_params -- the params that name this route's dimension
#                       (cat, x, rows, ...), in the order they should be tried.
# Exit:    undef when the request says nothing about bucketing.  Otherwise
#          { calc => [ '<col>_span:span(<col>,<interval>)' ],
#            src  => <column to bucket>, col => '<bucket column>' },
#          or { error => <message> } for a request that cannot be honoured,
#          which the caller renders as a 400 rather than drawing a chart of
#          something the reader did not ask for.
# Notes:   An ambiguous dimension is refused, not guessed: with rows=at,region
#          only tcol= knows which column the reader meant, and bucketing the
#          wrong one silently is worse than an error that says so.  A name that
#          is already a column, or already a calculated field, is refused too,
#          because two definitions of one name is the bug that rule prevents.
sub _span_calc_spec :Protected ($self, $columns, @dimension_params) {
	my $interval = $self->param('span') // '';
	my $tcol     = $self->param('tcol') // '';
	my $as       = $self->param('as')   // '';
	return undef unless length($interval) || length($tcol);

	return { error => $self->_i18n('error_span_tcol_orphan', $tcol) }
		if length($tcol) && !length($interval);

	require Database::BI::Calc;
	return { error => $self->_i18n('error_span_interval', $interval) }
		unless Database::BI::Calc::span_interval($interval);

	my %col_set = map { $_ => 1 } @$columns;

	my $col;
	if (length $tcol) {
		return { error => $self->_i18n('error_span_tcol_unknown', $tcol) }
			unless $col_set{$tcol};
		$col = $tcol;
	} else {
		my @named = grep { length }
			map { split /,/, ($self->param($_) // ''), -1 } @dimension_params;
		return { error => $self->_i18n('error_span_no_column') } unless @named == 1;
		$col = $named[0];
	}

	# A bucket column is written in the calc grammar, so spaces in the column's
	# name arrive as underscores, exactly as a reader typing the expression
	# would have to write them.
	(my $expr_col = $col) =~ s/ /_/g;
	my $name = length($as) ? $as : "${expr_col}_span";
	return { error => $self->_i18n('error_span_name', $name) }
		unless $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

	my $taken = $col_set{$name} || do {
		my $found  = 0;
		my $sk     = $self->_calc_spec_key;
		my $stored = length($sk) ? (($self->_read_models)->{fields}{$sk} // {}) : {};
		$found = 1 if $stored->{$name};
		for my $spec (@{ $self->every_param('c') // [] }) {
			next if $spec =~ /\A(?:path:|table:|url:|redis:)/i;
			my ($n) = $spec =~ /\A([A-Za-z_][A-Za-z0-9_]*):/;
			$found = 1 if defined $n && $n eq $name;
		}
		$found;
	};
	return { error => $self->_i18n('error_span_conflict', $name) } if $taken;

	return {
		src  => $col,
		col  => $name,
		calc => [ "$name:span($expr_col,'$interval')" ],
	};
}

# _apply_date_normalization($self, $records, \@columns, $spec_key) -> void
#
# Reads date_patterns from .bi/models.json for $spec_key and normalises each
# configured column's values to ISO-8601 in-place.  A value that does not match
# the stored pattern is left unchanged so YEAR/MONTH/etc. return undef (and the
# row falls into the '(unparseable)' bucket in _grouped_totals).
# Called at the top of _apply_calc_fields so registered patterns are applied
# before any calc expression is evaluated.
sub _apply_date_normalization :Protected ($self, $records, $columns, $spec_key) {
	return unless defined $spec_key && length $spec_key;
	my $models   = $self->_read_models;
	my $patterns = $models->{date_patterns}{$spec_key};
	return unless $patterns && %{$patterns};
	my %col_set = map { $_ => 1 } @{$columns};
	require Database::BI::Calc;
	for my $col (keys %{$patterns}) {
		next unless $col_set{$col};
		my $pat = $patterns->{$col};
		for my $row (@{$records}) {
			my $v = $row->{$col};
			next unless defined $v && length $v;
			# Only overwrite when normalisation succeeds; leave unchanged on
			# mismatch so the row lands in the '(unparseable)' group.
			my $iso = Database::BI::Calc::date_normalise($v, $pat);
			$row->{$col} = $iso if defined $iso;
		}
	}
}

# _extend_row($row, $name, $value) -> $row | \%copy
#
# Purpose: Write a virtual column into a row that came out of a source.  A row
#          from a SQL-backed source arrives with its key set locked (the backend
#          locks it so that reading a column that is not there fails loudly),
#          and a locked row cannot take a new key in place: the assignment raises
#          "Attempt to access disallowed key".  Such a row is replaced by an
#          unlocked copy of itself carrying the new cell, which the rest of the
#          pipeline reads exactly as it reads any other row.
# Entry:   $row -- the row hashref; $name -- the column to add; $value -- its value.
# Exit:    $row itself when it can take the key (already present, or writable),
#          otherwise a new hashref.
# Notes:   Only a *new* key is a problem -- writing a key a locked row already
#          has is allowed -- so the common case (a CSV-backed source, and any
#          repeated evaluation) copies nothing.
sub _extend_row {
	my ($row, $name, $value) = @_;
	return $row if ref $row ne 'HASH';
	require Hash::Util;
	unless (Hash::Util::hashref_locked($row)) {
		$row->{$name} = $value;
		return $row;
	}
	return { %$row, $name => $value };
}

# _apply_calc_fields($self, $records, \@columns, \%extra) -> ($records, \@columns)
#
# Reads ?c=<name>:<expression> params (those NOT matching a path:/table:/url:/redis:
# source spec) and compiles each via Database::BI::Calc.  Evaluates per row,
# appending the virtual column to each row hashref.  Croaks on compile error
# (caller renders 400); runtime undef values are logged at warn level.
# Later ?c= specs may reference names defined by earlier ones (evaluated in order).
#
# Optional \%extra keys:
#   params   => \%hash  -- named parameter values bound from the URL (?p.name=val)
#                          passed to Calc->new so expressions may reference them.
#   spec_key => $str    -- override the l= spec key used to look up stored calc
#                          fields (canvas context where ?l= is absent).
#   calc     => \@specs -- additional ?c=-style specs, for a canvas whose query
#                          string arrived with the request rather than as the
#                          request's own parameters.
sub _apply_calc_fields :Protected ($self, $records, $columns, $extra = undef) {
	my $bound_params     = ($extra // {})->{params}   // {};
	my $spec_key_override = ($extra // {})->{spec_key};
	my $extra_calc        = ($extra // {})->{calc}    // [];

	# Normalise date columns before evaluating expressions so that date
	# functions (YEAR, MONTH, etc.) see ISO-8601 values even when the source
	# file uses a non-ISO format (e.g. M/D/YYYY).
	my $date_spec = defined $spec_key_override
		? $spec_key_override : ($self->param('l') // '');
	$self->_apply_date_normalization($records, $columns, $date_spec);

	# Build calc spec list: stored fields from models.json first (lower priority),
	# then URL ?c= params (higher priority -- they override stored fields of the
	# same name so the user can test a new expression without permanently saving).
	my (@calc_specs, %seen_calc);
	{
		my $sk = defined $spec_key_override
			? $spec_key_override : ($self->param('l') // '');
		if (length $sk) {
			my $stored = ($self->_read_models)->{fields}{$sk} // {};
			for my $n (sort keys %{$stored}) {
				push @calc_specs, { name => $n, expr => $stored->{$n} };
				$seen_calc{$n} = $#calc_specs;
			}
		}
	}
	for my $spec (@{ $self->every_param('c') // [] }, @$extra_calc) {
		# Skip source specs handled by _run_pipeline_source.
		next if $spec =~ /\A(?:path:|table:|url:|redis:)/i;
		my ($name, $expr) = ($spec =~ /\A([A-Za-z_][A-Za-z0-9_]*):(.+)\z/s);
		next unless defined $name && defined $expr;
		if (exists $seen_calc{$name}) {
			$calc_specs[$seen_calc{$name}]{expr} = $expr; # URL overrides stored
		} else {
			push @calc_specs, { name => $name, expr => $expr };
			$seen_calc{$name} = $#calc_specs;
		}
	}

	my @cols = @{$columns};

	if (@calc_specs) {
		require Database::BI::Calc;
		for my $cs (@calc_specs) {
			my $name = $cs->{name};
			my $calc = Database::BI::Calc->new(
				expr    => $cs->{expr},
				columns => \@cols,
				params  => $bound_params,
			);
			croak $self->_i18n('error_calc_compile', $name, $calc->error)
				if $calc->has_error;

			my $undef_count = 0;
			for my $i (0 .. $#$records) {
				my $row = $records->[$i];
				my $val = $calc->evaluate($row);
				$undef_count++ unless defined $val;
				# Store '(unparseable)' rather than undef so that pivot/bar
				# grouping (which skips empty-string keys) keeps these rows in a
				# visible '(unparseable)' bucket rather than silently dropping them.
				# See _extend_row for why the row may have to be replaced.
				$records->[$i] = _extend_row($row, $name,
					defined $val ? $val : '(unparseable)');
			}
			if ($undef_count) {
				$self->app->log->warn(
					$self->_i18n('warn_calc_undef', $name, $undef_count)
				);
			}
			push @cols, $name unless grep { $_ eq $name } @cols;
		# Record as virtual so _grouped_totals can skip the SQL push path.
		$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
		$self->stash('_virtual_columns')->{$name} = 1;
		}
	}

	# Apply named value groups from models.json.
	# For each source column that has groups registered under the current l=
	# spec, add a virtual "${col}_group" column to every row.  Each row's value
	# is mapped to its group label; values not in any group become '(other)'.
	{
		my $spec_key = $self->param('l') // '';
		if (length $spec_key) {
			my $models = $self->_read_models;
			my $grps   = $models->{groups}{$spec_key};
			if ($grps && %{$grps}) {
				my %col_set = map { $_ => 1 } @cols;
				for my $col (sort keys %{$grps}) {
					next unless $col_set{$col};
					# Build reverse map: value -> group label.
					my %val2group;
					for my $gname (keys %{$grps->{$col}}) {
						for my $v (@{$grps->{$col}{$gname}}) {
							$val2group{$v} = $gname;
						}
					}
					my $vcol = "${col}_group";
					for my $i (0 .. $#$records) {
						my $row = $records->[$i];
						my $v   = $row->{$col} // '';
						$records->[$i] = _extend_row(
							$row, $vcol, $val2group{$v} // '(other)');
					}
					push @cols, $vcol unless grep { $_ eq $vcol } @cols;
					# Record group column as virtual.
					$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
					$self->stash('_virtual_columns')->{$vcol} = 1;
				}
			}
		}
	}

	return ($records, \@cols);
}

# ---------------------------------------------------------------------------
# Calculated-field model storage  (.bi/models.json)
# ---------------------------------------------------------------------------

# _canonical_path($path) -> $string
#
# The absolute, symlink-resolved form of a path, for the data_dir guard.  Two
# spellings of one directory have to compare equal, or the guard can be walked
# around: a model_dir reached through a symlink is still inside the directory it
# points at, and a data_dir that is itself a symlink is still where the user
# keeps their data.  Cwd::realpath resolves the whole path when it exists; a
# store directory usually does not exist yet -- deciding whether to create it is
# what the guard is for -- so the deepest ancestor that does exist is resolved
# and the names below it are re-attached.
sub _canonical_path {
	my ($path) = @_;

	my $abs = eval { $path->to_abs } // $path;
	my @tail;
	my $probe = $abs;
	while (1) {
		my $string = $probe->to_string;
		my $real   = -e $string ? realpath($string) : undef;
		if (defined $real && length $real) {
			return File::Spec->canonpath(
				@tail ? Mojo::File->new($real, @tail)->to_string : $real
			);
		}
		my $parent = $probe->dirname;
		last if $parent->to_string eq $string;   # the root: nothing left to resolve
		unshift @tail, $probe->basename;
		$probe = $parent;
	}

	# Nothing on the path exists at all, so the lexical absolute form is all
	# there is to compare.
	return File::Spec->canonpath($abs->to_string);
}

# _inside_dir($path, $dir) -> $bool
#
# True when $path names $dir itself or something below it.  abs2rel asks the
# file system what the relationship between the two is, so a textual prefix
# cannot make ".../data-archive" look like it is inside ".../data", and the
# comparison is made with the platform's separator rather than a hard-coded
# slash.
sub _inside_dir {
	my ($path, $dir) = @_;
	return 0 unless length $path && length $dir;
	return 1 if $path eq $dir;

	my $rel = eval { File::Spec->abs2rel($path, $dir) };
	return 0 unless defined $rel && length $rel;
	return 0 if File::Spec->file_name_is_absolute($rel);
	return $rel eq '..' || $rel =~ m{\A\.\.[\\/]} ? 0 : 1;
}

# _calc_models_path($self) -> $path_string_or_undef
#
# Returns the path to .bi/models.json (creating .bi/ on first call), or undef
# when the write must be skipped (data_dir safety guard, mkdir failure).
sub _calc_models_path :Protected ($self) {
	my $app      = $self->app;
	my $home     = $app->home;
	my $cfg_dir  = $app->config('model_dir') // '.bi';
	# Support absolute paths in model_dir (e.g. when tests redirect to a temp dir).
	my $bi_dir   = Mojo::File->new($cfg_dir)->is_abs
	                ? Mojo::File->new($cfg_dir)
	                : $home->child($cfg_dir);
	my $data_dir = _data_dir_for($app);

	# A store inside data_dir is refused, not created: the file would sit beside
	# the user's data, in a directory they chose for something else.  The test is
	# on canonical paths, so it holds however the two are spelled -- an absolute
	# path, a relative one, or either of them reached through a symlink.
	if (_inside_dir(_canonical_path($bi_dir), _canonical_path($data_dir))) {
		carp 'model_dir is inside data_dir; skipping model file write';
		return undef;
	}
	unless (-d $bi_dir) {
		mkdir $bi_dir->to_string
			or do { $app->log->warn("Cannot create $bi_dir: $!"); return undef };
	}
	return $bi_dir->child('models.json')->to_string;
}

# _read_models($self) -> \%models
#
# Returns the parsed models hashref from .bi/models.json, or an empty scaffold.
sub _read_models :Protected ($self) {
	my $path = $self->_calc_models_path;
	my $scaffold = { version => 1, fields => {}, groups => {}, date_patterns => {} };
	return $scaffold unless defined $path && -f $path;
	my $json = eval { Mojo::File->new($path)->slurp };
	return $scaffold unless $json && !$@;
	my $data = eval { decode_json($json) };
	return $scaffold unless ref $data eq 'HASH';
	$data->{fields}        //= {};
	$data->{groups}        //= {};
	$data->{date_patterns} //= {};
	return $data;
}

# _write_models($self, \%models) -> $bool
#
# Persists models to .bi/models.json.  Returns false when the store could not be
# written - because the data_dir guard refused it, or because the write failed -
# so a caller whose result is only an optimisation (the geocode cache: it
# degrades to a per-request cache) can say so rather than pretend.
sub _write_models :Protected ($self, $models) {
	my $path = $self->_calc_models_path;
	return 0 unless defined $path;
	my $ok = eval { Mojo::File->new($path)->spurt(encode_json($models)); 1 };
	$self->app->log->warn("Cannot write $path: $@") if !$ok && $@;
	return $ok ? 1 : 0;
}

# _analyses_path($self) -> $path_string_or_undef
#
# Returns the path to model_dir/analyses.json (creating model_dir on first call),
# or undef when the write must be skipped (data_dir safety guard, mkdir failure).
sub _analyses_path :Protected ($self) {
	my $app      = $self->app;
	my $home     = $app->home;
	my $cfg_dir  = $app->config('model_dir') // '.bi';
	my $bi_dir   = Mojo::File->new($cfg_dir)->is_abs
	                ? Mojo::File->new($cfg_dir)
	                : $home->child($cfg_dir);
	my $data_dir = $home->child($app->config('data_dir') // 'data');

	# The same refusal as the model store, with its own message: see
	# _canonical_path for why the comparison is on resolved paths.
	if (_inside_dir(_canonical_path($bi_dir), _canonical_path($data_dir))) {
		carp 'model_dir is inside data_dir; skipping analyses file write';
		return undef;
	}
	unless (-d $bi_dir) {
		mkdir $bi_dir->to_string
			or do { $app->log->warn("Cannot create $bi_dir: $!"); return undef };
	}
	unless (-w $bi_dir) {
		carp 'model_dir is not writable; analysis storage disabled';
		return undef;
	}
	return $bi_dir->child('analyses.json')->to_string;
}

# _read_analyses($self) -> \%analyses  (keyed by id)
sub _read_analyses :Protected ($self) {
	my $path = $self->_analyses_path;
	return {} unless defined $path && -f $path;
	my $json = eval { Mojo::File->new($path)->slurp };
	return {} unless $json && !$@;
	my $data = eval { decode_json($json) };
	return {} unless ref $data eq 'HASH';
	return $data;
}

# _write_analyses($self, \%analyses) -- atomic write (temp + rename)
sub _write_analyses :Protected ($self, $analyses) {
	my $path = $self->_analyses_path;
	return unless defined $path;
	my $dir = Mojo::File->new($path)->dirname->to_string;
	my ($fh, $tmpfile) = eval { tempfile(DIR => $dir, UNLINK => 0) };
	if ($@ || !$fh) {
		$self->app->log->warn("Cannot create temp file in $dir: " . ($@ // $!));
		return;
	}
	my $ok = eval {
		print {$fh} encode_json($analyses);
		close $fh;
		rename($tmpfile, $path);
		1;
	};
	unless ($ok) {
		$self->app->log->warn("Cannot write $path: $@");
		unlink $tmpfile;
	}
}

# _gen_analysis_id($self) -> $id_string
#
# Returns a 10-character URL-safe alphanumeric random ID.
Readonly my $_ID_CHARS => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

sub _gen_analysis_id :Protected ($self) {
	my $id = '';
	$id .= substr($_ID_CHARS, int(rand(62)), 1) for 1..10;
	return $id;
}

# The canvas is a 12-column CSS grid; a layout entry addresses cells in it.
# Shared by _validate_layout and by the layout precompute in canvas_render.
Readonly my $GRID_COLUMNS => 12;

# How many grid rows one visual may span.  A row is at least 15rem tall (see
# grid-auto-rows in templates/web/en/canvas.html.tt), so this is also a cap on
# how tall a single visual can be made from the canvas.
Readonly my $MAX_ROW_SPAN => 6;

# _validate_layout($self, $layout_or_undef) -> $error_string_or_undef
#
# A layout entry is { visual, x, y, w, h } -- the grid position of one visual
# on the canvas.  The canvas PATCHes these straight out of a drag, so they are
# untrusted input like every other field: reject anything that is not a whole
# number of columns or rows inside the grid, rather than store a position that
# renders as "span 0" or runs off the right-hand edge.
sub _validate_layout :Protected ($self, $layout) {
	return undef unless defined $layout;
	return 'layout must be an array' unless ref $layout eq 'ARRAY';

	my $n = 0;
	my @placed;   # the cells already spoken for, to reject an overlap
	for my $lp (@$layout) {
		$n++;
		return "layout entry $n must be a hash" unless ref $lp eq 'HASH';
		for my $f (qw( visual x y w h )) {
			return "layout entry $n is missing $f" unless defined $lp->{$f};
			return "layout entry $n: $f must be a whole number"
				if ref $lp->{$f} || $lp->{$f} !~ /\A\d+\z/;
		}
		return "layout entry $n: x must be between 1 and $GRID_COLUMNS"
			unless $lp->{x} >= 1 && $lp->{x} <= $GRID_COLUMNS;
		return "layout entry $n: y must be at least 1"
			unless $lp->{y} >= 1;
		return "layout entry $n: w must be between 1 and $GRID_COLUMNS"
			unless $lp->{w} >= 1 && $lp->{w} <= $GRID_COLUMNS;
		return "layout entry $n: h must be between 1 and $MAX_ROW_SPAN"
			unless $lp->{h} >= 1 && $lp->{h} <= $MAX_ROW_SPAN;
		return "layout entry $n: x + w - 1 must not exceed $GRID_COLUMNS"
			if $lp->{x} + $lp->{w} - 1 > $GRID_COLUMNS;

		# Two visuals cannot hold the same cell: the canvas is a grid of positions,
		# and an overlapping layout renders one visual on top of another.  The
		# canvas pushes the cards a drop lands on out of the way before it PATCHes,
		# so this rejects a hand-written or stale layout rather than a drag.
		for my $p (@placed) {
			next unless $p->{x} < $lp->{x} + $lp->{w} && $lp->{x} < $p->{x} + $p->{w};
			return "layout entry $n overlaps an earlier entry"
				if $p->{y} < $lp->{y} + $lp->{h} && $lp->{y} < $p->{y} + $p->{h};
		}
		push @placed, { x => $lp->{x}, y => $lp->{y}, w => $lp->{w}, h => $lp->{h} };
	}

	return undef;
}

# _validate_analysis($self, \%doc) -> $error_string_or_undef
#
# Structural validation of a saved-analysis document.  Called on create, on
# replace and on import; analyses_patch validates the keys it is given instead,
# so that a PATCH of one field cannot fail because of another field it never
# read.
sub _validate_analysis :Protected ($self, $doc) {
	return 'Missing required field: name'
		unless defined $doc->{name} && length $doc->{name};
	return 'Missing required field: datasets'
		unless ref $doc->{datasets} eq 'ARRAY' && @{ $doc->{datasets} };
	for my $ds (@{ $doc->{datasets} }) {
		return 'Each dataset entry must have a spec field'
			unless defined $ds->{spec} && length $ds->{spec};
		return qq{"$ds->{spec}" is not a valid spec (must start with table:, path:, url:, or redis:)}
			unless $ds->{spec} =~ m{\A(?:table:|path:|url:|redis:)};
	}
	if (defined $doc->{version}) {
		return sprintf($MESSAGES{error_analysis_version}, $doc->{version})
			unless $doc->{version} =~ /\A\d+\z/ && $doc->{version} <= 1;
	}
	for my $key (qw( visuals joins measures combines bookmarks layout hierarchies )) {
		if (defined $doc->{$key}) {
			return "$key must be an array"
				unless ref $doc->{$key} eq 'ARRAY';
		}
	}
	my $lerr = $self->_validate_layout($doc->{layout});
	return $lerr if $lerr;
	if (defined $doc->{fields}) {
		return 'fields must be a hash'
			unless ref $doc->{fields} eq 'HASH';
	}
	if (defined $doc->{params}) {
		return 'params must be a hash'
			unless ref $doc->{params} eq 'HASH';
	}
	return undef;
}

# _analysis_to_url($self, \%analysis) -> $url_string_or_undef
#
# Reconstructs a /join?l=...&j=...&f=... URL from a saved analysis.
# Used by canvas_render to redirect when no visuals exist yet.
sub _analysis_to_url :Protected ($self, $a) {
	my @datasets = @{ $a->{datasets} // [] };
	return undef unless @datasets;

	my $left_spec = $datasets[0]{spec} or return undef;
	my @params = ('l=' . url_escape($left_spec));

	# Build an alias->spec lookup for join resolution
	my %spec_by_alias;
	for my $ds (@datasets) {
		$spec_by_alias{ $ds->{alias} // '' } = $ds->{spec} // '';
	}

	for my $j (@{ $a->{joins} // [] }) {
		my $right_spec = $spec_by_alias{ $j->{right} // '' } // '';
		next unless $right_spec;
		push @params, 'j=' . url_escape(
			join('|', $right_spec, $j->{left_key}//'', $j->{right_key}//'')
		);
	}

	# Filters from all datasets
	for my $ds (@datasets) {
		for my $f (@{ $ds->{filters} // [] }) {
			push @params, 'f=' . url_escape($f);
		}
	}

	return '/join?' . join('&', @params);
}

# GET /api/analyses
sub analyses_list ($self) {
	my $analyses = $self->_read_analyses;
	my @list = map {
		my $a = $analyses->{$_};
		{ id => $_, name => $a->{name}, datasets => $a->{datasets},
		  updated => $a->{updated} }
	} sort keys %$analyses;
	$self->render(json => { analyses => \@list });
}

# POST /api/analyses
sub analyses_create ($self) {
	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_invalid}, $err) }, status => 400)
		if $err;

	my $analyses = $self->_read_analyses;
	unless ($self->_analyses_path) {
		return $self->render(json => { error => $MESSAGES{error_analysis_storage} }, status => 503);
	}

	my $id;
	my $tries = 0;
	do { $id = $self->_gen_analysis_id; $tries++ }
		while (exists $analyses->{$id} && $tries < 100);

	$body->{id}      = $id;
	$body->{version} //= 1;
	$body->{created} = time();
	$body->{updated} = time();

	# Strip caller-supplied immutable fields except id/version/created/updated
	delete $body->{$_} for grep { !m/\A(?:id|version|created|updated|name|datasets|joins|combines|fields|measures|params|visuals|layout|bookmarks|hierarchies)\z/ } keys %$body;

	$analyses->{$id} = $body;
	$self->_write_analyses($analyses);

	$self->res->headers->location("/api/analyses/$id");
	$self->render(json => { id => $id, created => 1 }, status => 201);
}

# GET /api/analyses/:id
sub analyses_get ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	$self->render(json => $analyses->{$id});
}

# PUT /api/analyses/:id  (full replace)
sub analyses_update ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_invalid}, $err) }, status => 400)
		if $err;

	$body->{id}      = $id;
	$body->{version} //= 1;
	$body->{created} = $analyses->{$id}{created} // time();
	$body->{updated} = time();

	$analyses->{$id} = $body;
	$self->_write_analyses($analyses);

	$self->render(json => { id => $id, updated => 1 });
}

# PATCH /api/analyses/:id  (partial update -- merges supplied keys)
sub analyses_patch ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	# Only the keys actually supplied are validated here: the canvas PATCHes
	# nothing but the layout (a drag) or the bookmarks, and a document that
	# fails on some other field it never mentioned is not this request's fault.
	if (exists $body->{layout}) {
		my $lerr = $self->_validate_layout($body->{layout});
		return $self->render(json => { error => sprintf($MESSAGES{error_analysis_invalid}, $lerr) }, status => 400)
			if $lerr;
	}

	my $existing = { %{ $analyses->{$id} } };
	for my $key (keys %$body) {
		next if $key eq 'id' || $key eq 'created';  # immutable
		$existing->{$key} = $body->{$key};
	}
	$existing->{updated} = time();

	$analyses->{$id} = $existing;
	$self->_write_analyses($analyses);

	$self->render(json => { id => $id, updated => 1 });
}

# DELETE /api/analyses/:id
sub analyses_delete ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	delete $analyses->{$id};
	$self->_write_analyses($analyses);

	$self->render(json => { deleted => 1 });
}

# POST /api/analyses/:id/visuals  (append one table or chart)
#
# Adds a visual to a saved canvas without sending the reader back to the table
# or chart page it came from.  The request is { kind, encode, options, title }
# and the visual is rendered here, with the same pipeline and renderer the
# canvas itself uses, before it is stored: a column that does not exist is a
# 400 rather than a broken card the reader only discovers after a reload.
#
# The new card is deliberately left out of the saved layout.  An auto-placed
# card is ordered after the saved ones and stays there without pinning a
# position that the next drag would have to fight; the canvas writes a layout
# entry once the reader moves or resizes it.
sub analyses_add_visual ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	my $kind = $body->{kind} // '';
	my %supported = map { $_ => 1 }
		qw( table bar pie line graph scatter heatmap stacked combo treemap histogram map wordcloud );
	return $self->render(json => { error => 'Unsupported visual kind' }, status => 400)
		unless $supported{$kind};

	for my $key (qw( encode options cross_row )) {
		return $self->render(json => { error => "$key must be an object" }, status => 400)
			if defined $body->{$key} && ref $body->{$key} ne 'HASH';
	}

	my $vis = {
		kind    => $kind,
		encode  => ($body->{encode}  // {}),
		options => ($body->{options} // {}),
	};

	# A card may bring a cross-row plan of its own; it is stored in the same
	# spelling cs=/by=/order= use -- { cs => [...], by => '...', order => [...] }
	# -- so the pass reads it through the one parser, with the page's plan left
	# out of it.  Only the shape is checked here: which columns exist is a fact
	# about the data file, and it is checked again on every render for the same
	# reason a saved canvas is.
	if (my $raw = $body->{cross_row}) {
		my $plan = _card_plan($raw);
		return $self->render(json => { error => $plan->{error} }, status => 400)
			if $plan->{error};
		$vis->{cross_row} = $plan;
	}

	$vis->{title} = $body->{title}
		if defined $body->{title} && !ref $body->{title} && length $body->{title};

	# The card is added without a page reload, so the canvas's own URL state has
	# to come with the request: a reader who adds a card while a chart is
	# cross-filtering the canvas, with calculated columns on the URL, or with a
	# what-if parameter set, gets a card drawn like the ones beside it rather
	# than against the unfiltered table.
	my $ctx = $self->_canvas_render_context($a, $body->{query});
	return $self->render(json => { error => $ctx->{error} }, status => $ctx->{status})
		if $ctx->{error};

	# The new card is never the cross-filter source: it did not exist when the
	# filter was made, so every cf applies to it, as it does to every card but
	# the source.
	my $records = $ctx->{records};
	for my $spec (@{ $ctx->{cf_specs} }) {
		$records = _apply_filter_spec($records, $spec);
	}

	# The index is known before the render, so the card's SVG and Leaflet ids
	# match the ones a later page load will give it.
	my $index = scalar @{ $a->{visuals} // [] };

	my $rendered = $self->_render_visual_html(
		$vis, $records, $ctx->{columns}, $ctx->{src}, $index, $ctx->{spec_key},
		(@{ $ctx->{cf_specs} } ? 1 : 0),
		$ctx->{cross_row},
	);
	return $self->render(json => { error => $rendered->{error} }, status => 400)
		if $rendered->{error};

	push @{ $a->{visuals} //= [] }, $vis;
	$a->{updated} = time();
	$self->_write_analyses($analyses);

	return $self->render(
		json   => {
			id     => $id,
			visual => $index,
			kind   => $kind,
			title  => ($vis->{title} // $rendered->{title} // 'Visual ' . ($index + 1)),
			html   => $rendered->{html},
			head   => ($rendered->{head} // ''),
			# The column a chart's marks filter by, so the card appended in
			# place is a cross-filter control like the cards around it.
			cf_col => (_vis_cf_col($vis) // ''),
		},
		status => 201,
	);
}

# PATCH /api/analyses/:id/visuals/:visual  (change a saved visual's columns)
#
# A map card that plotted the wrong column should not have to be deleted and
# added again: the visual keeps its index - and with it its place in the
# layout, its size, its title and the Leaflet ids a re-render reuses - while
# its C<encode> is replaced.  Like the append above, the replacement is drawn
# before it is stored, so an unknown column is a 400 and the saved visual is
# left alone.  The optional C<query> is the canvas page's URL state, so a card
# edited while the canvas is cross-filtered is redrawn with the others.
#
# C<cross_row> is repaired the same way, and on the same request: a card's plan
# is stored data like its columns, so a card that was saved with a plan this
# canvas cannot honour - or with none where one is now wanted - is fixed in
# place, keeping its layout slot, its size and its title.  The two keys are
# independent, so a repair that renames the column the pass produces writes
# both in one request rather than leaving the card drawn against a column that
# no longer exists.  A JSON C<null> is the card giving up its plan and taking
# the page's again, which is the state a card added without one is in; an
# empty plan (C<{ cs => [] }>) is the card running no pass even where the page
# runs one, and leaving the key out is no request to change it at all.
sub analyses_update_visual ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my $index = $self->stash('visual') // '';
	return $self->render(json => { error => 'Visual index must be a number' }, status => 400)
		unless $index =~ /\A\d+\z/;
	$index += 0;
	return $self->render(json => { error => "No visual at index $index" }, status => 404)
		unless $index < scalar @{ $a->{visuals} // [] };

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	my $has_encode = exists $body->{encode};
	my $has_plan   = exists $body->{cross_row};
	return $self->render(json => { error => 'encode or cross_row must be given' }, status => 400)
		unless $has_encode || $has_plan;

	my $vis = { %{ $a->{visuals}[$index] } };

	if ($has_encode) {
		return $self->render(json => { error => 'encode must be an object' }, status => 400)
			unless ref $body->{encode} eq 'HASH';
		$vis->{encode} = { %{ $body->{encode} } };
	}

	if ($has_plan) {
		if (defined $body->{cross_row}) {
			return $self->render(json => { error => 'cross_row must be an object or null' }, status => 400)
				unless ref $body->{cross_row} eq 'HASH';
			my $plan = _card_plan($body->{cross_row});
			return $self->render(json => { error => $plan->{error} }, status => 400)
				if $plan->{error};
			$vis->{cross_row} = $plan;
		}
		else {
			delete $vis->{cross_row};
		}
	}

	my $ctx = $self->_canvas_render_context($a, $body->{query});
	return $self->render(json => { error => $ctx->{error} }, status => $ctx->{status})
		if $ctx->{error};

	# The card is drawn as it is on this page: a cross-filter applies to every
	# card but the one that made it, and this card may be that one.
	my $records      = $ctx->{records};
	my $prefiltered  = 0;
	if (@{ $ctx->{cf_specs} } && $ctx->{cf_source} != $index) {
		for my $spec (@{ $ctx->{cf_specs} }) {
			$records = _apply_filter_spec($records, $spec);
		}
		$prefiltered = 1;
	}

	my $rendered = $self->_render_visual_html(
		$vis, $records, $ctx->{columns}, $ctx->{src}, $index, $ctx->{spec_key},
		$prefiltered,
		$ctx->{cross_row},
	);
	return $self->render(json => { error => $rendered->{error} }, status => 400)
		if $rendered->{error};

	$a->{visuals}[$index] = $vis;
	$a->{updated} = time();
	$self->_write_analyses($analyses);

	return $self->render(
		json => {
			id     => $id,
			visual => $index,
			kind   => ($vis->{kind} // ''),
			title  => ($vis->{title} // $rendered->{title} // 'Visual ' . ($index + 1)),
			html   => $rendered->{html},
			head   => ($rendered->{head} // ''),
			cf_col => (_vis_cf_col($vis) // ''),
		},
	);
}

# GET /api/analyses/:id/export
sub analyses_export ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	my $json = encode_json($analyses->{$id});
	$self->res->headers->content_disposition("attachment; filename=\"analysis-$id.json\"");
	$self->render(data => $json, format => 'json');
}

# POST /api/analyses/import  (create from uploaded JSON or raw body)
sub analyses_import ($self) {
	my $upload    = $self->req->upload('file');
	my $body_json = $upload ? $upload->slurp : $self->req->body;

	my $body = eval { decode_json($body_json) };
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_json}, $@) }, status => 400)
		unless ref $body eq 'HASH';

	# Strip any id/timestamps from imported document; assign fresh ones below
	delete @{$body}{qw( id created updated )};

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_invalid}, $err) }, status => 400)
		if $err;

	unless ($self->_analyses_path) {
		return $self->render(json => { error => $MESSAGES{error_analysis_storage} }, status => 503);
	}

	my $analyses = $self->_read_analyses;

	my $id;
	my $tries = 0;
	do { $id = $self->_gen_analysis_id; $tries++ }
		while (exists $analyses->{$id} && $tries < 100);

	$body->{id}      = $id;
	$body->{version} //= 1;
	$body->{created} = time();
	$body->{updated} = time();

	$analyses->{$id} = $body;
	$self->_write_analyses($analyses);

	$self->res->headers->location("/api/analyses/$id");
	$self->render(json => { id => $id, imported => 1 }, status => 201);
}

# _build_canvas_pipeline($self, \%analysis) -> ($src, $records, \@cols) or ()
#
# Opens the first dataset from a saved analysis and chains any declared joins.
# Returns the base pipeline triple for _render_visual_html.
# Returns an empty list on any error so canvas_render can respond 422.
# _canvas_render_context($self, \%analysis, $query) -> \%ctx | { error, status }
#
# The state a card is drawn through when it is rendered outside canvas_render:
# the base pipeline, calculated columns, bound parameters and the cross-filters
# named by a canvas page's query string.  C<cf_specs> are returned unapplied so
# the caller can decide which card, if any, is their source; C<cf_source> is
# the C<cv> index, or -1 when the page names none.  C<cross_row> is the
# validated cs= plan, undef when the page names none, which the caller passes to
# _render_visual_html so each card runs it over its own rows.  Only C<cf>,
# C<cv>, C<c>, C<cs>, C<by>, C<order>, C<range>, C<rcol> and C<p.<name>> are read
# from C<$query> - the same keys canvas_render reads from its own URL - so a
# page's state is not a way to reach anything else.
sub _canvas_render_context :Protected ($self, $a, $query) {
	my $params;
	if (defined $query) {
		return { error => 'query must be a string', status => 400 }
			if ref $query || length($query) > 4096;
		(my $qs = $query) =~ s/\A\?//;
		$params = Mojo::Parameters->new($qs);
	}

	my ($src, $records, $columns) = $self->_build_canvas_pipeline($a);
	return { error => 'Cannot open data source for this canvas', status => 422 }
		unless defined $records;

	my ($bound_ref, $p_errors) = $self->_bound_canvas_params(
		$a, sub { $params ? $params->param($_[0]) : undef },
	);
	return { error => join('; ', @$p_errors), status => 400 }
		if @$p_errors;
	my %param_values = %$bound_ref;

	eval {
		($records, $columns) = $self->_apply_calc_fields(
			$records, $columns,
			{
				params   => \%param_values,
				spec_key => ($a->{datasets}[0]{spec} // ''),
				calc     => [ $params ? @{ $params->every_param('c') // [] } : () ],
			}
		);
	};
	if ($@) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		return { error => $e, status => 400 };
	}

	# The canvas names cs= once and every card runs the same plan over its own
	# rows (see _render_visual_html).  Validated here, against the columns the
	# cards will be drawn from, so a card added or edited in place fails with
	# the same 400 the page itself would give.
	my $cross_row = $self->_cross_row_specs($columns, $params || Mojo::Parameters->new);
	return { error => $cross_row->{error}, status => 400 }
		if $cross_row && $cross_row->{error};

	my @cf_specs  = $params ? grep { /\S/ } @{ $params->every_param('cf') // [] } : ();
	my $cf_source = (defined $params && defined $params->param('cv'))
		? int($params->param('cv')) : -1;

	# The relative time range the canvas page names in its query string is part
	# of the state a card is drawn through, like cf= and the bound parameters,
	# so a visual added while a range is active shows the same rows as the
	# cards already on screen.
	$records = _apply_time_range(
		$records,
		$params ? $params->param('range') : undef,
		$params ? $params->param('rcol')  : undef,
	);

	return {
		src       => $src,
		records   => $records,
		columns   => $columns,
		spec_key  => ($a->{datasets}[0]{spec} // ''),
		cf_specs  => \@cf_specs,
		cf_source => $cf_source,
		cross_row => $cross_row,
	};
}

sub _build_canvas_pipeline :Protected ($self, $analysis) {
	my @datasets = @{ $analysis->{datasets} // [] };
	return () unless @datasets;

	my $left_spec = $datasets[0]{spec} or return ();
	my ($left_src) = $self->_open_spec($left_spec);
	return () unless $left_src;

	my $max_rows = $self->app->config('join_max_rows') // $DEFAULT_JOIN_MAX_ROWS;
	my $src = $left_src;

	# Build alias -> spec lookup for join resolution.
	my %spec_by_alias;
	for my $ds (@datasets) {
		$spec_by_alias{ $ds->{alias} // '' } = $ds->{spec} // '';
	}

	for my $j (@{ $analysis->{joins} // [] }) {
		my $right_spec = $spec_by_alias{ $j->{right} // '' } // '';
		next unless length $right_spec;
		my $left_key  = $j->{left_key}  // '';
		my $right_key = $j->{right_key} // $left_key;
		next unless length $left_key;

		my ($right_src) = $self->_open_spec($right_spec);
		next unless $right_src;

		require Database::Join;
		$src = Database::Join->new(
			databases      => [$src, $right_src],
			join_column    => $left_key,
			backend        => 'auto',
			max_array_rows => $max_rows,
			($left_key ne $right_key ? (join_map => {1 => $right_key}) : ()),
		);
	}

	my $records = eval { $src->selectall_arrayref };
	return () if $@;
	$records //= [];
	my @columns = _get_columns($src, $records);

	return ($src, $records, \@columns);
}

# _chart_json($self, \%chart_spec) -> $json_for_a_data_attribute
#
# The chart templates put this in the New canvas panel's data-chart attribute
# so the canvas buttons can save the chart exactly as it is drawn, including
# options the URL does not carry.  Escape '<' as well, so the value is inert
# even if a title or column name contains markup.
sub _chart_json :Protected ($self, $chart) {
	my $json = encode_json($chart);
	$json =~ s{<}{\\u003c}g;
	return $json;
}

# _chart_orientation(\%options) -> 'horizontal' | 'vertical'
#
# The chart pages store a bar's direction as options.orientation, the spelling
# their URL uses, while the canvas used to read options.orient; both are read
# here.  The values the pages emit are v/h and vertical/horizontal.
sub _chart_orientation {
	my ($options) = @_;

	my $orient = $options->{orientation} // $options->{orient} // '';
	return ($orient =~ /\A(?:h|horizontal)\z/i) ? 'horizontal' : 'vertical';
}

# _visual_measure($agg_fn, $val_col) -> \%measure
#
# The measure a canvas card aggregates a value column with: C<{ fn, val,
# label }> when the card can be drawn, or C<{ error }> when it cannot, which
# the card reports in place of its chart.
#
# A card that names no function keeps the default it has always had: count the
# rows when it names no value column, sum it when it does.  A named function is
# the measure vocabulary the pivot and the stats page share, with a percentile
# riding in the name as p<N> -- p90, p50 -- exactly as a pivot's measure spells
# it, so a card needs no second key to keep in step.  'count' counts rows, so it
# ignores the value column and needs none.
#
# label is what the card's title calls the result: 'Count', the column's own
# name for a plain sum, and "fn(col)" for anything else, so two cards over one
# column do not read alike when one of them is a median.  An explicit sum keeps
# the plain name, because naming the default should not change a card.
#
# The name itself is not checked here: _render_visual_html validates it once,
# before the dispatch, so that a card of any kind reports a function it cannot
# compute -- including the kinds that never call this.
sub _visual_measure {
	my ($agg_fn, $val_col) = @_;
	my $count_col = (!defined $val_col || !length $val_col || $val_col eq '__count__');
	# An absent name and an empty one are the same non-choice, so the default is
	# one branch rather than two.
	my $named = (defined $agg_fn && !ref $agg_fn && length $agg_fn) ? $agg_fn : undef;

	return { fn => 'count', val => undef, label => 'Count' }
		if defined $named && $named eq 'count';
	return { fn => 'count', val => undef, label => 'Count' }
		if !defined $named && $count_col;
	return { error => "Aggregate '$named' needs a value column" }
		if defined $named && $count_col;

	my $fn = defined $named ? $named : 'sum';
	return {
		fn    => $fn,
		val   => $val_col,
		label => ($fn eq 'sum' ? $val_col : "$fn($val_col)"),
	};
}

# _render_visual_html($self, \%vis, $records, \@columns, $src, $vis_id, $spec_key,
#                     $prefiltered, $cross_row)
#     -> { html => Str, title => Str, head => Str } | { error => Str }
#
# Renders one canvas visual spec to an HTML snippet without touching
# $self->render(), with each of the card's inline scripts closed over a
# function of its own (see _scope_card_scripts).  The scoping is done here
# rather than by the callers because every card passes through here and every
# caller wants the same thing: a card's script and the page's are separate
# programs, whether the card is drawn on a canvas of its own kind or returned
# to a page that is about to insert it.
sub _render_visual_html :Protected ($self, $vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row = undef) {
	my $rendered = $self->_render_visual_markup(
		$vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row,
	);
	return $rendered unless defined $rendered->{html};

	$rendered->{html} = _scope_card_scripts($rendered->{html});
	return $rendered;
}

# _render_visual_markup($self, \%vis, $records, \@columns, $src, $vis_id,
#                       $spec_key, $prefiltered, $cross_row)
#     -> { html => Str, title => Str, head => Str } | { error => Str }
#
# The card itself, without the scope _render_visual_html puts around its
# scripts.  Applies any per-visual filters, then dispatches by
# kind to the appropriate renderer.  $vis_id gives a map's Leaflet element
# ids a page-unique suffix; $spec_key is the dataset whose older per-dataset
# geocode entry may still be read while the shared cache is migrated.
# $cross_row is the canvas's validated cs= plan, run here so that each card's
# window is over that card's own rows: see the note at the pass below.  A card
# that saved a plan of its own uses that one instead.
sub _render_visual_markup :Protected ($self, $vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row = undef) {
	my $kind    = $vis->{kind}    // '';
	my $encode  = $vis->{encode}  // {};
	my $options = $vis->{options} // {};
	my $filters = $vis->{filters} // [];
	my $title   = $vis->{title}   // '';

	# Every chart on a canvas needs an element id of its own: HTML::D3 names the
	# SVG after the chart kind by default, so two bar cards both write #bar_chart
	# and the second card's script draws into the first.  The id carries the
	# visual's index, which is stable across renders, so a saved canvas and a
	# card appended in place agree; the chart pages render one chart and keep
	# HTML::D3's default.
	my $svg_id = 'vis-' . (defined($vis_id) ? $vis_id : 'chart');

	# Apply per-visual filters on top of the base pipeline records.
	my $vis_recs = $records;
	for my $f (@$filters) {
		$vis_recs = _apply_filter_spec($vis_recs, $f);
	}

	# Stage 6, per card.  A canvas names cs= once, but by the time the pass runs
	# the card has already been narrowed by its own filters and by the page's
	# cross-filter, so a running total is over the rows that card is drawn from:
	# two cards showing different regions show different running totals.  The
	# pass therefore cannot be hoisted above the card loop -- one shared pass
	# would give every card the same numbers, and those are the numbers of
	# neither card.  A fault is this card's error, not the page's: the plan was
	# validated once, and only the arithmetic can still fail here.
	#
	# A card that carries a cross-row plan of its own (visual.cross_row) runs that
	# plan instead of the page's: putting a running total on one card is not a
	# request to put one on every card, and a card whose plan is empty has none
	# at all rather than the page's.  Its plan is validated here rather than
	# when it was saved, because the columns a saved canvas has are the columns
	# its data file has today.  A card's own plan is its own fault, so a bad one
	# is that card's error while the page's bad plan is the page's 400.
	my $plan = $cross_row;
	if (ref $vis->{cross_row} eq 'HASH') {
		$plan = $self->_cross_row_specs_from($columns, $vis->{cross_row});
		return { error => $plan->{error} }
			if $plan && $plan->{error};
	}

	if ($plan) {
		# The pass writes its column onto the rows it is handed, and a card is
		# handed the canvas's rows -- the same hashrefs every card draws from.  The
		# numbers a pass produces are that card's, so it runs on copies: without
		# them one card's running total is written into its neighbour's rows, and a
		# card that asked for no plan at all reads a column it never asked for.
		my $own = [ map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$vis_recs ];
		my ($crossed, $crossed_cols) = eval {
			$self->_apply_cross_row($own, $columns, $plan)
		};
		if (my $e = $@) {
			$e =~ s/ at \S+ line \d+\.?\n?$//;
			return { error => $e };
		}
		($vis_recs, $columns) = ($crossed, $crossed_cols);
	}

	my %col_set = map { $_ => 1 } @$columns;

	# The aggregate function this card picked for itself, if any (encode.agg).
	# It is read and checked here, before the dispatch, so a misspelt function
	# is this card's error whatever kind it is, rather than a chart quietly
	# drawn some other way; the kinds that aggregate then honour it below.  A
	# percentile rides in the name (p90, p50), as it does in a pivot measure, so
	# there is no second key to keep in step.
	my $agg_fn = $encode->{agg};
	if (defined $agg_fn && !ref $agg_fn && length $agg_fn) {
		return { error => "Unknown aggregate function '$agg_fn'; expected one of: "
			. join(' ', @MEASURE_FNS) . ', or p1 to p100 for a percentile' }
			unless _measure_fn_ok($agg_fn);
	} else {
		$agg_fn = undef;
	}

	# A chart aggregates the rows it is given.  The SQL push path in
	# _grouped_totals re-reads the source, which has none of the filters the
	# caller already applied (a cross-filter, or this visual's own filters), so
	# those rows have to be folded in Perl.  Passing no source is how the
	# pipeline says so.
	my $agg_src = (@$filters || $prefiltered) ? undef : $src;

	require HTML::D3;

	# ------------------------------------------------------------------ bar --
	if ($kind eq 'bar') {
		my $cat_col   = $encode->{cat}   // '';
		my $val_col   = $encode->{value} // '';
		return { error => 'Missing cat column for bar visual' } unless length $cat_col;
		return { error => "Column not found: $cat_col" }        unless $col_set{$cat_col};
		my $count_mode = ($val_col eq '__count__' || !length $val_col);
		return { error => "Column not found: $val_col" }
			unless $count_mode || $col_set{$val_col};

		my $m = _visual_measure($agg_fn, $val_col);
		return { error => $m->{error} } if $m->{error};

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by => [$cat_col], fn => $m->{fn},
			  val => $m->{val}, as => 'value' },
		);
		return { error => 'No plottable data' } unless @$agg;

		$title ||= "$m->{label} by $cat_col";
		my @bars   = map { [_decode_cell($_->{$cat_col}), $_->{value}] } @$agg;
		my $orient = _chart_orientation($options);
		# The bar page caps its bars as max_bars and stores the cap as
		# max_items; the seed has to carry it or a seeded canvas draws every
		# category where the page drew the top few and Other.
		my $max_bars = int($options->{max_items} // $options->{max_bars} // 0);
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_bar_chart_snippet(\@bars, {
				orientation => $orient,
				x_label     => $cat_col,
				id          => $svg_id,
				($max_bars > 0 ? (max_bars => $max_bars) : ()),
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# ------------------------------------------------------------------ pie --
	if ($kind eq 'pie') {
		my $cat_col = $encode->{cat}   // '';
		my $val_col = $encode->{value} // '';
		return { error => 'Missing cat or val column for pie visual' }
			unless length($cat_col) && length($val_col);
		return { error => "Column not found: $cat_col" } unless $col_set{$cat_col};
		my $count_mode = ($val_col eq '__count__');
		return { error => "Column not found: $val_col" }
			unless $count_mode || $col_set{$val_col};

		my $m = _visual_measure($agg_fn, $val_col);
		return { error => $m->{error} } if $m->{error};

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by => [$cat_col], fn => $m->{fn},
			  val => $m->{val}, as => 'value' },
		);
		return { error => 'No plottable data' } unless @$agg;

		$title ||= "$m->{label} by $cat_col";
		my @slices = map { [_decode_cell($_->{$cat_col}), $_->{value}] } @$agg;
		my $scheme = $options->{scheme} // 'tableau10';
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_pie_chart_snippet(\@slices, {
				donut        => $options->{donut} ? 1 : 0,
				legend       => 1,
				color_scheme => $scheme,
				id           => $svg_id,
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# -------------------------------------------------------------- line/graph --
	if ($kind eq 'line' || $kind eq 'graph') {
		my $x_col = $encode->{x} // '';
		my $y_col = $encode->{y} // '';
		return { error => 'Missing x or y column for line visual' }
			unless length($x_col) && length($y_col);
		return { error => "Column not found: $x_col" } unless $col_set{$x_col};
		return { error => "Column not found: $y_col" } unless $col_set{$y_col};

		# A card whose spec names a measure plots one point per x value rather
		# than one per row: the shape /graph?agg= draws, and the only shape that
		# makes sense when the x axis is a bucket.  The fold writes its result
		# back under the y column's own name, so the loop below is the same one
		# an unaggregated card runs, and the groups arrive in label order, which
		# for an ISO bucket is chronological order.
		my $rows = $vis_recs;
		my $m;
		if (defined $agg_fn) {
			$m = _visual_measure($agg_fn, $y_col);
			return { error => $m->{error} } if $m->{error};
			my $agg = $self->_grouped_totals(
				{ source => undef, records => $vis_recs },
				{ by => [$x_col], fn => $m->{fn}, val => $m->{val}, as => 'value' },
			);
			$rows = [ map { { %$_, $y_col => $_->{value} } } @$agg ];
		}

		my @pairs;
		for my $row (@$rows) {
			my $xv = $row->{$x_col} // ''; next unless length $xv;
			my $yn = _numeric_cell($row->{$y_col} // ''); next unless defined $yn;
			push @pairs, [_decode_cell($xv), $yn];
		}
		return { error => 'No plottable data' } unless @pairs;

		$title ||= $m ? "$m->{label} by $x_col" : "$y_col vs $x_col";
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_zoomable_line_chart_snippet(\@pairs, { id => $svg_id });
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# --------------------------------------------------------------- scatter --
	if ($kind eq 'scatter') {
		my $x_col = $encode->{x} // '';
		my $y_col = $encode->{y} // '';
		return { error => 'Missing x or y column for scatter visual' }
			unless length($x_col) && length($y_col);
		return { error => "Column not found: $x_col" } unless $col_set{$x_col};
		return { error => "Column not found: $y_col" } unless $col_set{$y_col};

		my @points;
		for my $row (@$vis_recs) {
			my $xv = _numeric_cell($row->{$x_col} // ''); next unless defined $xv;
			my $yv = _numeric_cell($row->{$y_col} // ''); next unless defined $yv;
			push @points, [$xv, $yv];
		}
		return { error => 'No plottable data' } unless @points;

		$title ||= "$y_col vs $x_col";
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_scatter_chart_snippet(\@points, {
				x_label => $x_col,
				y_label => $y_col,
				id      => $svg_id,
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# -------------------------------------------------------------- heatmap --
	if ($kind eq 'heatmap') {
		my $x_col   = $encode->{x}     // '';
		my $y_col   = $encode->{y}     // '';
		my $val_col = $encode->{value} // '';
		return { error => 'Missing x or y column for heatmap visual' }
			unless length($x_col) && length($y_col);
		return { error => "Column not found: $x_col" } unless $col_set{$x_col};
		return { error => "Column not found: $y_col" } unless $col_set{$y_col};
		return { error => "Column not found: $val_col" }
			if length($val_col) && !$col_set{$val_col};

		my (@x_order, @y_order, %seen_x, %seen_y);
		for my $row (@$vis_recs) {
			my $xv = $row->{$x_col} // ''; next unless length $xv;
			my $yv = $row->{$y_col} // ''; next unless length $yv;
			push @x_order, $xv unless $seen_x{$xv}++;
			push @y_order, $yv unless $seen_y{$yv}++;
		}
		my $m = _visual_measure($agg_fn, $val_col);
		return { error => $m->{error} } if $m->{error};

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by  => [$x_col, $y_col],
			  fn  => $m->{fn},
			  val => $m->{val},
			  as  => 'value' },
		);
		my %grid;
		for my $r (@$agg) {
			$grid{$r->{$x_col}}{$r->{$y_col}} = $r->{value};
		}
		my @triples = map {
			my ($raw_x, $xv) = ($_, _decode_cell($_));
			map { [$xv, _decode_cell($_), $grid{$raw_x}{$_} // 0] } @y_order
		} @x_order;
		return { error => 'No plottable data' } unless @triples;

		$title ||= "$m->{label} by $x_col and $y_col";
		my $scheme = $options->{scheme} // 'YlOrRd';
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_heatmap_snippet(\@triples, {
				x_label      => $x_col,
				y_label      => $y_col,
				val_label    => $m->{label},
				color_scheme => $scheme,
				show_values  => ($options->{show_values} ? 1 : 0),
				id           => $svg_id,
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# --------------------------------------------------------------- stacked --
	if ($kind eq 'stacked') {
		my $cat_col = $encode->{cat}    // '';
		my $seg_col = $encode->{series} // '';
		my $val_col = $encode->{value}  // '';
		return { error => 'Missing cat or series column for stacked visual' }
			unless length($cat_col) && length($seg_col);
		return { error => "Column not found: $cat_col" } unless $col_set{$cat_col};
		return { error => "Column not found: $seg_col" } unless $col_set{$seg_col};
		my $count_mode = (!length $val_col || $val_col eq '__count__');
		return { error => "Column not found: $val_col" }
			unless $count_mode || $col_set{$val_col};

		my $m = _visual_measure($agg_fn, $val_col);
		return { error => $m->{error} } if $m->{error};

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by  => [$cat_col, $seg_col],
			  fn  => $m->{fn},
			  val => $m->{val},
			  as  => 'value' },
		);
		my @data = map {
			my ($c, $s) = ($_->{$cat_col}//'', $_->{$seg_col}//'');
			(length $c && length $s)
				? { cat => $c, seg => $s, val => $_->{value} }
				: ()
		} @$agg;
		return { error => 'No plottable data' } unless @data;

		$title ||= "$m->{label} by $cat_col and $seg_col";
		my $scheme = $options->{scheme} // 'tableau10';
		my $orient = (_chart_orientation($options) eq 'horizontal') ? 'h' : 'v';
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_stacked_bar_snippet(\@data, {
				scheme  => $scheme,
				x_label => $cat_col,
				orient  => $orient,
				id      => $svg_id,
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# ---------------------------------------------------------------- combo --
	if ($kind eq 'combo') {
		my $x_col    = $encode->{cat}      // $encode->{x}    // '';
		my $bar_col  = $encode->{bar_val}  // $encode->{bar}  // '';
		my $line_col = $encode->{line_val} // $encode->{line} // '';
		return { error => 'Missing cat, bar_val, or line_val for combo visual' }
			unless length($x_col) && length($bar_col) && length($line_col);
		return { error => "Column not found: $x_col"    } unless $col_set{$x_col};
		return { error => "Column not found: $bar_col"  } unless $col_set{$bar_col};
		return { error => "Column not found: $line_col" } unless $col_set{$line_col};

		# One card, one function: a combo aggregates both its series the same
		# way, so the two cannot be read against different arithmetic by
		# accident.
		my $bar_m  = _visual_measure($agg_fn, $bar_col);
		my $line_m = _visual_measure($agg_fn, $line_col);
		return { error => $bar_m->{error}  } if $bar_m->{error};
		return { error => $line_m->{error} } if $line_m->{error};

		my $bar_rows = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by => [$x_col], fn => $bar_m->{fn}, val => $bar_m->{val},  as => 'bar_val' },
		);
		my $line_rows = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by => [$x_col], fn => $line_m->{fn}, val => $line_m->{val}, as => 'line_val' },
		);
		my (%bar_map, %line_map, @x_order, %x_seen);
		for my $r (@$bar_rows) {
			my $xv = _decode_cell($r->{$x_col} // ''); next unless length $xv;
			push @x_order, $xv unless $x_seen{$xv}++;
			$bar_map{$xv} = $r->{bar_val};
		}
		for my $r (@$line_rows) {
			my $xv = _decode_cell($r->{$x_col} // ''); next unless length $xv;
			push @x_order, $xv unless $x_seen{$xv}++;
			$line_map{$xv} = $r->{line_val};
		}
		return { error => 'No plottable data' } unless @x_order;

		my @data = map { { x => $_, bar_val => $bar_map{$_}, line_val => $line_map{$_} } }
		           @x_order;
		# Sum keeps the columns in the title because that is what the card has
		# always said; count needs no column, so it reads as the tally it is.
		$title ||= ($bar_m->{fn} eq 'sum')
			? "$bar_col and $line_col by $x_col"
			: ($bar_m->{fn} eq 'count')
				? "Count by $x_col"
				: "$bar_m->{fn} of $bar_col and $line_col by $x_col";
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_combo_snippet(\@data, {
				bar_label  => $bar_col,
				line_label => $line_col,
				id         => $svg_id,
			});
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# --------------------------------------------------------------- treemap --
	if ($kind eq 'treemap') {
		my $cat_col = $encode->{group} // $encode->{cat}   // '';
		my $val_col = $encode->{size}  // $encode->{value} // '';
		return { error => 'Missing group column for treemap visual' } unless length $cat_col;
		return { error => "Column not found: $cat_col" } unless $col_set{$cat_col};
		my $count_mode = (!length $val_col || $val_col eq '__count__');
		return { error => "Column not found: $val_col" }
			unless $count_mode || $col_set{$val_col};

		my $m = _visual_measure($agg_fn, $val_col);
		return { error => $m->{error} } if $m->{error};

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by  => [$cat_col],
			  fn  => $m->{fn},
			  val => $m->{val},
			  as  => 'value' },
		);
		return { error => 'No plottable data' } unless @$agg;

		$title ||= "$m->{label} by $cat_col";
		my $scheme = $options->{scheme} // 'tableau10';
		# The snippet takes one row per tile as { path, value }, the shape the
		# treemap page builds; a [label, value] pair is not a path and croaks.
		my @tiles = map {
			{ path => 'Root/' . _decode_cell($_->{$cat_col}), value => $_->{value} }
		} @$agg;
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_treemap_snippet(\@tiles, { scheme => $scheme, id => $svg_id });
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# ------------------------------------------------------------ histogram --
	if ($kind eq 'histogram') {
		my $col = $encode->{value} // $encode->{col} // '';
		return { error => 'Missing col for histogram visual' } unless length $col;
		return { error => "Column not found: $col" }           unless $col_set{$col};

		my @values;
		for my $row (@$vis_recs) {
			my $v = _numeric_cell($row->{$col} // '');
			push @values, $v if defined $v;
		}
		return { error => 'No plottable data' } unless @values;

		my $bins = int($options->{bins} // 10);
		$bins = 1   if $bins < 1;
		$bins = 200 if $bins > 200;
		my $min_v = min(@values);
		my $max_v = max(@values);
		my @bin_data;
		if ($min_v == $max_v) {
			push @bin_data, { label => "$min_v", count => scalar @values,
			                  lo => $min_v, hi => $min_v };
		} else {
			my $raw_w = ($max_v - $min_v) / $bins;
			my $width = sprintf('%.10g', $raw_w) + 0;
			$width = $raw_w if $width <= 0;
			my $fmt = ($width == int($width)) ? '%d' : '%g';
			my (@bin_counts, @bin_los);
			for my $i (0 .. $bins - 1) {
				push @bin_los,    $min_v + $i * $width;
				push @bin_counts, 0;
			}
			for my $v (@values) {
				my $idx = POSIX::floor(sprintf('%.10g', ($v - $min_v) / $width) + 0);
				$idx = $bins - 1 if $idx >= $bins;
				$idx = 0         if $idx < 0;
				$bin_counts[$idx]++;
			}
			for my $i (0 .. $bins - 1) {
				next unless $bin_counts[$i];
				my $lo  = $bin_los[$i];
				my $hi  = $lo + $width;
				push @bin_data, {
					label => sprintf("[${fmt},${fmt})", $lo, $hi),
					count => $bin_counts[$i],
					lo    => $lo,
					hi    => $hi,
				};
			}
		}

		$title ||= "Distribution of $col";
		my $sn = HTML::D3->new(title => $title, width => 480, height => 320, responsive => 1)
			->render_histogram_snippet(\@bin_data, { binned => 1, x_label => $col, id => $svg_id });
		my $html = $sn->{html};
		utf8::decode($html) unless utf8::is_utf8($html);
		return { html => $html, title => $title };
	}

	# ------------------------------------------------------------------- map --
	if ($kind eq 'map') {
		my $map = $self->_map_data(
			$vis_recs, $columns, $encode, $options, $spec_key, $vis_id,
		);
		return { error => $map->{error} } if $map->{error};

		my $html = '';
		if ($map->{map_body}) {
			$html .= '<div class="canvas-map-wrap">' . $map->{map_body} . '</div>';
		}
		if ($map->{marker_count}) {
			$html .= '<p class="map-summary">Plotting '
				. $map->{marker_count} . ' marker' . ($map->{marker_count} == 1 ? '' : 's')
				. ' for ' . $map->{row_count} . ' of ' . $map->{source_rows}
				. ' row' . ($map->{source_rows} == 1 ? '' : 's') . '.</p>';
		}
		if (@{ $map->{messages} }) {
			$html .= '<div class="map-notes" role="status"><ul>'
				. join('', map {
					'<li class="map-note" data-key="' . xml_escape($_->{key} // '') . '">'
					. xml_escape($_->{text} // '') . '</li>'
				} @{ $map->{messages} })
				. '</ul></div>';
		}

		return {
			html  => $html,
			title => $title || $map->{title},
			head  => ($map->{map_head} // ''),
		};
	}

	# ------------------------------------------------------------ word cloud --
	# A card that draws the words of a text column, the way GET /wordcloud does,
	# from the same counted and ranked words (see _wordcloud_counts).  It is the
	# one kind with no value column and no measure: the size of a word is how
	# many of the card's own rows contain it, so a card the reader has filtered
	# shows the words of those rows.
	if ($kind eq 'wordcloud') {
		my $col = $encode->{col} // '';
		return { error => 'Missing col for word cloud visual' } unless length $col;
		return { error => "Column not found: $col" } unless $col_set{$col};

		my $topn   = _wordcloud_option($options->{topn},   50, 1, 500);
		my $minlen = _wordcloud_option($options->{minlen},  3, 1, 64);

		my $cloud = _wordcloud_counts(
			$vis_recs, $col, $topn, $minlen, $options->{stop},
		);
		my @tags = @{ $cloud->{words} };

		$title ||= "Words in $col";
		my $summary = $cloud->{distinct}
			? scalar(@tags) . ' of ' . $cloud->{distinct} . ' different word'
				. ($cloud->{distinct} == 1 ? '' : 's')
				. ' &middot; ' . $cloud->{total} . ' word'
				. ($cloud->{total} == 1 ? '' : 's')
				. ' in ' . $cloud->{rows} . ' row'
				. ($cloud->{rows} == 1 ? '' : 's')
			: '';

		if (!@tags) {
			return {
				html  => '<div class="wordcloud-card"><p class="wordcloud-empty">'
					. 'No words: no row in this view has text in '
					. xml_escape($col) . ' at least ' . $minlen
					. ' characters long.</p></div>',
				title => $title,
			};
		}

		# HTML::TagCloud ranks the words and works out each one's level; the size
		# it would give that level is 12px plus the level.  The size is written on
		# the word here instead of using the module's style sheet, because that
		# sheet scopes itself through #htmltagcloud -- an id only one element on a
		# page may carry, and a canvas may hold two word-cloud cards.  The level,
		# the part that is actually arithmetic, stays the module's.  The module is
		# handed the word as it is and the escaping happens on the way out, because
		# the same word is both what the reader reads and, unescaped, the filter a
		# click on it asks for.
		require HTML::TagCloud;
		my $ranked = HTML::TagCloud->new(levels => 18);
		$ranked->add_static($_->{word}, $_->{count}) for @tags;

		# A word is a control, not a label.  Clicking one cross-filters the canvas
		# the way a chart mark does -- ?cf=...&cv=<card>, so every other card is
		# narrowed and this one stays drawn in full -- but with C<contains> rather
		# than C<eq>: a word is a token inside a cell, not the cell's whole value,
		# so no row equals it.  The href carries the whole URL the click asks for,
		# so a word filters even before the page's script runs; the script takes
		# the click over only to keep the rest of the query string (a bound
		# parameter, a drill path) and to record the undo step, as it does for a
		# mark.  A card drawn with no index -- by anything that is not a canvas
		# render -- names no source, so the filter applies to every card.
		my $cv = (defined $vis_id && $vis_id =~ /\A\d+\z/) ? "&cv=$vis_id" : '';
		my $spans = join(' ', map {
			my $word  = $_->{name};
			my $label = xml_escape("Filter by $col: $word");
			# aria-describedby names the canvas's cross-filter help, which covers
			# a word as well as a chart mark: the label says which word this is,
			# the help says what pressing Enter on it does.
			'<a class="wordcloud-word" href="?cf='
				. _percent_encode("$col:contains:$word") . $cv . '"'
				. ' data-cf-value="' . xml_escape($word) . '"'
				. ' style="font-size:' . (12 + $_->{level}) . 'px"'
				. ' aria-label="' . $label . '" title="' . $label . '"'
				. ' aria-describedby="cf-help">'
				. xml_escape($word) . '</a>'
		} $ranked->tags(scalar @tags));

		return {
			html  => '<div class="wordcloud-card" data-col="' . xml_escape($col) . '">'
				. '<p class="wordcloud-cloud">' . $spans . '</p>'
				. '<p class="wordcloud-summary">' . $summary . '</p></div>',
			title => $title,
		};
	}

	# ----------------------------------------------------------------- table --
	if ($kind eq 'table') {
		return { error => 'No data to display' } unless @$vis_recs;
		my @cols = @$columns;
		if (ref $encode->{columns} eq 'ARRAY' && @{ $encode->{columns} }) {
			# A table names the columns it shows, and it is the one kind that
			# could name a column nothing produces: the heading printed and
			# every cell under it was empty, which reads as missing data rather
			# than as a card drawn against a column that is not there.  Whether
			# a plan produces a name is not something a reader can see from the
			# card, so the name is refused here as the charts below refuse it.
			for my $c (@{ $encode->{columns} }) {
				next if ref $c || !length $c;
				return { error => "Column not found: $c" } unless $col_set{$c};
			}
			@cols = @{ $encode->{columns} };
		}

		$title ||= 'Table';
		my $max_rows_t = int($options->{rows} // 50);
		$max_rows_t = 200 if $max_rows_t > 200;
		$max_rows_t = 1   if $max_rows_t < 1;

		my $html = '<div class="visual-table-wrap"><table class="data-table">'
		         . '<thead><tr>';
		for my $c (@cols) {
			(my $ch = $c) =~ s/&/&amp;/g; $ch =~ s/</&lt;/g; $ch =~ s/>/&gt;/g;
			$html .= "<th>$ch</th>";
		}
		$html .= '</tr></thead><tbody>';
		my $count = 0;
		for my $row (@$vis_recs) {
			last if $count++ >= $max_rows_t;
			$html .= '<tr>';
			for my $c (@cols) {
				my $v = $row->{$c} // '';
				$v =~ s/&/&amp;/g; $v =~ s/</&lt;/g; $v =~ s/>/&gt;/g;
				$html .= "<td>$v</td>";
			}
			$html .= '</tr>';
		}
		$html .= '</tbody></table></div>';
		return { html => $html, title => $title };
	}

	return { error => "Unknown visual kind: $kind" };
}

# _vis_cf_col(\%vis) -> $col_name | undef
#
# Returns the primary categorical dimension of a visual -- the column that
# makes sense to cross-filter on when the user clicks a mark.
# Priority: cat > group > x > col (histogram).  Series/size/val are measures,
# not dimensions, so they are intentionally excluded.
sub _vis_cf_col {
	my ($vis) = @_;
	my $enc = $vis->{encode} // {};
	for my $key (qw(cat group x col)) {
		return $enc->{$key} if length($enc->{$key} // '');
	}
	return undef;
}

# GET /a/:id  -- render a saved canvas
#
# redirects to the reconstructed data-view URL when the
# canvas has no visuals array.
# renders N visuals in a CSS grid when visuals are present.
# _bound_canvas_params($self, $a, $lookup) -> (\%bound, \@errors)
#
# Resolve the canvas's declared parameters against URL values.  $lookup takes a
# parameter name ("p.<name>") and returns the raw string from the request or
# undef; the default is used when it returns undef.  Numbers are coerced and
# range-checked, and an error is reported rather than a value bound, so the
# canvas page and a card appended to it draw the same parameter values.
sub _bound_canvas_params :Protected ($self, $a, $lookup) {
	my %param_defs = %{ $a->{params} // {} };
	my (%bound_params, @errors);

	for my $pname (sort keys %param_defs) {
		my $def     = $param_defs{$pname};
		my $type    = $def->{type}    // 'string';
		my $default = $def->{default} // '';
		my $raw     = $lookup->("p.$pname");
		my $val     = defined $raw ? $raw : $default;

		if ($type eq 'number') {
			require Scalar::Util;
			unless (Scalar::Util::looks_like_number($val)) {
				push @errors, sprintf($MESSAGES{error_param_type}, $pname);
				next;
			}
			$val = $val + 0;
			my ($lo, $hi) = ($def->{min}, $def->{max});
			if (defined $lo && $val < $lo) {
				push @errors, sprintf($MESSAGES{error_param_range},
					$pname, $lo, defined $hi ? $hi : '+inf');
				next;
			}
			if (defined $hi && $val > $hi) {
				push @errors, sprintf($MESSAGES{error_param_range},
					$pname, defined $lo ? $lo : '-inf', $hi);
				next;
			}
		}
		$bound_params{$pname} = $val;
	}

	return (\%bound_params, \@errors);
}

sub canvas_render ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(text => $MESSAGES{error_analysis_id_invalid}, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	unless (exists $analyses->{$id}) {
		# An HTML page, not plain text, so the user keeps the breadcrumb and
		# the site navigation.  No canvas_id: there is nothing to delete.
		my ($platform, $language) = $self->_resolve_template;
		return $self->render(
			handler     => 'tt',
			template    => "$platform/$language/canvas_error",
			format      => 'html',
			status      => 404,
			title       => 'Canvas not found',
			canvas_name => $id,
			error_msg   => sprintf($MESSAGES{error_analysis_not_found}, $id),
			error_specs => [],
			language    => $language,
		);
	}
	my $a = $analyses->{$id};

	# freshness: compare each dataset's current mtime against
	# the analysis's saved updated timestamp.  Flag stale when any source
	# is newer.  Non-fatal: the canvas renders with a stale banner.
	my ($freshness_stale, $freshness_msg, $freshness_source_mtime) = (0, '', '');
	{
		my $analysis_updated = $a->{updated} // 0;
		# Parse ISO-8601 to epoch for comparison if needed.
		if ($analysis_updated && $analysis_updated =~ /
			\A
			(\d{4}) - (\d{2}) - (\d{2})	# $1 yr  $2 mon  $3 day
			T
			(\d{2}) : (\d{2}) : (\d{2})	# $4 hr  $5 min  $6 sec
			Z? \z
		/x) {
			require POSIX;
			$analysis_updated = POSIX::mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
		}
		my $newest_src_mtime = 0;
		for my $ds (@{ $a->{datasets} // [] }) {
			my $spec = $ds->{spec} // '';
			next unless $spec =~ /\A(?:table|path):/;
			my ($src) = eval { $self->_open_spec($spec) };
			next unless $src && $src->can('updated');
			my $mt = eval { $src->updated } // 0;
			$newest_src_mtime = $mt if $mt > $newest_src_mtime;
		}
		if ($newest_src_mtime && $analysis_updated && $newest_src_mtime > $analysis_updated) {
			$freshness_stale = 1;
			$freshness_msg   = $MESSAGES{freshness_stale_msg};
			require POSIX;
			$freshness_source_mtime = POSIX::strftime('%Y-%m-%d %H:%M UTC', gmtime($newest_src_mtime));
		}
	}

	# if visuals array is non-empty, render the canvas.
	my @visuals = @{ $a->{visuals} // [] };
	if (@visuals) {

		# bound parameters from URL ?p.<name>=<value>.
		# Parameter definitions live in the analysis: params => { name => { type, default, min, max } }.
		# URL values are type-coerced and range-checked; out-of-range returns 400.
		my ($bound_ref, $p_errors) = $self->_bound_canvas_params(
			$a, sub { $self->param($_[0]) },
		);
		my %bound_params = %$bound_ref;
		if (@$p_errors) {
			return $self->render(
				text   => join('; ', @$p_errors),
				status => 400,
			);
		}

		# Build stash list for parameter bar: sorted by name.
		my %param_defs = %{ $a->{params} // {} };
		my @canvas_params = map {
			my $def = $param_defs{$_};
			{
				name    => $_,
				type    => ($def->{type}    // 'string'),
				value   => $bound_params{$_},
				default => ($def->{default} // ''),
				min     => (defined $def->{min} ? $def->{min} : ''),
				max     => (defined $def->{max} ? $def->{max} : ''),
			}
		} sort keys %param_defs;

		# Everything else the canvas is showing has to survive a change of time
		# range, so the control carries the rest of this page's query string: the
		# cross-filter (cf/vc), the drill path (dd/dl), the calculated columns
		# (c) and the what-if parameter values (p.<name>).
		my @canvas_range_hidden;
		{
			my $q = $self->req->query_params;
			for my $name ($q->names) {
				next if $name eq 'range' || $name eq 'rcol';
				push @canvas_range_hidden,
					map { { name => $name, value => $_ } } @{ $q->every_param($name) // [] };
			}
		}

		my ($src, $records, $columns) = $self->_build_canvas_pipeline($a);
		unless (defined $records) {
			my ($platform, $language) = $self->_resolve_template;
			my @specs = map { $_->{spec} // '' } @{ $a->{datasets} // [] };
			return $self->render(
				handler     => 'tt',
				template    => "$platform/$language/canvas_error",
				format      => 'html',
				status      => 422,
				title       => 'Canvas unavailable',
				canvas_id   => $id,
				canvas_name => ($a->{name} // $id),
				error_msg   => 'The data source for this canvas could not be opened.',
				error_specs => \@specs,
				language    => $language,
			);
		}

		# Apply calc fields with bound params so expressions may reference them.
		my $canvas_spec_key = ($a->{datasets}[0]{spec} // '');
		eval {
			($records, $columns) = $self->_apply_calc_fields(
				$records, $columns,
				{ params => \%bound_params, spec_key => $canvas_spec_key }
			);
		};
		if ($@) {
			(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
			return $self->render(text => $e, status => 400);
		}

		# cs= belongs to the page, not to a card: one plan, run per card on that
		# card's own rows (see _render_visual_html).  A fault is the page's 400 --
		# the same message repeated on every card would be noise, not a report.
		my $cross_row = $self->_cross_row_specs($columns);
		if ($cross_row && $cross_row->{error}) {
			return $self->render(text => $cross_row->{error}, status => 400);
		}

		# The relative time range the page names (?range=/?rcol=) narrows every
		# card, before the per-card cross-filter.  The before_dispatch hook has
		# already resolved it into the f= params the routes apply, but the canvas
		# builds its own pipeline, so it applies the range itself from the same
		# two specs.
		if (my $range = $self->stash('time_range')) {
			for my $spec (@{ $self->stash('range_specs') // [] }) {
				$records = _apply_filter_spec($records, $spec);
			}
		}

		# cross-filter state from URL params.
		# ?cf=col:op:val (repeatable) filters all visuals except the source.
		# ?cv=N identifies the source visual (shown unfiltered but highlighted).
		# Semantics: self-highlighting (source shown in full; others filtered).
		# Multiple simultaneous selections are not supported in this version.
		my @cf_specs  = grep { /\S/ } @{ $self->every_param('cf') // [] };
		my $cf_source = defined($self->param('cv'))
			? int($self->param('cv')) : -1;
		my $cf_active = !!@cf_specs;

		# Build the "clear cross-filter" URL for the chip close button.
		my $cf_clear_url = $self->req->url->clone;
		$cf_clear_url->query->remove('cf')->remove('cv');
		$cf_clear_url = $cf_clear_url->to_string;

		# Human-readable summary for the cross-filter chip, e.g. "region = North".
		my $cf_display = '';
		if ($cf_active) {
			my @parts;
			for my $spec (@cf_specs) {
				my ($col, $op, $val) = split /:/, $spec, 3;
				$val //= '';
				my $sym = ($op eq 'eq') ? '='  : ($op eq 'ne') ? '!='
				        : ($op eq 'lt') ? '<'  : ($op eq 'le') ? '<='
				        : ($op eq 'gt') ? '>'  : ($op eq 'ge') ? '>='
				        : ($op eq 'contains') ? 'contains'
				        : ($op eq 'starts')   ? 'starts with'
				        : $op;
				push @parts, "$col $sym $val";
			}
			$cf_display = join(' AND ', @parts);
		}

		# drill-through and drill-down.
		#
		# Drill-through: when cross-filters are active, build a URL to the
		# primary data source with those filters applied as ?f= params so the
		# user can inspect the raw rows behind the selection.
		my $drillthrough_url = '';
		if (@cf_specs) {
			my $ds0   = ($a->{datasets} // [])->[0];
			my $spec0 = ($ds0  // {})->{spec} // '';
			my $base  = $self->_spec_to_url($spec0);
			if ($base ne '/') {
				my $sep = ($base =~ /\?/) ? '&' : '?';
				for my $cf (@cf_specs) {
					$base .= $sep . 'f=' . url_escape($cf);
					$sep = '&';
				}
				$drillthrough_url = $base;
			}
		}

		# Drill-down: navigate a named hierarchy one level at a time.
		# ?dd=<name> names the active hierarchy; ?dl=<N> is the current level
		# (0-based); accumulated ?cf= params carry the drill path.
		my $dd_name  = $self->param('dd') // '';
		my $dl_raw   = $self->param('dl');
		my $dd_level = (defined $dl_raw && length $dl_raw) ? int($dl_raw) : 0;
		$dd_level    = 0 if $dd_level < 0;

		my ($dd_hier) = grep { ($_->{name} // '') eq $dd_name }
		                     @{ $a->{hierarchies} // [] };

		# A drill needs a first level to name: a hierarchy with none answers no
		# press, and #cf-help has no column it could call the one that drills.
		my $drill_active = ($dd_hier && length $dd_name
			&& @{ $dd_hier->{levels} // [] }) ? 1 : 0;
		my $drill_col    = '';
		my @drill_crumb  = ();
		my $drill_max    = 0;

		if ($drill_active) {
			my @levels = @{ $dd_hier->{levels} // [] };
			$drill_max = $#levels;
			# Allow dl up to scalar(@levels) -- one past the last valid level
			# means "all levels drilled through" (drill-through mode).
			my $dl_cap = scalar @levels;
			$dd_level  = $dl_cap if $dd_level > $dl_cap;
			$drill_col = $levels[$dd_level] // '';

			# Extract drilled values: each crossed level contributes a
			# cf=<col>:eq:<val> param in the URL.
			my %cf_by_col;
			for my $cf (@cf_specs) {
				my ($col, $op, $val) = split /:/, $cf, 3;
				$cf_by_col{$col} = ($val // '')
					if length($col // '') && ($op // '') eq 'eq';
			}

			# "All" crumb -- keep ?dd=, remove dl/cf/cv.
			my $all_url = $self->req->url->clone;
			$all_url->query->remove('dl')->remove('cf')->remove('cv');
			push @drill_crumb, {
				label => 'All',
				url   => ($dd_level > 0 ? $all_url->to_string : ''),
				cur   => ($dd_level == 0 ? 1 : 0),
			};

			# One crumb per drilled value (levels 0 .. dd_level-1).
			for my $i (0 .. $dd_level - 1) {
				my $col_i   = $levels[$i];
				my $val_i   = $cf_by_col{$col_i} // '';
				my $is_last = ($i == $dd_level - 1);

				# Back-link: keep ?dd=, cf for levels 0..i, dl=i+1.
				my $back_url = '';
				unless ($is_last) {
					my $u = $self->req->url->clone;
					$u->query->remove('dl')->remove('cf')->remove('cv');
					$u->query->append('dl' => $i + 1);
					for my $j (0 .. $i) {
						my $val_j = $cf_by_col{ $levels[$j] };
						$u->query->append('cf' => "$levels[$j]:eq:$val_j")
							if defined $val_j;
					}
					$back_url = $u->to_string;
				}

				push @drill_crumb, {
					label => $val_i,
					url   => $back_url,
					cur   => $is_last ? 1 : 0,
				};
			}
		}

		# Pre-build CSS grid position strings to avoid TT hash-key lookups, and
		# keep the two spans of a saved card so the page can print the card's size
		# on the card before the script has measured anything.
		my %layout_pos;
		my %layout_size;
		for my $lp (@{ $a->{layout} // [] }) {
			my ($x, $y, $w, $h) = @{$lp}{qw(x y w h)};
			next unless defined $x && defined $y && defined $w && defined $h;
			$layout_pos{ $lp->{visual} // '' } =
				"grid-column:${x}/span ${w};grid-row:${y}/span ${h}";
			$layout_size{ $lp->{visual} // '' } = [$w, $h];
		}

		my @rendered;
		my $canvas_map_head = '';
		for my $i (0 .. $#visuals) {
			my $vis = $visuals[$i];

			# Apply cross-filter to every visual except the source (self-highlighting).
			my $vis_recs = $records;
			if ($cf_active && $i != $cf_source) {
				for my $cfs (@cf_specs) {
					$vis_recs = _apply_filter_spec($vis_recs, $cfs);
				}
			}

			my $result = $self->_render_visual_html(
				$vis, $vis_recs, $columns, $src, $i, $canvas_spec_key,
				($cf_active && $i != $cf_source ? 1 : 0),
				$cross_row,
			);
			$canvas_map_head ||= $result->{head} // '';
			push @rendered, {
				id        => $i,
				title     => ($vis->{title} // $result->{title} // ('Visual ' . ($i + 1))),
				html      => $result->{html}  // '',
				error     => $result->{error} // '',
				kind      => $vis->{kind}     // '',
				style     => $layout_pos{$i}  // '',
				# The saved spans, or nothing: a card with no saved position is
				# placed by the browser, and only the script can measure that.
				w         => (defined $layout_size{$i} ? $layout_size{$i}[0] : undef),
				h         => (defined $layout_size{$i} ? $layout_size{$i}[1] : undef),
				cf_col    => (_vis_cf_col($vis) // ''),
				cf_source => ($i == $cf_source ? 1 : 0),
			};
		}

		# bookmarks list for the toolbar panel.
		my @canvas_bookmarks = @{ $a->{bookmarks} // [] };
		# Pre-encode as JSON for the JS canvasBookmarks variable.
		# Escape </ so the array literal cannot prematurely close a <script> tag.
		(my $bm_json = encode_json(\@canvas_bookmarks)) =~ s{</}{<\\/}g;

		my $canvas_columns_json = encode_json([
			map { { name => $_, numeric => _column_is_numeric($records, $_) ? 1 : 0 } }
				@$columns
		]);
		# The JSON is written into a <script> block.  Escape '<' so a column
		# name containing markup cannot close the tag, as the chart spec is.
		$canvas_columns_json =~ s{<}{\\u003c}g;

		# The columns the page's own plan produces, for the panel that repairs a
		# card's: a card that takes the page's plan plots whatever that plan makes,
		# so the panel can only tell a reader what a change would cost it if it
		# knows the page's columns too.
		my $page_aliases = ($cross_row && ref $cross_row eq 'HASH')
			? [ map { $_->{as} } @{ $cross_row->{specs} // [] } ] : [];
		my $canvas_page_aliases_json = encode_json($page_aliases);
		$canvas_page_aliases_json =~ s{<}{\\u003c}g;

		my ($platform, $language) = $self->_resolve_template;
		return $self->render(
			handler      => 'tt',
			template     => "$platform/$language/canvas",
			format       => 'html',
			title        => $a->{name},
			canvas_id    => $id,
			canvas_name  => $a->{name},
			canvas_data_url  => ($self->_analysis_to_url($a) // ''),
			canvas_columns_json => $canvas_columns_json,
			canvas_page_aliases_json => $canvas_page_aliases_json,
			# The same menu the table page's cross-row panel renders, so a card
			# can offer the functions the pass actually knows.
			cross_row_menu => \@CROSS_ROW_MENU,
			visuals      => \@rendered,
			canvas_params    => \@canvas_params,
			canvas_bookmarks => \@canvas_bookmarks,
			canvas_bookmarks_json => $bm_json,
			canvas_time_range  => $self->stash('time_range'),
			canvas_time_range_col => ($self->stash('time_range') ? $self->stash('time_range')->{col} : ''),
			canvas_time_range_clear_url => (do {
				my $u = $self->req->url->clone;
				$u->query->remove('range')->remove('rcol');
				$self->stash('time_range') ? $u->to_string : '';
			}),
			canvas_range_cols  => [ @$columns ],
			canvas_range_hidden => \@canvas_range_hidden,
			cf_active        => $cf_active    ? 1 : 0,
			cf_display       => $cf_display,
			cf_clear_url     => $cf_clear_url,
			drillthrough_url => $drillthrough_url,
			drill_active     => $drill_active  ? 1 : 0,
			# A drill is a hierarchy that exists, not a name in the query string:
			# a bookmark can outlive the hierarchy it was saved on, and a page
			# that said it was drilled when nothing answered would stop making
			# its marks controls and have no column to name in #cf-help.
			drill_name       => ($drill_active ? $dd_name : ''),
			drill_level      => $dd_level,
			drill_col        => $drill_col,
			drill_crumb      => \@drill_crumb,
			drill_max        => $drill_max,
			extra_head       => $canvas_map_head,
			back_url         => '/',
			back_label       => 'Home',
			freshness_stale  => $freshness_stale,
			freshness_msg    => $freshness_msg,
			freshness_source_mtime => $freshness_source_mtime,
			language     => $language,
		);
	}

	# no visuals yet -- reconstruct the data-view URL and redirect.
	my $url = $self->_analysis_to_url($a);
	return $self->render(text => 'Cannot reconstruct URL from this analysis', status => 422)
		unless defined $url;

	$self->redirect_to($url);
}

# _run_export_pipeline($self) -> ($records, \@columns, $left_label) or ()
#
# Purpose: Thin wrapper over _run_pipeline_source that additionally applies
#          f= filters, d=1 dedup, and page/per_page pagination.  Used by
#          export_data, export_write, folder_view, and import_url (row-viewing
#          routes that do not need the source object for aggregation).
# Entry:   Reads "l=", "j=" (repeatable), "c=" (repeatable), "f=" (repeatable),
#          "d=", "page=", "per_page=" query/body params.
# Exit:    On success: ($filtered_arrayref, \@column_names, $left_label_string).
#          On failure: empty list (left table not found / fetch error).
sub _run_export_pipeline :Protected ($self) {
	my (undef, $records, $columns, $left_label) = $self->_run_pipeline_source;
	return () unless defined $records;

	# The export honours span= like the page it was linked from, and accepts the
	# dimension params of the aggregating routes so a chart's own URL can be
	# pasted into /export and mean the same thing.
	my $span = $self->_span_calc_spec($columns, 'cat', 'x', 'rows', 'group');
	if ($span && $span->{error}) {
		$self->render(text => $span->{error}, status => 400);
		return ();
	}

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		$self->render(text => $e, status => 400);
		return ();
	}

	return () unless $self->_reduce_or_render(\$records, \$columns);

	my @columns = @{ $columns // [] };

	# d=1 has been applied by _reduce_or_render, before the cross-row pass.

	# Sort support for /export: applied in memory after filtering/dedup.
	my $sort = $self->param('sort');
	my $dir  = ($self->param('dir') // 'asc') =~ /\Adesc\z/i ? 'desc' : 'asc';
	if (defined $sort && grep { $_ eq $sort } @columns) {
		@$records = sort { ($a->{$sort} // '') cmp ($b->{$sort} // '') } @$records;
		@$records = reverse @$records if $dir eq 'desc';
	} elsif (defined $sort) {
		carp $self->_i18n('error_sort_column', $sort);
	}

	# Server-side pagination for /export.
	if (defined $self->param('page') || defined $self->param('per_page')) {
		my ($page, $per_page, $offset) = $self->_pagination;
		my $total    = scalar @$records;
		my $has_next = ($total > $offset + $per_page) ? 1 : 0;
		my @page_recs = splice(@$records, $offset, $per_page);
		$records = \@page_recs;
		$self->stash(export_has_next => $has_next, export_page => $page, export_per_page => $per_page);
	}

	return ($records, \@columns, $left_label);
}

# _decode_cell($s) -> $character_string
#
# Purpose: Ensure $s is a Perl character string, not raw UTF-8 bytes.
#          URL-fetched data (via LWP::UserAgent::Cached + D::A HTML parsing)
#          arrives as byte strings without the UTF-8 flag set.  encode_json
#          then treats each byte as a Latin-1 code point and re-encodes it,
#          producing mojibake (e.g. an o-umlaut character displayed as two garbage bytes).  This helper
#          upgrades the flag in-place on a copy so the original hash key is
#          unchanged but the value passed to HTML::D3 is a proper character.
# Entry:   $s -- any defined scalar (undef returned as-is).
# Exit:    The same string value, but with the UTF-8 flag set if it was absent.
sub _decode_cell {
	my $s = shift;
	return $s unless defined $s;
	utf8::decode($s) unless utf8::is_utf8($s);
	$s;
}

# _serialize_csv($records, \@columns) -> $utf8_string
#
# Purpose: Build a complete RFC 4180 CSV document (header + data rows) from
#          $records.  Shared by _render_csv (HTTP download) and the csv branch
#          of export_write (filesystem write) to eliminate duplicated logic.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns a UTF-8 Perl string ending with CRLF.
#
# Optimisation: rows are collected in @lines and joined in one operation.
# The previous pattern ($out .= _csv_row(...) per row) triggers O(N) string
# reallocations; joining a pre-built array is a single O(total_bytes) allocation.
# For exports of thousands of rows the difference is measurable.
#
# XS note: for very large exports, replacing _csv_row with Text::CSV_XS
# (available from CPAN) would further reduce serialisation time -- its C-level
# implementation is roughly 5-10x faster than the pure-Perl version here.
sub _serialize_csv {
	my ($records, $columns) = @_;
	my @lines = _csv_row(@$columns);
	for my $row (@$records) {
		push @lines, _csv_row(map { $row->{$_} } @$columns);
	}
	return encode('UTF-8', join('', @lines));
}

# _render_csv($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Serialise $records to RFC 4180 CSV and emit as a UTF-8 download.
# Entry:   $name is a safe filename stem (alphanumeric/underscore).
# Exit:    Renders the Mojolicious response; does not return a meaningful value.
# Side Effects: Writes HTTP response headers and body.
sub _render_csv :Protected ($self, $records, $columns, $name) {
	$self->stash(buffer => 0);
	$self->res->headers->content_type('text/csv; charset=UTF-8');
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.csv"});
	$self->render(data => _serialize_csv($records, $columns));
}

# _render_sqlite($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Write $records to a SQLite database and emit it as a binary download.
# Entry:   $name is a safe filename stem.
# Exit:    Renders the Mojolicious response.
# Side Effects: Creates and unlinks a temporary file; writes HTTP response.
sub _render_sqlite :Protected ($self, $records, $columns, $name) {
	$self->stash(buffer => 0);
	my $data = $self->_write_sqlite_db($records, $columns);
	$self->res->headers->content_type('application/vnd.sqlite3');
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.db"});
	$self->render(data => $data);
}

# _render_json($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Emit $records as a JSON array download.
# Entry:   $records is an arrayref of hashrefs; $name is a safe filename stem.
# Exit:    Renders the Mojolicious response.
# Side Effects: Writes HTTP response headers and body.
sub _render_json :Protected ($self, $records, $columns, $name) {
	$self->stash(buffer => 0);
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.json"});
	$self->render(json => $records);
}

# ---------------------------------------------------------------------------
# Public actions
# ---------------------------------------------------------------------------

=encoding utf8

=head1 ACTIONS

=head2 index

C<GET /> -- Scan C<data_dir> and present a card grid of available tables.

=head3 API SPECIFICATION

=head4 INPUT

None (reads C<data_dir> from application config).

=head4 OUTPUT

Renders C<home.html.tt> with:

  tables     ARRAYREF of { name => $stem, file => $basename }
  title      'Choose a Database'

=head3 MESSAGES

None produced by this action; any file-scan errors are silently ignored
(empty directory yields an empty card grid).

=head3 FORMAL SPECIFICATION

  index == lambda self .
    let dir  = resolve self.app.config.data_dir in
    let tbls = { b | b in dir /\ basename(b) =~ EXT_RE } in
    post render(home, tables: map(stem, tbls))

=head3 EXAMPLE

  GET / -> 200 text/html containing a card for each file in data/

=cut

sub index ($self) {
	my ($platform, $language) = $self->_resolve_template;

	# The layout writes the resolved language into <html lang>, so every action
	# that renders a template from $platform/$language hands it over; t/html-lang.t
	# holds the controller to that.  A screen reader, a translation tool and
	# anything that indexes the page read the attribute.
	$self->render(
		template => "$platform/$language/home",
		handler  => 'tt',
		format   => 'html',
		tables   => $self->_scan_data_dir,
		title    => 'Choose a Database',
		language => $language,
	);
}

=head2 tutorial

C<GET /tutorial> -- Render the tutorial that is part of the application.

The chapters, questions and glossary are data in L<Database::BI::Tutorial>.
They are not in this module's POD, so adding a feature means adding a chapter
there and no change to this action or to the template.

=cut

sub tutorial ($self) {
	return if $self->buffer_is_cached;
	my ($platform, $language) = $self->_resolve_template;

	$self->render(
		template => "$platform/$language/tutorial",
		handler  => 'tt',
		format   => 'html',
		title    => 'Tutorial',
		language => $language,
		intro    => Database::BI::Tutorial->intro,
		parts    => Database::BI::Tutorial->parts,
		faq      => Database::BI::Tutorial->faq,
		glossary => Database::BI::Tutorial->glossary,
		version  => $self->app->VERSION,
	);
}

=head2 view

C<GET /view/:table> -- Open and display the chosen table from C<data_dir>.

=head3 API SPECIFICATION

=head4 INPUT

  :table   string   Table name (alphanumeric + underscore).  Returns 404 on
                    other characters.
  ?f=      string   (repeatable) Filter spec: "col:op:val".

=head4 DOMAIN CONSTRAINTS: :table

C<:table> is validated against C<\A[A-Za-z_][A-Za-z0-9_]*\z> before C<open_table>
is ever called.  The first character must be a letter (A-Z, a-z) or an
underscore; subsequent characters may also include digits (0-9).

=over 4

=item Valid partition

C<sales> (letters only), C<_temp> (underscore-start), C<report_2024>
(mixed).  A name that is valid but has no backing file returns 200 with
an error message -- NOT 404.

=item Invalid partition

C<1sales> (digit-start, 404), C<my.data> (dot, 404), C<my-data>
(hyphen, 404), non-ASCII characters (404).

=item Boundary values

C<a> (single letter, valid), C<_> (single underscore, valid), C<1>
(single digit, 404), C<a1> (letter then digit, valid), C<1a> (digit
then letter, 404).

=back

=head4 OUTPUT

On success renders C<dashboard.html.tt> with table data.
On error re-renders C<home.html.tt> with an C<error> stash variable.

=head3 MESSAGES

  error_table_open   -- DataSource initialisation or fetch_all threw.

=head3 FORMAL SPECIFICATION

  view == lambda self .
    pre  self.stash('table') =~ TABLE_NAME_RE
    let src     = open_table(table) in
    let records = src.fetch_all()   in
    let cols    = get_columns(src, records) in
    post render(dashboard, records: filter(records, f_params))

=head3 EXAMPLE

  GET /view/sales      -> 200 HTML table of all sales rows
  GET /view/sales?f=region:eq:North -> shows only North region rows
  GET /view/../etc     -> 404

=cut

sub view ($self) {
	my ($platform, $language) = $self->_resolve_template;
	my $table = $self->stash('table');

	unless (defined $table && $table =~ $TABLE_NAME_RE) {
		return $self->reply->not_found;
	}

	my ($page, $per_page, $offset) = $self->_pagination;

	my $dedup = $self->param('d') ? 1 : 0;
	my ($source, $records, $has_next, $is_multi);
	eval {
		$source = $self->open_table($table);
		# Multi-table SQLite: flag redirect without fetching data.
		if ($source && $source->sqlite_tables && @{ $source->sqlite_tables } > 1) {
			$is_multi = 1;
		} else {
			# _fetch_page applies reduce-before-paginate: full-fetch + filter + dedup
			# + Perl paginate when f= or d=1 are set; N+1 trick otherwise.
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup });
		}
	};
	if ($@) {
		# No file by that name: a 404 that names the table, with the trail
		# and the navigation, rather than the home page and the backend's
		# message (which gives away the data directory).
		my $stem_of = sub { lc($_[0]->basename =~ s/\.[^.]+\z//r) };
		unless (grep { $stem_of->($_) eq lc $table } _data_dir_for($self->app)->list->each) {
			return $self->render(
				template  => "$platform/$language/not_found",
				handler   => 'tt',
				format    => 'html',
				status    => 404,
				title     => 'Table not found',
				error_msg => $self->_i18n('error_table_missing', $table),
				language  => $language,
			);
		}
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Choose a Database',
			error    => $self->_i18n('error_table_open', $table, $@),
			language => $language,
		);
	}

	if ($is_multi) {
		return $self->redirect_to('/tables?l=' . url_escape("table:$table"));
	}

	# A cross-row spec that could not be honoured has already rendered its 400
	# inside _fetch_page; drawing the page over it would hide the reason.
	return if $self->stash('_cross_row_error');

	$records //= [];
	my @columns = _get_columns($source, $records);
	# Stage 6 wrote its columns onto the rows before the page was sliced, so the
	# list is what makes the table show them -- and what lets a calculated field
	# below name one of them.
	my %seen_col = map { $_ => 1 } @columns;
	push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };
	# The page from _fetch_page is already reduced; this call is here for the chip
	# list only -- filter_specs (for export URLs) and filters_json (for the UI).
	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });

	# Calculated fields belong to the table, not only to its charts.  The table
	# action is addressed by :table rather than l=, so name the spec explicitly
	# when looking up the fields saved for it; otherwise a saved column would
	# appear in every chart and not in the table it was made from.
	# span= adds a bucket column to the table rather than grouping it: a table has
	# no dimension to bucket *into*, so the reader gets the column and the raw
	# value beside it.  See _span_calc_spec.
	my $span = $self->_span_calc_spec(\@columns, ());
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	my ($calc_records, $calc_columns) = eval {
		$self->_apply_calc_fields($records, \@columns, {
			spec_key => "table:$table",
			($span ? (calc => $span->{calc}) : ()),
		})
	};
	if ($@) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		return $self->render(text => $e, status => 400);
	}
	$records = $calc_records;
	@columns = @$calc_columns;

	my $page_url = $self->req->url->clone;
	$page_url->query->remove('page')->remove('per_page');
	my $page_base_url = $page_url->to_string;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $records,
		columns          => \@columns,
		table            => $table,
		title            => ucfirst($table),
		left_spec        => "table:$table",
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_join_tables,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		back_url         => _safe_back_url($self->param('back2')),
		back_label       => $self->param('back2_label') // 'Back',
		export_url       => $self->_build_export_url("table:$table", [], $filter_specs, undef, $dedup, {
			span => $self->param('span'), tcol => $self->param('tcol'), as => $self->param('as'),
		}),
		page             => $page,
		per_page         => $per_page,
		has_next         => $has_next,
		page_base_url    => $page_base_url,
		language         => $language,
	);
}

=head2 browse

C<GET /browse> -- Navigate the filesystem and pick a data file.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute filesystem path to browse (default: $HOME).
                    Returns 404 when the path does not exist or is not a
                    directory.

=head4 OUTPUT

Renders C<browse.html.tt> with:

  current_path   string
  parent_href    string or undef (undef at filesystem root)
  crumbs         ARRAYREF of { name, href }
  dirs           ARRAYREF of { name, href }   -- subdirectories, sorted
  files          ARRAYREF of { name, href }   -- supported data files, sorted

=head3 MESSAGES

None; errors render as 404.

=head3 FORMAL SPECIFICATION

  browse == lambda self .
    let dir = realpath(param('path') // HOME) in
    pre  is_dir(dir)
    post render(browse, dirs: subdirs(dir), files: supported_files(dir))

=head3 EXAMPLE

  GET /browse                            -> 200, lists $HOME
  GET /browse?path=/tmp                  -> 200, lists /tmp
  GET /browse?path=/nonexistent/xyz      -> 404

=cut

sub browse ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $raw_path = $self->param('path') // $ENV{HOME} // '/';
	my $dir      = eval { Mojo::File->new($raw_path)->realpath };
	return $self->reply->not_found unless defined $dir && -d $dir;

	my $listing = $self->_list_dir($dir, 1);

	# Add browse hrefs to file entries (dirs already have path; browse needs href).
	my @dirs = map {
		+{ name => $_->{name}, href => '/browse?path=' . url_escape($_->{path}) }
	} @{ $listing->{dirs} };

	my @files = map {
		+{ name => $_->{name}, href => '/open?path=' . url_escape($_->{path}) }
	} @{ $listing->{files} };

	# Build breadcrumb trail from filesystem root down to $dir.
	my @crumbs;
	{
		my $f = $dir;
		while (1) {
			my $name = $f->basename;
			$name    = '/' unless length $name;
			unshift @crumbs, { name => $name, href => '/browse?path=' . url_escape($f->to_string) };
			my $parent = $f->dirname;
			last if $parent->to_string eq $f->to_string;
			$f = $parent;
		}
	}

	my $parent      = $dir->dirname;
	my $parent_href = $parent->to_string ne $dir->to_string
		? '/browse?path=' . url_escape($parent->to_string)
		: undef;

	$self->render(
		template     => "$platform/$language/browse",
		handler      => 'tt',
		format       => 'html',
		title        => 'Browse Files',
		current_path => $dir->to_string,
		parent_href  => $parent_href,
		crumbs       => \@crumbs,
		dirs         => \@dirs,
		files        => \@files,
		language     => $language,
	);
}

=head2 open_file

C<GET /open> -- Open a supported data file from any absolute filesystem path.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute path to the data file.  Returns 404 when missing,
                    not a regular file, or the extension is not in SUPPORTED_EXT.
  ?f=      string   (repeatable) Filter spec: "col:op:val".

=head4 DOMAIN CONSTRAINTS: ?path=

=over 4

=item Extension filter (C<EXT_RE>)

The basename must match C<\.(?:csv|db|sql|xml|tsv|psv)\z> (case-insensitive).
The C<\z> anchor (absolute end-of-string) means a URL-encoded trailing
newline (e.g. C<file.csv%0A> decoded to C<file.csv\n>) does NOT pass --
the C<\n> falls after the C<\z> boundary and the extension check fails.

=item Valid partition

C</data/sales.csv> (lowercase extension), C</tmp/REPORT.CSV> (uppercase
extension, /i matches), any C<.db>, C<.sql>, C<.xml>, C<.tsv>, C<.psv> regular
file.

=item Invalid partition

Absent C<?path=> (404), non-existent file (404), directory instead of
file (404), unsupported extension such as C<.txt> (404), empty string
(404), path containing a C<%0A> (newline) suffix (404).

=item Double-extension filenames

A file like C<file.php.csv> passes C<EXT_RE> (last segment is C<.csv>)
but produces table stem C<file.php> which fails C<DataSource>'s
C<TABLE_NAME_RE>.  The C<open_table> call is inside C<eval>, so the
croak is caught and the action returns 200 with a friendly error, not
a 500.

=back

=head4 OUTPUT

On success renders C<dashboard.html.tt> with C<back_url> pointing to the
directory's C</browse> page, and C<file_path> set to the resolved absolute
path (used by the template to record the file in C<localStorage>).
On error re-renders C<home.html.tt> with C<error>, C<back_url>, C<back_label>.

=head3 MESSAGES

  error_file_open   -- DataSource threw during initialisation or fetch_all.

=head3 FORMAL SPECIFICATION

  open_file == lambda self .
    let file = realpath(param('path')) in
    pre  is_file(file) /\ basename(file) =~ EXT_RE
    let src = open_table(stem(file), dir=dirname(file)) in
    post render(dashboard, file_path: file.to_string)

=head3 EXAMPLE

  GET /open?path=/data/archive/sales.csv   -> 200, table view
  GET /open                                -> 404
  GET /open?path=/etc/passwd               -> 404

=cut

sub open_file ($self) {
	my ($platform, $language) = $self->_resolve_template;
	my $file_path = $self->param('path');

	return $self->reply->not_found unless defined $file_path;

	my ($page, $per_page, $offset) = $self->_pagination;

	# Bare redis:// URL (no table name) -- redirect to key-listing page.
	if ($file_path =~ $REDIS_URL_RE) {
		return $self->redirect_to('/tables?l=' . url_escape($file_path));
	}

	# Redis spec: redis:tablename|redis://host:port -- delegate to _open_spec.
	if ($file_path =~ $REDIS_SPEC_RE) {
		my $lspec = $file_path;
		my ($source, $label) = $self->_open_spec($lspec);
		return $self->reply->not_found unless $source;
		my $table = $label;
		my $dedup = $self->param('d') ? 1 : 0;
		my ($records, $has_next);
		eval {
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup });
		};
		if ($@) {
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $label, $@),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		# A cross-row spec that could not be honoured has already rendered its 400
		# inside _fetch_page; the page must not be drawn over it.
		return if $self->stash('_cross_row_error');

		$records //= [];
		my @columns  = _get_columns($source, $records);
		my %seen_col = map { $_ => 1 } @columns;
		push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };
		my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });
		my $rpage_url = $self->req->url->clone;
		$rpage_url->query->remove('page')->remove('per_page');
		return $self->render(
			template         => "$platform/$language/dashboard",
			handler          => 'tt',
			format           => 'html',
			records          => $records,
			columns          => \@columns,
			table            => $table,
			title            => $label,
			back_url         => _safe_back_url($self->param('back')) // '/',
			back_label       => $self->param('back_label') // 'Home',
			back2_url        => _safe_back_url($self->param('back2')),
			back2_label      => $self->param('back2_label') // 'Back',
			file_path        => $file_path,
			left_spec        => $lspec,
			combine_specs    => [],
			current_joins    => [],
			available_tables => $self->_scan_join_tables,
			join_summaries   => [],
			filter_specs     => $filter_specs,
			filters_json     => $filters_json,
			dedup            => $dedup,
			export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
			page             => $page,
			per_page         => $per_page,
			has_next         => $has_next,
			page_base_url    => $rpage_url->to_string,
			language         => $language,
		);
	}

	# Remote path /../hostname/dir/file.ext: delegate opening to _open_spec
	# and render the dashboard directly, bypassing the realpath/local-file path.
	if ($file_path =~ m{\A/\.\./}) {
		my $lspec = 'path:' . $file_path;
		my ($source, $label) = $self->_open_spec($lspec);
		return $self->reply->not_found unless $source;
		my $filename = $label;
		(my $table = $filename) =~ s/\.[^.]+\z//;
		my $dedup = $self->param('d') ? 1 : 0;
		my ($records, $has_next);
		eval {
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup });
		};
		if ($@) {
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $filename, $@),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		# A cross-row spec that could not be honoured has already rendered its 400
		# inside _fetch_page; the page must not be drawn over it.
		return if $self->stash('_cross_row_error');

		$records //= [];
		my @columns  = _get_columns($source, $records);
		my %seen_col = map { $_ => 1 } @columns;
		push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };
		my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });
		my $rpage_url = $self->req->url->clone;
		$rpage_url->query->remove('page')->remove('per_page');
		return $self->render(
			template         => "$platform/$language/dashboard",
			handler          => 'tt',
			format           => 'html',
			records          => $records,
			columns          => \@columns,
			table            => $table,
			title            => $filename,
			back_url         => '/',
			back_label       => 'Home',
			back2_url        => _safe_back_url($self->param('back2')),
			back2_label      => $self->param('back2_label') // 'Back',
			file_path        => $file_path,
			left_spec        => $lspec,
			combine_specs    => [],
			current_joins    => [],
			available_tables => $self->_scan_join_tables,
			join_summaries   => [],
			filter_specs     => $filter_specs,
			filters_json     => $filters_json,
			dedup            => $dedup,
			export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
			page             => $page,
			per_page         => $per_page,
			has_next         => $has_next,
			page_base_url    => $rpage_url->to_string,
			language         => $language,
		);
	}

	my $file = eval { Mojo::File->new($file_path)->realpath };
	return $self->reply->not_found
		unless defined $file && -f $file && $file->basename =~ $EXT_RE;

	my $dir      = $file->dirname;
	(my $table   = $file->basename) =~ s/\.[^.]+\z//;
	my $back     = '/browse?path=' . url_escape($dir->to_string);
	my $filename = $file->basename;
	my $lspec    = 'path:' . $file->to_string;

	my $it = $self->param('it');	# optional: select a specific internal table

	# A table opened from the schema browser belongs to a file in data_dir.  Name
	# it as table:store/sales so the join, filter and export panels keep the
	# chosen internal table instead of dropping back to the file's first table.
	if (defined $it && $it =~ $TABLE_NAME_RE) {
		my $data_dir = eval { _data_dir_for($self->app)->realpath };
		my $file_dir = eval { $file->dirname->realpath };
		$lspec = "table:$table/$it" if $data_dir && $file_dir && "$file_dir" eq "$data_dir";
	}

	# Allow the tables view to override the default "Back to browser" link.
	my $back_override = _safe_back_url($self->param('back'));
	if ($back_override) {
		$back = $back_override;
	}
	my $back_label_default = $back_override ? ($self->param('back_label') // 'Back') : 'Back to browser';

	my $dedup = $self->param('d') ? 1 : 0;
	my ($source, $records, $has_next, $is_multi_local);
	eval {
		$source = $self->open_table($table, directory => $dir->to_string,
			defined $it ? (internal_table => $it) : ());
		# Multi-table SQLite without it=: flag redirect without fetching data.
		if (!defined $it && $source && $source->sqlite_tables
				&& @{ $source->sqlite_tables } > 1) {
			$is_multi_local = 1;
		} else {
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup });
		}
	};
	if ($@) {
		# Provide a SQLite-specific hint when the error looks like a table-name
		# mismatch or a missing-tables failure so the user knows what to do.
		my $hint;
		if ($filename =~ /\.(?:sql|db)\z/i) {
			$hint = 'SQLite files must contain at least one user-defined table. '
				. 'The table name inside the database does not need to match the '
				. 'filename -- the application auto-detects and uses the first table found.';
		}
		return $self->render(
			template    => "$platform/$language/home",
			handler     => 'tt',
			format      => 'html',
			tables      => [],
			title       => 'Error',
			error       => $self->_i18n('error_file_open', $filename, $@),
			hint        => $hint,
			back_url    => $back,
			back_label  => $back_label_default,
			back2_url   => _safe_back_url($self->param('back2')),
			back2_label => $self->param('back2_label') // 'Back',
			language    => $language,
		);
	}

	if ($is_multi_local) {
		return $self->redirect_to('/tables?l=' . url_escape("path:${\$file->to_string}"));
	}

	# A cross-row spec that could not be honoured has already rendered its 400
	# inside _fetch_page; the page must not be drawn over it.
	return if $self->stash('_cross_row_error');

	$records //= [];
	my @columns  = _get_columns($source, $records);
	my %seen_col = map { $_ => 1 } @columns;
	push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };
	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });

	my $lpage_url = $self->req->url->clone;
	$lpage_url->query->remove('page')->remove('per_page');

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $records,
		columns          => \@columns,
		table            => defined $it ? $it : $table,
		title            => defined $it ? "$filename ($it)" : $filename,
		back_url         => $back,
		back_label       => $back_label_default,
		back2_url        => _safe_back_url($self->param('back2')),
		back2_label      => $self->param('back2_label') // 'Back',
		file_path        => $file->to_string,
		left_spec        => $lspec,
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_join_tables,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
		page             => $page,
		per_page         => $per_page,
		has_next         => $has_next,
		page_base_url    => $lpage_url->to_string,
		language         => $language,
	);
}

=head2 import_url

C<GET /import> -- Fetch a remote HTML page, extract the first (or selected)
table, and render it as a sortable data grid.

=head3 API SPECIFICATION

=head4 INPUT

  ?url=          string   Required.  Full http:// or https:// URL of the page
                          that contains the HTML table.  Returns home with an
                          error message if the scheme is wrong, the fetch fails,
                          or no table is found at the specified index.
  ?table_index=  integer  Zero-based index of the C<< <table> >> to use when
                          the page contains more than one table (default: 0).
  ?f=            string   (repeatable) Filter spec: "col:op:val".

=head4 OUTPUT

On success renders C<dashboard.html.tt> with the same stash shape as C<open_file>,
plus C<source_url> (the original URL) for C<localStorage> tracking.

On error re-renders C<home.html.tt> with an C<error> stash variable.

=head3 MESSAGES

  error_url_required  -- empty or missing C<url> param
  error_url_invalid   -- URL does not begin with http:// or https://
  error_url_fetch     -- LWP fetch failure or no table found at the index

=head3 EXAMPLE

  GET /import?url=https://matrix.perl-magpie.org/dist/Database-Abstraction/
  GET /import?url=https://example.com/data.html&table_index=2

=cut

sub import_url ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $url = $self->param('url') // '';
	my $idx = $self->param('table_index') // 0;
	$idx    = 0 unless $idx =~ /\A[0-9]+\z/;

	my $err_home = sub ($key, @args) {
		$self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => $self->_scan_data_dir,
			title    => 'Choose a Database',
			error    => $self->_i18n($key, @args),
			language => $language,
		);
	};

	return $err_home->('error_url_required') unless length $url;
	return $err_home->('error_url_invalid', $url)
		unless $url =~ m{\Ahttps?://}i;
	return $err_home->('error_url_ssrf', $url)
		unless _is_safe_url($url);

	my $source = eval { $self->open_table('', url => $url, html_table_index => $idx) };
	return $err_home->('error_url_fetch', $url, $@ // 'unknown error') if $@ || !$source;

	my $records = eval { $source->fetch_all };
	return $err_home->('error_url_fetch', $url, $@ // 'empty result') if $@;

	my $label   = $source->table_name;
	my $lspec   = "url:$url";
	my @columns = _get_columns($source, $records);
	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	my $self_url = '/import?url=' . url_escape($url);
	$self_url   .= '&table_index=' . $idx if $idx;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $label,
		title            => $label,
		source_url       => $url,
		back_url         => $self_url,
		back_label       => $label,
		back2_url        => _safe_back_url($self->param('back2')),
		back2_label      => $self->param('back2_label') // 'Back',
		left_spec        => $lspec,
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_join_tables,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
		language         => $language,
	);
}

=head2 columns_api

C<GET /api/columns> -- Return column names for a table or file as JSON.

Used by the join UI to populate the right-key dropdown without a page reload.

=head3 API SPECIFICATION

=head4 INPUT

  ?table=  string   Table name from C<data_dir>, or C<file/table> for a table
                    inside a multi-table SQLite file.
  ?path=   string   Absolute path to a data file.
  ?spec=   string   Unified spec: C<"table:name">, C<"table:file/table"> or
                    C<"path:/abs/path">.
                    Parsed only when C<table> and C<path> are both absent.

One of C<table>, C<path>, or C<spec> must be present; C<table> takes
precedence over C<path>, and both take precedence over C<spec>.

=head4 OUTPUT

  200 application/json   { "columns": ["col1", "col2", ...] }
  404 application/json   { "error": "not found" }

=head3 MESSAGES

None produced by this action directly; internal errors yield a 404.

=head3 FORMAL SPECIFICATION

  columns_api == lambda self .
    let src = open_spec(table_param or path_param or parse_spec(spec_param)) in
    pre  src /= undef
    post render_json({ columns: get_columns(src) })

=head3 EXAMPLE

  GET /api/columns?table=sales            -> {"columns":["product","region","amount"]}
  GET /api/columns?table=store/customer   -> {"columns":["id","name","email"]}
  GET /api/columns?spec=table:sales       -> {"columns":["product","region","amount"]}
  GET /api/columns?spec=path:/data/f.csv  -> {"columns":[...]}
  GET /api/columns?table=noexist          -> 404

=cut

sub columns_api ($self) {
	my $table_name = $self->param('table');
	my $path       = $self->param('path');

	# Accept the unified spec format used by /join and /graph:
	# "table:name" or "path:/abs/path" -- mirrors _open_spec's parsing.
	if (!defined($table_name) && !defined($path)) {
		my $spec = $self->param('spec') // '';
		if ($spec =~ m{\Atable:([A-Za-z_][A-Za-z0-9_]*(?:/[A-Za-z_][A-Za-z0-9_]*)?)\z}) {
			$table_name = $1;
		} elsif ($spec =~ /\Apath:(.+)\z/s) {
			$path = $1;
		}
	}

	my $source;
	if (defined $table_name && $table_name =~ m{\A([A-Za-z_][A-Za-z0-9_]*)(?:/([A-Za-z_][A-Za-z0-9_]*))?\z}) {
		my ($table, $internal) = ($1, $2);
		my $data_dir = _data_dir_for($self->app);
		return $self->render(json => { error => 'not found' }, status => 404)
			unless grep { -f $data_dir->child(lc($table) . ".$_") } @SUPPORTED_EXT;
		$source = eval {
			$self->open_table(lc $table, directory => $data_dir->to_string,
				defined $internal ? (internal_table => $internal) : ())
		};
	}
	elsif (defined $path) {
		if ($path =~ m{\A/\.\./([^/]+)((?:/.+)?)/([^/]+)\z}) {
			my ($host, $dir_part, $file) = ($1, $2 // '', $3);
			$dir_part = '/' unless length $dir_part;
			if ($host =~ $REMOTE_HOST_RE) {
				my ($tbl, $ext) = $file =~ /\A(.+)\.([^.]+)\z/ ? ($1, $2) : ($file, undef);
				$source = eval { $self->open_table($tbl, directory => $dir_part, host => $host,
					defined $ext ? (file_ext => $ext) : ()) };
			}
		} else {
			my $file = eval { Mojo::File->new($path)->realpath };
			if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
				my $dir = $file->dirname->to_string;
				(my $tbl = $file->basename) =~ s/\.[^.]+\z//;
				$source = eval { $self->open_table($tbl, directory => $dir) };
			}
		}
	}

	return $self->render(json => { error => 'not found' }, status => 404) unless $source;

	# Use _get_columns to ensure consistent ordering with the view action.
	my $recs = ($source->columns ? [] : eval { $source->fetch_all } // []);
	my @cols = _get_columns($source, $recs);

	$self->render(json => { columns => \@cols });
}

=head2 range_api

C<GET /api/range> -- Return the min and max ISO date values for one column.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   Required. Data source spec ("table:name", "path:/abs/path", etc.).
  ?col=  string   Required. Column name to compute the range for.

=head4 OUTPUT

  200 application/json   { "min": "YYYY-MM-DD", "max": "YYYY-MM-DD" }
  200 application/json   { "min": null, "max": null }  (no parseable dates)
  400 application/json   { "error": "..." }

=head3 FORMAL SPECIFICATION

  range_api == lambda self .
    let src = _open_spec(param('l')) in
    pre  src /= undef /\ col /= ''
    post render_json({ min: min_date(src, col), max: max_date(src, col) })

=cut

sub range_api ($self) {
	my $spec_str = $self->param('l') // '';
	my $col      = $self->param('col') // '';
	return $self->render(json => { error => 'l required'   }, status => 400) unless length $spec_str;
	return $self->render(json => { error => 'col required' }, status => 400) unless length $col;

	my ($source) = $self->_open_spec($spec_str);
	return $self->render(json => { min => undef, max => undef }) unless $source;

	my $records = eval { $source->fetch_all } // [];

	my $iso_re = qr/\A\d{4}-\d{2}-\d{2}\z/;
	my $mdy_re = qr|\A(\d{1,2})/(\d{1,2})/(\d{4})\z|;
	my @dates;
	for my $rec (@$records) {
		my $v = $rec->{$col} // '';
		next unless length $v;
		if ($v =~ $iso_re) {
			push @dates, $v;
		} elsif (my @m = ($v =~ $mdy_re)) {
			push @dates, sprintf '%04d-%02d-%02d', $m[2], $m[0], $m[1];
		}
	}

	return $self->render(json => { min => undef, max => undef }) unless @dates;
	@dates = sort @dates;
	$self->render(json => { min => $dates[0], max => $dates[-1] });
}

=head2 join_tables

C<GET /join> -- Perform one or more left joins and render the merged table.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   Required. Left table spec: "table:name", "table:file/table"
                  or "path:/abs/path".  Returns 404 if unresolvable.
  ?j=    string   (repeatable) Join step: "<right-spec>|<left-key>|<right-key>".
                  Invalid or non-existent steps are silently skipped.
  ?f=    string   (repeatable) Result filter: "col:op:val".

=head4 OUTPUT

Renders C<dashboard.html.tt> with the merged/filtered result set.

=head3 MESSAGES

  error_table_open   -- Left table fetch threw (re-renders home with error).

=head3 FORMAL SPECIFICATION

  join_tables == lambda self .
    let left = open_spec(param('l')) in
    pre  left /= undef
    let joined  = fold(_left_join, left, param_list('j')) in
    let filtered = fold(_apply_filter_spec, joined, param_list('f')) in
    post render(dashboard, records: filtered)

=head3 PSEUDOCODE

  1. Parse and open left table spec; 404 on failure.
  2. For each j= param (in order):
       a. Parse right-spec, left-key, right-key from "|"-split.
       b. Verify left-key exists in current column list.
       c. Open right table; skip step on any error.
       d. Verify right-key exists in right column list.
       e. Call _left_join; update records and columns.
  3. Apply all f= filters via _apply_filter_spec.
  4. Build stable table key for localStorage ("join:left:right1:...").
  5. Render dashboard.

=head3 EXAMPLE

  GET /join?l=table:sales&j=table:products|product|name
    -> merged left join of sales and products on product/name columns

=cut

sub join_tables ($self) {
	# Rows stacked from other files cannot be paged from one backend; the
	# combine route runs joins and combines together.
	return $self->combine_tables if @{ $self->every_param('c') };

	my ($platform, $language) = $self->_resolve_template;

	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return $self->reply->not_found unless $left_src;

	my @join_specs = @{ $self->every_param('j') };
	my @summaries;

	# Build the join chain: each step wraps the previous source in a
	# Database::Join.  Data is not fetched until after the loop.
	my $max_rows  = $self->app->config('join_max_rows') // $DEFAULT_JOIN_MAX_ROWS;
	my $join_type = $self->param('jtype') // 'left';
	$join_type    = 'left' unless $join_type =~ /\A(?:left|inner|outer)\z/;
	my $src = $left_src;
	my @schema_warnings;
	for my $jspec (@join_specs) {
		my ($right_spec, $left_key, $right_key) = split /\|/, $jspec, 3;
		next unless defined $right_spec && defined $left_key && defined $right_key;

		my $cur_cols = $src->columns;
		next unless $cur_cols;
		next unless +{ map { $_ => 1 } @$cur_cols }->{$left_key};

		my ($right_src, $right_label) = $self->_open_spec($right_spec);
		next unless $right_src;

		my $right_cols = $right_src->columns;
		next unless $right_cols;
		next unless +{ map { $_ => 1 } @$right_cols }->{$right_key};

		# Types are compared while the two sides are still separate sources;
		# after the join is built the mismatched columns are already published
		# under different names.  See _schema_type_warnings.
		push @schema_warnings, $self->_schema_type_warnings(
			$src, $right_src, $left_label, $right_label, $left_key, $right_key);

		require Database::Join;
		local $SIG{__WARN__} = sub { push @schema_warnings, $_[0] };
		$src = Database::Join->new(
			databases        => [$src, $right_src],
			join_column      => $left_key,
			backend          => 'auto',
			max_array_rows   => $max_rows,
			join_type        => $join_type,
			($left_key ne $right_key ? (join_map         => {1 => $right_key})   : ()),
			($right_label             ? (collision_prefix => {1 => $right_label}) : ()),
		);
		push @summaries, { label => $right_label, left_key => $left_key, right_key => $right_key };
	}

	my ($page, $per_page, $offset) = $self->_pagination;
	my $dedup  = $self->param('d') ? 1 : 0;
	my $sort   = $self->param('sort');
	my $dir    = ($self->param('dir') // 'asc') =~ /\Adesc\z/i ? 'desc' : 'asc';

	my ($records, $has_next);
	eval {
		($records, $has_next) = $self->_fetch_page($src,
			{ per_page  => $per_page, offset   => $offset,
			  dedup     => $dedup,    sort_col => $sort,
			  sort_dir  => $dir });
	};
	if ($@) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Error',
			error    => $self->_i18n('error_table_open', $left_label, $@),
			language => $language,
		);
	}
	# A cross-row spec that could not be honoured has already rendered its 400
	# inside _fetch_page; the page must not be drawn over it.
	return if $self->stash('_cross_row_error');

	$records //= [];
	my @columns = _get_columns($src, $records);
	my %seen_col = map { $_ => 1 } @columns;
	push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };

	if (defined $sort && !grep { $_ eq $sort } @columns) {
		carp $self->_i18n('error_sort_column', $sort);
	}

	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });

	my $title     = $left_label;
	$title       .= ' + ' . join(' + ', map { $_->{label} } @summaries) if @summaries;
	my $table_key = 'join:' . lc($left_label);
	$table_key   .= ':' . lc($_->{label}) for @summaries;

	my $page_url = $self->req->url->clone;
	$page_url->query->remove('page')->remove('per_page');

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $records,
		columns          => \@columns,
		table            => $table_key,
		title            => $title,
		back_url         => $self->_spec_to_url($left_spec),
		back_label       => "Back to $left_label",
		back2_url        => _safe_back_url($self->param('back2')),
		back2_label      => $self->param('back2_label') // 'Back',
		left_spec        => $left_spec,
		combine_specs    => [],
		current_joins    => \@join_specs,
		available_tables => $self->_scan_join_tables,
		join_summaries   => \@summaries,
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($left_spec, \@join_specs, $filter_specs, undef, $dedup),
		schema_warnings  => \@schema_warnings,
		page             => $page,
		per_page         => $per_page,
		has_next         => $has_next,
		page_base_url    => $page_url->to_string,
		language         => $language,
	);
}

=head2 combine_tables

C<GET /combine> -- Stack rows from two or more tables vertically into a single
unified view.

Unlike C</join> (which appends columns from a matching row in a second table),
C</combine> appends the I<rows> from a second table beneath the rows of the
first.  All columns from all sources appear as headers; where a row has no
value for a particular column (because that column did not exist in its source
file) the cell is left blank.

This is equivalent to a SQL C<UNION ALL> across heterogeneous schemas.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   (required) Left table spec: "table:name" or "path:/abs/path".
                  Returns 404 if unresolvable.
  ?c=    string   (repeatable) Additional table spec to stack beneath the
                  current result.  Invalid or non-existent specs are silently
                  skipped.
  ?f=    string   (repeatable) Result filter: "col:op:val".

=head4 OUTPUT

Renders C<dashboard.html.tt> with the combined result set.

=head3 MESSAGES

  error_table_open   -- Left table fetch threw (re-renders home with error).

=head3 FORMAL SPECIFICATION

  combine_tables == lambda self .
    let left = open_spec(param('l')) in
    pre  left /= undef
    let sources  = [left] ++ map(open_spec, param_list('c')) in
    let combined = _combine_tables(sources) in
    let filtered = fold(_apply_filter_spec, combined, param_list('f')) in
    post render(dashboard, records: filtered)

=head3 EXAMPLE

  GET /combine?l=table:cats&c=table:dogs
    -> unified view: all cat and dog rows; Species/Name/Color/Breed/Eye Color
       appear for both; Environment (cats-only) and Sex/Fixed (dogs-only)
       are blank where the source file lacks that column.

=cut

sub combine_tables ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return $self->reply->not_found unless $left_src;

	# The same join-then-stack pipeline the charts of this view use, so the
	# table shows the rows they draw.
	my (undef, $records, $cols_ref) = $self->_run_pipeline_source;
	unless (defined $records) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Error',
			error    => $self->_i18n('error_table_open', $left_label, ''),
			language => $language,
		);
	}
	my @join_specs    = @{ $self->every_param('j') };
	my @combine_specs = @{ $self->every_param('c') };
	my @summaries     = (@{ $self->stash('pipeline_joined') // [] },
		@{ $self->stash('pipeline_combined') // [] });

	# Apply the filters in memory before paginating (reduce-before-paginate).
	my @columns;
	return unless $self->_reduce_or_render(\$records, \$cols_ref);
	@columns = @$cols_ref;
	# _reduce_or_render has removed duplicates for d=1; $dedup is for the page.
	my $dedup = $self->param('d') ? 1 : 0;

	# In-memory sort for /combine (no single backend to delegate to).
	my $sort = $self->param('sort');
	my $dir  = ($self->param('dir') // 'asc') =~ /\Adesc\z/i ? 'desc' : 'asc';
	if (defined $sort && grep { $_ eq $sort } @columns) {
		carp $self->_i18n('warn_combine_sort');
		@$records = sort { ($a->{$sort} // '') cmp ($b->{$sort} // '') } @$records;
		@$records = reverse @$records if $dir eq 'desc';
	} elsif (defined $sort) {
		carp $self->_i18n('error_sort_column', $sort);
	}

	# Server-side pagination: slice the fully-reduced combined set.  The page
	# below is therefore reduced too, and asks for chips only.
	my ($page, $per_page, $offset) = $self->_pagination;
	my $total    = scalar @$records;
	my $has_next = ($total > $offset + $per_page) ? 1 : 0;
	my @page_recs = splice(@$records, $offset, $per_page);
	$records = \@page_recs;

	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });

	my $title     = $left_label;
	$title       .= ' + ' . join(' + ', map { $_->{label} } @summaries) if @summaries;
	my $table_key = (@join_specs ? 'join+combine:' : 'combine:') . lc($left_label);
	$table_key   .= ':' . lc($_->{label}) for @summaries;

	my $page_url = $self->req->url->clone;
	$page_url->query->remove('page')->remove('per_page');

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $records,
		columns          => \@columns,
		table            => $table_key,
		title            => $title,
		back_url         => $self->_spec_to_url($left_spec),
		back_label       => "Back to $left_label",
		back2_url        => _safe_back_url($self->param('back2')),
		back2_label      => $self->param('back2_label') // 'Back',
		left_spec        => $left_spec,
		combine_specs    => \@combine_specs,
		current_joins    => \@join_specs,
		available_tables => $self->_scan_join_tables,
		join_summaries   => \@summaries,
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($left_spec, \@join_specs, $filter_specs, \@combine_specs, $dedup),
		schema_warnings  => $self->stash('schema_warnings') // [],
		page             => $page,
		per_page         => $per_page,
		has_next         => $has_next,
		page_base_url    => $page_url->to_string,
		language         => $language,
	);
}

=head2 export_data

C<GET /export> -- Stream the current logical view as a browser file download.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=        string   (required) Left table spec.
  ?j=        string   (repeatable) Join steps.
  ?f=        string   (repeatable) Filter specs.
  ?format=   string   "csv" (default), "sqlite", or "json".

=head4 DOMAIN CONSTRAINTS: ?format=

Exact lowercase string match.

=over 4

=item Valid partitions

C<csv> (explicit CSV), C<sqlite> (SQLite binary), C<json> (JSON array),
absent/undef (defaults to CSV).

=item Invalid partitions (all fall back to CSV)

Any value not in the valid set (e.g. C<SQLITE>, C<Json>).

=back

=head4 OUTPUT

  200 text/csv                  Content-Disposition: attachment; filename=<name>.csv
  200 application/vnd.sqlite3   Content-Disposition: attachment; filename=<name>.db
  200 application/json          Content-Disposition: attachment; filename=<name>.json
  404 application/json          { "error": "Table not found" }

=head3 MESSAGES

None beyond the 404 response.

=head3 FORMAL SPECIFICATION

  export_data == lambda self .
    let (recs, cols, label) = _run_export_pipeline() in
    pre  recs /= undef
    post if format = 'sqlite' then render_sqlite(recs, cols)
         else if format = 'json' then render_json(recs, cols)
         else render_csv(recs, cols)

=head3 EXAMPLE

  GET /export?l=table:sales&format=csv     -> downloads sales.csv
  GET /export?l=table:sales&format=sqlite  -> downloads sales.db
  GET /export?l=table:sales&format=json    -> downloads sales.json

=cut

sub export_data ($self) {
	my ($records, $columns, $left_label) = $self->_run_export_pipeline;
	return if $self->stash('_reduce_error');
	return $self->reply->not_found unless $records;

	# Surface schema-type-mismatch warnings in a response header so API
	# consumers (and the user via browser dev tools) can see them even
	# though exports render no HTML template.
	my $warnings = $self->stash('schema_warnings') // [];
	if (@$warnings) {
		my $hdr = join('; ', map { s/\s+/ /gr =~ s/^\s+|\s+$//gr } @$warnings);
		$self->res->headers->header('X-BI-Warnings' => $hdr);
	}

	my $format = $self->param('format') // 'csv';
	(my $safe_name = lc $left_label) =~ s/[^a-z0-9_]+/_/g;

	return $format eq 'sqlite' ? $self->_render_sqlite($records, $columns, $safe_name)
	     : $format eq 'json'   ? $self->_render_json($records, $columns, $safe_name)
	     :                       $self->_render_csv($records, $columns, $safe_name);
}

=head2 export_write

C<POST /export> -- Write the current logical view to a chosen filesystem path.

=head3 API SPECIFICATION

=head4 INPUT

  l=         string   (required) Left table spec.
  j=         string   (repeatable) Join steps.
  f=         string   (repeatable) Filter specs.
  dir=       string   Target directory (must exist; resolved via realpath).
  filename=  string   Output filename including extension.  Extension determines
                      format: C<.csv> -> RFC 4180 CSV; C<.sql> -> SQLite;
                      C<.json> -> JSON array of row objects.

=head4 DOMAIN CONSTRAINTS: filename=

The extension check uses C</\.csv\z/i> (CSV), C</\.sql\z/i> (SQLite), or
C</\.json\z/i> (JSON): the C</i> flag makes matching case-insensitive, so
C<.CSV>, C<.SQL>, and C<.JSON> are accepted alongside lowercase forms.
Everything else returns 415.

Path separator characters (C</> and C<\>) in C<filename> are stripped
first via C<m{([^/\\]+)\z}> -- only the basename is kept, preventing
directory traversal.

=over 4

=item Valid partitions

C<report.csv>, C<report.sql>, C<report.json>, C<REPORT.CSV>, C<report.SQL>.
A single-character stem (C<a.csv>) is also valid.

=item Invalid partitions (415)

C<report.txt>, C<report> (no extension), empty string.

=back

=head4 OUTPUT

  200 application/json   { "saved": "/abs/path/to/file" }
  404 application/json   { "error": "..." }  -- bad dir or table not found
  415 application/json   { "error": "..." }  -- unsupported extension
  500 application/json   { "error": "..." }  -- write failure

=head3 MESSAGES

  error_dir_not_found   -- realpath of dir failed or result is not a directory.
  error_ext_required    -- filename extension is not .csv or .sql.
  error_write_failed    -- DBI or filesystem write threw.

=head3 FORMAL SPECIFICATION

  export_write == lambda self .
    let dir  = realpath(param('dir'))      in
    let file = dir / strip_path(param('filename')) in
    pre  is_dir(dir) /\ ext(file) in {csv, sql}
    let (recs, cols, _) = _run_export_pipeline() in
    pre  recs /= undef
    post spurt(file, serialise(recs, cols))
         /\ render_json({ saved: file.to_string })

=head3 EXAMPLE

  POST /export  l=table:sales dir=/home/user/exports filename=report.csv
    -> { "saved": "/home/user/exports/report.csv" }

=cut

sub export_write ($self) {
	my $dir      = $self->param('dir')      // '';
	my $filename = $self->param('filename') // '';

	my $dest_dir = eval { Mojo::File->new($dir)->realpath };
	unless (defined $dest_dir && -d $dest_dir) {
		return $self->render(
			json   => { error => $self->_i18n('error_dir_not_found', $dir) },
			status => 404,
		);
	}

	# Strip any path separators the browser might include.
	($filename) = $filename =~ m{([^/\\]+)\z};
	my $format;
	if    ($filename && $filename =~ /\.csv\z/i)  { $format = 'csv';    }
	elsif ($filename && $filename =~ /\.sql\z/i)  { $format = 'sqlite'; }
	elsif ($filename && $filename =~ /\.json\z/i) { $format = 'json';   }
	else {
		return $self->render(
			json   => { error => $self->_i18n('error_ext_required') },
			status => 415,
		);
	}

	my ($records, $columns, $left_label) = $self->_run_export_pipeline;
	return if $self->stash('_reduce_error');
	return $self->render(json => { error => 'Table not found' }, status => 404)
		unless $records;

	my $dest = $dest_dir->child($filename);
	eval {
		if ($format eq 'csv') {
			$dest->spurt(_serialize_csv($records, $columns));
		}
		elsif ($format eq 'json') {
			$dest->spurt(encode_json($records));
		}
		else {
			$dest->spurt($self->_write_sqlite_db($records, $columns));
		}
	};
	return $self->render(
		json   => { error => $self->_i18n('error_write_failed', $@) },
		status => 500,
	) if $@;

	$self->render(json => { saved => $dest->to_string });
}

=head2 dirs_api

C<GET /api/dirs> -- Return a JSON directory listing for the export panel.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Directory to list (default: $HOME).  Returns 404 when not
                    a directory.  Hidden entries (names starting with ".") are
                    excluded.

=head4 OUTPUT

  200 application/json
    {
      "path":   "/abs/path",
      "parent": "/abs/parent" or null (at filesystem root),
      "dirs":   [ { "name": "alpha", "path": "/abs/path/alpha" }, ... ]
    }

  404 application/json   { "error": "Not a directory" }

=head3 MESSAGES

None beyond the 404 response.

=head3 FORMAL SPECIFICATION

  dirs_api == lambda self .
    let dir = realpath(param('path') // HOME) in
    pre  is_dir(dir)
    post render_json({ path: dir, parent: parent(dir), dirs: subdirs(dir) })

=head3 EXAMPLE

  GET /api/dirs?path=/home/user  -> {"path":"/home/user","parent":"/home","dirs":[...]}

=cut

sub dirs_api ($self) {
	my $raw = $self->param('path') // $ENV{HOME} // '/';
	my $dir = eval { Mojo::File->new($raw)->realpath };
	return $self->render(json => { error => 'Not a directory' }, status => 404)
		unless defined $dir && -d $dir;

	my $listing = $self->_list_dir($dir, 0);
	my $parent  = $dir->dirname;

	$self->render(json => {
		path   => $dir->to_string,
		parent => ($parent->to_string ne $dir->to_string ? $parent->to_string : undef),
		dirs   => $listing->{dirs},
	});
}

=head2 stat_api

C<GET /api/stat> -- Return filesystem metadata for a file path.

Used by the home page tooltip to show modification time and size for recently
opened files without a page reload.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute path to query.  Returns HTTP 400 when absent.

=head4 OUTPUT

  200 application/json   (file exists)
    { "exists": true, "path": "/resolved/path", "mtime": 1700000000, "size": 4096 }

  200 application/json   (file does not exist)
    { "exists": false, "path": "/original/path" }

  400 application/json   { "error": "\"path\" parameter is required" }

C<mtime> is Unix epoch seconds.  C<size> is bytes.  A missing/unresolvable
path returns HTTP 200 with C<exists: false> (not 404) so the UI can
distinguish "file was deleted" from a request error.

=head3 MESSAGES

  error_path_required   -- the "path" query parameter was not supplied.

=head3 FORMAL SPECIFICATION

  stat_api == lambda self .
    let path = param('path') in
    pre  path /= undef
    let file = realpath(path) in
    post if is_file(file) then
           render_json({ exists: true, mtime: mtime(file), size: size(file) })
         else render_json({ exists: false })

=head3 EXAMPLE

  GET /api/stat?path=/data/sales.csv
    -> { "exists": true, "path": "/data/sales.csv", "mtime": 1700000000, "size": 1234 }

  GET /api/stat?path=/deleted.csv
    -> { "exists": false, "path": "/deleted.csv" }

=cut

sub stat_api ($self) {
	my $path = $self->param('path');
	unless (defined $path && length $path) {
		return $self->render(
			json   => { error => $self->_i18n('error_path_required') },
			status => 400,
		);
	}

	my $file = eval { Mojo::File->new($path)->realpath };
	# Restrict to files with a supported data extension so stat_api cannot be
	# used as a filesystem oracle to probe /etc/shadow, /root/.ssh/, etc.
	return $self->render(json => { exists => \0, path => $path })
		unless defined $file && -f $file && $file->basename =~ $EXT_RE;

	my @s = stat $file->to_string;

	# For SQLite files, count user tables so the home-page tooltip can show
	# "SQLite database - N tables". Silently omit the count if the file is
	# not actually a SQLite file (e.g. a Berkeley DB .db file).
	my $table_count;
	if ($file->basename =~ /\.(?:sql|sqlite|sqlite3|db)\z/i) {
		eval {
			require DBI;
			my $dbh = DBI->connect(
				'dbi:SQLite:dbname=' . $file->to_string,
				'', '',
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
			);
			my $tbls = $dbh->selectcol_arrayref(
				q{SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'}
			);
			$table_count = scalar @{ $tbls // [] };
			$dbh->disconnect;
		};
	}

	$self->render(json => {
		exists => \1,
		path   => $file->to_string,
		mtime  => $s[9],
		size   => $s[7],
		(defined $table_count ? (table_count => $table_count) : ()),
	});
}

=head2 upload_file

C<POST /upload> -- Accept a drag-and-dropped data file and return a redirect URL.

The file is saved under its original filename in a managed subdirectory of
C<< <uploads_dir>/ >>.  The subdirectory name is randomised so that
concurrent uploads of files with the same name do not collide.

=head3 API SPECIFICATION

=head4 INPUT

Multipart form upload, field name: C<file>.

  file   upload   Supported extensions: csv, db, sql, xml, tsv, psv.

=head4 OUTPUT

  200 application/json   { "url": "/open?path=/abs/path/file.csv", "path": "/abs/path/file.csv" }
  400 application/json   { "error": "No file received" }
  413 application/json   { "error": "File too large to upload (limit: 50 MB)" }
  415 application/json   { "error": "Unsupported file type. Accepted: ..." }
  500 application/json   { "error": "Could not save uploaded file" }

=head3 MESSAGES

  error_upload_none       -- no file was received in the multipart upload.
  error_upload_ext        -- the file's extension is not in the supported list.
  error_upload_too_large  -- the upload body exceeded MAX_UPLOAD_MIB (50 MiB).
  error_upload_save       -- move_to failed or the destination file was not
                             created (I/O error, full disk, permission error).

=head3 IMPLEMENTATION NOTES

The C<move_to> call is wrapped with the C<eval { ...; 1 }> idiom (not
C<eval {}> + C<if ($@)>).  Mojolicious dispatch and DESTROY-phase evals can
leave C<$@> set before the action runs; checking C<if ($@)> after a new eval
may fire falsely on that stale value.  C<eval { move_to(); 1 }> returns 1 on
success and C<undef> on exception, so the result is independent of any prior
C<$@> value.

=head3 FORMAL SPECIFICATION

  upload_file == lambda self .
    let upload = req.upload('file') in
    pre  upload /= undef /\ basename(upload.filename) =~ EXT_RE
         /\ NOT req->is_limit_exceeded
         /\ upload.size <= MAX_UPLOAD_BYTES
    let dest = uploads_dir/<random>/<filename> in
    let ok = eval { upload.move_to(dest); 1 } in
    pre  ok /\ -f dest
    post render_json({ url: '/open?path=' ++ url_escape(dest), path: dest })

=head3 EXAMPLE

  POST /upload  (multipart: file=@sales.csv)
    -> { "url": "/open?path=%2F...%2Fsales.csv", "path": "/.../.uploads/abc123/sales.csv" }

=cut

sub upload_file ($self) {
	my $upload = $self->req->upload('file');
	unless ($upload && $upload->filename) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_none') },
			status => 400,
		);
	}

	# Enforce upload size limit.  max_request_size in startup() sets the
	# transport-layer cap, but Mojolicious still calls the controller when the
	# limit fires (with req->is_limit_exceeded true and partial content in the
	# upload asset).  Check is_limit_exceeded first; fall through to an asset
	# size check as a belt-and-braces guard for any bytes that slipped through.
	if ($self->req->is_limit_exceeded || $upload->size > $MAX_UPLOAD_BYTES) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_too_large', $MAX_UPLOAD_MIB) },
			status => 413,
		);
	}

	# /s so .* matches \n; a percent-decoded newline inside a browser filename
	# must not silently truncate the directory-strip, leaving "dir\ncomponent" in.
	(my $filename = $upload->filename) =~ s{.*[/\\]}{}s;
	unless ($filename && $filename =~ $EXT_RE) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_ext') },
			status => 415,
		);
	}

	# Store uploads in <uploads_dir>/<random_subdir>/<original_filename>.  The
	# staging directory comes from the app (config uploads_dir, default
	# <app_home>/.uploads) so a deployment can point it at a writable disc and
	# a test can keep its uploads out of the directory another process clears.
	# Using the original filename is essential: Database::Abstraction derives
	# the table name from the file stem, so "sales.csv" must stay "sales.csv".
	# The random subdirectory prevents collisions from concurrent same-name uploads.
	my $uploads_base = $self->app->_uploads_dir;
	$uploads_base->make_path unless -d $uploads_base;
	my $sub_dir = tempdir(DIR => $uploads_base->to_string, CLEANUP => 0);
	my $dest    = Mojo::File->new($sub_dir)->child($filename)->to_string;

	# move_to returns the destination Mojo::File on success; croaks on I/O
	# failure.  Wrap in eval so a disk error becomes a 500 JSON response
	# rather than a bare Mojolicious exception page.
	# Use the "eval { ...; 1 }" idiom: $ok is undef only when THIS eval
	# threw, avoiding false positives from a stale $@ left by Mojo's
	# internal dispatch code that runs before the controller action.
	my $ok = eval { $upload->move_to($dest); 1 };
	if (!$ok || !-f $dest) {
		remove_tree($sub_dir);
		return $self->render(
			json   => { error => $self->_i18n('error_upload_save') },
			status => 500,
		);
	}

	$self->render(json => {
		url  => '/open?path=' . url_escape($dest),
		path => $dest,
	});
}

sub clear_uploads ($self) {
	my $uploads_dir = $self->app->_uploads_dir;

	return $self->render(json => { freed => 0, count => 0 })
		unless -d $uploads_dir;

	my ($freed, $count) = (0, 0);

	# Each upload lands in <uploads_dir>/<random_subdir>/<filename>.
	# Iterate the subdirs, tally file sizes, then remove each subdir tree.
	$uploads_dir->list({ dir => 1 })->each(sub {
		my ($entry) = @_;
		if (-d $entry) {
			$entry->list->each(sub {
				my ($file) = @_;
				return unless -f $file;
				$freed += (-s $file) // 0;
				$count++;
			});
			$entry->remove_tree;
		} elsif (-f $entry) {
			$freed += (-s $entry) // 0;
			$count++;
			unlink $entry->to_string;
		}
	});

	$self->render(json => { freed => $freed, count => $count });
}

# graph_view
#
# Purpose: Render a D3.js line chart from the current data pipeline.
# Entry:   Query params identical to /join (l=, j=, c=, f=, d=) plus:
#            x=<column>  -- X-axis column name
#            y=<column>  -- Y-axis column name (values must be numeric)
#            back=<url>  -- URL for the "Back to table" link (set by JS)
# Exit:    Emits a TT-rendered HTML page with a brush-to-zoom HTML::D3 snippet.
#          Each data point carries an "extra" hash of every column not used
#          as the X or Y axis; HTML::D3 displays these in the hover tooltip.
#          A "Reset zoom" button appears after the user brushes to zoom in.
#          Returns HTTP 400 for missing/invalid column names, 404 if the
#          data source cannot be opened, 200 with an error message when
#          no plottable rows exist.
sub graph_view ($self) {
	my $x_col      = $self->param('x')      // '';
	my $y_col      = $self->param('y')      // '';
	my $series_col = $self->param('series') // '';
	my $agg_fn     = lc($self->param('agg') // '');
	my $back       = _safe_back_url($self->param('back')) // '/';
	my $back2      = _safe_back_url($self->param('back2'));
	my $back2_lbl  = $self->param('back2_label') // '';

	return $self->render(text => 'Missing x or y column parameter', status => 400)
		unless length($x_col) && length($y_col);

	# ?agg= is the measure vocabulary the pivot and the stats page already use,
	# with no new names: a misspelt one is refused here rather than drawn as
	# nothing.  Absent, this route behaves exactly as it always has.
	if (length $agg_fn && !_measure_fn_ok($agg_fn)) {
		return $self->render(
			text   => $self->_i18n('error_agg_fn', $agg_fn, join(' ', @MEASURE_FNS)),
			status => 400,
		);
	}

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'x');
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	# Pre-filter before building pairs, same as _run_export_pipeline.
	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $x_col", status => 400)
		unless $col_set{$x_col};
	return $self->render(text => "Column not found: $y_col", status => 400)
		unless $col_set{$y_col};
	if (length $series_col) {
		return $self->render(text => "Column not found: $series_col", status => 400)
			unless $col_set{$series_col};
	}

	# The x axis is the dimension span= buckets.
	$x_col = $span->{col} if $span;

	# --- Aggregated path: ?agg= plots one point per group of the x axis rather
	# than one per row, which is what turns a bucketed x into a timechart. ---
	if (length $agg_fn) {
		my $m = _visual_measure($agg_fn, $y_col);
		return $self->render(text => $m->{error}, status => 400) if $m->{error};

		my $agg_rows = $self->_grouped_totals(
			{ source => $src, records => $records },
			{
				by  => [ length($series_col) ? ($x_col, $series_col) : ($x_col) ],
				fn  => $m->{fn},
				val => $m->{val},
				as  => 'value',
			},
		);

		my (%value_of, %series_seen, @series_order, %bucket_seen, @bucket_order);
		for my $row (@$agg_rows) {
			my $bucket = _decode_cell($row->{$x_col} // '');
			next unless length $bucket;
			push @bucket_order, $bucket unless $bucket_seen{$bucket}++;
			my $name = length($series_col) ? _decode_cell($row->{$series_col} // '') : '';
			next if length($series_col) && !length $name;
			push @series_order, $name unless $series_seen{$name}++;
			$value_of{$bucket}{$name} = $row->{value};
		}

		# Buckets in label order: the ISO labels a time bucket produces sort
		# chronologically as strings, which is why they are ISO.
		my @buckets = sort @bucket_order;
		my @series  = sort @series_order;
		my $title   = "$m->{label} by $x_col" . (length($series_col) ? " and $series_col" : '');

		require HTML::D3;
		my ($chart_html, $point_count, @series_data);
		if (length $series_col) {
			@series_data = map {
				my $name = $_;
				my @points = map {
					defined $value_of{$_}{$name}
						? { label => $_, value => $value_of{$_}{$name} } : ()
				} @buckets;
				@points ? { name => $name, data => \@points } : ();
			} @series;
			return $self->render(
				text   => 'No plottable data: no rows have valid numeric values in the Y column.',
				status => 200,
			) unless @series_data;
			$point_count = scalar @series_data;
			$chart_html = HTML::D3->new(title => $title, width => 1100, height => 580)
				->render_multi_series_line_chart_snippet(\@series_data, { animated => 1 })->{html};
		} else {
			my @pairs = map {
				defined $value_of{$_}{''} ? [ $_, $value_of{$_}{''} ] : ()
			} @buckets;
			return $self->render(
				text   => 'No plottable data: no rows have valid numeric values in the Y column.',
				status => 200,
			) unless @pairs;
			$point_count = scalar @pairs;
			$chart_html = HTML::D3->new(title => $title, width => 1100, height => 580)
				->render_zoomable_line_chart_snippet(\@pairs, { animated => 1 })->{html};
		}
		utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

		my %chart_spec = (
			kind   => 'graph',
			title  => $title,
			encode => {
				x => $x_col, y => $y_col,
				(length($series_col) ? (series => $series_col) : ()),
				agg => $m->{fn},
			},
		);
		my ($platform, $language) = $self->_resolve_template;
		my ($source_url, $source_accessed) = $self->_url_attribution;
		return $self->render(
			handler          => 'tt',
			template         => "$platform/$language/graph",
			format           => 'html',
			title            => $title,
			chart_html       => $chart_html,
			chart            => \%chart_spec,
			chart_json       => $self->_chart_json(\%chart_spec),
			back_url         => ($back2 // $back),
			back_label       => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
			($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
			point_count      => $point_count,
			source_url       => $source_url,
			source_accessed  => $source_accessed,
			language         => $language,
		);
	}

	# --- Multi-series path: ?series=<col> groups records into one line per value ---
	if (length $series_col) {
		my %by_series;
		my @series_order;
		for my $row (@{$records}) {
			my $x   = $row->{$x_col}      // '';
			my $y   = $row->{$y_col}      // '';
			my $grp = $row->{$series_col} // '';
			next unless length($x) && length($y) && length($grp);
			my $yn  = _numeric_cell($y);
			next unless defined $yn;
			unless (exists $by_series{$grp}) {
				push @series_order, $grp;
				$by_series{$grp} = [];
			}
			push @{$by_series{$grp}}, { label => _decode_cell($x), value => $yn };
		}

		return $self->render(
			text   => 'No plottable data: no rows have valid numeric values in the Y column.',
			status => 200,
		) unless @series_order;

		my @series_data = map { { name => $_, data => $by_series{$_} } } @series_order;

		my ($source_url, $source_accessed) = $self->_url_attribution;

		require HTML::D3;
		my $title   = "$y_col vs $x_col by $series_col";
		my $snippet = HTML::D3->new(title => $title, width => 1100, height => 580)
			->render_multi_series_line_chart_snippet(\@series_data, { animated => 1 });

		my $chart_html = $snippet->{html};
		utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

		my %chart_spec = (
			kind   => 'graph',
			title  => $title,
			encode => { x => $x_col, y => $y_col, series => $series_col },
		);
		my ($platform, $language) = $self->_resolve_template;
		return $self->render(
			handler         => 'tt',
			template        => "$platform/$language/graph",
			format          => 'html',
			title           => $title,
			chart_html      => $chart_html,
			chart           => \%chart_spec,
			chart_json      => $self->_chart_json(\%chart_spec),
			back_url        => ($back2 // $back),
			back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
			($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
			point_count     => scalar @series_order,
			source_url      => $source_url,
			source_accessed => $source_accessed,
			language        => $language,
		);
	}

	# --- Single-series path (original behaviour when ?series= is absent) ---

	# Extract [label, value] pairs; skip rows where Y is missing or non-numeric.
	my @pairs;
	for my $row (@{$records}) {
		my $x  = $row->{$x_col} // '';
		my $y  = $row->{$y_col} // '';
		next unless length($x) && length($y);
		my $yn = _numeric_cell($y);
		next unless defined $yn;
		my %extra = map { $_ => _decode_cell($row->{$_}) } grep { $_ ne $x_col && $_ ne $y_col } @{$columns};
		push @pairs, [_decode_cell($x), $yn, \%extra];
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid numeric values in the Y column.',
		status => 200,
	) unless @pairs;

	my @y_vals = map { $_->[1] } @pairs;
	my ($min_y, $max_y, $avg_y);

	# Try aggregate() push path for the global min/max/avg reference lines.
	# Falls back to List::Util on the already-extracted @y_vals when push is
	# not available (no source, filters active, or non-pushable column).
	my @f_specs    = grep { /\S/ } @{ _filter_specs($self) };
	my $has_filter = !!@f_specs;
	if (!$ENV{BI_FORCE_PERL_AGG} && $src && !$has_filter && !_dedup_requested($self)
		&& _measure_pushable($src, 'avg', $y_col, $records)) {
		my $ref = eval {
			$src->aggregate(
				by       => [],
				measures => [
					_measure('min', $y_col, 'lo'),
					_measure('max', $y_col, 'hi'),
					_measure('avg', $y_col, 'mean'),
				],
			)
		};
		if (!$@ && $ref && @$ref) {
			$min_y = $ref->[0]{lo};
			$max_y = $ref->[0]{hi};
			$avg_y = $ref->[0]{mean};
		}
	}
	# Perl fallback: compute from the already-stripped @y_vals.
	unless (defined $min_y) {
		$min_y = min(@y_vals);
		$max_y = max(@y_vals);
		$avg_y = sum(@y_vals) / scalar(@y_vals);
	}

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = "$y_col vs $x_col";
	my $snippet = HTML::D3->new(title => $title, width => 1100, height => 580)
		->render_zoomable_line_chart_snippet(\@pairs, { animated => 1 });

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind   => 'graph',
		title  => $title,
		encode => { x => $x_col, y => $y_col },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler          => 'tt',
		template         => "$platform/$language/graph",
		format           => 'html',
		title            => $title,
		chart_html       => $chart_html,
		chart            => \%chart_spec,
		chart_json       => $self->_chart_json(\%chart_spec),
		back_url         => ($back2 // $back),
		back_label       => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		point_count      => scalar @pairs,
		ref_min_y        => $min_y,
		ref_max_y        => $max_y,
		ref_avg_y        => sprintf('%.4g', $avg_y),
		source_url       => $source_url,
		source_accessed  => $source_accessed,
		language         => $language,
	);
}

sub pie_view ($self) {
	my $cat_col      = $self->param('cat') // '';
	my $val_col      = $self->param('val') // '';
	my $donut        = $self->param('donut') ? 1 : 0;
	my $back         = _safe_back_url($self->param('back')) // '/';
	my $back2        = _safe_back_url($self->param('back2'));
	my $back2_lbl    = $self->param('back2_label') // '';

	return $self->render(text => 'Missing cat or val column parameter', status => 400)
		unless length($cat_col) && length($val_col);

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'cat');
	return $self->render(text => $span->{error}, status => 400)
		if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $cat_col", status => 400)
		unless $col_set{$cat_col};

	# '__count__' is the sentinel value sent when the user picks "Count (rows)".
	my $count_mode = ($val_col eq '__count__');
	return $self->render(text => "Column not found: $val_col", status => 400)
		unless $count_mode || $col_set{$val_col};

	$cat_col = $span->{col} if $span;

	# Detect the currency symbol from the first non-empty source value.
	# This is a display concern; derive from the pre-filtered source rows so the
	# $/$GBP/EUR prefix on the legend is unchanged regardless of the push path.
	my $currency_symbol = '';
	if (!$count_mode) {
		for my $row (@$records) {
			my $v = $row->{$val_col} // '';
			next unless length($v);
			if ($v =~ /\A\s*\(?\s*([^\d\s.,\-\(])/) {
				$currency_symbol = $1;
				last;
			}
		}
	}

	# Aggregate via _grouped_totals (push path or Perl fold).
	my $agg_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{
			by  => [$cat_col],
			fn  => $count_mode ? 'count' : 'sum',
			val => $count_mode ? undef   : $val_col,
			as  => 'value',
		},
	);

	# Top-N: keep the highest-N slices, aggregate the rest as "Other".
	my $topn_n = int($self->param('topn') || 0);
	if ($topn_n > 0 && @$agg_rows > $topn_n) {
		my @sorted   = sort { ($b->{value} // 0) <=> ($a->{value} // 0) } @$agg_rows;
		my @top_agg  = @sorted[0 .. $topn_n - 1];
		my %top_cats = map { ($_->{$cat_col} // '') => 1 } @top_agg;
		my $other_rec = [
			grep { !$top_cats{$_->{$cat_col} // ''} } @$records
		];
		if (@$other_rec) {
			my $other = $self->_grouped_totals(
				{ source => undef, records => $other_rec },
				{ by  => [], fn  => ($count_mode ? 'count' : 'sum'),
				  val => ($count_mode ? undef : $val_col), as => 'value' },
			);
			push @top_agg, { $cat_col => 'Other', value => $other->[0]{value} }
				if @$other && defined $other->[0]{value};
		}
		$agg_rows = \@top_agg;
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected columns.',
		status => 200,
	) unless @$agg_rows;

	my @slices = map { [_decode_cell($_->{$cat_col}), $_->{value}] } @$agg_rows;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $scheme  = $self->param('scheme') // 'tableau10';
	my $title   = $count_mode ? "Count by $cat_col" : "$val_col by $cat_col";
	my $snippet = HTML::D3->new(title => $title, width => 600, height => 500)
		->render_pie_chart_snippet(\@slices, {
			animated     => 1,
			donut        => $donut,
			sort_slices  => 'value',
			max_slices   => 12,
			legend       => 1,
			color_scheme => $scheme,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'pie',
		title   => $title,
		encode  => { cat => $cat_col, value => $val_col },
		options => { scheme => $scheme, donut => $donut },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler          => 'tt',
		template         => "$platform/$language/pie",
		format           => 'html',
		title            => $title,
		chart_html       => $chart_html,
		chart            => \%chart_spec,
		chart_json       => $self->_chart_json(\%chart_spec),
		back_url         => ($back2 // $back),
		back_label       => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		drill_back_url   => $back,
		slice_count      => scalar @slices,
		cat_col          => $cat_col,
		val_col          => $val_col,
		currency_symbol  => $currency_symbol,
		source_url       => $source_url,
		source_accessed  => $source_accessed,
		language         => $language,
	);
}

=head2 heatmap_view

C<GET /heatmap> -- Render a D3.js grid heatmap for two categorical axes.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  x=<col>      X-axis (horizontal) categorical column (required)
  y=<col>      Y-axis (vertical) categorical column (required)
  val=<col>    Cell value column (optional; when absent, cells show row count)
  scheme=<name> D3 sequential colour scheme name (default: YlOrRd)
  show_val=1   Overlay the numeric value inside each cell
  back=<url>   URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l       spec     Required.  Left table spec (table:name or path:/abs/path).
  x       string   Required.  Name of the X-axis categorical column.
  y       string   Required.  Name of the Y-axis categorical column.
  val     string   Optional.  Name of the value column; omit for count mode.
  scheme  string   Optional.  D3 sequential colour scheme name.
  show_val flag    Optional.  Set to 1 to render values inside cells.
  back    url      Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html           Rendered heatmap page.
  200 text/plain          "No plottable data: ..." when grid is empty.
  400 text/plain          Missing x= or y= parameter.
  400 text/plain          Column not found: <col>.
  404 text/plain          "Could not open data source" when l= is absent/invalid.

=head3 MESSAGES

  error_heatmap_no_data -- no (x,y) pair has a non-empty value.

=head3 FORMAL SPECIFICATION

  heatmap_view == lambda self .
    pre length(x_col) > 0 /\ length(y_col) > 0
        /\ x_col in columns /\ y_col in columns
    let triples = { (row[x_col], row[y_col], row[val_col]) | row in records,
                    all three fields non-empty } in
    post render(heatmap, triples)

=head3 EXAMPLE

  GET /heatmap?l=table:sales&x=region&y=product&val=amount
    -> 200 HTML page containing D3 heatmap SVG

=cut

sub heatmap_view ($self) {
	my $x_col     = $self->param('x')        // '';
	my $y_col     = $self->param('y')        // '';
	my $val_col   = $self->param('val')      // '';
	my $scheme    = $self->param('scheme')   // 'YlOrRd';
	my $show_v    = $self->param('show_val') ? 1 : 0;
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	return $self->render(text => 'Missing x or y column parameter', status => 400)
		unless length($x_col) && length($y_col);

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'x');
	return $self->render(text => $span->{error}, status => 400)
		if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $x_col", status => 400)
		unless $col_set{$x_col};
	return $self->render(text => "Column not found: $y_col", status => 400)
		unless $col_set{$y_col};
	return $self->render(text => "Column not found: $val_col", status => 400)
		if length($val_col) && !$col_set{$val_col};

	# A heatmap's time dimension is its x axis, which is the one span= buckets.
	$x_col = $span->{col} if $span;

	# Collect first-seen axis order from the filtered source rows.
	# The aggregate path returns groups ordered by (x,y) ascending, which
	# differs from first-seen.  We re-derive the layout order from the source
	# so the grid renders in natural data order regardless of backend.
	my (@x_order, @y_order, %seen_x, %seen_y);
	for my $row (@$records) {
		my $x = $row->{$x_col} // next;
		my $y = $row->{$y_col} // next;
		next unless length($x) && length($y);
		push @x_order, $x unless $seen_x{$x}++;
		push @y_order, $y unless $seen_y{$y}++;
	}

	# Aggregate with _grouped_totals (push or Perl fold).
	my $agg_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{
			by  => [$x_col, $y_col],
			fn  => length($val_col) ? 'sum' : 'count',
			val => length($val_col) ? $val_col : undef,
			as  => 'value',
		},
	);

	# Index aggregate rows by [x][y] for O(1) lookup.
	my %grid;
	for my $row (@$agg_rows) {
		$grid{$row->{$x_col}}{$row->{$y_col}} = $row->{value};
	}

	my @triples = map {
		my ($raw_x, $xv) = ($_, _decode_cell($_));
		map { [$xv, _decode_cell($_), $grid{$raw_x}{$_} // 0] } @y_order
	} @x_order;

	return $self->render(
		text   => 'No plottable data: check that x and y columns contain values.',
		status => 200,
	) unless @triples;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = length($val_col) ? "$val_col by $x_col and $y_col"
	                                : "Count by $x_col and $y_col";
	my $snippet = HTML::D3->new(title => $title, width => 900, height => 500)
		->render_heatmap_snippet(\@triples, {
			x_label      => $x_col,
			y_label      => $y_col,
			val_label    => (length($val_col) ? $val_col : 'Count'),
			color_scheme => $scheme,
			show_values  => $show_v,
			animated     => 1,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'heatmap',
		title   => $title,
		encode  => { x => $x_col, y => $y_col, value => $val_col },
		options => { scheme => $scheme, show_values => $show_v },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler          => 'tt',
		template         => "$platform/$language/heatmap",
		format           => 'html',
		title            => $title,
		chart_html       => $chart_html,
		chart            => \%chart_spec,
		chart_json       => $self->_chart_json(\%chart_spec),
		cell_count       => scalar @triples,
		back_url         => ($back2 // $back),
		back_label       => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url       => $source_url,
		source_accessed  => $source_accessed,
		language         => $language,
	);
}

=head2 bar_view

C<GET /bar> -- Render a D3.js bar chart grouped by a categorical column.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  cat=<col>    Category (X-axis) column (required)
  val=<col>    Value column to sum per category; omit or use C<__count__>
               to count rows instead of summing (optional)
  orient=h     Horizontal bars (default: vertical)
  sort=value|label  Sort bars by descending value or ascending label
  max=N        Collapse bars beyond the top-N into an "Other" bar
  back=<url>   URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l       spec     Required.  Left table spec (table:name or path:/abs/path).
  cat     string   Required.  Name of the category column.
  val     string   Optional.  Name of the value column; use __count__ or
                   omit entirely to count rows per category.
  orient  string   Optional.  "h" for horizontal bars; default vertical.
  sort    string   Optional.  "value" or "label"; default file order.
  max     integer  Optional.  Collapse beyond top-N categories into "Other".
  back    url      Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html           Rendered bar chart page (SVG element id="bar_chart").
  200 text/plain          "No plottable data: ..." when no categories exist.
  400 text/plain          Missing cat= parameter.
  400 text/plain          Column not found: <col>.
  404 text/plain          "Could not open data source" when l= is absent/invalid.

=head3 MESSAGES

  error_bar_no_data -- no row has a non-empty category value.

=head3 FORMAL SPECIFICATION

  bar_view == lambda self .
    pre length(cat_col) > 0 /\ cat_col in columns
    let bars = { (cat, sum(val)) | row in records, row[cat_col] = cat,
                 val /= undef } in
    post render(bar, bars, orientation, sort, max_bars)

=head3 EXAMPLE

  GET /bar?l=table:sales&cat=region&val=amount&sort=value
    -> 200 HTML page with id="bar_chart" SVG element

=cut

sub bar_view ($self) {
	my $cat_col   = $self->param('cat')    // '';
	my $val_col   = $self->param('val')    // '';
	my $orient    = $self->param('orient') // 'vertical';
	my $sort      = $self->param('sort')   // 'none';
	my $max_bars  = int($self->param('max') || 0);
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	return $self->render(text => 'Missing cat column parameter', status => 400)
		unless length($cat_col);

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	# span= buckets the category column by expanding into the calculated field a
	# reader could have typed, so the buckets come from the same arithmetic a
	# ?c= definition would use.  See _span_calc_spec.
	my $span = $self->_span_calc_spec($columns, 'cat');
	return $self->render(text => $span->{error}, status => 400)
		if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $cat_col", status => 400)
		unless $col_set{$cat_col};

	# '__count__' sentinel: count rows per category instead of summing a column.
	my $count_mode = ($val_col eq '__count__' || !length($val_col));
	return $self->render(text => "Column not found: $val_col", status => 400)
		unless $count_mode || $col_set{$val_col};

	# The chart groups by the bucket column the request asked for, if it did.
	$cat_col = $span->{col} if $span;

	# Aggregate via _grouped_totals (push path or Perl fold).
	my $agg_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{
			by  => [$cat_col],
			fn  => $count_mode ? 'count' : 'sum',
			val => $count_mode ? undef   : $val_col,
			as  => 'value',
		},
	);

	# Top-N: keep the highest-N categories, aggregate the rest as "Other".
	my $topn_n = int($self->param('topn') || 0);
	if ($topn_n > 0 && @$agg_rows > $topn_n) {
		my @sorted   = sort { ($b->{value} // 0) <=> ($a->{value} // 0) } @$agg_rows;
		my @top_agg  = @sorted[0 .. $topn_n - 1];
		my %top_cats = map { ($_->{$cat_col} // '') => 1 } @top_agg;
		my $other_rec = [
			grep { !$top_cats{$_->{$cat_col} // ''} } @$records
		];
		if (@$other_rec) {
			my $other = $self->_grouped_totals(
				{ source => undef, records => $other_rec },
				{ by  => [], fn  => ($count_mode ? 'count' : 'sum'),
				  val => ($count_mode ? undef : $val_col), as => 'value' },
			);
			push @top_agg, { $cat_col => 'Other', value => $other->[0]{value} }
				if @$other && defined $other->[0]{value};
		}
		$agg_rows = \@top_agg;
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected columns.',
		status => 200,
	) unless @$agg_rows;

	my @bars = map { [_decode_cell($_->{$cat_col}), $_->{value}] } @$agg_rows;

	my $orientation = ($orient eq 'h') ? 'horizontal' : 'vertical';
	my $sort_bars   = ($sort eq 'value' || $sort eq 'label') ? $sort : 'none';

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = $count_mode ? "Count by $cat_col"
	                          : "$val_col by $cat_col";
	my $snippet = HTML::D3->new(title => $title, width => 800, height => 480)
		->render_bar_chart_snippet(\@bars, {
			animated     => 1,
			orientation  => $orientation,
			sort_bars    => $sort_bars,
			color        => 'categorical',
			show_values  => 0,
			value_label  => ($count_mode ? 'Count' : $val_col),
			x_label      => $cat_col,
			($max_bars > 0 ? (max_bars => $max_bars) : ()),
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'bar',
		title   => $title,
		encode  => { cat => $cat_col, value => $val_col },
		options => { orientation => ($orient // 'v'), max_items => $max_bars },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/bar",
		format          => 'html',
		title           => $title,
		chart_html      => $chart_html,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		bar_count       => scalar @bars,
		cat_col         => $cat_col,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

=head2 folder_view

C<GET /folder> -- Browse a data table grouped by the letter-prefix hierarchy
of an order-number column (e.g. A10, CT4, B3).

The top level displays one folder icon per initial letter group (A, B, C ...).
Clicking a folder with sub-prefixes (e.g. C contains CA and CB items) shows
the sub-folders; clicking a leaf prefix shows the actual data rows sorted
numerically by the embedded digit sequence.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  col=<col>      Column whose values contain order codes (optional; auto-
                 detected when absent by scanning the first 10 rows for
                 values matching C<[A-Z]{1,4}\d+[A-Z]?>)
  prefix=<str>   Current drill-down prefix, e.g. "CA" (optional; top-level
                 when absent)
  back=<url>     URL for the "Back to table" breadcrumb link (optional;
                 derived from C<l=> when absent)

=head3 API SPECIFICATION

=head4 INPUT

  l       spec     Required.  Left table spec (table:name or path:/abs/path).
  col     string   Optional.  Order-code column name.
  prefix  string   Optional.  Current letter prefix; max length MAX_PREFIX_LEN.
  back    url      Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html    Rendered folder page with folder grid and/or item table.
  400 text/plain   "Missing l= parameter" when l= is absent.
  400 text/plain   "Prefix too long" when prefix exceeds MAX_PREFIX_LEN (20).
  404 text/plain   "Could not open data source" when the data source is unavailable.

=head3 MESSAGES

None -- all failure paths render plain text with an HTTP status code.

=head3 FORMAL SPECIFICATION

  folder_view == lambda self .
    pre length(left_spec) > 0 /\ length(prefix) <= MAX_PREFIX_LEN
    let records = pipeline(left_spec, joins, filters)
        prefix_map = { p -> [row] | row in records, row[col] =~ /[A-Z]+/ -> p } in
    IF prefix = "" THEN
      post render(folder, folders = first_letters(prefix_map))
    ELSE
      post render(folder, folders = sub_prefixes(prefix, prefix_map),
                          items   = sort_numeric(prefix_map[prefix]))

=head3 EXAMPLE

  GET /folder?l=table:orders&col=order_no
    -> 200 HTML folder grid showing A (12 items), B (7 items), C (4 items)

  GET /folder?l=table:orders&col=order_no&prefix=A
    -> 200 HTML folder grid for sub-prefixes and items directly under "A"

=cut

sub folder_view ($self) {
	my $key_col   = $self->param('col')    // '';
	my $prefix    = $self->param('prefix') // '';
	my $left_spec = $self->param('l')      // '';

	return $self->render(text => 'Missing l= parameter', status => 400)
		unless length($left_spec);

	# Guard against DoS: a crafted prefix longer than any real order-code would
	# generate O(N) breadcrumb entries and a proportionally large HTML response.
	return $self->render(text => 'Prefix too long', status => 400)
		if length($prefix) > $MAX_PREFIX_LEN;

	# Fall back to the table's own URL when no explicit back= is supplied,
	# so the breadcrumb always has a "Back to table" link.
	my $back = _safe_back_url($self->param('back'))
		|| $self->_spec_to_url($left_spec);

	my ($records, $columns) = $self->_run_export_pipeline;
	return if $self->stash('_reduce_error');
	return $self->render(text => 'Could not open data source', status => 404)
		unless $records;

	# Auto-detect key column: find the first column whose sampled values look
	# like order-number codes (1-4 uppercase letters followed by digits).
	if (!length($key_col)) {
		my $sample_end = $#{$records} < 9 ? $#{$records} : 9;
		OUTER: for my $col (@{$columns}) {
			for my $row (@{$records}[0 .. $sample_end]) {
				if (($row->{$col} // '') =~ /\A[A-Z]{1,4}\d+[A-Z]?\z/) {
					$key_col = $col;
					last OUTER;
				}
			}
		}
		$key_col ||= ($columns->[0] // '');
	}

	# Build prefix -> [rows] map.  Prefix is the leading letter-run of each
	# key value: "A10" -> "A", "CT4" -> "CT", "CC30A" -> "CC".
	my %prefix_to_rows;
	for my $row (@{$records}) {
		my $val = $row->{$key_col} // '';
		my ($p) = $val =~ /\A([A-Z]+)/;
		next unless defined $p;
		push @{ $prefix_to_rows{$p} }, $row;
	}

	# Return the sorted list of "one-step" child prefixes of $par: all known
	# prefixes that share the parent as a strict prefix and extend it by
	# exactly one letter.
	my $sub_prefixes = sub {
		my ($par) = @_;
		my $len = length($par);
		my %seen;
		for my $p (keys %prefix_to_rows) {
			next if length($p) <= $len;
			next if substr($p, 0, $len) ne $par;
			$seen{ substr($p, 0, $len + 1) } = 1;
		}
		return sort keys %seen;
	};

	# Count total items underneath a prefix (including all deeper sub-prefixes).
	my $deep_count = sub {
		my ($par) = @_;
		my $n = 0;
		for my $p (keys %prefix_to_rows) {
			$n += scalar @{ $prefix_to_rows{$p} }
				if substr($p, 0, length($par)) eq $par;
		}
		return $n;
	};

	my ($platform, $language) = $self->_resolve_template;

	# Base URL carries the table spec (and optional col=) so every sub-link
	# re-uses the same data source without repeating params.
	my $base_url = '/folder?l=' . url_escape($left_spec);
	$base_url .= '&col=' . url_escape($key_col) if length($key_col);
	# The table it came from travels too, so a folder level keeps the trail.
	$base_url .= '&back=' . url_escape($back);

	my (@folders, @items, @breadcrumb);

	if (!length($prefix)) {
		# Top level: group all prefixes by their first letter.
		my %first_letter;
		for my $p (keys %prefix_to_rows) {
			$first_letter{ substr($p, 0, 1) } = 1;
		}
		for my $fl (sort keys %first_letter) {
			push @folders, {
				name  => $fl,
				count => $deep_count->($fl),
				href  => $base_url . '&prefix=' . url_escape($fl),
			};
		}
	} else {
		# Build breadcrumb: one entry per letter-prefix layer up to current.
		# e.g. prefix="CD" -> [ {name="C", href=...}, {name="CD", href=undef} ]
		for my $i (1 .. length($prefix)) {
			my $p = substr($prefix, 0, $i);
			push @breadcrumb, {
				name => $p,
				href => ($i < length($prefix))
					? ($base_url . '&prefix=' . url_escape($p))
					: undef,
			};
		}

		# One-step child prefixes of the current prefix (sub-folders).
		for my $sp ($sub_prefixes->($prefix)) {
			push @folders, {
				name  => $sp,
				count => $deep_count->($sp),
				href  => $base_url . '&prefix=' . url_escape($sp),
			};
		}

		# Items whose prefix matches exactly (e.g. prefix="C" shows C1, C3, ...).
		@items = @{ $prefix_to_rows{$prefix} // [] };

		# Sort by the numeric part of the key value so A9 < A10.
		@items = sort {
			my ($an) = ($a->{$key_col} // '') =~ /(\d+)/;
			my ($bn) = ($b->{$key_col} // '') =~ /(\d+)/;
			($an // 0) <=> ($bn // 0)
				|| ($a->{$key_col} // '') cmp ($b->{$key_col} // '');
		} @items;
	}

	my $title = length($prefix) ? "Folder: $prefix" : 'Folder view';

	$self->render(
		handler    => 'tt',
		template   => "$platform/$language/folder",
		format     => 'html',
		title      => $title,
		folders    => \@folders,
		items      => \@items,
		columns    => $columns,
		key_col    => $key_col,
		prefix     => $prefix,
		breadcrumb => \@breadcrumb,
		# Inside a folder the trail goes on past this page, so its own crumb
		# links to the top of the folder view.
		(@breadcrumb ? (trail => do {
			my $trail = _breadcrumb_trail($self);
			$trail->[-1]{url} = $base_url if @$trail;
			$trail;
		}) : ()),
		base_url   => $base_url,
		back_url   => $back,
		back_label => 'Back to table',
		left_spec  => $left_spec,
		language   => $language,
	);
}

=head2 tables_view

C<GET /tables> -- Schema browser for multi-table databases (SQLite, etc.).
Lists all internal tables with their columns; clicking a table opens it.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=   string   Required.  Table spec: "table:name" (data_dir) or
                 "path:/abs/path" (filesystem path).  The file must be a
                 SQLite database.

=head4 OUTPUT

Renders C<tables.html.tt> with:

  db_label   string   Short name / stem of the database file
  tables     ARRAYREF of { name, columns => [...], href }
  spec       string   The raw l= spec (for building back links)
  back_url   string   URL to navigate back one level
  back_label string   Label for the back link

=cut

sub tables_view ($self) {
	my ($platform, $language) = $self->_resolve_template;
	my $spec = $self->param('l');
	return $self->reply->not_found unless defined $spec && length $spec;

	my ($file_path, $db_label, $back_url, $back_label);
	my @tables;

	if ($spec =~ /\Atable:([A-Za-z0-9_]+)\z/) {
		my $table_name = lc $1;
		my $data_dir   = _data_dir_for($self->app);
		for my $ext (qw(sql sqlite sqlite3 db)) {
			my $p = $data_dir->child("$table_name.$ext");
			if (-f $p) {
				$file_path = $p->to_string;
				last;
			}
		}
		return $self->reply->not_found unless defined $file_path;
		$db_label  = $table_name;
		$back_url  = '/';
		$back_label = 'Home';
	} elsif ($spec =~ /\Apath:(.+)\z/) {
		my $path_arg = $1;
		my $file = eval { Mojo::File->new($path_arg)->realpath };
		return $self->reply->not_found
			unless defined $file && -f $file && $file->basename =~ /\.(?:sql|sqlite|sqlite3|db)\z/i;
		$file_path  = $file->to_string;
		($db_label  = $file->basename) =~ s/\.[^.]+\z//;
		$back_url   = '/browse?path=' . url_escape($file->dirname->to_string);
		$back_label = 'Back to browser';
	} elsif ($spec =~ $REDIS_URL_RE) {
		# Bare redis:// URL -- scan keys and present a picker.
		# Parse redis://[:password@]host[:port][/db]
		my ($password, $hostport, $db_idx);
		if ($spec =~ m{\Aredis://(?::([^@]*)@)?([^/]+)(?:/(\d+))?\z}i) {
			($password, $hostport, $db_idx) = ($1, $2, $3);
		}
		$hostport //= 'localhost:6379';
		$db_label   = "redis://$hostport";
		$back_url   = '/';
		$back_label = 'Home';

		eval {
			# Load Redis::Fast if available, fall back to Redis.
			# Use the file-path form ("Redis/Fast.pm") because require with a
			# plain string treats it as a filename, not a module name.
			my $pkg;
			for my $mod ('Redis::Fast', 'Redis') {
				(my $file = $mod) =~ s{::}{/}g;
				if (eval { require "$file.pm"; 1 }) { $pkg = $mod; last }
			}
			croak 'Redis or Redis::Fast must be installed to browse a Redis server'
				unless $pkg;

			my $redis = $pkg->new(
				server      => $hostport,
				cnx_timeout => 5,
				read_timeout => 10,
			);
			$redis->auth($password) if defined $password && length $password;
			$redis->select(int($db_idx)) if defined $db_idx && int($db_idx) > 0;

			# SCAN in a loop; stop at 200 keys -- enough for a picker.
			my $cursor = 0;
			my @all_keys;
			do {
				my ($new_cursor, $batch) = $redis->scan($cursor, 'COUNT', 100);
				$cursor = $new_cursor;
				push @all_keys, @{ $batch // [] };
			} while ($cursor ne '0' && @all_keys < 200);

			my $tables_url = '/tables?l=' . url_escape($spec);
			for my $key (sort @all_keys) {
				my $open_url = '/open?path='    . url_escape("redis:$key|$spec")
					. '&back='       . url_escape($tables_url)
					. '&back_label=Redis+keys';
				push @tables, { name => $key, columns => [], href => $open_url };
			}
		};
		return $self->reply->not_found if $@;
	} else {
		return $self->reply->not_found;
	}

	if (defined $file_path) { eval {
		require DBI;
		my $dbh = DBI->connect(
			"dbi:SQLite:dbname=$file_path", q{}, q{},
			{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
		my $tnames = $dbh->selectcol_arrayref(
			q{SELECT name FROM sqlite_master }
			. q{WHERE type='table' AND name NOT LIKE 'sqlite_%' }
			. q{ORDER BY name});
		for my $tname (@{ $tnames // [] }) {
			my @cols;
			my $sth = eval { $dbh->prepare("PRAGMA table_info(\"$tname\")") };
			if ($sth) {
				$sth->execute;
				while (my $row = $sth->fetchrow_hashref) {
					push @cols, $row->{name};
				}
			}
			my $open_url = '/open?path=' . url_escape($file_path)
				. '&it=' . url_escape($tname)
				. '&back=' . url_escape('/tables?l=' . $spec)
				. '&back_label=' . url_escape(ucfirst($db_label) . ' schema');
			push @tables, { name => $tname, columns => \@cols, href => $open_url };
		}
		$dbh->disconnect;
	}; return $self->reply->not_found if $@; }

	$self->render(
		template   => "$platform/$language/tables",
		handler    => 'tt',
		format     => 'html',
		title      => ucfirst($db_label) . ' -- Tables',
		db_label   => $db_label,
		tables     => \@tables,
		spec       => $spec,
		back_url   => $back_url,
		back_label => $back_label,
		language   => $language,
	);
}

=head2 pivot_view

C<GET /pivot> -- Crosstab / pivot table view.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  rows=<col>[,<col>...]  Row dimensions (required, comma-separated column names)
  cols=<col>[,<col>...]  Column dimensions (optional)
  m=<col>:<fn>:<as>      Measure spec, repeatable (required); col may be empty for count
  h=<as>:<op>:<val>      Post-aggregation HAVING filter (repeatable, optional)
  totals=1               Include row subtotals, column subtotals, and grand total
  scheme=<name>          Colour scheme for cell shading (optional)
  max_cols=<n>           Collapse column headers beyond top-N into "Other"
  page= / per_page=      Pagination over row groups
  format=csv|sqlite|json Export the pivot grid

=cut

sub pivot_view ($self) {
	my $left_spec = $self->param('l') // '';
	return $self->render(text => 'Missing l= parameter', status => 400)
		unless length $left_spec;

	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	my $rows_str = $self->param('rows') // '';
	return $self->render(text => $self->_i18n('error_pivot_rows_required'), status => 400)
		unless length $rows_str;

	my @measure_strs = @{ $self->every_param('m') // [] };
	return $self->render(text => $self->_i18n('error_pivot_measure_req'), status => 400)
		unless @measure_strs;

	# Split dimensions on comma.  A dimension name containing a comma
	# would produce an ambiguous split; that must be rejected.
	my @rows = split /,/, $rows_str, -1;
	my @cols = split /,/, ($self->param('cols') // ''), -1;
	@cols = grep { length $_ } @cols;

	my @measures;
	for my $ms (@measure_strs) {
		my $m = _parse_measure_param($ms);
		return $self->render(
			text   => $self->_i18n('error_pivot_measure_invalid', $ms, join(' ', @MEASURE_FNS)),
			status => 400,
		) unless $m;
		push @measures, $m;
	}

	my $show_totals = ($self->param('totals') // '') ? 1 : 0;
	my $scheme      = $self->param('scheme') // '';
	my $max_cols_n  = int($self->param('max_cols') || 0);
	my $format      = lc($self->param('format') // '');

	# Build the data pipeline.
	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	# span= buckets one dimension, which for a pivot is one of the rows= columns;
	# the dimension itself may be any of them, so with more than one it is tcol=
	# that says which.  See _span_calc_spec.
	my $span = $self->_span_calc_spec($columns, 'rows');
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	# Calculated fields (?c=name:expr) -- evaluated before aggregation so calc
	# columns are available as row/col dimensions and measure columns.
	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};

	for my $dim (@rows, @cols) {
		return $self->render(
			text   => $self->_i18n('error_pivot_dim_not_found', $dim),
			status => 400,
		) unless $col_set{$dim};
	}

	if ($span) {
		@rows = map { $_ eq $span->{src} ? $span->{col} : $_ } @rows;
		@cols = map { $_ eq $span->{src} ? $span->{col} : $_ } @cols;
	}

	for my $m (@measures) {
		next unless defined $m->{col} && length $m->{col};
		return $self->render(
			text   => $self->_i18n('error_measure_column', $m->{col}),
			status => 400,
		) unless $col_set{$m->{col}};
	}

	my $pipeline = { source => $src, records => $records };

	# -----------------------------------------------------------------------
	# Aggregate: one _grouped_totals call per measure, grouped by all
	# row AND column dimensions together.
	# -----------------------------------------------------------------------
	my (%cells, %row_combos, %col_combos);
	my (@row_key_order, @col_key_order);
	my (%row_seen, %col_seen);

	for my $m (@measures) {
		my $cv  = (defined $m->{col} && length $m->{col}) ? $m->{col} : undef;
		my $agg = $self->_grouped_totals($pipeline, {
			by  => [@rows, @cols],
			fn  => $m->{fn},
			val => $cv,
			as  => $m->{as},
		});
		for my $row (@$agg) {
			my $rkey = join("\x00", map { $row->{$_} // '' } @rows);
			my $ckey = join("\x00", map { $row->{$_} // '' } @cols);
			unless ($row_seen{$rkey}++) {
				push @row_key_order, $rkey;
				$row_combos{$rkey} = { map { $_ => ($row->{$_} // '') } @rows };
			}
			unless ($col_seen{$ckey}++) {
				push @col_key_order, $ckey;
				$col_combos{$ckey} = { map { $_ => ($row->{$_} // '') } @cols };
			}
			$cells{$rkey}{$ckey}{$m->{as}} = $row->{$m->{as}};
		}
	}

	# -----------------------------------------------------------------------
	# Post-aggregation HAVING filters (h=<as>:<op>:<val>) applied row-by-row.
	# Each filter operates on a virtual row whose keys are the measure aliases.
	# -----------------------------------------------------------------------
	my @h_specs = @{ $self->every_param('h') // [] };
	if (@h_specs) {
		my @keep;
		for my $rkey (@row_key_order) {
			# Build a virtual row containing each measure's cell value
			# (using first col-combo as representative, or grand-total style).
			# For HAVING, we filter on the *row subtotal* value, not a single cell.
			# We'll compute a temp subtotal row for each row key.
			my %vrow;
			for my $m (@measures) {
				# Sum across cols for this row as representative value.
				my $v = 0;
				for my $ck (@col_key_order) {
					my $cv = $cells{$rkey}{$ck}{$m->{as}};
					$v += $cv if defined $cv;
				}
				$vrow{$m->{as}} = $v;
			}
			my $ok = 1;
			for my $hs (@h_specs) {
				my $passed = _apply_filter_spec([\%vrow], $hs);
				$ok = 0 unless @$passed;
			}
			push @keep, $rkey if $ok;
		}
		@row_key_order = @keep;
	}

	# -----------------------------------------------------------------------
	# Top-N rows: keep only the top-N row groups (ranked by measure sum
	# across all col combos); aggregate the remaining rows as an "Other" row.
	# -----------------------------------------------------------------------
	{
		my $topn_n   = int($self->param('topn') || 0);
		my $topn_col = $self->param('topn_col') // '';

		if ($topn_n > 0 && @row_key_order > $topn_n) {
			my %m_aliases = map { $_->{as} => 1 } @measures;
			if (length $topn_col && !$m_aliases{$topn_col}) {
				return $self->render(
					text   => $self->_i18n('error_topn_col', $topn_col),
					status => 400,
				);
			}
			my $sort_as = length($topn_col) ? $topn_col : $measures[0]{as};

			# Sort rows by descending sum of sort_as across all column combos.
			my @sorted_rkeys = sort {
				(do { my $s = 0; $s += ($cells{$b}{$_}{$sort_as} // 0) for @col_key_order; $s })
				<=>
				(do { my $s = 0; $s += ($cells{$a}{$_}{$sort_as} // 0) for @col_key_order; $s })
			} @row_key_order;

			my @top_rkeys  = @sorted_rkeys[0 .. $topn_n - 1];
			my @rest_rkeys = @sorted_rkeys[$topn_n .. $#sorted_rkeys];

			if (@rest_rkeys) {
				my %top_rkey_set = map { $_ => 1 } @top_rkeys;
				my $other_rec = [
					grep {
						my $r = $_;
						!$top_rkey_set{ join("\x00", map { $r->{$_} // '' } @rows) }
					} @$records
				];
				if (@$other_rec) {
					my $ork = '__topn_other__';
					$row_combos{$ork} = { map { $_ => 'Other' } @rows };
					for my $m (@measures) {
						my $cv = (defined $m->{col} && length $m->{col}) ? $m->{col} : undef;
						my $oa = $self->_grouped_totals(
							{ source => undef, records => $other_rec },
							{ by => [@cols], fn => $m->{fn}, val => $cv, as => $m->{as} },
						);
						for my $row (@$oa) {
							my $ck = join("\x00", map { $row->{$_} // '' } @cols);
							$cells{$ork}{$ck}{$m->{as}} = $row->{$m->{as}};
						}
					}
					@row_key_order = (@top_rkeys, $ork);
				} else {
					@row_key_order = @top_rkeys;
				}
			} else {
				@row_key_order = @top_rkeys;
			}
		}
	}

	# -----------------------------------------------------------------------
	# Subtotals and grand total (three additional _grouped_totals calls
	# per measure when totals=1).
	# -----------------------------------------------------------------------
	my (%row_subtotals, %col_subtotals, %grand_total);

	if ($show_totals) {
		for my $m (@measures) {
			my $cv = (defined $m->{col} && length $m->{col}) ? $m->{col} : undef;

			# Row subtotals: group by @rows only.
			my $rsub = $self->_grouped_totals($pipeline, {
				by  => [@rows],
				fn  => $m->{fn},
				val => $cv,
				as  => $m->{as},
			});
			for my $r (@$rsub) {
				my $rk = join("\x00", map { $r->{$_} // '' } @rows);
				$row_subtotals{$rk}{$m->{as}} = $r->{$m->{as}};
			}

			# Column subtotals: group by @cols only.
			if (@cols) {
				my $csub = $self->_grouped_totals($pipeline, {
					by  => [@cols],
					fn  => $m->{fn},
					val => $cv,
					as  => $m->{as},
				});
				for my $c (@$csub) {
					my $ck = join("\x00", map { $c->{$_} // '' } @cols);
					$col_subtotals{$ck}{$m->{as}} = $c->{$m->{as}};
				}
			}

			# Grand total: group by nothing (all rows -> one result row).
			my $gtot = $self->_grouped_totals($pipeline, {
				by  => [],
				fn  => $m->{fn},
				val => $cv,
				as  => $m->{as},
			});
			$grand_total{$m->{as}} = $gtot->[0]{$m->{as}} if @$gtot;
		}
	}

	# -----------------------------------------------------------------------
	# max_cols: collapse the tail of column combos beyond top-N into "Other".
	# The top-N are ranked by the first measure's column subtotal (or cell sum).
	# -----------------------------------------------------------------------
	if ($max_cols_n > 0 && @col_key_order > $max_cols_n) {
		my $first_as = $measures[0]{as};
		my @sorted_ckeys = sort {
			(  $show_totals
			   ? ($col_subtotals{$b}{$first_as} // 0)
			   : (do { my $s = 0; $s += ($cells{$_}{$b}{$first_as} // 0) for @row_key_order; $s })
			)
			<=>
			(  $show_totals
			   ? ($col_subtotals{$a}{$first_as} // 0)
			   : (do { my $s = 0; $s += ($cells{$_}{$a}{$first_as} // 0) for @row_key_order; $s })
			)
		} @col_key_order;
		my @top_ckeys  = @sorted_ckeys[0 .. $max_cols_n - 1];
		my @rest_ckeys = @sorted_ckeys[$max_cols_n .. $#sorted_ckeys];
		if (@rest_ckeys) {
			my $other_key = '__other__';
			$col_combos{$other_key} = { map { $_ => 'Other' } @cols };
			for my $rk (@row_key_order) {
				for my $m (@measures) {
					my ($v, $have) = (0, 0);
					for my $ck (@rest_ckeys) {
						my $cv = $cells{$rk}{$ck}{$m->{as}};
						if (defined $cv) { $v += $cv; $have = 1 }
					}
					$cells{$rk}{$other_key}{$m->{as}} = $have ? $v : undef;
				}
			}
			@col_key_order = (@top_ckeys, $other_key);
		} else {
			@col_key_order = @top_ckeys;
		}
	}

	# -----------------------------------------------------------------------
	# Export path: build flat records from the grid.
	# -----------------------------------------------------------------------
	if ($format && $format =~ /\A(?:csv|sqlite|sql|json|xlsx)\z/) {
		my @grid_records;
		for my $rk (@row_key_order) {
			for my $ck (@col_key_order) {
				my %rec;
				$rec{$_} = $row_combos{$rk}{$_} // '' for @rows;
				$rec{$_} = $col_combos{$ck}{$_} // '' for @cols;
				$rec{$_->{as}} = $cells{$rk}{$ck}{$_->{as}} // '' for @measures;
				push @grid_records, \%rec;
			}
		}
		my @export_cols = (@rows, @cols, map { $_->{as} } @measures);
		return $self->_render_csv(\@grid_records, \@export_cols, 'pivot')
			if $format eq 'csv';
		return $self->_render_sqlite(\@grid_records, \@export_cols, 'pivot')
			if $format eq 'sqlite' || $format eq 'sql';
		return $self->_render_json(\@grid_records, \@export_cols, 'pivot')
			if $format eq 'json';
		if ($format eq 'xlsx') {
			$self->stash(buffer => 0);
			require Excel::Writer::XLSX;
			my $out = '';
			open my $fh, '>', \$out
				or return $self->render(text => 'Cannot open XLSX buffer', status => 500);
			my $wb = Excel::Writer::XLSX->new($fh);
			my $ws = $wb->add_worksheet('pivot');
			$ws->write_row(0, 0, \@export_cols);
			my $row_idx = 1;
			for my $rec (@grid_records) {
				$ws->write_row($row_idx++, 0, [ map { $rec->{$_} // '' } @export_cols ]);
			}
			$wb->close;
			$self->res->headers->content_type(
				'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
			);
			$self->res->headers->content_disposition(
				'attachment; filename="pivot.xlsx"'
			);
			return $self->render(data => $out);
		}
	}

	# -----------------------------------------------------------------------
	# Pagination: slice @row_key_order using the N+1 trick.
	# Must come after the export early-return above (exports use the full set)
	# and after subtotals/grand total (computed from $pipeline, not @row_key_order).
	# -----------------------------------------------------------------------
	my ($page, $per_page, $offset) = $self->_pagination;
	my $total_row_groups = scalar @row_key_order;
	my $piv_has_next = ($total_row_groups > $offset + $per_page) ? 1 : 0;
	@row_key_order = $offset < $total_row_groups
		? @row_key_order[$offset .. ($piv_has_next ? $offset + $per_page - 1 : $#row_key_order)]
		: ();

	my $piv_page_url = $self->req->url->clone;
	$piv_page_url->query->remove('page')->remove('per_page');

	# -----------------------------------------------------------------------
	# Build the template-ready data structure.
	# -----------------------------------------------------------------------
	my @col_combo_list = map {
		my $ck = $_;
		{
			key      => $ck,
			dim_vals => $col_combos{$ck},
			label    => join(' / ', map { $col_combos{$ck}{$_} // '' } @cols),
		}
	} @col_key_order;

	my @grid_rows;
	for my $rk (@row_key_order) {
		my %row_cells;
		for my $ck (@col_key_order) {
			$row_cells{$ck} = $cells{$rk}{$ck} // {};
		}
		push @grid_rows, {
			row_vals  => $row_combos{$rk},
			cells     => \%row_cells,
			subtotals => $show_totals ? ($row_subtotals{$rk} // {}) : {},
		};
	}

	(my $left_label = $left_spec) =~ s/\A(?:table:|path:|url:)//;

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler       => 'tt',
		template      => "$platform/$language/pivot",
		format        => 'html',
		title         => 'Pivot: ' . join(', ', @rows),
		rows_dims     => \@rows,
		cols_dims     => \@cols,
		measures      => \@measures,
		col_combos    => \@col_combo_list,
		grid_rows     => \@grid_rows,
		show_totals   => $show_totals,
		col_subtotals => \%col_subtotals,
		grand_total   => \%grand_total,
		scheme            => $scheme,
		left_spec         => $left_spec,
		left_label        => $left_label,
		back_url          => ($back2 // $back),
		back_label        => ($back2 ? ($back2_lbl || 'Back') : ($self->param('back_label') // 'Back to table')),
		($back2 ? (back2_url => $back, back2_label => ($self->param('back_label') // 'Back to table')) : ()),
		page              => $page,
		per_page          => $per_page,
		has_next          => $piv_has_next,
		page_base_url     => $piv_page_url->to_string,
		total_row_groups  => $total_row_groups,
		language      => $language,
	);
}

=head2 stats_view

C<GET /stats> -- Column statistics panel.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus C<p=N>
to choose the percentile column (1 to 100, default 95), and C<range=name> with
C<rcol=column> for a relative window of rows.  Displays per-column statistics:
row_count, null_count, distinct_count, and for numeric columns min, max, range,
mean, median, the chosen percentile and sample standard deviation; first and
last are shown for every column, being the first and last value the column
holds.

C<distinct_count> is computed through C<_grouped_totals>, so it agrees with the
pivot view.  The numeric statistics are computed in Perl by sorting the column's
values, through the same C<_percentile_of>, C<_median_of>, C<_stdev_of> and
C<_range_of> arithmetic the pivot's C<median>, C<pN>, C<stdev> and C<range>
measures use -- so a median here and a median measure there are the same number.

=cut

sub stats_view ($self) {
	my $left_spec = $self->param('l') // '';
	return $self->render(text => 'Missing l= parameter', status => 400)
		unless length $left_spec;

	# The percentile column is the reader's to choose; an unreadable one is a
	# 400 rather than a silent 95, so the page never claims a level it did not
	# apply.
	my $pct_arg    = $self->param('p');
	my $percentile = 95;
	if (defined $pct_arg && length $pct_arg) {
		return $self->render(
			text   => $self->_i18n('error_stats_percentile', $pct_arg),
			status => 400,
		) unless $pct_arg =~ /\A\d{1,3}\z/ && $pct_arg >= 1 && $pct_arg <= 100;
		$percentile = $pct_arg + 0;
	}

	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my $row_count = scalar @$records;
	my $pipeline  = { source => $src, records => $records };

	my @stats;
	for my $col (@{$columns}) {
		# null_count = rows where cell is undef or '' (phase 2 definition).
		my @nonnull    = grep { defined $_->{$col} && length($_->{$col}) } @$records;
		my $null_count = $row_count - scalar @nonnull;

		# distinct_count via _grouped_totals (count groups by the column).
		my $dist_rows      = $self->_grouped_totals($pipeline, {
			by => [$col],
			fn => 'count',
			as => 'cnt',
		});
		my $distinct_count = scalar @$dist_rows;

		# first/last: the value the column holds in the first and the last row
		# that has one.  $nonnull is in row order, so no second pass is needed
		# and the two agree with the pivot's first() and last() measures.
		my $first_val = $nonnull[0]  ? $nonnull[0]{$col}  : undef;
		my $last_val  = $nonnull[-1] ? $nonnull[-1]{$col} : undef;

		# Numeric statistics, through the same arithmetic the pivot measures use.
		my @nums = grep { defined $_ } map { _numeric_cell($_->{$col}) } @nonnull;
		my ($min_val, $max_val, $avg_val, $median_val, $range_val, $pct_val, $stdev_val);
		if (@nums) {
			my @sorted = sort { $a <=> $b } @nums;
			$min_val = $sorted[0];
			$max_val = $sorted[-1];
			my $sum  = 0;
			$sum += $_ for @nums;
			$avg_val = $sum / @nums;
			# _median_of is _percentile_of at 50; a stdev of one value is undef,
			# which the template shows as a dash rather than as a spread of 0.
			$median_val = _median_of(\@sorted);
			$range_val  = _range_of(\@sorted);
			$pct_val    = _percentile_of(\@sorted, $percentile);
			$stdev_val  = _stdev_of(\@sorted);
		}

		push @stats, {
			col            => $col,
			row_count      => $row_count,
			null_count     => $null_count,
			distinct_count => $distinct_count,
			first          => $first_val,
			last           => $last_val,
			(defined $min_val ? (
				min     => $min_val,
				max     => $max_val,
				range   => sprintf('%.4g', $range_val),
				avg     => sprintf('%.4g', $avg_val),
				median  => sprintf('%.4g', $median_val),
				pct     => sprintf('%.4g', $pct_val),
				stdev   => (defined $stdev_val ? sprintf('%.4g', $stdev_val) : undef),
			) : ()),
		};
	}

	(my $left_label = $left_spec) =~ s/\A(?:table:|path:|url:)//;

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler    => 'tt',
		template   => "$platform/$language/stats",
		format     => 'html',
		title          => 'Column statistics',
		stats          => \@stats,
		stats_percentile => $percentile,
		row_count      => $row_count,
		left_spec      => $left_spec,
		left_label     => $left_label,
		drill_back_url => $back,
		drill_sep      => (CORE::index($back, '?') >= 0 ? '&' : '?'),
		stats_url      => $self->req->url->path_query,
		back_url       => ($back2 // $back),
		back_label     => ($back2 ? ($back2_lbl || 'Back') : ($self->param('back_label') // 'Back to table')),
		($back2 ? (back2_url => $back, back2_label => ($self->param('back_label') // 'Back to table')) : ()),
		language   => $language,
	);
}

# ---------------------------------------------------------------------------
# Calculated-field CRUD  (POST /calc/save, POST /calc/delete, GET /calc/list)
# ---------------------------------------------------------------------------

sub calc_save ($self) {
	my $spec = $self->param('l') // '';
	my $name = $self->param('name') // '';
	my $expr = $self->param('expr') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(
		json   => { error => $self->_i18n('error_calc_name', $name) },
		status => 400,
	) unless $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
	return $self->render(json => { error => 'expr= required' }, status => 400)
		unless length $expr;

	my $models = $self->_read_models;
	$models->{fields}{$spec}{$name} = $expr;
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

sub calc_delete ($self) {
	my $spec = $self->param('l') // '';
	my $name = $self->param('name') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	delete $models->{fields}{$spec}{$name};
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

sub calc_list ($self) {
	my $spec = $self->param('l') // '';
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { fields => $models->{fields}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Named-group CRUD  (POST /groups/save, POST /groups/delete, GET /groups/list)
# ---------------------------------------------------------------------------

sub groups_save ($self) {
	my $spec       = $self->param('l')     // '';
	my $col        = $self->param('col')   // '';
	my $group_name = $self->param('group') // '';
	my @values     = @{ $self->every_param('values') // [] };

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => 'col= required' }, status => 400)
		unless length $col;
	return $self->render(json => { error => 'group= required' }, status => 400)
		unless length $group_name;

	my $models = $self->_read_models;
	$models->{groups}{$spec}{$col}{$group_name} = \@values;
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

sub groups_delete ($self) {
	my $spec       = $self->param('l')     // '';
	my $col        = $self->param('col')   // '';
	my $group_name = $self->param('group') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $col && length $group_name) {
		delete $models->{groups}{$spec}{$col}{$group_name};
	} elsif (length $col) {
		delete $models->{groups}{$spec}{$col};
	} else {
		delete $models->{groups}{$spec};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

sub groups_list ($self) {
	my $spec = $self->param('l') // '';
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { groups => $models->{groups}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Date-pattern CRUD  (POST /dates/save, POST /dates/delete, GET /dates/list)
# ---------------------------------------------------------------------------

# dates_save: POST /dates/save?l=<spec>&col=<col>&pattern=<fmt>[&time=<fmt>][&as=timestamp]
# Stores a strptime-style date normalisation pattern for $col in models.json.
# Only the three patterns in %ALLOWED_DATE_PATTERNS are accepted, and only the
# two in %ALLOWED_TIME_PATTERNS beside one of them.
#
# A pattern on its own is stored as the string it has always been, so an
# existing entry keeps its meaning.  A time, or as=timestamp, stores the hash
# shape { date =>, time =>, as => } that Calc::date_normalise reads, and which
# normalises the column to 'YYYY-MM-DDTHH:MM:SS' -- the shape the date
# comparisons already read to the second, so a last_24_hours window filters on
# a column that has a pattern of this kind.
sub dates_save ($self) {
	my $spec    = $self->param('l')       // '';
	my $col     = $self->param('col')     // '';
	my $pattern = $self->param('pattern') // '';
	my $time    = $self->param('time')    // '';
	my $as      = $self->param('as')      // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => 'col= required' }, status => 400)
		unless length $col;
	return $self->render(
		json   => { error => $self->_i18n('error_date_pattern', $pattern) },
		status => 400,
	) unless $ALLOWED_DATE_PATTERNS{$pattern};
	return $self->render(
		json   => { error => $self->_i18n('error_date_time_pattern', $time) },
		status => 400,
	) if length($time) && !$ALLOWED_TIME_PATTERNS{$time};
	return $self->render(
		json   => { error => $self->_i18n('error_date_as', $as) },
		status => 400,
	) if length($as) && $as ne 'timestamp';

	my $stored = (length($time) || length($as))
		? { date => $pattern, (length($time) ? (time => $time) : ()), (length($as) ? (as => $as) : ()) }
		: $pattern;

	my $models = $self->_read_models;
	$models->{date_patterns}{$spec}{$col} = $stored;
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# dates_delete: POST /dates/delete?l=<spec>&col=<col>
# Removes the pattern for $col (or all patterns for $spec when col is absent).
sub dates_delete ($self) {
	my $spec = $self->param('l')   // '';
	my $col  = $self->param('col') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $col) {
		delete $models->{date_patterns}{$spec}{$col};
	} else {
		delete $models->{date_patterns}{$spec};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# dates_list: GET /dates/list?l=<spec>
# Returns { patterns: { col: pattern, ... } } for $spec, where a pattern is the
# date-format string it has always been or, for a column that also holds a time,
# { date =>, time =>, as => }.
sub dates_list ($self) {
	my $spec = $self->param('l') // '';
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { patterns => $models->{date_patterns}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Geo column preferences CRUD  (POST /geo/save, POST /geo/delete, GET /geo/list)
#
# Stores the user's choice of lat/lon/loc columns for a given l= spec in
# models.json under geo.<spec>.columns.  The geocode cache itself lives under
# geo.<spec>.places and is written by _map_data independently.
# ---------------------------------------------------------------------------

# geo_save: POST /geo/save?l=<spec>&col=<col>&kind=lat|lon|location
sub geo_save ($self) {
	my $spec = $self->param('l')    // '';
	my $col  = $self->param('col')  // '';
	my $kind = $self->param('kind') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => 'col= required' }, status => 400)
		unless length $col;
	return $self->render(json => { error => 'kind must be lat, lon, or location' }, status => 400)
		unless $kind =~ /\A(?:lat|lon|location)\z/;

	my $models = $self->_read_models;
	$models->{geo}{$spec}{columns}{$col} = { kind => $kind };
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# geo_delete: POST /geo/delete?l=<spec>&col=<col>
# Omit col= to clear all column preferences for the spec.
sub geo_delete ($self) {
	my $spec = $self->param('l')   // '';
	my $col  = $self->param('col') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $col) {
		delete $models->{geo}{$spec}{columns}{$col};
	} else {
		delete $models->{geo}{$spec}{columns};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# geo_list: GET /geo/list?l=<spec>
# Returns { columns: { col: { kind: "lat"|"lon"|"location" }, ... } }.
sub geo_list ($self) {
	my $spec = $self->param('l') // '';
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { columns => $models->{geo}{$spec}{columns} // {} });
}

# ---------------------------------------------------------------------------
# Scatter chart  (GET /scatter)
# ---------------------------------------------------------------------------

sub scatter_view ($self) {
	my $x_col      = $self->param('x')      // '';
	my $y_col      = $self->param('y')      // '';
	my $series_col = $self->param('series') // '';
	my $size_col   = $self->param('size')   // '';
	my $scheme     = $self->param('scheme') // 'tableau10';
	my $min_r      = int($self->param('min_r') || 3);
	my $max_r      = int($self->param('max_r') || 15);
	$min_r = 1 if $min_r < 1; $min_r = 40 if $min_r > 40;
	$max_r = 1 if $max_r < 1; $max_r = 40 if $max_r > 40;
	($min_r, $max_r) = ($max_r, $min_r) if $min_r > $max_r;
	my $back       = _safe_back_url($self->param('back')) // '/';
	my $back2      = _safe_back_url($self->param('back2'));
	my $back2_lbl  = $self->param('back2_label') // '';

	return $self->render(text => 'Missing x= parameter', status => 400) unless length $x_col;
	return $self->render(text => 'Missing y= parameter', status => 400) unless length $y_col;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $x_col",      status => 400) unless $col_set{$x_col};
	return $self->render(text => "Column not found: $y_col",      status => 400) unless $col_set{$y_col};
	return $self->render(text => "Column not found: $series_col", status => 400)
		if length $series_col && !$col_set{$series_col};
	return $self->render(text => "Column not found: $size_col",   status => 400)
		if length $size_col && !$col_set{$size_col};

	if (length $series_col && !$SCATTER_SCHEMES{$scheme}) {
		return $self->render(text => "Unknown colour scheme: $scheme", status => 400);
	}

	my @points;
	for my $row (@$records) {
		my $xv = _numeric_cell($row->{$x_col} // '');
		my $yv = _numeric_cell($row->{$y_col} // '');
		next unless defined $xv && defined $yv;
		my %extra = map { $_ => _decode_cell($row->{$_} // '') }
		            grep { $_ ne $x_col && $_ ne $y_col } @$columns;
		my %pt_meta;
		$pt_meta{series} = _decode_cell($row->{$series_col}) if length $series_col;
		if (length $size_col) {
			my $sv = _numeric_cell($row->{$size_col} // '');
			$pt_meta{size} = $sv if defined $sv;
		}
		push @points, [$xv, $yv, \%extra, (%pt_meta ? \%pt_meta : ())];
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid numeric values in both selected columns.',
		status => 200,
	) unless @points;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = "$y_col vs $x_col";
	my $snippet = HTML::D3->new(title => $title, width => 800, height => 480)
		->render_scatter_chart_snippet(\@points, {
			animated           => 1,
			x_label            => $x_col,
			y_label            => $y_col,
			(length $series_col ? (colour_by_series => 1, series_col => $series_col, scheme => $scheme) : ()),
			(length $size_col   ? (size_col => $size_col, radius_range => [$min_r, $max_r])            : ()),
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'scatter',
		title   => $title,
		encode  => { x => $x_col, y => $y_col,
			(length $series_col ? (series => $series_col) : ()),
			(length $size_col   ? (size   => $size_col)   : ()),
		},
		options => { scheme => $scheme },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/scatter",
		format          => 'html',
		title           => $title,
		chart_html      => $chart_html,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		point_count     => scalar @points,
		x_col           => $x_col,
		y_col           => $y_col,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# ---------------------------------------------------------------------------
# Stacked bar chart  (GET /stacked)
# ---------------------------------------------------------------------------

sub stacked_view ($self) {
	my $cat_col   = $self->param('cat')    // '';
	# ?series= is the canonical spec name; ?seg= is the legacy alias (keep both).
	my $seg_col   = $self->param('series') // $self->param('seg') // '';
	my $val_col   = $self->param('val')    // '';
	my $orient    = $self->param('orient') // 'v';
	my $scheme    = $self->param('scheme') // 'tableau10';
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	return $self->render(text => 'Missing cat= parameter',    status => 400) unless length $cat_col;
	return $self->render(text => 'Missing series= parameter', status => 400) unless length $seg_col;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'cat');
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $cat_col", status => 400) unless $col_set{$cat_col};
	return $self->render(text => "Column not found: $seg_col", status => 400) unless $col_set{$seg_col};

	my $count_mode = (!length $val_col || $val_col eq '__count__');
	return $self->render(text => "Column not found: $val_col", status => 400)
		unless $count_mode || $col_set{$val_col};

	$cat_col = $span->{col} if $span;

	# Aggregate by [cat, seg] via _grouped_totals to respect the governing
	# invariant (all numbers from a single path) and to get ascending key order.
	my $agg_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{
			by  => [$cat_col, $seg_col],
			fn  => $count_mode ? 'count' : 'sum',
			val => $count_mode ? undef   : $val_col,
			as  => 'value',
		},
	);

	# render_stacked_bar_snippet accepts flat [{cat_col=>,seg_col=>,val_col=>}] rows
	# and handles the stacking itself; only include pairs actually returned (no phantom
	# zero cells for missing intersections).
	my @data = map {
		my $cat = _decode_cell($_->{$cat_col} // '');
		my $seg = _decode_cell($_->{$seg_col} // '');
		(length $cat && length $seg)
			? { cat => $cat, seg => $seg, val => $_->{value} }
			: ()
	} @$agg_rows;

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected columns.',
		status => 200,
	) unless @data;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = $count_mode ? "Count by $cat_col and $seg_col"
	                          : "$val_col by $cat_col and $seg_col";
	my $snippet = HTML::D3->new(title => $title, width => 900, height => 500)
		->render_stacked_bar_snippet(\@data, {
			orient  => ($orient eq 'h') ? 'h' : 'v',
			x_label => $cat_col,
			scheme  => $scheme,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'stacked',
		title   => $title,
		encode  => { cat => $cat_col, series => $seg_col, value => $val_col },
		options => { orientation => $orient, scheme => $scheme },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/stacked",
		format          => 'html',
		title           => $title,
		chart_html      => $chart_html,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		bar_count       => scalar(grep { defined $_->{cat} } @data),
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# ---------------------------------------------------------------------------
# Combo bar+line chart  (GET /combo)
# ---------------------------------------------------------------------------

sub combo_view ($self) {
	# ?cat= is the canonical spec name; ?x= is the legacy alias (keep both).
	my $x_col      = $self->param('cat') // $self->param('x') // '';
	# ?bar_val= is the canonical spec name; ?bar= is the legacy alias (keep both).
	my $bar_col    = $self->param('bar_val')  // $self->param('bar')  // '';
	# ?line_val= is the canonical spec name; ?line= is the legacy alias (keep both).
	my $line_col   = $self->param('line_val') // $self->param('line') // '';
	my $bar_label  = $self->param('bar_label')   // '';
	my $line_label = $self->param('line_label')  // '';
	my $back       = _safe_back_url($self->param('back')) // '/';
	my $back2      = _safe_back_url($self->param('back2'));
	my $back2_lbl  = $self->param('back2_label') // '';

	return $self->render(text => 'Missing cat= parameter',      status => 400) unless length $x_col;
	return $self->render(text => 'Missing bar_val= parameter',  status => 400) unless length $bar_col;
	return $self->render(text => 'Missing line_val= parameter', status => 400) unless length $line_col;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'cat', 'x');
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $x_col",    status => 400) unless $col_set{$x_col};
	return $self->render(text => "Column not found: $bar_col",  status => 400) unless $col_set{$bar_col};
	return $self->render(text => "Column not found: $line_col", status => 400) unless $col_set{$line_col};

	$x_col = $span->{col} if $span;

	# Aggregate bar and line measures separately via _grouped_totals so both
	# use the same path (push or fold) and produce ascending x-axis order.
	# A category missing from one result set renders as a gap (undef), not zero.
	my $bar_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{ by => [$x_col], fn => 'sum', val => $bar_col,  as => 'bar_val' },
	);
	my $line_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{ by => [$x_col], fn => 'sum', val => $line_col, as => 'line_val' },
	);

	# Merge: build a lookup from both result sets and walk the union of categories.
	my (%bar_map, %line_map, @x_order, %x_seen);
	for my $r (@$bar_rows) {
		my $xv = _decode_cell($r->{$x_col} // '');
		next unless length $xv;
		push @x_order, $xv unless $x_seen{$xv}++;
		$bar_map{$xv} = $r->{bar_val};
	}
	for my $r (@$line_rows) {
		my $xv = _decode_cell($r->{$x_col} // '');
		next unless length $xv;
		push @x_order, $xv unless $x_seen{$xv}++;
		$line_map{$xv} = $r->{line_val};
	}

	my @data = map { {
		x        => $_,
		bar_val  => $bar_map{$_},   # undef = gap in bar series
		line_val => $line_map{$_},  # undef = gap in line series
	} } @x_order;

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected columns.',
		status => 200,
	) unless @data;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $eff_bar_lbl  = $bar_label  || $bar_col;
	my $eff_line_lbl = $line_label || $line_col;
	my $title        = "$eff_bar_lbl and $eff_line_lbl by $x_col";
	my $snippet = HTML::D3->new(title => $title, width => 900, height => 500)
		->render_combo_snippet(\@data, {
			bar_label  => $eff_bar_lbl,
			line_label => $eff_line_lbl,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind   => 'combo',
		title  => $title,
		encode => { x => $x_col, bar => $bar_col, line => $line_col },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/combo",
		format          => 'html',
		title           => $title,
		chart_html      => $chart_html,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		point_count     => scalar @data,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# ---------------------------------------------------------------------------
# Treemap  (GET /treemap)
# ---------------------------------------------------------------------------

sub treemap_view ($self) {
	# ?group= is the canonical spec name; ?cat= is the legacy alias (keep both).
	my $cat_col   = $self->param('group') // $self->param('cat') // '';
	# ?size= is the canonical spec name; ?val= is the legacy alias (keep both).
	my $val_col   = $self->param('size')  // $self->param('val') // '';
	my $scheme    = $self->param('scheme') // 'tableau10';
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	return $self->render(text => 'Missing group= parameter', status => 400) unless length $cat_col;
	# ?color= (colour-by-measure) is not yet implemented; reject it explicitly.
	return $self->render(text => '?color= is not yet supported for /treemap', status => 400)
		if defined $self->param('color');

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	my $span = $self->_span_calc_spec($columns, 'group', 'cat');
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $cat_col", status => 400) unless $col_set{$cat_col};

	my $count_mode = (!length $val_col || $val_col eq '__count__');
	return $self->render(text => "Column not found: $val_col", status => 400)
		unless $count_mode || $col_set{$val_col};

	$cat_col = $span->{col} if $span;

	my $agg_rows = $self->_grouped_totals(
		{ source => $src, records => $records },
		{
			by  => [$cat_col],
			fn  => $count_mode ? 'count' : 'sum',
			val => $count_mode ? undef   : $val_col,
			as  => 'value',
		},
	);

	# Top-N: keep the highest-N tiles, aggregate the rest as "Other".
	my $topn_n = int($self->param('topn') || 0);
	if ($topn_n > 0 && @$agg_rows > $topn_n) {
		my @sorted   = sort { ($b->{value} // 0) <=> ($a->{value} // 0) } @$agg_rows;
		my @top_agg  = @sorted[0 .. $topn_n - 1];
		my %top_cats = map { ($_->{$cat_col} // '') => 1 } @top_agg;
		my $other_rec = [
			grep { !$top_cats{$_->{$cat_col} // ''} } @$records
		];
		if (@$other_rec) {
			my $other = $self->_grouped_totals(
				{ source => undef, records => $other_rec },
				{ by  => [], fn  => ($count_mode ? 'count' : 'sum'),
				  val => ($count_mode ? undef : $val_col), as => 'value' },
			);
			push @top_agg, { $cat_col => 'Other', value => $other->[0]{value} }
				if @$other && defined $other->[0]{value};
		}
		$agg_rows = \@top_agg;
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected column.',
		status => 200,
	) unless @$agg_rows;

	my @data = map {
		{ path => 'Root/' . _decode_cell($_->{$cat_col}), value => $_->{value} }
	} @$agg_rows;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = $count_mode ? "Treemap of $cat_col by count" : "Treemap of $cat_col by $val_col";
	my $snippet = HTML::D3->new(title => $title, width => 800, height => 500)
		->render_treemap_snippet(\@data, {
			scheme => $scheme,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'treemap',
		title   => $title,
		encode  => { cat => $cat_col, value => $val_col },
		options => { scheme => $scheme },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/treemap",
		format          => 'html',
		title           => $title,
		chart_html      => $chart_html,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		tile_count      => scalar @data,
		cat_col         => $cat_col,
		drill_back_url  => $back,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# ---------------------------------------------------------------------------
# Histogram  (GET /histogram)
# ---------------------------------------------------------------------------

sub histogram_view ($self) {
	my $col       = $self->param('col')   // '';
	my $_bins_raw = $self->param('bins');
	my $bins      = (defined $_bins_raw && length $_bins_raw) ? $_bins_raw : 10;
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	return $self->render(text => 'Missing col= parameter', status => 400) unless length $col;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $col", status => 400) unless $col_set{$col};

	my @values;
	for my $row (@$records) {
		my $v = _numeric_cell($row->{$col} // '');
		push @values, $v if defined $v;
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid numeric values in the selected column.',
		status => 200,
	) unless @values;

	$bins = int($bins);
	$bins = 1   if $bins < 1;
	$bins = 200 if $bins > 200;

	# Server-side binning: compute equal-width bins over the data range.
	# Values equal to $max land in the highest bin (no overflow bar).
	# Uses the same bin-boundary logic as Calc.pm bin() to stay consistent with
	# ?c=band:bin(col,width) computed columns on the same data.
	use POSIX qw(floor);
	my $min_v = min(@values);
	my $max_v = max(@values);
	my @bin_data;
	if ($min_v == $max_v) {
		# All values identical: one bin.
		push @bin_data, { label => "$min_v", count => scalar @values, lo => $min_v, hi => $min_v };
	} else {
		my $raw_w = ($max_v - $min_v) / $bins;
		# Round up to a "nice" width using 10 significant digits (same guard as Calc bin()).
		my $width = sprintf('%.10g', $raw_w) + 0;
		$width = $raw_w if $width <= 0;  # safety: never produce zero width
		my $fmt = ($width == int($width)) ? '%d' : '%g';

		# Build bin boundaries.
		my @bin_counts;
		my @bin_los;
		for my $i (0 .. $bins - 1) {
			push @bin_los, $min_v + $i * $width;
			push @bin_counts, 0;
		}

		# Assign each value to a bin.
		for my $v (@values) {
			my $idx = floor(sprintf('%.10g', ($v - $min_v) / $width) + 0);
			$idx = $bins - 1 if $idx >= $bins;  # max value -> last bin
			$idx = 0         if $idx < 0;
			$bin_counts[$idx]++;
		}

		for my $i (0 .. $bins - 1) {
			next unless $bin_counts[$i];
			my $lo  = $bin_los[$i];
			my $hi  = $lo + $width;
			my $lbl = sprintf("[${fmt},${fmt})", $lo, $hi);
			push @bin_data, { label => $lbl, count => $bin_counts[$i], lo => $lo, hi => $hi };
		}
	}

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = "Distribution of $col";
	my $snippet = HTML::D3->new(title => $title, width => 800, height => 480)
		->render_histogram_snippet(\@bin_data, {
			binned  => 1,
			x_label => $col,
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'histogram',
		title   => $title,
		encode  => { value => $col },
		options => { bins => $bins },
	);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler          => 'tt',
		template         => "$platform/$language/histogram",
		format           => 'html',
		title            => $title,
		chart_html       => $chart_html,
		chart            => \%chart_spec,
		chart_json       => $self->_chart_json(\%chart_spec),
		value_count      => scalar @values,
		bins             => $bins,
		back_url         => ($back2 // $back),
		back_label       => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url       => $source_url,
		source_accessed  => $source_accessed,
		language         => $language,
	);
}

# ---------------------------------------------------------------------------
# Word cloud  (GET /wordcloud)
# ---------------------------------------------------------------------------

# The words that say nothing about the data: without them a cloud of a notes
# column is all "the" and "and".  English, like the only page language the
# templates have.  ?stop= adds to this list for one request rather than
# replacing it, so adding a word never silently brings back the ones this list
# already removes.
my %STOP_WORD = map { $_ => 1 } qw(
	a about above after again against all also am an and any are as at be
	because been before being below between both but by can could did do does
	doing down during each few for from further had has have having he her here
	hers herself him himself his how i if in into is it its itself just me more
	most my myself no nor not now of off on once only or other our ours ourselves
	out over own same she should so some such than that the their theirs them
	themselves then there these they this those through to too under until up
	very was we were what when where which while who whom why will with would
	you your yours yourself yourselves
);

# _percent_encode($text) -> $url_component
#
# Purpose: Percent-encode one value for a query string.
# Notes:   url_escape() works on bytes, so a decoded (character) string is
#          encoded to UTF-8 first; otherwise "caf\x{e9}" would become "caf%E9" and a
#          browser would read that back as Latin-1.
sub _percent_encode {
	my ($text) = @_;
	my $bytes = defined $text ? "$text" : '';
	utf8::encode($bytes) if utf8::is_utf8($bytes);
	return url_escape($bytes);
}

# _word_tokens($text, $minlen) -> @words
#
# Purpose: The words in one cell, lower-cased and split on everything that is
#          neither a letter, a digit nor an apostrophe.
# Entry:   $text is a cell (may be undef); $minlen is the shortest word kept.
# Exit:    The words at least $minlen characters long that contain a letter.
#          A run of digits alone is kept -- a year or a model number can be the
#          point of a column -- while a run of punctuation is not a word at all.
# Notes:   A CSV cell arrives as bytes, so it is decoded first (the same
#          _decode_cell() every page uses): without that, \p{L} would see the
#          bytes of "caf\x{e9}" and split the word in two.  The apostrophe stays
#          inside a word, so O'Brien is one word rather than "o" and "brien".
sub _word_tokens {
	my ($text, $minlen) = @_;
	return () unless defined $text && length $text;

	my @words = split /[^\p{L}\p{N}']+/, lc _decode_cell($text);
	for my $word (@words) {
		$word =~ s/\A'+//;
		$word =~ s/'+\z//;
	}

	return grep { length($_) >= $minlen && /\p{L}/ } @words;
}

# _wordcloud_option($raw, $default, $min, $max) -> $n
#
# Purpose: One of the two counts a cloud takes -- how many words to show, how
#          short a word may be.
# Notes:   A value that is absent or unreadable is the default, not the minimum:
#          ?topn= with nothing after it must not silently show a single word.
sub _wordcloud_option {
	my ($raw, $default, $min, $max) = @_;

	my $n = (defined $raw && !ref $raw && $raw =~ /\A\d+\z/) ? int $raw : $default;
	$n = $min if $n < $min;
	$n = $max if $n > $max;
	return $n;
}

# _wordcloud_counts($records, $col, $topn, $minlen, $extra_stop) -> \%cloud
#
# Purpose: The words a text column repeats and how often each appears, ranked,
#          which is what both the /wordcloud page and a canvas's word-cloud card
#          draw.  One function, so the page and the card cannot count differently.
# Entry:   $records is a list of rows; $col names the text column; $topn is how
#          many words to return; $minlen is the shortest word kept; $extra_stop
#          is the reader's own stoplist ("apple,pear"), added to the built-in
#          one rather than replacing it.
# Exit:    { words => [ { word, count }, ... ] } in cloud order -- count
#          descending, then alphabetically -- with distinct (every different word
#          seen, before truncation), total (words counted) and rows (rows read).
# Notes:   A word counts once per row that contains it, so a long note does not
#          outweigh ten short rows that say the same thing.
sub _wordcloud_counts {
	my ($records, $col, $topn, $minlen, $extra_stop) = @_;

	my %stop = %STOP_WORD;
	for my $extra (split /[\s,]+/, $extra_stop // '') {
		$stop{ lc $extra } = 1 if length $extra;
	}

	my (%count, $row_count);
	for my $row (@$records) {
		$row_count++;
		my %seen;
		$count{$_}++ for grep { !$seen{$_}++ && !$stop{$_} }
			_word_tokens($row->{$col}, $minlen);
	}

	my $total = sum(values %count) // 0;
	my @words = sort { $count{$b} <=> $count{$a} || $a cmp $b } keys %count;
	my $distinct = scalar @words;
	@words = @words[0 .. $topn - 1] if @words > $topn;

	return {
		words    => [ map { { word => $_, count => $count{$_} } } @words ],
		distinct => $distinct,
		total    => $total,
		rows     => $row_count,
	};
}

# _wordcloud_link($back, $col, $word, $cloud_url) -> $url
#
# Purpose: The view URL that shows the rows containing one word, with the cloud
#          as that page's breadcrumb, so a click on a word is a drill-down.
# Note:    The URL is returned unescaped; the caller escapes it once for the
#          href it goes into, because HTML::TagCloud writes its input verbatim.
sub _wordcloud_link {
	my ($back, $col, $word, $cloud_url) = @_;
	my $sep = $back =~ /\?/ ? '&' : '?';

	return $back . $sep . 'f=' . _percent_encode("$col:contains:$word")
		. '&back2=' . _percent_encode($cloud_url)
		. '&back2_label=' . _percent_encode('Back to word cloud');
}

sub wordcloud_view ($self) {
	my $col       = $self->param('col') // '';
	my $_topn     = $self->param('topn');
	my $_minlen   = $self->param('minlen');
	my $back_raw  = $self->param('back');
	my $back      = _safe_back_url($back_raw) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	# A count that is absent or unreadable is the default, not a clamp of zero:
	# ?topn= with nothing after it must not silently show a single word.
	my $topn   = _wordcloud_option($_topn,   50, 1, 500);
	my $minlen = _wordcloud_option($_minlen,  3, 1, 64);

	return $self->render(text => 'Missing col= parameter', status => 400) unless length $col;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404) unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @$columns;
	return $self->render(text => "Column not found: $col", status => 400) unless $col_set{$col};

	# One pass over the rows, shared with a canvas's word-cloud card so the page
	# and the card count the same way.
	my $cloud = _wordcloud_counts(
		$records, $col, $topn, $minlen, $self->param('stop'),
	);
	my @words      = map { $_->{word} } @{ $cloud->{words} };
	my %count      = map { $_->{word} => $_->{count} } @{ $cloud->{words} };
	my $distinct   = $cloud->{distinct};
	my $word_total = $cloud->{total};
	my $row_count  = $cloud->{rows};

	# A word links back to the rows that contain it, so the cloud is a way into
	# the data rather than a picture of it.  Only when the request names the page
	# it came from: a bare /wordcloud URL has no table to filter, and sending a
	# click to "/?f=..." would be a dead end.
	my $drill = (defined $back_raw && length $back_raw) ? 1 : 0;

	my $cloud_url = $self->req->url->path->to_string;
	my $qs        = $self->req->url->query->to_string;
	$cloud_url .= "?$qs" if length $qs;

	my @tags = map {
		{
			word  => _decode_cell($_),
			count => $count{$_},
			($drill ? (href => _wordcloud_link($back, $col, $_, $cloud_url)) : ()),
		}
	} @words;

	# The font size is the module's own logarithm of the count, so a word that
	# appears twice as often is one step bigger rather than twice as wide.
	require HTML::TagCloud;
	my $ranked = HTML::TagCloud->new(levels => 18);
	for my $tag (@tags) {
		my $name = xml_escape($tag->{word});
		if (defined $tag->{href}) {
			$ranked->add($name, xml_escape($tag->{href}), $tag->{count});
		}
		else {
			$ranked->add_static($name, $tag->{count});
		}
	}

	my $cloud_html = @tags ? $ranked->html_and_css(scalar @tags) : '';

	my ($source_url, $source_accessed) = $self->_url_attribution;
	my $title = "Words in $col";

	# The spec a canvas word-cloud card reads (_render_visual_html), so the
	# layout's New canvas / Add to existing canvas buttons save this cloud as
	# it is drawn, as they do for every other chart page.
	my $stop = $self->param('stop');
	my %chart_spec = (
		kind    => 'wordcloud',
		title   => $title,
		encode  => { col => $col },
		options => {
			topn   => $topn,
			minlen => $minlen,
			((defined $stop && length $stop) ? (stop => $stop) : ()),
		},
	);

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/wordcloud",
		format          => 'html',
		title           => $title,
		chart           => \%chart_spec,
		chart_json      => $self->_chart_json(\%chart_spec),
		cloud_html      => $cloud_html,
		words           => \@tags,
		col             => $col,
		topn            => $topn,
		minlen          => $minlen,
		drill           => $drill,
		distinct_words  => $distinct,
		word_total      => $word_total,
		row_count       => $row_count,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# ---------------------------------------------------------------------------
# Map  (GET /map)
#
# one route, one template, two ways for a row to get a
# position.  With lat= and lon= the columns already hold coordinates; with
# loc=<column> every distinct value of that column is geocoded once, by
# Database::BI::Model::Geocode.  Answers are remembered in one shared cache in
# the model store, keyed by the place rather than by the file or column that
# named it, so a second visit asks nothing and a second dataset naming the same
# place asks nothing either.  Everything before that - the pipeline, calculated
# fields and f= filters - is the same as every other visual, so a map shows the
# filtered, calculated view and not the raw table.
# ---------------------------------------------------------------------------

# _map_data($self, \@records, \@columns, \%encode, \%options, $spec_key, $id_suffix)
#     -> \%result
#
# Resolve a map's markers and draw its HTML.  The map page and a map card on a
# canvas both come through here: a map spec names either loc=<column> (places
# to geocode) or lat=/lon= (coordinates already in the data), and everything
# else - the marker cap, popups, the geocode cache and HTML::OSM - is the same
# in both places.  %result has { map_body, map_head, title, messages, ... } on success
# or { error, status } when the spec cannot be drawn.  $id_suffix makes the
# Leaflet element ids unique when several maps share one page; undef leaves the
# map page's own ids alone.
sub _map_data :Protected ($self, $records, $columns, $encode, $options, $spec_key, $id_suffix) {
	$encode  //= {};
	$options //= {};

	my $loc_col = $encode->{loc} // '';
	my $lat_col = $encode->{lat} // '';
	my $lon_col = $encode->{lon} // '';
	my $by_location = length $loc_col;

	return { error => $self->_i18n('error_map_source'), status => 400 }
		unless $by_location || (length($lat_col) && length($lon_col));
	return { error => $self->_i18n('error_map_coordinates'), status => 400 }
		if !$by_location && (!length($lat_col) || !length($lon_col));

	my %col_set = map { $_ => 1 } @$columns;
	my $cfg     = $self->app->config;

	my @popup = grep {
		defined($_) && !ref($_) && length($_) && $_ ne $loc_col && $col_set{$_}
	} @{ ref($options->{popup}) eq 'ARRAY' ? $options->{popup} : [] };

	# Default: when no popup columns are requested, show every column that is
	# not a coordinate column so the marker tooltip is informative out of the box.
	unless (@popup) {
		my %coord_set = map { $_ => 1 }
			grep { defined($_) && length($_) } ($loc_col, $lat_col, $lon_col);
		@popup = grep { !$coord_set{$_} } @$columns;
	}

	my ($backend, $plotted_rows) = (undef, 0);
	my (@markers, @messages);

	if ($by_location) {
		return { error => $self->_i18n('error_map_loc_column', $loc_col), status => 400 }
			unless $col_set{$loc_col};

		require Database::BI::Model::Geocode;

		# The geocoder is a config seam first and a recommended dependency
		# second: a deployment may hand in an object, and a test does exactly
		# that.  With neither, the model reports the module as unavailable and
		# the map is still the map.
		my $injected = $cfg->{geocoder};
		my $geocode  = Database::BI::Model::Geocode->new(
			(defined($injected) && ref($injected) && $injected->can('geocode_many')
				? (geocoder => $injected) : ()),
			(defined($cfg->{openaddr}) && length($cfg->{openaddr})
				? (openaddr => $cfg->{openaddr}) : ()),
		);

		# A place name means the same place whichever file's column holds it, so
		# the answers live in one shared cache: the second dataset that names a
		# place plots it without asking the geocoder.  A per-dataset entry from an
		# older model store is folded in as well; the shared answer wins if both
		# have the name, and places only the old entry knows about are moved into
		# the shared cache below, so the next dataset benefits from them too.
		my $cache_spec = ($spec_key // '') . '|loc=' . $loc_col;
		my $models     = $self->_read_models;
		my $legacy     = Database::BI::Model::Geocode->cache_from_models($models, $cache_spec);
		my $shared     = Database::BI::Model::Geocode->shared_cache_from_models($models);
		my %cache      = (%$legacy, %$shared);
		my $to_share   = grep { !exists $shared->{$_} } keys %$legacy;
		my $region     = $cfg->{map_region};

		my $result = $geocode->resolve_column(
			$records, $loc_col,
			cache => \%cache,
			((defined($region) && $region =~ /\A[A-Za-z]{2}\z/) ? (region => $region) : ()),
			max   => _map_limit($cfg->{map_geocode_max}, $DEFAULT_MAP_GEOCODE_MAX),
		);

		push @messages, @{ $result->{messages} };
		$backend      = $result->{backend};
		$plotted_rows = $result->{counts}{plotted};

		# Only a request that asked something new, or found old answers to move
		# into the shared cache, has something new to remember: rewriting the
		# store for a page answered entirely from the shared cache would be a
		# write per view.  $to_share empties after the migration, so an old store
		# is written once per dataset rather than on every view.
		if ($result->{counts}{attempted} || $to_share) {
			my $updated = Database::BI::Model::Geocode->models_with_shared_cache(
				$models, $result->{cache},
				(defined($backend) ? (backend => $backend) : ()),
				built => _iso8601_utc(),
			);
			my $written = $self->_write_models($updated);

			# A failed migration is not worth a page message: the answers are
			# still in the old entry, so this dataset is unaffected.  A failed
			# new lookup is, because the next visit pays for it again.
			if (!$written && $result->{counts}{attempted}) {
				push @messages, {
					key  => 'warn_map_cache_unwritten',
					text => $self->_i18n('warn_map_cache_unwritten'),
				};
			}
		}

		for my $marker (@{ $result->{markers} }) {
			my $row = ($marker->{first_row} <= $#$records)
				? $records->[ $marker->{first_row} ] : {};
			push @markers, {
				%{ $marker },
				'label' => _map_popup(
					$marker->{value}, $marker->{rows},
					[ map { [ $_, $row->{$_} ] } @popup ],
				),
			};
		}

	} else {
		return { error => "Column not found: $lat_col", status => 400 }
			unless $col_set{$lat_col};
		return { error => "Column not found: $lon_col", status => 400 }
			unless $col_set{$lon_col};

		my (%by_key, $out_of_lat, $out_of_lon, $unusable);

		for my $index (0 .. $#$records) {
			my $row = $records->[$index];
			my $lat = _numeric_cell($row->{$lat_col} // '');
			my $lon = _numeric_cell($row->{$lon_col} // '');

			# A row is never plotted at (0,0): a fake point in the Gulf of
			# Guinea is worse than a missing one.  A whole column outside its
			# range is named instead, because a transposed pair is the error a
			# user makes here.
			if (defined($lat) && ($lat < -90 || $lat > 90)) { $out_of_lat++; next }
			if (defined($lon) && ($lon < -180 || $lon > 180)) { $out_of_lon++; next }
			unless (defined($lat) && defined($lon)) { $unusable++; next }

			# Rows at one coordinate are one marker: that is what makes a large
			# file renderable, and "how many are here?" is the question a map
			# answers.
			my $key   = sprintf('%.6f,%.6f', $lat, $lon);
			my $point = $by_key{$key};
			if ($point) { $point->{rows}++; next }

			$point = $by_key{$key} = {
				'lat' => $lat, 'lon' => $lon, 'rows' => 1, 'first_row' => $index,
			};
			push @markers, $point;
		}

		return { error => $self->_i18n('error_map_coordinate_range', $lat_col, 'latitude'),
			status => 400 } if !@markers && $out_of_lat;
		return { error => $self->_i18n('error_map_coordinate_range', $lon_col, 'longitude'),
			status => 400 } if !@markers && $out_of_lon;
		return { error => $self->_i18n('error_map_coordinate_numeric', $lat_col, $lon_col),
			status => 400 } if !@markers && @$records;

		$plotted_rows += $_->{rows} for @markers;

		push @messages, {
			key  => 'warn_map_coordinate_rows',
			text => $self->_i18n('warn_map_coordinate_rows', $plotted_rows,
				scalar(@$records), scalar(@$records) - $plotted_rows),
		} if $plotted_rows < scalar @$records;

		for my $marker (@markers) {
			my $row = $records->[ $marker->{first_row} ];
			$marker->{label} = _map_popup(
				sprintf('%.6f, %.6f', $marker->{lat}, $marker->{lon}),
				$marker->{rows},
				[ map { [ $_, $row->{$_} ] } @popup ],
			);
		}
	}

	my $title = $by_location ? "Map of $loc_col" : "$lat_col and $lon_col";
	my $cap   = _map_limit($options->{max},
		_map_limit($cfg->{map_max_markers}, $DEFAULT_MAP_MAX_MARKERS));

	if (@markers > $cap) {
		push @messages, {
			key  => 'warn_map_markers_capped',
			text => $self->_i18n('warn_map_markers_capped', $cap, scalar @markers),
		};
		@markers = @markers[0 .. $cap - 1];
	}

	push @messages, {
		key  => 'error_map_no_markers',
		text => $self->_i18n('error_map_no_markers'),
	} unless @markers;

	# Leaflet's CSS and JS belong in the head, which the layout owns; the rest of
	# the map - the search box, the buttons, the div and its script - goes in the
	# body where the map should appear.
	my ($map_head, $map_body);
	if (@markers) {
		# HTML::OSM is a recommended dependency, so its absence - or an install
		# older than the options below - is a state the page reports and
		# survives: the markers are still counted, nothing is drawn, and the
		# rest of the application is untouched.  The version check is not
		# optional: HTML::OSM rejects unknown constructor keys, so passing
		# search/max_zoom to an older copy would croak and turn the page into a
		# 500 rather than the warning this branch produces.
		#
		# The installed version comes back with the answer so the warning can
		# say which problem it is: "not installed" and "installed but older than
		# 0.12" have different fixes, and the old wording called both of them
		# "could not be loaded".  The probe is a method (see
		# _map_renderer_version) so the tests can produce either state without
		# installing or removing the module.
		my ($osm_ok, $osm_version) = $self->_map_renderer_version;
		if ($osm_ok) {
			# Markers go in a cluster group rather than straight onto the map.
			# A card may plot up to map_max_markers (2000 by default), and at a
			# low zoom that many pins overlap into noise; markercluster draws a
			# count instead and splits it as the reader zooms in.  A sparse map
			# looks the same - the plugin leaves markers that are far apart on
			# their own - but the plugin is only fetched once the map itself is.
			# The Leaflet assets are a config seam too.  A deployment with no
			# outbound network access serves them from its own origin; any key
			# the operator leaves out keeps HTML::OSM's pinned CDN URL.  The tile
			# layer has its own key, since a local tile server removes the last
			# outbound request the page makes.
			my %leaflet_assets;
			for my $asset (
				[ 'leaflet_js_url',                  'js_url' ],
				[ 'leaflet_css_url',                 'css_url' ],
				[ 'leaflet_cluster_js_url',          'cluster_js_url' ],
				[ 'leaflet_cluster_css_url',         'cluster_css_url' ],
				[ 'leaflet_cluster_default_css_url', 'cluster_default_css_url' ],
			) {
				my ($key, $param) = @$asset;
				my $url = $cfg->{$key};
				$leaflet_assets{$param} = $url
					if defined $url && !ref $url && length $url;
			}

			my $tile_url = $cfg->{tile_url};
			$tile_url = undef
				unless defined($tile_url) && !ref($tile_url) && length($tile_url);

			# options{tile_url} wins over the global config tile_url when set.
			# HTML::OSM >= 0.12 is the minimum, so tile_url is always accepted.
			my $eff_tile_url = $options->{tile_url} // $tile_url;
			$eff_tile_url = undef
				unless defined($eff_tile_url) && !ref($eff_tile_url) && length($eff_tile_url);

			my %osm_args = (
				height   => '560px',
				width    => '100%',
				cluster  => 1,
				search   => 0,
				($eff_tile_url                  ? (tile_url => $eff_tile_url)        : ()),
				(defined($options->{zoom})      ? (zoom     => $options->{zoom})     : ()),
				(defined($options->{max_zoom})  ? (max_zoom => $options->{max_zoom}) : ()),
				%leaflet_assets,
			);
			my $map = HTML::OSM->new(%osm_args);
			my $color_col     = $options->{color_col} // '';
			my $color_rules   = $options->{color_rules}   // [];
			my $color_default = $options->{color_default} // $DEFAULT_MARKER_COLOR;
			my $size_col      = $options->{size} // '';

			# Bubble maps: one radius per marker, scaled across the plotted
			# values.  Circle markers keep their pixel size as the reader
			# zooms, which is what makes them comparable.
			my ($size_min, $size_max) = _map_size_range($records, \@markers, $size_col);

			for my $marker (@markers) {
				my $row = $records->[ $marker->{first_row} ];
				my $color;
				if (length $color_col) {
					my $cval = (defined($row) ? $row->{$color_col} : undef) // '';
					$color = _apply_color_rule($cval, $color_rules, $color_default);
				}
				if (length $size_col) {
					my $sv = defined($row)
						? _numeric_cell($row->{$size_col} // '') : undef;
					$map->add_circle_marker(
						[ $marker->{lat}, $marker->{lon} ],
						html   => $marker->{label},
						radius => _map_radius($sv, $size_min, $size_max),
						(defined($color) ? (colour => _color_hex($color)) : ()),
					);
				} else {
					$map->add_marker(
						[ $marker->{lat}, $marker->{lon} ],
						html => $marker->{label},
						(defined($color) ? (icon => _marker_icon($color)) : ()),
					);
				}
			}

			# Heat map overlay: when heat=1 is requested, plot a density
			# heatmap in addition to the regular markers.  The weight column
			# (weight=<col>) drives the intensity of each point; absent the
			# column every point has equal weight 1.0.  Normalisation to [0,1]
			# ensures the heatmap library gets values in the expected range.
			if ($options->{heat}) {
				my $weight_col  = $options->{weight} // '';
				my @heat_pts;
				for my $marker (@markers) {
					my $row = $records->[ $marker->{first_row} ];
					my $w;
					if (length $weight_col && defined $row) {
						$w = _numeric_cell($row->{$weight_col} // '');
					}
					push @heat_pts, [ $marker->{lat}, $marker->{lon},
						(defined($w) ? $w : 1) ];
				}
				# Normalise weights to [0,1] when a weight column was used.
				if (length $weight_col && @heat_pts) {
					my $max_w = 0;
					$max_w = $_->[2] > $max_w ? $_->[2] : $max_w for @heat_pts;
					if ($max_w > 0) {
						$_->[2] = $_->[2] / $max_w for @heat_pts;
					}
				}
				eval { $map->add_heatmap(\@heat_pts) };
			}

			($map_head, $map_body) = $map->onload_render();
			($map_head, $map_body) = _canvas_map_html($map_head, $map_body, $id_suffix)
				if defined($id_suffix) && length($id_suffix);
		} elsif (defined $osm_version) {
			push @messages, {
				key  => 'error_map_renderer_old',
				text => $self->_i18n('error_map_renderer_old', $osm_version),
			};
		} else {
			push @messages, {
				key  => 'error_map_renderer_missing',
				text => $self->_i18n('error_map_renderer_missing'),
			};
		}
	}

	my %chart_spec = (
		kind   => 'map',
		title  => $title,
		encode => ($by_location ? { loc => $loc_col }
		                        : { lat => $lat_col, lon => $lon_col }),
	);
	$chart_spec{options}{popup} = \@popup if @popup;
	$chart_spec{options}{max}   = $options->{max}
		if defined($options->{max}) && $options->{max} =~ /\A\d+\z/ && $options->{max} > 0;
	$chart_spec{options}{zoom}  = $options->{zoom}  if defined $options->{zoom};
	$chart_spec{options}{heat}  = 1                 if $options->{heat};
	$chart_spec{options}{weight} = $options->{weight}
		if defined($options->{weight}) && length($options->{weight});
	if (defined($options->{size}) && length($options->{size})) {
		$chart_spec{encode}{size} = $options->{size};
	}
	if (defined($options->{scheme}) && length($options->{scheme})) {
		$chart_spec{options}{scheme} = $options->{scheme};
	}
	if (defined($options->{color_col}) && length($options->{color_col})) {
		$chart_spec{encode}{color}         = $options->{color_col};
		$chart_spec{options}{color_rules}  = $options->{color_rules}
			if defined($options->{color_rules}) && @{ $options->{color_rules} };
		$chart_spec{options}{color_default} = $options->{color_default}
			if defined($options->{color_default});
	}

	return {
		title        => $title,
		map_head     => $map_head,
		map_body     => $map_body,
		messages     => \@messages,
		marker_count => scalar @markers,
		row_count    => $plotted_rows,
		source_rows  => scalar @$records,
		loc_col      => ($by_location ? $loc_col : undef),
		lat_col      => ($by_location ? undef    : $lat_col),
		lon_col      => ($by_location ? undef    : $lon_col),
		backend      => $backend,
		chart        => \%chart_spec,
	};
}

# _map_renderer_version() -> ($ok, $installed_version)
#
# Loads the optional HTML::OSM and says whether it is new enough for the options
# _map_data passes.  $installed_version is undef when the module could not be
# loaded at all; when it is defined but $ok is false the copy is too old.
#
# This is a method rather than an inline require so a test can replace it.
# Test::Without::Module does not produce the missing case here: its @INC hook
# is bypassed during Mojolicious' in-process dispatch, so the installed copy is
# still found, and the branch an operator without the dependency is in cannot
# be reached by hiding the module.  Replacing one method exercises the same
# else branch, the same message and the same page.
sub _map_renderer_version {
	my $self = shift;

	my $version = eval {
		require HTML::OSM;
		HTML::OSM->VERSION;
	};
	return (0, undef) unless defined($version) && length($version);

	my $new_enough = eval { HTML::OSM->VERSION($MIN_HTML_OSM_VERSION); 1 };
	return ($new_enough ? 1 : 0, $version);
}

# _canvas_map_html($head, $body, $id_suffix) -> ($head, $body)
#
# HTML::OSM names the map element "map" and its reset button "reset-button".
# With search => 0 (always set by _map_data), the search-box and
# clear-search-button elements are absent.  Suffixing still happens so a
# canvas with two maps gets distinct element ids and local variable scopes.
# The head is the same Leaflet stylesheet and script for every map, so only
# the first head is passed to the layout.
# _scope_card_scripts($html) -> $html
#
# Purpose: Close every inline script in a rendered card over a function of its
#          own, so two cards on one canvas cannot collide.
# Entry:   $html -- one card's markup, as _render_visual_markup returns it.
# Exit:    The same markup, with each inline script wrapped.
# Notes:   Called once, by _render_visual_html, so no caller has to remember
#          it and no card is scoped twice.  HTML::D3 writes a chart as a
#          snippet that declares its SVG with
#          C<const>.  A top-level C<const> belongs to the page's shared lexical
#          environment rather than to the <script> element it was written in,
#          so a canvas of two charts failed at the second one -- "Identifier
#          'svg' has already been declared" -- and drew an empty card, while
#          either card on a page of its own was fine.  A script with a C<src>,
#          or with a C<type> of its own (a data block, a module), is left
#          alone, and one that is already wrapped is not wrapped twice.
sub _scope_card_scripts {
	my ($html) = @_;
	return '' unless defined $html && length $html;

	# ~ is the delimiter because the lookaheads below need !, and the wrapper
	# the replacement builds is a pair of braces, which a brace-delimited
	# pattern would take for its own.
	$html =~ s~(<script\b(?![^>]*\bsrc=)(?![^>]*\btype=)[^>]*>)(.*?)(</script>)~_wrap_card_script($1, $2, $3)~gsex;

	return $html;
}

# _wrap_card_script($open, $body, $close) -> $html
#
# Purpose: One <script> element of a card, closed over a function of its own.
# Entry:   The element's opening tag, its body and its closing tag.
# Exit:    The same element, wrapped unless it already is.
# Notes:   Split out of _scope_card_scripts so that pattern can use a plain
#          delimiter: its lookaheads need the ones the wrapper is made of.
sub _wrap_card_script {
	my ($open, $body, $close) = @_;

	# A body that already opens with the wrapper is left alone, so scoping a
	# card twice is scoping it once.
	my ($blank) = $body =~ /\A(\s*)/;
	return $open . $body . $close
		if CORE::index(substr($body, length $blank), '(function () {') == 0;

	return $open . "\n(function () {\n" . $body . "\n})();\n" . $close;
}

sub _canvas_map_html {
	my ($head, $body, $id_suffix) = @_;

	my $suffix = $id_suffix // 'map';
	$suffix =~ s/[^A-Za-z0-9_-]//g;
	$suffix = 'map' unless length $suffix;

	my %ids = (
		'map'                 => "map-$suffix",
		'search-box'          => "search-box-$suffix",
		'reset-button'        => "reset-button-$suffix",
		'clear-search-button' => "clear-search-button-$suffix",
	);
	for my $old (sort keys %ids) {
		my $new = $ids{$old};
		$body =~ s/id="\Q$old\E"/id="$new"/g;
		$body =~ s{getElementById\('\Q$old\E'\)}{getElementById('$new')}g;
		$body =~ s{L\.map\('\Q$old\E'\)}{L.map('$new')}g;
	}
	$body =~ s{<div id="$ids{map}"></div>}{<div id="$ids{map}" class="canvas-map"></div>};

	# The card owns the map's size, so the page-wide #map rule is noise here.
	$head =~ s{<style>.*?</style>}{}s;

	# The scope around the map's script is not put on here: every card is
	# scoped once, by _render_visual_html, whichever kind it is.
	return ($head, $body);
}

sub map_view ($self) {
	my $loc_col   = $self->param('loc') // '';
	my $lat_col   = $self->param('lat') // '';
	my $lon_col   = $self->param('lon') // '';
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	# Optional display params
	my $zoom_raw     = $self->param('zoom')     // '';
	my $max_zoom_raw = $self->param('max_zoom') // '';
	my $tiles_name   = $self->param('tiles')    // '';
	my $heat         = $self->param('heat')     // 0;
	my $weight_col   = $self->param('weight')   // '';
	my $size_col     = $self->param('size')     // '';
	my $series_col   = $self->param('series')   // '';
	my $scheme       = $self->param('scheme')   // 'tableau10';

	# tiles= names a source from tile_sources in config; an arbitrary URL is
	# never accepted so a crafted share link cannot redirect tiles fetches.
	my $tile_url_override;
	if (length $tiles_name) {
		my $sources = $self->app->config('tile_sources') // {};
		unless (exists $sources->{$tiles_name}) {
			return $self->render(
				text   => $self->_i18n('error_map_tiles_unknown', $tiles_name),
				status => 400,
			);
		}
		$tile_url_override = $sources->{$tiles_name}{url};
	}

	my $zoom_val;
	if (length $zoom_raw && $zoom_raw =~ /\A\d+\z/) {
		$zoom_val = int $zoom_raw;
		$zoom_val = 0  if $zoom_val < 0;
		$zoom_val = 19 if $zoom_val > 19;
	}

	my $max_zoom_val;
	if (length $max_zoom_raw && $max_zoom_raw =~ /\A\d+\z/) {
		$max_zoom_val = int $max_zoom_raw;
		$max_zoom_val = 0  if $max_zoom_val < 0;
		$max_zoom_val = 28 if $max_zoom_val > 28;
	} else {
		my $cfg_max_zoom = $self->app->config('map_max_zoom');
		$max_zoom_val = int($cfg_max_zoom)
			if defined($cfg_max_zoom) && $cfg_max_zoom =~ /\A\d+\z/;
	}

	my $by_location = length $loc_col;

	return $self->render(text => $self->_i18n('error_map_source'), status => 400)
		unless $by_location || (length($lat_col) && length($lon_col));
	return $self->render(text => $self->_i18n('error_map_coordinates'), status => 400)
		if !$by_location && (!length($lat_col) || !length($lon_col));

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		return $self->render(text => $e, status => 400);
	}

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{ $columns };
	my @popup = grep { length($_) && $_ ne $loc_col && $col_set{$_} }
		@{ $self->every_param('popup') };

	# Marker colour params.  color= applies explicit threshold rules;
	# series= colours one value per distinct category from scheme=, which is the
	# categorical form the other chart pages already offer.
	my $color_col     = $self->param('color') // '';
	my $color_def_raw = $self->param('color_default') // '';
	my ($color_rules, $color_default) =
		_parse_color_rules($self->every_param('color_rule'), $color_def_raw);

	if (length($color_col) && !$col_set{$color_col}) {
		return $self->render(text => "Column not found: $color_col", status => 400);
	}
	return $self->render(text => 'Use either color= or series=, not both', status => 400)
		if length($color_col) && length($series_col);
	return $self->render(text => "Column not found: $size_col", status => 400)
		if length($size_col) && !$col_set{$size_col};

	my (@series_cats, $series_palette);
	if (length $series_col) {
		return $self->render(text => "Column not found: $series_col", status => 400)
			unless $col_set{$series_col};
		return $self->render(text => "Unknown colour scheme: $scheme", status => 400)
			unless $SCATTER_SCHEMES{$scheme};

		$series_palette = $CATEGORY_PALETTES{$scheme} // $CATEGORY_PALETTES{tableau10};
		my %seen;
		@series_cats = grep { !$seen{$_}++ } map {
			my $value = $_->{$series_col};
			defined($value) ? "$value" : '';
		} @$records;

		# A legend longer than two cycles of the palette helps nobody; the
		# remaining values keep a palette colour but are not listed.
		my $limit = @$series_palette * 2;
		@series_cats = @series_cats[0 .. $limit - 1] if @series_cats > $limit;

		$color_col   = $series_col;
		$color_rules = [
			map {
				{
					op    => 'eq',
					val   => $series_cats[$_],
					color => $series_palette->[ $_ % @$series_palette ],
				}
			} 0 .. $#series_cats
		];
		$color_default = $series_palette->[0];
	}

	my %options;
	$options{popup}         = \@popup       if @popup;
	$options{color_col}     = $color_col    if length $color_col;
	$options{color_rules}   = $color_rules  if @$color_rules;
	$options{color_default} = $color_default;
	$options{size}          = $size_col     if length $size_col;
	$options{scheme}        = $scheme       if length $series_col;
	my $max = $self->param('max');
	$options{max}      = $max            if defined($max) && $max =~ /\A\d+\z/ && $max > 0;
	$options{zoom}     = $zoom_val       if defined $zoom_val;
	$options{max_zoom} = $max_zoom_val   if defined $max_zoom_val;
	$options{tile_url} = $tile_url_override if defined $tile_url_override;
	$options{heat}     = 1               if $heat;
	$options{weight}   = $weight_col     if length($weight_col) && $col_set{$weight_col};

	# Build colour legend for the template
	my @color_legend;
	if (length $color_col) {
		if (@series_cats) {
			for my $i (0 .. $#series_cats) {
				push @color_legend, {
					color => $series_palette->[ $i % @$series_palette ],
					label => length($series_cats[$i]) ? $series_cats[$i] : '(blank)',
				};
			}
		} else {
			my %op_label = (
				gt => '>', ge => '>=', lt => '<', le => '<=', eq => '=', ne => '!=',
			);
			for my $rule (@$color_rules) {
				push @color_legend, {
					color => $rule->{color},
					label => $color_col . ' ' . ($op_label{ $rule->{op} } // $rule->{op})
						. ' ' . $rule->{val},
				};
			}
			push @color_legend, { color => $color_default, label => 'Other' }
				if @color_legend;
		}
	}

	my $result = $self->_map_data(
		$records, $columns,
		($by_location ? { loc => $loc_col } : { lat => $lat_col, lon => $lon_col }),
		\%options,
		$self->param('l') // '',
		undef,
	);

	return $self->render(text => $result->{error}, status => $result->{status})
		if $result->{error};

	my ($source_url, $source_accessed) = $self->_url_attribution;
	my ($platform, $language) = $self->_resolve_template;

	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/map",
		format          => 'html',
		title           => $result->{title},
		extra_head      => $result->{map_head},
		map_body        => $result->{map_body},
		messages        => $result->{messages},
		marker_count    => $result->{marker_count},
		row_count       => $result->{row_count},
		source_rows     => $result->{source_rows},
		loc_col         => $result->{loc_col},
		lat_col         => $result->{lat_col},
		lon_col         => $result->{lon_col},
		backend         => $result->{backend},
		chart           => $result->{chart},
		chart_json      => $self->_chart_json($result->{chart}),
		color_col       => $color_col,
		color_legend    => \@color_legend,
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# _map_popup($heading, $rows, \@extras) -> $html
#
# The popup for one marker: what it is, how many rows it stands for, and the
# columns the request asked for.  Leaflet treats a popup string as HTML, and a
# place name out of a user's file is not markup, so every value is escaped here.
sub _map_popup {
	my ($heading, $rows, $extras) = @_;

	my @lines = '<strong>' . xml_escape($heading // '') . '</strong>';
	push @lines, $rows . ' rows' if $rows != 1;
	push @lines, map { xml_escape($_->[0]) . ': ' . xml_escape($_->[1]) }
		grep { defined($_->[1]) && length($_->[1]) } @{ $extras // [] };

	return join('<br>', @lines);
}

# _map_size_range($records, \@markers, $col) -> ($min, $max)
#
# The numeric range of the bubble-size column across the markers that will be
# drawn, or an empty list when the column is absent or has no numeric values.
sub _map_size_range {
	my ($records, $markers, $col) = @_;
	return () unless defined($col) && length($col);

	my ($min, $max);
	for my $marker (@$markers) {
		my $row = $records->[ $marker->{first_row} ];
		next unless defined $row;
		my $value = _numeric_cell($row->{$col} // '');
		next unless defined $value;
		$min = $value if !defined($min) || $value < $min;
		$max = $value if !defined($max) || $value > $max;
	}

	return ($min, $max);
}

# _map_radius($value, $min, $max) -> $pixels
#
# A bubble radius for one marker: 6..30 px across the plotted range, and the
# midpoint for a column that is constant or has no numeric value.  Pixels, not
# metres: a circle over the same place must not grow as the reader zooms in.
sub _map_radius {
	my ($value, $min, $max) = @_;

	return 10 unless defined $value;
	return 10 unless defined($min) && defined($max) && $max > $min;

	my $fraction = ($value - $min) / ($max - $min);
	$fraction = 0 if $fraction < 0;
	$fraction = 1 if $fraction > 1;

	return int(6 + $fraction * 24 + 0.5);
}

# _map_limit($value, $default) -> $integer
#
# A positive integer from a config value or request parameter, or the default.
# An absent, empty or nonsensical map setting is an operator's typo, not a data
# error, so the page falls back instead of refusing.
sub _map_limit {
	my ($value, $default) = @_;

	return $default unless defined($value) && ($value =~ /\A\d+\z/) && ($value > 0);

	return $value + 0;
}

# _parse_color($str) -> $color_or_undef
#
# Accepts a lowercase CSS named color from a fixed whitelist, or a hex color
# string in #rgb or #rrggbb form.  Returns the normalised lowercase string or
# undef when the input is invalid.
sub _parse_color {
	my ($c) = @_;
	return undef unless defined($c) && length($c);
	$c = lc $c;
	return $c if $NAMED_COLORS{$c};
	return $c if $c =~ /\A#[0-9a-f]{3}\z/;
	return $c if $c =~ /\A#[0-9a-f]{6}\z/;
	return undef;
}

# _parse_color_rules(\@raw_rules, $default_raw) -> (\@rules, $default_color)
#
# Parses the ?color_rule=op:threshold:color repeatable param list and the
# optional ?color_default=color param into a structured rules array and a
# fallback colour.  Invalid rule entries are silently dropped.
sub _parse_color_rules {
	my ($raw_rules, $default_raw) = @_;
	my $default_color = _parse_color($default_raw // '') // $DEFAULT_MARKER_COLOR;
	my @rules;
	for my $raw (@{ $raw_rules // [] }) {
		my ($op, $val, $color_str) = split /:/, $raw, 3;
		next unless defined($op) && defined($val) && defined($color_str);
		$op = lc $op;
		next unless $op =~ /\A(?:gt|ge|lt|le|eq|ne)\z/;
		my $color = _parse_color($color_str);
		next unless defined $color;
		push @rules, { op => $op, val => $val, color => $color };
	}
	return (\@rules, $default_color);
}

# _apply_color_rule($value, \@rules, $default_color) -> $color
#
# Returns the first colour whose rule matches $value, or $default_color.
# Numeric comparisons are used when both sides look like plain numbers.
sub _apply_color_rule {
	my ($value, $rules, $default) = @_;
	$value //= '';
	for my $rule (@$rules) {
		my ($op, $threshold, $color) = @{$rule}{qw(op val color)};
		my ($num_val, $num_thr);
		if (	$value     =~ /\A-?\d+(?:\.\d+)?\z/ &&
			$threshold =~ /\A-?\d+(?:\.\d+)?\z/) {
			$num_val = $value     + 0;
			$num_thr = $threshold + 0;
		}
		my $match;
		if (defined $num_val) {
			$match = ($op eq 'gt' && $num_val >  $num_thr)
			      || ($op eq 'ge' && $num_val >= $num_thr)
			      || ($op eq 'lt' && $num_val <  $num_thr)
			      || ($op eq 'le' && $num_val <= $num_thr)
			      || ($op eq 'eq' && $num_val == $num_thr)
			      || ($op eq 'ne' && $num_val != $num_thr);
		} else {
			$match = ($op eq 'eq' && lc($value) eq lc($threshold))
			      || ($op eq 'ne' && lc($value) ne lc($threshold));
		}
		return $color if $match;
	}
	return $default;
}

# _marker_icon($color) -> $data_uri
#
# Returns a data:image/svg+xml URI for a 32x32 teardrop pin icon whose fill is
# $color.  The icon anchor is [16,32] (HTML::OSM's hardcoded default), so the
# path tip lands at the bottom centre of the bounding box.
sub _marker_icon {
	my ($color) = @_;
	$color //= $DEFAULT_MARKER_COLOR;

	# Commas in path data avoid spaces that would need percent-encoding.
	my $svg =
		"<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32' viewBox='0 0 32 32'>" .
		"<path d='M16,0C10,0,5,5,5,12C5,21,16,32,16,32C16,32,27,21,27,12C27,5,22,0,16,0Z'" .
		" fill='$color' stroke='#444' stroke-width='1.5'/>" .
		"<circle cx='16' cy='12' r='5' fill='white' opacity='0.65'/>" .
		"</svg>";

	# Minimal percent-encoding for a data: URI (RFC 2397).
	$svg =~ s/#/%23/g;
	$svg =~ s/</%3C/g;
	$svg =~ s/>/%3E/g;
	$svg =~ s/ /%20/g;

	return "data:image/svg+xml,$svg";
}

# _color_hex($color) -> $hex
#
# add_circle_marker() accepts hex colours only, while _parse_color() also
# allows a fixed set of CSS names for the icon path.  Translate the names so a
# colour rule means the same thing on a bubble map as on a pin map.
sub _color_hex {
	my ($color) = @_;

	return $DEFAULT_MARKER_COLOR unless defined($color) && length($color);
	return $color if $color =~ /\A#[0-9a-f]{3}(?:[0-9a-f]{3})?\z/;

	return $NAMED_COLOR_HEX{$color} // $DEFAULT_MARKER_COLOR;
}

# _iso8601_utc() -> $string
#
# When a geocode cache was built, in the form the model store records.
sub _iso8601_utc {
	require POSIX;

	return POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

# _catalog_entry($self, $mf, $analyses) -> \%entry
#
# Build one catalog entry for a Mojo::File data file.
sub _catalog_entry :Protected ($self, $mf, $analyses) {
	my $path  = $mf->to_string;
	my $name  = $mf->basename;
	my $size  = -s $path // 0;
	my $mtime = (stat($path))[9] // 0;

	require POSIX;
	my $mtime_str = $mtime ? POSIX::strftime('%Y-%m-%d %H:%M UTC', gmtime($mtime)) : '';

	# Find which analyses reference this file.
	# Normalize path separators so that Windows paths stored with backslashes
	# match Mojo::File paths that may use forward slashes, and vice versa.
	# Case-fold only the path portion on case-insensitive filesystems.
	my $use_ci = File::Spec->case_tolerant;
	(my $norm_path = $path) =~ s{\\}{/}g;
	$norm_path = lc $norm_path if $use_ci;

	my @refs;
	for my $aid (sort keys %$analyses) {
		my $a = $analyses->{$aid};
		for my $ds (@{ $a->{datasets} // [] }) {
			my $spec = $ds->{spec} // '';
			my $table_stem = $mf->basename; $table_stem =~ s/\.[^.]+\z//;
			(my $norm_spec = $spec) =~ s{\\}{/}g;
			$norm_spec = lc $norm_spec if $use_ci;
			if (CORE::index($norm_spec, $norm_path) >= 0 || CORE::index($spec, "table:$table_stem") == 0) {
				push @refs, { id => $aid, name => $a->{name} };
				last;
			}
		}
	}

	# Derive a human-readable type from the extension.
	my ($ext) = ($name =~ /\.([^.]+)\z/);
	$ext = lc($ext // '');
	my %type_map = (
		csv => 'CSV file', tsv => 'TSV file', psv => 'PSV file',
		xml => 'XML file', xlsx => 'XLSX spreadsheet',
		sql => 'SQLite database', sqlite => 'SQLite database',
		sqlite3 => 'SQLite database', db => 'Berkeley DB / SQLite',
	);
	my $type = $type_map{$ext} // 'Data file';

	return {
		name           => $name,
		path           => $path,
		type           => $type,
		size           => $size,
		mtime_str      => $mtime_str,
		analysis_count => scalar @refs,
		analyses       => \@refs,
	};
}

# GET /catalog
sub catalog_view ($self) {
	return if $self->buffer_is_cached;
	my $dir       = _data_dir_for($self->app);
	my $analyses  = $self->_read_analyses;

	my @entries;
	if (-d $dir) {
		my $ext_re = $EXT_RE;
		for my $mf ($dir->list->each) {
			next unless $mf->to_string =~ $ext_re;
			push @entries, $self->_catalog_entry($mf, $analyses);
		}
	}

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler        => 'tt',
		template       => "$platform/$language/catalog",
		format         => 'html',
		title          => 'Dataset catalog',
		catalog_entries => \@entries,
		language       => $language,
	);
}

# _share_secret($self) -> $secret_string
sub _share_secret :Protected ($self) {
	my $s = $self->app->config('share_secret') // '';
	unless (length $s) {
		carp 'share_secret not configured; using insecure default';
		$s = 'BI_DEFAULT_INSECURE_SECRET';
	}
	return $s;
}

# _make_share_token($self, $id, $expires) -> $token_string
#
# Signs with HMAC-SHA256 using Digest::SHA (Perl core since 5.10).
sub _make_share_token :Protected ($self, $id, $expires) {
	require Digest::SHA;
	require MIME::Base64;
	my $secret  = $self->_share_secret;
	my $payload = "$id|$expires";
	my $hmac    = Digest::SHA::hmac_sha256_hex($payload, $secret);
	return MIME::Base64::encode_base64url("$payload|$hmac");
}

# _verify_share_token($self, $id, $token) -> 1 | undef
sub _verify_share_token :Protected ($self, $id, $token) {
	return undef unless defined $token && length $token;
	require MIME::Base64;
	my $decoded = eval { MIME::Base64::decode_base64url($token) };
	return undef unless defined $decoded;
	my ($tid, $expires, $hmac) = split /\|/, $decoded, 3;
	return undef unless defined $tid && defined $expires && defined $hmac;
	return undef unless $tid eq $id;
	return undef unless $expires =~ /\A\d+\z/ && $expires > time();
	require Digest::SHA;
	my $secret   = $self->_share_secret;
	my $expected = Digest::SHA::hmac_sha256_hex("$id|$expires", $secret);
	return undef unless $hmac eq $expected;
	return 1;
}

# POST /api/analyses/:id/share
sub analyses_share ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => $MESSAGES{error_analysis_id_invalid} }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf($MESSAGES{error_analysis_not_found}, $id) }, status => 404)
		unless exists $analyses->{$id};

	my $expires = time() + $SHARE_TOKEN_TTL;
	my $token   = $self->_make_share_token($id, $expires);
	my $url     = $self->req->url->base->to_string . "/share/$id?token=" . url_escape($token);

	$self->render(json => { token => $token, url => $url, expires => $expires });
}

# GET /share/:id?token=...
sub share_view ($self) {
	my $id    = $self->stash('id') // '';
	my $token = $self->param('token') // '';
	return $self->render(text => $MESSAGES{error_analysis_id_invalid}, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => $MESSAGES{error_token_missing}, status => 401)
		unless length $token;
	unless ($self->_verify_share_token($id, $token)) {
		return $self->render(text => $MESSAGES{error_token_invalid}, status => 403);
	}

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf($MESSAGES{error_analysis_not_found}, $id), status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my @visuals = @{ $a->{visuals} // [] };
	unless (@visuals) {
		return $self->render(text => 'This shared analysis has no visuals', status => 404);
	}

	# Reuse canvas_render logic by temporarily setting id in stash and
	# forwarding; set sharing_mode so the template hides admin controls.
	$self->stash(sharing_mode => 1);
	# Delegate to canvas_render which reads stash('id').
	return $self->canvas_render;
}

# GET /embed/:id?token=...
sub embed_view ($self) {
	my $id    = $self->stash('id') // '';
	my $token = $self->param('token') // '';
	return $self->render(text => $MESSAGES{error_analysis_id_invalid}, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => $MESSAGES{error_token_missing}, status => 401)
		unless length $token;
	unless ($self->_verify_share_token($id, $token)) {
		return $self->render(text => $MESSAGES{error_token_invalid}, status => 403);
	}

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf($MESSAGES{error_analysis_not_found}, $id), status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	# X-Frame-Options: embed is opt-in.
	$self->res->headers->header('X-Frame-Options' => 'SAMEORIGIN');

	my @visuals = @{ $a->{visuals} // [] };
	unless (@visuals) {
		return $self->render(text => 'This shared analysis has no visuals', status => 404);
	}

	# Build a minimal context for the embed template.
	# Reuse the canvas pipeline helper to render visuals.
	my ($src, $records, $columns) = $self->_build_canvas_pipeline($a);
	return $self->render(text => 'Cannot open data source', status => 422)
		unless defined $records;

	my @rendered;
	for my $i (0 .. $#visuals) {
		my $vis = $visuals[$i];
		my $ctx = eval { $self->_canvas_render_context($a, $self->req->url->query->to_string) };
		next unless $ctx && ref $ctx eq 'HASH' && !$ctx->{error};
		push @rendered, $ctx;
	}

	# Simpler: delegate to canvas_render and let it handle the heavy lifting.
	# Just set a flag so the embed template is selected.
	$self->stash(embed_mode => 1, sharing_mode => 1);
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler     => 'tt',
		template    => "$platform/$language/embed",
		format      => 'html',
		title       => $a->{name},
		canvas_id   => $id,
		canvas_name => $a->{name},
		visuals     => \@rendered,
		language    => $language,
	);
}

# GET /a/:id/visual/:n/:format
sub visual_download ($self) {
	my $id     = $self->stash('id')     // '';
	my $n      = $self->stash('n')      // 0;
	my $format = $self->stash('fmt') // '';

	return $self->render(text => $MESSAGES{error_analysis_id_invalid}, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => 'Format must be csv or png', status => 400)
		unless $format =~ /\A(?:csv|png)\z/;
	return $self->render(text => 'Visual index must be a non-negative integer', status => 400)
		unless $n =~ /\A\d+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf($MESSAGES{error_analysis_not_found}, $id), status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my @visuals = @{ $a->{visuals} // [] };
	return $self->render(text => "Visual $n not found", status => 404)
		unless $n < scalar @visuals;

	if ($format eq 'csv') {
		$self->stash(buffer => 0);
		# Run the pipeline and return CSV for this visual's data.
		my (undef, $records, $columns) = $self->_run_pipeline_source;
		return $self->render(text => 'Cannot open data source', status => 422)
			unless defined $records;
		my $csv = $self->_serialize_csv($records, $columns);
		$self->res->headers->content_disposition(
			"attachment; filename=\"visual-$n.csv\""
		);
		return $self->render(data => encode('UTF-8', $csv), format => 'txt');
	}

	# PNG: not implemented in the server (canvas/SVG rendering is client-side).
	# Return 501 with a descriptive message.
	return $self->render(
		text   => 'PNG download requires the browser SVG renderer; use the in-page Save Image button',
		status => 501,
	);
}

# ask_api($self)
#
# POST /api/ask
#
# Translates a plain-English question into an analysis spec by
# calling the configured AI provider.  The model receives only column
# names and types -- never raw row data, file paths, or spec_key.
#
# Body params:
#   l=<spec>      (required) -- left table spec
#   q=<question>  (required) -- natural language question
#   f=<filter>    (repeatable, optional)
#
# Returns JSON: { spec, url, valid => 1 }
# On error:     { error } with 400, 503, or 502 status
sub ask_api ($self) {
	my $api_key = $self->app->config('ai_api_key') // '';
	return $self->render(json => { error => $MESSAGES{ask_unavailable} }, status => 503)
		unless length $api_key;

	my $left_spec = $self->param('l') // '';
	return $self->render(json => { error => 'Missing required parameter: l' }, status => 400)
		unless length $left_spec;

	my $question = $self->param('q') // '';
	return $self->render(json => { error => $MESSAGES{ask_no_question} }, status => 400)
		unless length $question;

	my ($src, $records, $columns, $left_label) = $self->_run_pipeline_source;
	return $self->render(json => { error => 'Could not open data source' }, status => 404)
		unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };

	# Sample up to 200 rows for type inference; avoids slurping huge files.
	my @sample = @{$records}[0 .. ($#$records < 199 ? $#$records : 199)];

	require Database::BI::Ask;
	my $typed_cols = Database::BI::Ask::infer_column_types(\@sample, $columns);

	my $ai_config = {
		provider => $self->app->config('ai_provider') // 'anthropic',
		api_key  => $api_key,
		model    => $self->app->config('ai_model')    // 'claude-haiku-5-5',
	};

	my $result = Database::BI::Ask::ask(
		question  => $question,
		spec_key  => $left_spec,
		label     => $left_label // $left_spec,
		columns   => $typed_cols,
		ai_config => $ai_config,
	);

	if (my $err = $result->{error}) {
		my ($status, $msg) =
			$err eq 'ask_unavailable'              ? (503, $MESSAGES{ask_unavailable})
		  : $err eq 'ask_no_question'              ? (400, $MESSAGES{ask_no_question})
		  : $err eq 'ask_provider_error'           ? (502, $MESSAGES{ask_provider_error})
		  : $err eq 'ask_unparseable'              ? (422, $MESSAGES{ask_unparseable})
		  : $err =~ /\Aask_invalid_spec:(.+)\z/   ? (422, sprintf($MESSAGES{ask_invalid_spec}, $1))
		  :                                          (500, $err);
		return $self->render(json => { error => $msg }, status => $status);
	}

	return $self->render(json => $result);
}

# summary_api($self)
#
# POST /api/summary
#
# Runs the same pipeline as insights_view, computes insights, then generates
# a narrative summary via Database::BI::Summary::generate().
#
# Body params:
#   l=<spec>   (required) -- left table spec
#   f=<filter> (repeatable, optional)
#   ai=1       (optional) -- request LLM polish (honoured only when ai_api_key
#                           is set in the app config)
#
# Returns JSON: { text, source, cached }
# On error:     { error } with 400 or 404 status
sub summary_api ($self) {
	my $left_spec = $self->param('l') // '';
	return $self->render(json => { error => 'Missing required parameter: l' }, status => 400)
		unless length $left_spec;

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(json => { error => 'Could not open data source' }, status => 404)
		unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(json => { error => $e }, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my $row_count = scalar @$records;
	(my $label = $left_spec) =~ s/\A(?:table:|path:|url:|redis:[^|]+\|)//;

	require Database::BI::Insights;
	my $insights = Database::BI::Insights::compute(
		records  => $records,
		columns  => $columns,
		spec_key => $left_spec,
	);

	my $use_ai = $self->param('ai') ? 1 : 0;
	my $ai_config = {
		provider => $self->app->config('ai_provider') // 'anthropic',
		api_key  => $self->app->config('ai_api_key')  // '',
		model    => $self->app->config('ai_model')    // 'claude-haiku-5-5',
	};

	require Database::BI::Summary;
	my $result = Database::BI::Summary::generate(
		insights  => $insights,
		spec_key  => $left_spec,
		label     => $label,
		row_count => $row_count,
		use_ai    => $use_ai,
		ai_config => $ai_config,
	);

	return $self->render(json => $result);
}

# insights_view($self)
#
# Accepts the same l=, j=, f=, c= pipeline as /stats.  Runs the standard
# pipeline (date normalisation, calc fields, filters), then delegates to
# Database::BI::Insights::compute() for pure-arithmetic insight detection.
#
# No LLM or external service is invoked.  Every returned insight carries a
# view_url linking to the chart or stats page that shows the underlying data.
#
# Stash keys:
#   insights   -- arrayref of insight hashrefs (kind/headline/detail/view_url/method)
#   left_spec  -- the l= value
#   left_label -- human-readable data-source label
#   row_count  -- number of rows analysed
#   base_url   -- current request URL (passed to Insights for fallback URLs)
sub insights_view ($self) {
	my $left_spec = $self->param('l') // '';
	return $self->render(text => 'Missing l= parameter', status => 400)
		unless length $left_spec;

	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	my ($src, $records, $columns) = $self->_run_pipeline_source;
	return $self->render(text => 'Could not open data source', status => 404)
		unless defined $records;

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns) };
	if ($@) { (my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//; return $self->render(text => $e, status => 400) }

	return unless $self->_reduce_or_render(\$records, \$columns);

	my $row_count = scalar @$records;
	(my $left_label = $left_spec) =~ s/\A(?:table:|path:|url:|redis:[^|]+\|)//;

	require Database::BI::Insights;
	my $insights = Database::BI::Insights::compute(
		records  => $records,
		columns  => $columns,
		spec_key => $left_spec,
		base_url => $self->req->url->path_query,
	);

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler      => 'tt',
		template     => "$platform/$language/insights",
		format       => 'html',
		title        => 'Automatic insights',
		insights     => $insights,
		left_spec    => $left_spec,
		left_label   => $left_label,
		row_count    => $row_count,
		ai_available => (length($self->app->config('ai_api_key') // '') ? 1 : 0),
		back_url     => ($back2 // $back),
		back_label   => ($back2 ? ($back2_lbl || 'Back') : ($self->param('back_label') // 'Back to table')),
		($back2 ? (back2_url => $back, back2_label => ($self->param('back_label') // 'Back to table')) : ()),
		language     => $language,
	);
}

1;

__END__

=head1 NAME

Database::BI::Controller::Dashboard - Home picker, filesystem browser, table
viewer, left-join engine, result filter, export, and file upload

=head1 SYNOPSIS

All routes in C<Database::BI> are handled by this controller.  You do not
call its methods directly -- Mojolicious dispatches HTTP requests to them
automatically.  The examples below show browser URLs and their curl
equivalents.

B<Open the home page and see all tables in the data directory:>

  # Browser
  http://localhost:3000/

  # curl
  curl http://localhost:3000/

B<View a single table (file: data/sales.csv):>

  # Browser
  http://localhost:3000/view/sales

  # curl
  curl http://localhost:3000/view/sales

B<Filter rows -- show only rows where region equals "North":>

  # Browser (add ?f=col:op:val to any view URL)
  http://localhost:3000/view/sales?f=region:eq:North

  # Multiple filters -- "North" AND amount greater than 100:
  http://localhost:3000/view/sales?f=region:eq:North&f=amount:gt:100

  # curl
  curl 'http://localhost:3000/view/sales?f=region:eq:North'

B<Join two tables -- left-join sales with products on the product column:>

  # Browser
  http://localhost:3000/join?l=table:sales&j=table:products|product|name

  # The j= parameter is: right-table-spec | left-key | right-key
  # You can chain multiple joins:
  http://localhost:3000/join?l=table:sales&j=table:products|product|name&j=table:regions|region|id

B<Open a file anywhere on the filesystem (not just in data/):>

  http://localhost:3000/open?path=/home/user/reports/q3.csv

B<Download the current view as a CSV file:>

  # Uses the same l=, j=, f= parameters as /join
  http://localhost:3000/export?l=table:sales&format=csv

  # Download as a SQLite database file instead:
  http://localhost:3000/export?l=table:sales&format=sqlite

  # Download a filtered + joined result:
  http://localhost:3000/export?l=table:sales&j=table:products|product|name&f=region:eq:North&format=csv

B<Save the current view to a file on the server (instead of downloading):>

  # POST with form fields; format is inferred from the filename extension
  curl -X POST http://localhost:3000/export \
       -F l=table:sales \
       -F dir=/home/user/exports \
       -F filename=report.csv

  # Save as SQLite:
  curl -X POST http://localhost:3000/export \
       -F l=table:sales \
       -F dir=/home/user/exports \
       -F filename=report.sql

B<Get the column list for a table (used by the join UI):>

  curl http://localhost:3000/api/columns?table=sales
  # Returns: {"columns":["product","region","amount","date"]}

B<Check when a file was last modified (used by the tooltip on the home page):>

  curl 'http://localhost:3000/api/stat?path=/data/sales.csv'
  # Returns: {"exists":true,"path":"/data/sales.csv","mtime":1700000000,"size":1234}

B<Browse the filesystem to find a data file:>

  http://localhost:3000/browse
  http://localhost:3000/browse?path=/home/user/data

B<Upload a data file by dropping it onto the page (multipart form POST):>

  curl -X POST http://localhost:3000/upload \
       -F file=@/home/user/data/sales.csv
  # Returns: {"url":"/open?path=/.../.uploads/.../sales.csv","path":"/.../.uploads/.../sales.csv"}

=head2 graph_view

C<GET /graph> -- Render a D3.js v7 line chart from the current data pipeline.

Accepts the same pipeline parameters as L</join_tables> (C<l=>, C<j=>,
C<c=>, C<f=>, C<d=>) plus:

=over 4

=item C<x=E<lt>colE<gt>>

Column name to use as the X axis (required).  Any data type is accepted;
values are displayed as categorical labels.

=item C<y=E<lt>colE<gt>>

Column name to use as the Y axis (required).  Non-numeric characters
(currency symbols, commas, etc.) are stripped before comparison; rows
where the value is still non-numeric after stripping are silently skipped.

=item C<back=E<lt>urlE<gt>>

URL for the "Back to table" link rendered in the graph toolbar.  Defaults
to C</> when absent.  The dashboard JS sets this to the current page URL
before navigating.

=back

=head3 API SPECIFICATION

=head4 INPUT

  l=<spec>     string   Left-table spec (required).  Same syntax as /join.
  x=<col>      string   X-axis column name (required).
  y=<col>      string   Y-axis column name (required; must be numeric).
  back=<url>   string   Back-link URL (optional; default "/").
  j=, c=, f=, d=        Pipeline params -- see L</join_tables>.

=head4 OUTPUT

  200 text/html   TT-rendered graph page.  The HTML::D3 snippet embeds a
                  C<const data = [...]> JSON array where each element has:
                    { label: <x-value>, value: <y-value>,
                      extra: { <col>: <val>, ... } }
                  C<extra> contains every column not used as X or Y, so
                  the hover tooltip shows the complete row for each point.
                  The chart supports brush-to-zoom; a "Reset zoom" button
                  appears after a brush selection.  The toolbar shows the
                  count of plotted data points.

  400 text/plain  C<x=> or C<y=> absent, or named column not found.
  404 text/plain  Data source could not be opened.

=head3 MESSAGES

  Missing x or y column parameter          C<x=> or C<y=> query param absent.
  Column not found: <name>                  Named column absent from result set.
  Could not open data source                Left-table spec unresolvable or 404.
  No plottable data: no rows have valid ... All rows lack a numeric Y value.

=head3 EXAMPLE

  GET /graph?l=table:sales&x=product&y=amount

Renders a line chart of C<amount> (Y) against C<product> (X).  Mousing over
a dot shows a tooltip with the product name, the amount, and every other
column in that row (e.g. C<region>, C<date>).

=head3 FORMAL SPECIFICATION

  graph_view : Controller × Params → HTML | Error

  let pipeline = run_export_pipeline(l, j, c, f, d)
  let pairs    = [ [row[x], num(row[y]), row \ {x,y}]
                   | row ∈ pipeline.records,  num(row[y]) ≠ ⊥ ]

  pre  x ∈ params ∧ y ∈ params           else 400
  pre  x ∈ pipeline.cols                  else 400
  pre  y ∈ pipeline.cols                  else 400
  pre  pairs ≠ []                          else 200 "No plottable data"
  post HTML::D3->render_line_chart_snippet(pairs) embedded in TT layout

=cut

=head2 pie_view

C<GET /pie> -- Render a D3.js v7 animated pie chart from the current data
pipeline.

Each row's category value (C<cat=>) is used as a slice label; the numeric
value column (C<val=>) is summed per category.  Accounting-notation
negatives such as C<(1,234.56)> are handled automatically.  Slices are
sorted by total descending; when there are more than 12 distinct categories
the smallest ones are collapsed into a single "Other" slice.

Clicking any slice or legend entry navigates back to the table view with
an C<f=cat:eq:value> filter applied automatically, so the user can drill
into the data behind a slice without leaving the application.

=head3 API SPECIFICATION

=head4 INPUT

  l=<spec>    string   Left-table spec (required).  Same syntax as /join.
  cat=<col>   string   Category column name (required; used as slice labels).
  val=<col>   string   Numeric value column name (required; values are summed).
  donut=1     flag     Render as a donut chart with a hole in the centre (optional).
  back=<url>  string   URL for the "Back to table" breadcrumb link (optional; default "/").
  f=<spec>    string   Result filter (repeatable; same syntax as /join).

=head4 OUTPUT

  200 text/html   TT-rendered pie chart page containing:
                  - Two-level breadcrumb (Home > Back to table).
                  - Export buttons for SVG and PNG (legend is composited in).
                  - An animated D3.js pie or donut chart with a colour-coded
                    legend.  Each slice and legend entry is clickable and
                    navigates to the filtered table view.
                  - Slice count (e.g. "7 slices").

  200 text/plain  "No plottable data" when every row has a non-numeric or
                  missing value column (HTTP 200, not 4xx, so the page can
                  render a friendly message).

  400 text/plain  C<cat=> or C<val=> absent, or named column not found.
  404 text/plain  Data source could not be opened.

=head4 DOMAIN CONSTRAINTS

  cat=    Any column name that exists in the result set.  Cell values are
          used verbatim as slice labels.  Empty-string cells are skipped.

  val=    Must be a column whose cells contain numbers (after stripping
          currency symbols, commas, and handling accounting-notation negatives).
          Rows where the value is still non-numeric after stripping are skipped.
          Negative totals are included in the chart (slice values may be negative
          if the source data contains credits or reversals).

  donut=  Any truthy value (e.g. "1") enables the donut hole.  Absent or
          "0" renders a solid pie.

=head3 MESSAGES

  Missing cat or val column parameter    C<cat=> or C<val=> query param absent.
  Column not found: <name>               Named column absent from the result set.
  Could not open data source             Left-table spec unresolvable or 404.
  No plottable data: ...                 All rows lack a valid numeric value.

=head3 EXAMPLE

  GET /pie?l=table:sales&cat=region&val=amount&back=/view/sales

Renders a pie chart of total C<amount> per C<region>.  Clicking the
"North" slice navigates to C</view/sales?f=region:eq:North>.

With a donut hole:

  GET /pie?l=table:sales&cat=region&val=amount&donut=1

=head3 FORMAL SPECIFICATION

  pie_view : Controller x Params -> HTML | Error

  let pipeline = run_export_pipeline(l, j, f, d)
  let totals   = { cat => sum { val(row) | row in pipeline.records,
                                           cat(row) != '', num(val(row)) != bot }
                 | cat in range(cat_col) }

  pre  cat in params /\ val in params     else 400
  pre  cat in pipeline.cols               else 400
  pre  val in pipeline.cols               else 400
  pre  totals != {}                        else 200 "No plottable data"
  post HTML::D3->render_pie_chart_snippet(slices) embedded in TT layout
       where slices = sort_desc { |s.value| | s in totals }

=cut

=head2 clear_uploads

C<POST /uploads/clear> -- Delete every file from the upload staging
directory and return the total disk space recovered.

The staging directory accumulates files from drag-and-drop uploads.
It grows indefinitely; this action lets users reclaim that space without
needing shell access.

=head3 API SPECIFICATION

=head4 INPUT

No parameters.  The directory cleared is the one C<POST /upload> writes to:
C<uploads_dir> from the configuration, or C<< <app_home>/.uploads >> when that
key is not set.

=head4 OUTPUT

  200 application/json   { "freed": <bytes>, "count": <n> }

C<freed> is the total number of bytes removed.  C<count> is the number of
files deleted.  Both are 0 when the directory is absent or already empty.

=cut

=head2 scatter_view

C<GET /scatter> -- Render a D3.js scatter plot or bubble chart.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  x=<col>        X-axis column (required; numeric)
  y=<col>        Y-axis column (required; numeric)
  series=<col>   Colour-by category column (optional)
  size=<col>     Bubble-radius numeric column (optional)
  scheme=<name>  D3 colour scheme (default tableau10; only used with series=)
  min_r=N        Minimum bubble radius in px (default 3; range 1-40)
  max_r=N        Maximum bubble radius in px (default 15; range 1-40)
  back=<url>     URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l        spec    Required.  Left table spec (table:name or path:/abs/path).
  x        string  Required.  Numeric X-axis column name.
  y        string  Required.  Numeric Y-axis column name.
  series   string  Optional.  Categorical colour-dimension column.
  size     string  Optional.  Numeric bubble-radius column.
  scheme   string  Optional.  One of: tableau10 category10 set2 set3 paired.
  min_r    int     Optional.  Minimum radius 1-40 (default 3).
  max_r    int     Optional.  Maximum radius 1-40 (default 15).
  back     url     Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html    Rendered scatter chart page.
  400 text/plain   Missing x= or y= parameter.
  400 text/plain   Column not found: <col>.
  400 text/plain   Unknown colour scheme: <scheme>  (only when series= is set).
  404 text/plain   "Could not open data source" when l= is absent/invalid.

=head3 FORMAL SPECIFICATION

  scatter_view == lambda self .
    pre  length(x_col) > 0 /\ length(y_col) > 0
         /\ x_col in columns /\ y_col in columns
         /\ (series_col != '' => series_col in columns)
         /\ (size_col   != '' => size_col   in columns)
         /\ (series_col != '' => scheme in SCATTER_SCHEMES)
         /\ 1 <= min_r <= 40 /\ 1 <= max_r <= 40
    post render(scatter, pairs)

=head3 EXAMPLE

  GET /scatter?l=table:sales&x=quantity&y=amount&series=region
    -> 200 HTML page containing D3 scatter chart SVG

=cut

=head2 stacked_view

C<GET /stacked> -- Render a D3.js stacked bar chart.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  cat=<col>     X-axis category column (required)
  series=<col>  Stack-segment column (required; seg= is a backwards-compat alias)
  val=<col>     Numeric measure column (optional; count rows when absent)
  scheme=<name> D3 colour scheme (default tableau10)
  back=<url>    URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l       spec    Required.  Left table spec.
  cat     string  Required.  X-axis categorical column name.
  series  string  Required.  Stack-segment categorical column name.
  val     string  Optional.  Numeric measure column; omit for count mode.
  scheme  string  Optional.  D3 colour scheme name.
  back    url     Optional.  Safe back-link URL.

=head4 OUTPUT

  200 text/html    Rendered stacked bar chart page.
  400 text/plain   Missing cat= or series= parameter.
  400 text/plain   Column not found: <col>.
  404 text/plain   "Could not open data source".

=head3 FORMAL SPECIFICATION

  stacked_view == lambda self .
    pre  length(cat_col) > 0 /\ length(series_col) > 0
         /\ cat_col in columns /\ series_col in columns
    let rows = _grouped_totals(records, cat_col, series_col, val_col) in
    post render(stacked, rows)

=head3 EXAMPLE

  GET /stacked?l=table:sales&cat=region&series=product&val=amount
    -> 200 HTML page containing D3 stacked bar chart SVG

=cut

=head2 combo_view

C<GET /combo> -- Render a D3.js combo bar+line chart.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  cat=<col>       X-axis category column (required; x= is a backwards-compat alias)
  bar_val=<col>   Numeric column plotted as bars (required; bar= is a backwards-compat alias)
  line_val=<col>  Numeric column plotted as a line (required; line= is a backwards-compat alias)
  back=<url>      URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l         spec    Required.  Left table spec.
  cat       string  Required.  X-axis categorical column name (x= also accepted).
  bar_val   string  Required.  Numeric bar-measure column (bar= also accepted).
  line_val  string  Required.  Numeric line-measure column (line= also accepted).
  back      url     Optional.  Safe back-link URL.

=head4 OUTPUT

  200 text/html    Rendered combo chart page.
  400 text/plain   Missing cat=, bar_val=, or line_val= parameter.
  400 text/plain   Column not found: <col>.
  404 text/plain   "Could not open data source".

=head3 FORMAL SPECIFICATION

  combo_view == lambda self .
    pre  length(cat_col) > 0 /\ length(bar_col) > 0 /\ length(line_col) > 0
         /\ cat_col in columns /\ bar_col in columns /\ line_col in columns
    post render(combo, pairs)

=head3 EXAMPLE

  GET /combo?l=table:sales&cat=month&bar_val=revenue&line_val=units
    -> 200 HTML page containing D3 combo bar+line chart SVG

=cut

=head2 treemap_view

C<GET /treemap> -- Render a D3.js treemap where tile area encodes a numeric column.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  group=<col>  Tile-label categorical column (required; cat= is a backwards-compat alias)
  size=<col>   Tile-area numeric column (required; val= is a backwards-compat alias)
  topn=N       Keep only the top-N tiles by size; remainder collapsed into "Other"
  scheme=<name> D3 colour scheme (default tableau10)
  back=<url>   URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l       spec    Required.  Left table spec.
  group   string  Required.  Tile-label categorical column (cat= also accepted).
  size    string  Required.  Tile-area numeric column (val= also accepted).
  topn    int     Optional.  Keep top-N tiles; 0 or absent means no limit.
  scheme  string  Optional.  D3 colour scheme name.
  back    url     Optional.  Safe back-link URL.

=head4 OUTPUT

  200 text/html    Rendered treemap page.
  400 text/plain   Missing group= or size= parameter.
  400 text/plain   Unrecognised scheme= parameter (?color= returns 400).
  400 text/plain   Column not found: <col>.
  404 text/plain   "Could not open data source".

=head3 FORMAL SPECIFICATION

  treemap_view == lambda self .
    pre  length(group_col) > 0 /\ length(size_col) > 0
         /\ group_col in columns /\ size_col in columns
         /\ color param absent (scheme= is the correct param name)
    let tiles = _grouped_totals(records, group_col, [], size_sum) in
    let top   = topn > 0 ? top_n(tiles, topn) : tiles in
    post render(treemap, top)

=head3 EXAMPLE

  GET /treemap?l=table:sales&group=product&size=amount&topn=10
    -> 200 HTML page containing D3 treemap SVG

=cut

=head2 histogram_view

C<GET /histogram> -- Render a D3.js histogram with server-side binning.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  col=<col>   Numeric column to bin (required)
  bins=N      Number of bins (default 10; max 200)
  back=<url>  URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l     spec    Required.  Left table spec.
  col   string  Required.  Numeric column to histogram.
  bins  int     Optional.  Bin count 1-200 (default 10).
  back  url     Optional.  Safe back-link URL.

=head4 OUTPUT

  200 text/html    Rendered histogram page.
  400 text/plain   Missing col= parameter.
  400 text/plain   Column not found: <col>.
  200 text/html    Empty histogram page when no numeric values exist.
  404 text/plain   "Could not open data source".

=head3 FORMAL SPECIFICATION

  histogram_view == lambda self .
    pre  length(col) > 0 /\ col in columns
         /\ 1 <= bins <= 200
    let vals  = { row[col] | row in records, looks_like_number(row[col]) } in
    let width = (max(vals) - min(vals)) / bins in
    let bdata = bin(vals, width) in
    post render(histogram, bdata, bins => |bdata|)

=head3 EXAMPLE

  GET /histogram?l=table:sales&col=amount&bins=20
    -> 200 HTML page containing D3 histogram SVG

=cut

=head2 wordcloud_view

C<GET /wordcloud> -- Render a word cloud of a text column with HTML::TagCloud.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  col=<col>    Text column to read (required)
  topn=N       Different words to show (default 50; range 1--500)
  minlen=N     Shortest word kept (default 3; range 1--64)
  stop=<words> Extra words to ignore, comma or space separated
  back=<url>   URL for the "Back to table" breadcrumb link; when given, each
               word links to the rows that contain it

=head3 API SPECIFICATION

=head4 INPUT

  l       spec    Required.  Left table spec.
  col     string  Required.  Column whose cells are read as text.
  topn    int     Optional.  Word count 1-500 (default 50).
  minlen  int     Optional.  Minimum word length 1-64 (default 3).
  stop    string  Optional.  Extra stopwords, comma or space separated.
  back    url     Optional.  Safe back-link URL; enables the drill-down links.

=head4 OUTPUT

  200 text/html    Rendered word cloud page.
  400 text/plain   Missing col= parameter.
  400 text/plain   Column not found: <col>.
  400 text/plain   A refused c= calculated field or cs= cross-row spec.
  404 text/plain   "Could not open data source".

=head4 SEMANTICS

A word is lower-cased, split on anything that is not a letter, a digit or an
apostrophe, and dropped when it is shorter than C<minlen> or holds no letter.
A word counts once per row that contains it, so the size of a word is the
number of rows, not the number of repetitions inside one cell.  The built-in
English stopword list is removed, and C<stop=> adds to it.

=head3 EXAMPLE

  GET /wordcloud?l=table:sales&col=product&back=/view/sales
    -> 200 HTML page with a word cloud whose words filter the sales table

=cut

=head2 map_view

C<GET /map> -- Render an OpenStreetMap map of the view.

A row gets a position one of two ways.  With C<loc=E<lt>columnE<gt>> the column
holds places, and each distinct value is geocoded once by
L<Database::BI::Model::Geocode> (one lookup per value however often the column
repeats it); the answers are remembered in the model store and shared by every
dataset, so a second visit - or another file naming the same place - asks
nothing.  With C<lat=> and C<lon=> the columns already hold
coordinates.  Rows sharing a position become one marker whose popup says how
many rows it stands for.  Markers are clustered with Leaflet.markercluster, so
a dense map draws a count at low zoom and splits it into individual pins as it
is zoomed in; a sparse map looks the same, because markers far enough apart are
left on their own.  Clustering is always on; there is no C<cluster=> switch.

The map page never shows the L<HTML::OSM> Nominatim search box: C<search => 0>
is always passed, so nothing typed on the page leaves the reader's machine.
L<HTML::OSM> 0.12 or later is the renderer; with an older optional install (or
none at all) the page still renders the marker count and a warning, rather than
failing.

Accepts the same C<l=>, C<j=>, C<c=> and C<f=> pipeline params as every other
visual, so the map shows the filtered, calculated view.

  loc=<col>       Location column to geocode (required unless lat= and lon= are given)
  lat=<col>       Latitude column (numeric, -90..90)
  lon=<col>       Longitude column (numeric, -180..180)
  popup=<col>     Column shown in the marker popup (repeatable; default: all non-coordinate columns)
  max=N           Markers to draw (default: map_max_markers, 2000)
  zoom=N          Initial zoom, 0..19 (default: fit the markers)
  max_zoom=N      Tile layer maxZoom, 0..28 (default: map_max_zoom config, if set)
  tiles=<name>    Named tile source from the tile_sources config key
  heat=1          Add a heatmap layer over the markers
  weight=<col>    Numeric intensity column for the heatmap (normalised to 0..1)
  size=<col>      Numeric bubble-radius column; markers become circles
  color=<col>     Column whose value picks a marker colour
  color_rule=<op>:<value>:<colour>  Repeatable colour rule; op is
                  gt, ge, lt, le, eq or ne; first match wins
  color_default=<colour>  Fallback when no rule matches (default #3388ff)
  series=<col>    Colour markers by category; mutually exclusive with color=
  scheme=<name>   Palette for series=: tableau10, category10, set2, set3, paired
  back=<url>, back2=<url>, back2_label=<text>  Breadcrumb links
  f=              Result filters (repeatable)

A colour rule is C<< E<lt>opE<gt>:E<lt>valueE<gt>:E<lt>colourE<gt> >>; rules
are tried in the order given and the first match wins.  The comparison is
numeric when both the cell and the rule's value look like numbers, and
otherwise only C<eq>/C<ne> are meaningful (case-insensitive).  A colour is
C<#rgb>, C<#rrggbb> or a CSS name such as C<red>; names are mapped to hex for
bubble markers, which C<add_circle_marker> accepts only as hex.  C<series=>
cycles the chosen palette across distinct values instead, and its legend lists
categories rather than rules.

Config values: C<map_geocode_max> (new lookups per request, default 500),
C<map_max_markers> (markers per request, default 2000), C<map_region> (a
two-letter country hint for ambiguous place names), C<map_max_zoom> (the tile
layer's default maxZoom), C<tile_sources> (a hashref of named tile sources,
each C<< { url => ... } >>), C<tile_url> (the single default tile layer) and
C<geocoder> (an object to use instead of loading L<Geo::Coder::Free>; the seam
the tests use).  The C<leaflet_*>_url keys point Leaflet, markercluster and the
heatmap plugin at self-hosted copies for an offline deployment.

=head3 API SPECIFICATION

=head4 INPUT

  l        spec    Required.  Left table spec (table:name or path:/abs/path).
  loc      string  Optional.  Column of places to geocode.
  lat      string  Optional.  Numeric latitude column.
  lon      string  Optional.  Numeric longitude column.
  popup    string  Optional, repeatable.  Columns shown in the popup.  Default: all non-coordinate columns.
  max      int     Optional.  Positive marker cap for this request.
  zoom     int     Optional.  0..19; out-of-range values are clamped.
  max_zoom int     Optional.  0..28; out-of-range values are clamped.
  tiles    string  Optional.  A key of the tile_sources config hashref.
  heat     bool    Optional.  Add the heatmap layer.
  weight   string  Optional.  Numeric column for heatmap intensity.
  size     string  Optional.  Numeric column for bubble radius.
  color    string  Optional.  Column whose value selects a marker colour.
  color_rule string Optional, repeatable.  <op>:<value>:<colour>.
  color_default string Optional.  Fallback marker colour.
  series   string  Optional.  Column to colour by category.
  scheme   string  Optional.  Palette for series= (default tableau10).
  back     url     Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html    Rendered map page.
  400 text/plain   No loc=, or lat= without lon=.
  400 text/plain   Column not found: <col>  (or the geocode message naming it).
  400 text/plain   Coordinate column wholly out of range, naming it.
  400 text/plain   Unknown tile source "<name>".
  400 text/plain   Unknown colour scheme: <name>.
  400 text/plain   Use either color= or series=, not both.
  404 text/plain   "Could not open data source" when l= is absent/invalid.

=head3 EXAMPLE

  GET /map?l=table:sales&loc=place
    -> 200 HTML page containing Leaflet markers for the places that resolved

=cut

=head2 canvas_render

C<GET /a/:id> -- Render a saved analysis (canvas).  The document holds its
datasets, joins, calculated fields, parameters, layouts, bookmarks and
hierarchies, so the page is the stored analysis plus the request's overlays.

Cross-filtering:
C<?cf=E<lt>colE<gt>:E<lt>opE<gt>:E<lt>valE<gt>> (repeatable), with C<cv=> as
the selected value; drill-down uses C<?dd=E<lt>hierarchyE<gt>&dl=E<lt>levelE<gt>>
where level 0 is the first level and one past the last means "drilled
through"; parameter overrides are C<?p.E<lt>nameE<gt>=E<lt>valueE<gt>>.

C<?cs=>/C<by=>/C<order=> name the cross-row columns (see C<_cross_row_specs>).
The plan is validated once for the page and then run once per card, after that
card's own filters and after the cross-filter, so each card's running total is
over the rows that card draws.

=head3 API SPECIFICATION

=head4 INPUT

  id       path    Required.  Alphanumeric analysis id.
  cf       string  Optional, repeatable.  col:op:val cross-filter.
  cv       string  Optional.  Selected value for the cross-filter.
  dd       string  Optional.  Named hierarchy to drill.
  dl       int     Optional.  Current drill level (0-based).
  p.<name> string  Optional.  Parameter override.
  cs       string  Optional, repeatable.  Cross-row spec, as on the data pages.
  by       string  Optional.  Partition for the cross-row pass.
  order    string  Optional, repeatable.  Read order for the cross-row pass.

=head4 OUTPUT

  200 text/html    Rendered canvas.
  400 text/plain   Invalid id or parameter.
  404 text/plain   Unknown analysis.
  422 text/plain   Stored document fails validation.

=head2 analyses_list / analyses_create / analyses_get / analyses_update / analyses_patch / analyses_delete / analyses_import / analyses_export / analyses_add_visual / analyses_update_visual

C</api/analyses> -- CRUD and import/export for saved analyses.  Documents are
validated on write: unknown top-level keys are dropped and a document that is
not a JSON object is refused.  Import accepts a document exported by
C<GET /api/analyses/:id/export> and creates a new id.

=head3 API SPECIFICATION

=head4 INPUT / OUTPUT

  GET    /api/analyses                 -> 200 { analyses: [ { id, name, datasets, updated }, ... ] }
  POST   /api/analyses                 <- JSON document; 201 { id } or 400 { error }
  POST   /api/analyses/import          <- JSON document; 201 { id } or 400 { error }
  GET    /api/analyses/:id             -> 200 document, 400 invalid id, 404 unknown
  PUT    /api/analyses/:id             <- JSON document; 200 { saved: 1 }, 400, 404
  PATCH  /api/analyses/:id             <- partial JSON document; 200 { saved: 1 }, 400, 404
  DELETE /api/analyses/:id             -> 200 { deleted: 1 }, 400, 404
  GET    /api/analyses/:id/export      -> 200 JSON document, 400, 404
  POST   /api/analyses/:id/visuals     <- JSON visual; 201 { visual }, 400, 404
  PATCH  /api/analyses/:id/visuals/:visual  <- partial JSON visual; 200, 400, 404

Writes return 503 when the model store is not writable.

=head2 analyses_share / share_view / embed_view / visual_download

C<POST /api/analyses/:id/share> issues a signed, expiring read-only token;
C<GET /share/:id?token=...> renders the canvas without edit controls, and
C<GET /embed/:id?token=...> renders it without page chrome for an iframe.
C<GET /a/:id/visual/:n/csv> downloads one visual's rows as CSV; the C<png>
form is not rendered server-side and returns 501, because the chart pages
rasterise their own SVG in the browser.

=head3 API SPECIFICATION

=head4 INPUT / OUTPUT

  POST /api/analyses/:id/share   <- expires=<seconds> (optional)
                                 -> 200 { token, expires }, 400, 404
  GET  /share/:id?token=...      -> 200 text/html, 400 missing token,
                                    401/403 bad or expired token, 404 unknown
  GET  /embed/:id?token=...      -> as /share/:id, plus 422 invalid document
  GET  /a/:id/visual/:n/:fmt     -> 200 text/csv for fmt=csv; 501 for fmt=png;
                                    400 bad visual index; 404 unknown analysis

=head2 catalog_view

C<GET /catalog> -- List every supported file in C<data_dir> with its type,
size, modification time and the saved analyses that reference it.  Lineage is
computed by scanning the analysis store; there is no second registry.

=head3 API SPECIFICATION

=head4 OUTPUT

  200 text/html    Catalog page.

=head2 insights_view

C<GET /insights> -- Automatic statistical insights for a dataset: Tukey IQR
outliers, period-over-period deltas, top movers, and seasonality from the
lag-1 autocorrelation of monthly totals.  Pure arithmetic - no LLM and no
network call.  Every insight links to a chart or stats view showing the data
behind it.

=head3 API SPECIFICATION

=head4 INPUT

  l        spec    Required.  Left table spec.
  f        string  Optional, repeatable.  Result filters.
  back, back2, back2_label, back_label  Optional.  Breadcrumb links.

=head4 OUTPUT

  200 text/html    Insights page.
  400 text/plain   Missing l= or an invalid pipeline parameter.
  404 text/plain   "Could not open data source".

=head2 ask_api

C<POST /api/ask> -- Translate a plain-English question into an analysis spec.
The model receives column names and inferred types only: no row data, no file
paths.  The returned spec is validated (column names and kinds) before it is
returned.  Absent when C<ai_api_key> is not configured.

=head3 API SPECIFICATION

=head4 INPUT

  l        spec    Required.  Left table spec.
  q        string  Required.  The question.
  f        string  Optional, repeatable.  Result filters.

=head4 OUTPUT

  200 application/json  { spec, url, valid => 1 }
  400 application/json  { error }
  404 application/json  { error } (unopenable source)
  503 application/json  { error } (no ai_api_key)

=head2 summary_api

C<POST /api/summary> -- Narrative summary of an analysis.  The deterministic
path builds template sentences offline; C<ai=1> additionally asks the
configured LLM to polish them from aggregate facts only (no raw rows, no file
paths).  Results are cached in-process for one hour.

=head3 API SPECIFICATION

=head4 INPUT

  l        spec    Required.  Left table spec.
  f        string  Optional, repeatable.  Result filters.
  ai       bool    Optional.  Use the LLM when ai_api_key is configured.

=head4 OUTPUT

  200 application/json  { summary, facts, ai => 0|1 }
  400 application/json  { error }
  404 application/json  { error }

=head2 geo_list / geo_save / geo_delete

C</geo/*> -- Coordinate-column preferences, stored per dataset spec under
C<geo.E<lt>specE<gt>.columns> in the model store.  The Map panel reads them on
open and pre-populates its column selects.

=head3 API SPECIFICATION

=head4 INPUT / OUTPUT

  GET  /geo/list?l=<spec>   -> 200 { columns: { <col>: { kind: lat|lon|location } } }
                               400 { error }
  POST /geo/save            <- l=, col=, kind=lat|lon|location
                            -> 200 { saved: 1 }, 400 { error }
  POST /geo/delete          <- l=, col= (omit col to clear the spec)
                            -> 200 { deleted: 1 }, 400 { error }

=head2 calc_list / calc_save / calc_delete

C<GET /calc/list>, C<POST /calc/save>, C<POST /calc/delete> -- Manage stored
calculated fields for a table spec.

Calculated fields are named expression strings evaluated per-row by
C<Database::BI::Calc> and appended as virtual columns before any aggregation.

=head3 API SPECIFICATION

=head4 calc_list (GET /calc/list)

  INPUT:  l=<spec>   (required)
  OUTPUT: 200 application/json  { "fields": { "<name>": "<expr>", ... } }
          400 application/json  { "error": "l= required" }

=head4 calc_save (POST /calc/save)

  INPUT:  l=<spec>   (required)
          name=<id>  (required; must match /\A[A-Za-z_][A-Za-z0-9_]*\z/)
          expr=<expression>  (required; max 512 chars; hostile patterns rejected)
  OUTPUT: 200 application/json  { "saved": 1 }
          400 application/json  { "error": "..." }  (compile error or hostile input)

=head4 calc_delete (POST /calc/delete)

  INPUT:  l=<spec>   (required)
          name=<id>  (required)
  OUTPUT: 200 application/json  { "deleted": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /calc/save  l=path:/data/sales.csv&name=margin&expr=amount-cost
    -> 200 { "saved": 1 }
  GET /calc/list?l=path:/data/sales.csv
    -> 200 { "fields": { "margin": "amount-cost" } }

=cut

=head2 groups_list / groups_save / groups_delete

C<GET /groups/list>, C<POST /groups/save>, C<POST /groups/delete> -- Manage
named value groups that produce virtual C<${col}_group> columns.

=head3 API SPECIFICATION

=head4 groups_list (GET /groups/list)

  INPUT:  l=<spec>  (required), col=<col>  (required)
  OUTPUT: 200 application/json  { "groups": { "<label>": ["<val>", ...], ... } }
          400 application/json  { "error": "l= required" } or "col= required"

=head4 groups_save (POST /groups/save)

  INPUT:  l=<spec>, col=<col>, group=<label>, values=<newline-separated values>
  OUTPUT: 200 application/json  { "saved": 1 }
          400 application/json  { "error": "..." }

=head4 groups_delete (POST /groups/delete)

  INPUT:  l=<spec>, col=<col>, group=<label>  (omit group= to delete all groups for col)
  OUTPUT: 200 application/json  { "deleted": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /groups/save  l=path:/data/sales.csv&col=region&group=North&values=MN%0AWI%0AIA
    -> 200 { "saved": 1 }
  GET /groups/list?l=path:/data/sales.csv&col=region
    -> 200 { "groups": { "North": ["MN","WI","IA"] } }

=cut

=head2 dates_list / dates_save / dates_delete

C<GET /dates/list>, C<POST /dates/save>, C<POST /dates/delete> -- Manage stored
date-normalisation patterns that convert non-ISO date columns to ISO-8601
(C<YYYY-MM-DD>) in-place before aggregation.

=head3 API SPECIFICATION

=head4 dates_list (GET /dates/list)

  INPUT:  l=<spec>  (required)
  OUTPUT: 200 application/json  { "patterns": { "<col>": "<pattern>", ... } }
          400 application/json  { "error": "l= required" }

=head4 dates_save (POST /dates/save)

  INPUT:  l=<spec>, col=<col>, pattern=<fmt>
          Supported patterns: %m/%d/%Y  %d/%m/%Y  %d-%b-%Y
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "Unsupported date format pattern ..." }

=head4 dates_delete (POST /dates/delete)

  INPUT:  l=<spec>, col=<col>  (omit col= to delete all patterns for the spec)
  OUTPUT: 200 application/json  { "deleted": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /dates/save  l=path:/data/sales.csv&col=sale_date&pattern=%m/%d/%Y
    -> 200 { "ok": 1 }
  GET /dates/list?l=path:/data/sales.csv
    -> 200 { "patterns": { "sale_date": "%m/%d/%Y" } }

=cut

=head1 DESCRIPTION

All user-facing routes in C<Database::BI> are handled by this controller.
See the individual action POD above for per-endpoint documentation.

=head2 Filter operators and the quick-filter bar

Filters are expressed as C<f=col:op:val> query parameters and are applied
server-side after all joins.  Multiple C<f=> params are applied in order
(AND semantics).

The colon separator is split with a limit of 3, so values may themselves
contain colons (e.g. C<f=sale_date:eq:2025-01-15>, or a time value like
C<f=start_time:eq:14:30:00>).

B<Supported operators:>

  eq        case-insensitive string equality
  ne        case-insensitive string inequality
  contains  case-insensitive substring match
  starts    case-insensitive prefix match
  lt        numeric less-than
  le        numeric less-than-or-equal
  gt        numeric greater-than
  ge        numeric greater-than-or-equal
  empty     cell is undef or empty string (val ignored)
  notempty  cell is defined and non-empty (val ignored)

B<Quick-filter bar (table view):>

A filter row below the toolbar lets the user pick a column, operator, and
value and press "Apply filter" (or Enter) to add a condition without
opening any panel.  The current URL is updated with the new C<f=> param
and the page reloads; all other URL parameters (joins, dedup, etc.) are
preserved automatically via the browser C<URL> API.

Active filter chips appear in the toolbar.  Each chip has an individual
x-button to remove just that condition.  The "x Clear filters" link
removes all C<f=> params at once.

B<Drill-down from pie chart:>

Clicking a pie slice or legend entry on C</pie> navigates to the table
view with C<f=cat_col:eq:label> appended, so the user can inspect the
rows behind any slice without manually typing a filter.

=head2 Cross-row columns

A measure folds a group into one number, a calculated field computes one row
from that row, and C<cs=> is the third shape: one row worked out from many,
written back beside every row of the view.

  cs=<column>:<function>:<alias>            write a column of that name
  cs=<column>:<function>:<alias>:<count>    a moving window needs its width
  by=<column>[,<column>...]                 partition; without it there is one
  order=<column>[:asc|desc]                 the order the rows are read in

B<Functions:> C<pct_of_total>, C<rank> and C<zscore> are order-free.  They
answer a whole-partition question: a row's share of the partition total (the
shares sum to 1), its rank with ties sharing a rank and the next rank
skipping (as SQL C<RANK()> does), and its z-score against the same sample
standard deviation the C<stdev> measure and C</stats> use.

C<running_total>, C<running_count>, C<running_pct>, C<window_sum>,
C<window_avg>, C<lag>, C<delta> and C<pct_change> accumulate in order and
require C<order=>; each takes the rows in that order, so
C<running_total(amount)> over C<order=day:asc> is the year-to-date a reader
expects.  Only C<window_sum> and C<window_avg> take a parameter, the width of
the row window, and the window includes the row itself.

C<order=> decides the order the pass reads the rows in, not the order the
page shows them in: the table and its sort controls are untouched, so a
reader can sort by amount while a running total follows the date.  Ties keep
their arrival order, which is what makes two runs over the same file agree.

C<by=> partitions the rows.  Rows whose partition column is empty are grouped
together under the empty value rather than dropped -- C<_grouped_totals>
excludes such rows, because a pivot cell needs a key, but a windowed column has
to cover every displayed row.

A cell that is not numeric yields C<undef> in the produced column rather than
a placeholder: there is no previous row for the first row of a partition, and
a chart skips an undefined value while the measure fold does too, so a window
column cannot silently become a zero.

The pass is stage 6 of the pipeline: after the filters, so a window is over
what the filters left, and before anything slices a page, so page 2 continues
page 1's running total rather than restarting it.  C</export> runs the same
stages and carries the same column.  A spec that cannot be honoured -- an
unknown function, an unknown column, a parameter on a function that takes
none, a parameter that is not a positive whole number, a missing C<order=>
for an accumulating function -- is a 400 naming the parameter.

=head1 COMMON PITFALLS

These are the most common mistakes when working with this controller.

=over 4

=item B<SQLite files must use the .sql extension, not .sqlite>

C<Database::Abstraction> (the data-reading library) probes for a file called
C<tablename.sql> when it wants to open a SQLite database.  It does B<not>
look for C<.sqlite> or C<.db3>.  If your file is called C<inventory.sqlite>,
rename it to C<inventory.sql> or it will not appear in the file browser and
will return 404 when opened.

=item B<Filter values that contain a colon still work>

A date like C<2025-01-15> contains hyphens, not colons, so it is fine.  But
if your value itself contains a colon (for example, a time like C<14:30:00>),
the filter still works because the C<col:op:val> spec is split on the B<first
two> colons only -- the rest of the string becomes the value.

  # This correctly matches "14:30:00" in the start_time column:
  ?f=start_time:eq:14:30:00

=item B<Left join keeps only the FIRST matching right-table row>

When the right table has two rows with the same join key, only the first one
(in file order) is used.  The second is silently ignored.  If you need all
matches, consider pre-processing your data so join keys are unique.

=item B<Export format comes from the filename extension, not a Content-Type header>

When using C<POST /export> to save a file to disk, the format (CSV or SQLite)
is determined by the extension of the C<filename> parameter.  C<.csv> produces
a CSV file; C<.sql> produces a SQLite database.  Any other extension returns
HTTP 415 (Unsupported Media Type).  The C<Content-Type> request header is
ignored entirely.

=item B<Template Toolkit variables starting with underscore are silently dropped>

If you add a stash variable with a name starting with C<_> (for example,
C<_tmp> or C<_result>), Template Toolkit will silently produce an empty string
when the template tries to read it.  This is a TT quirk when C<TRIM =E<gt> 1>
is active.  Always use names that start with a letter.

=item B<_apply_filter_spec always passes all records through for unknown operators>

If you pass an operator that is not in the supported list (for example C<regex>
or C<like>), the filter is treated as a no-op and B<all rows are returned>.  No
error is produced.  This is intentional so that future operators can be added
without breaking existing clients that read a wider response.

=item B<Uploaded files are evicted automatically, but not immediately>

Files uploaded via C<POST /upload> are stored in C<uploads_dir>, which
defaults to C<.uploads/> under the application home directory.  C<Database::BI>
evicts upload subdirectories whose modification time is older than 24 hours
B<on every server startup>.
Between restarts, files accumulate.  For an immediate full purge (regardless
of age), post to C<POST /uploads/clear> or click the "Clear upload cache"
button in the UI.

=item B<Open C<data/> tables by name; open other files by absolute path>

The C<view> action (C<GET /view/:table>) only looks inside C<data_dir>.
To open a file from anywhere else on the filesystem, use C<open_file>
(C<GET /open?path=/abs/path>).  The two routes use different URL schemes and
are not interchangeable.

=back

=head1 LIMITATIONS

=over 4

=item *

Multi-table joins are delegated to C<Database::Join> with C<backend =E<gt> 'auto'>.
For datasets up to C<join_max_rows> combined rows (default 10,000; configurable
in C<database_bi.conf>) the join runs in Perl memory; larger datasets spill to
a temporary SQLite database so peak RAM is bounded by the result set rather than
the sum of all source tables.

=item *

C<_resolve_language> extracts only the primary language subtag from the first
C<Accept-Language> tag (e.g. C<de> from C<de-DE,de;q=0.9,en;q=0.8>).
Quality weights and multiple alternatives are not ranked.

=item *

No GeoIP-based language resolution is implemented.  The language is resolved
from the HTTP C<Accept-Language> header only.

=item *

C<Sub::Protected> enforcement requires the CHECK compilation phase; when modules
are loaded dynamically at test time the "Too late to run CHECK block" warning
is emitted and the restrilanguage> extracts only the primary language subtag from the first
C<Accept-Language> tag (e.g. C<de> from C<de-DE,de;q=0.9,en;q=0.8>).
Quality weights and multiple alternatives are not ranked.

=item *

No GeoIP-based language resolution is implemented.  The language is resolved
from the HTTP C<Accept-Language> header only.

=item *

C<Sub::Protected> enforcement requires the CHECK compilation phase; when modules
are loaded dynamically at test time the "Too late to run CHECK block" warning
is emitted and the restriction is not enforced in that context.

=back

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
