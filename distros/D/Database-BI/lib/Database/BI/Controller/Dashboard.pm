package Database::BI::Controller::Dashboard;

use strict;
use warnings;

our $VERSION = '0.023.0';

use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;

use Carp		qw(croak carp);
use Cwd			qw(realpath);
use List::Util		qw(min max sum);
use CGI::Info;
use CGI::Lingua;
use Database::BI::I18N ();
use Unicode::Normalize ();
use Database::BI::Tutorial;
use Database::BI::Util;
use Mojo::File;
use Mojo::JSON		qw(encode_json decode_json from_json to_json);
use Mojo::Parameters;
use Mojo::URL;
use Mojo::Util		qw(url_escape encode xml_escape hmac_sha1_sum secure_compare);
use Digest::SHA ();
use Scalar::Util ();
use Database::BI::Password ();
use File::Path		qw(remove_tree);
use File::Spec;
use File::Temp		qw(tempfile tempdir);
use Readonly;
use Sub::Protected;
use version ();

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# File extensions that Database::Abstraction can probe, in probe order.
# .sql, .sqlite, and .sqlite3 are all SQLite databases; .db is Berkeley DB.
# As many digits as a request parameter may have and still be exact in a Perl
# number.  More than this is not a page number or a limit, it is someone probing.
Readonly my $MAX_WHOLE_NUMBER_DIGITS => 15;
Readonly my %ANALYSIS_KEYS => map { $_ => 1 } qw(id version created updated name datasets joins combines fields measures params visuals layout bookmarks hierarchies);
Readonly my $MAX_HISTOGRAM_BINS      => 200;

# What a text card on a canvas may be styled with.  The fonts are ones browsers
# already have, so a card needs no CDN, and a stored card names a font by its
# key: only the CSS written here ever reaches a style attribute.
Readonly my @TEXT_FONTS => (
	{ value => '',          label => 'Same as the page', css => '' },
	{ value => 'arial',     label => 'Arial',            css => 'Arial, Helvetica, sans-serif' },
	{ value => 'georgia',   label => 'Georgia',          css => 'Georgia, "Times New Roman", serif' },
	{ value => 'times',     label => 'Times New Roman',  css => '"Times New Roman", Times, serif' },
	{ value => 'verdana',   label => 'Verdana',          css => 'Verdana, Geneva, sans-serif' },
	{ value => 'trebuchet', label => 'Trebuchet MS',     css => '"Trebuchet MS", Helvetica, sans-serif' },
	{ value => 'courier',   label => 'Courier New',      css => '"Courier New", Courier, monospace' },
);
Readonly my %TEXT_FONT_CSS  => map { $_->{value} => $_->{css} } grep { length $_->{value} } @TEXT_FONTS;
Readonly my %TEXT_ALIGNS    => map { $_ => 1 } qw(left center right);
Readonly my $MIN_TEXT_POINTS => 8;
Readonly my $MAX_TEXT_POINTS => 96;
Readonly my $MAX_TEXT_CHARS  => 20_000;
Readonly my $TEXT_TITLE_CHARS => 60;

# What HTML::D3 calls its heatmap colour scales.
Readonly my %SEQUENTIAL_SCHEMES => map { $_ => 1 } qw(YlOrRd Blues Greens Purples RdPu YlGnBu);
Readonly my $DEFAULT_SEQUENTIAL_SCHEME  => 'YlOrRd';
Readonly my $DEFAULT_CATEGORICAL_SCHEME => 'tableau10';

Readonly my @SUPPORTED_EXT => qw( csv db sql sqlite sqlite3 xml tsv psv xlsx json );
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

# MariaDB spec: mariadb:server/table, where server names an entry in the
# mariadb_servers configuration.  A spec travels in URLs, links and saved
# canvases, so it holds no address or password.  It has no '|', which also lets
# it be the right side of a j= join.
Readonly my $MARIADB_SPEC_RE   => qr{\Amariadb:([A-Za-z_][A-Za-z0-9_]*)/([A-Za-z_][A-Za-z0-9_]*)\z};

# A server with no table: lists its tables.
Readonly my $MARIADB_SERVER_RE => qr{\Amariadb:([A-Za-z_][A-Za-z0-9_]*)\z};

# Hostname pattern accepted in /../hostname/... remote paths.
# Mirrors Database::Abstraction's own host validation regex.
# Accepts 'hostname', 'user@hostname', and IPv4 addresses (IPv6 is excluded
# because the [...] notation would be ambiguous in the path syntax).
Readonly my $REMOTE_HOST_RE => qr/\A(?:[a-zA-Z0-9][a-zA-Z0-9._-]*\@)?[a-zA-Z0-9][a-zA-Z0-9._-]*\z/;

# The tile layer HTML::OSM 0.10 hardcodes.  HTML::OSM >= 0.14 is required;
# 0.12 introduced search => 0, max_zoom, and tile_url (0.11), 0.13 the scale
# bar, the key on the map and fit, and 0.14 the nonce on its scripts.
Readonly my $DEFAULT_TILE_URL => 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

# The language the distribution ships templates for.  It is what a request falls
# back to when the language it resolved has no template directory of its own;
# see _resolve_language.  Keep it equal to Database::BI's $DEFAULT_LANGUAGE.
Readonly my $DEFAULT_LANGUAGE => 'en';

# The floor this controller passes options for.  HTML::OSM validates its
# constructor arguments strictly, so an older install does not ignore the new
# keys - it croaks on them.  _map_data therefore checks the version before
# building a map, and reports a missing or old renderer instead of a 500.
# 0.13 draws the scale bar and the key on the map, listing only what is in view
# (scale, legend, and group on each marker), and opens on every marker (fit).
# 0.14 puts the Content-Security-Policy nonce on its scripts (nonce).
Readonly my $MIN_HTML_OSM_VERSION => '0.14';

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
	error_login_required   => 'Log in first: this server asks for a password.',
	error_login_failed     => 'That is not the password.',
	error_login_locked     => 'Too many wrong passwords from this address. Try again in %d minutes.',
	error_hidden_target    => 'Refused to save into "%s": a hidden file or folder (one whose name starts with a dot) holds settings, not exports.',
	error_outside_roots    => 'Refused: "%s" is outside the folders this server may use (file_roots in database_bi.conf).',
	error_outside_export_dirs => 'Refused: exports are saved only in the export folders (export_dirs in database_bi.conf), and "%s" is not one of them.',
	error_export_not_file  => 'Refused: "%s" is already there and is not a plain file, so an export does not replace it.',
	error_remote_needs_password => 'Refused: this server has no password, so it answers only the machine it runs on. Whoever runs it can set one with "script/database-bi password".',
	error_cross_site       => 'Refused: this request came from another site (%s). Only pages of this application can change what it keeps or write files.',
	error_host_refused     => 'Refused: this server does not answer to the name "%s". Open it as localhost or by its IP address, or add the name to allowed_hosts in database_bi.conf.',
	error_write_failed     => 'Write failed: %s',
	error_ext_required     => 'Use a .csv, .sql, or .json filename extension',
	error_upload_none      => 'No file received',
	error_upload_ext       => 'Unsupported file type. Accepted: CSV, TSV, PSV, XML, JSON, SQLite (.sql, .sqlite, .sqlite3), Berkeley DB (.db), XLSX',
	error_upload_too_large => 'File too large (maximum %s MiB)',
	error_upload_save      => 'Could not save uploaded file',
	error_uploads_clear    => 'Could not clear the uploaded files',
	error_export_sqlite    => 'Could not build the SQLite export; the server log has the reason',
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
	error_lookup_name           => 'Lookup name "%s" is not a valid identifier',
	error_lookup_unknown        => 'Lookup "%s" is not stored for any dataset',
	error_lookup_remote         => 'Lookup "%s": "%s" is not a file; a lookup reads a file under data_dir (use Import for a URL)',
	error_lookup_outside        => 'Lookup "%s": "%s" is not under data_dir',
	error_lookup_not_found      => 'Lookup "%s": file "%s" not found, or not a supported data file',
	error_lookup_too_large      => 'Lookup "%s": "%s" is %d bytes, more than a lookup may be (%d)',
	error_lookup_unreadable     => 'Lookup "%s": cannot read "%s": %s',
	error_lookup_key_unknown    => 'Lookup "%s": key column "%s" is not in "%s"',
	error_lookup_field_unknown  => 'Lookup "%s": field "%s" is not in "%s"',
	error_lookup_col_unknown    => 'Lookup "%s": column "%s" is not in this dataset (nolk=%s skips the lookup)',
	error_lookup_name_taken     => 'Lookup "%s": field "%s" cannot be added, because "%s" is a column already',
	warn_lookup_duplicate_key   => 'Lookup "%s": %d duplicate key(s) in "%s"; the first row of each is used',
	error_extract_name          => 'Extraction name "%s" is not a valid identifier',
	error_extract_pattern       => 'Extraction "%s": %s',
	error_extract_no_names      => 'Extraction "%s": the pattern names no group; write one as (?<name>...) for each column',
	error_extract_field         => 'Extraction "%s": the pattern has no group named "%s"',
	error_extract_col_unknown   => 'Extraction "%s": column "%s" is not in this dataset',
	error_extract_name_taken    => 'Extraction "%s": group "%s" cannot be added, because "%s" is a column already',
	error_accel_spec            => 'Cannot accelerate "%s": it must be a table: or path: spec naming a local file that exists',
	error_accel_sqlite          => 'Cannot accelerate "%s": it is a SQLite database already',
	error_accel_open            => 'Cannot accelerate "%s": the file cannot be opened: %s',
	error_accel_store           => 'Cannot accelerate "%s": the model store cannot be written (model_dir inside data_dir, or not writable)',
	error_accel_build           => 'Cannot accelerate "%s": %s',
	error_analysis_not_found    => 'Analysis "%s" not found',
	error_analysis_invalid      => 'Invalid analysis spec: %s',
	error_analysis_version      => 'Unsupported analysis version %s; please upgrade the application',
	error_analysis_storage      => 'Analysis storage is not writable; use import/export instead',
	error_analysis_json         => 'Invalid JSON body: %s',
	error_analysis_id_invalid   => 'Invalid analysis id',
	error_text_card_empty       => 'A text card needs some text',
	error_text_card_long        => 'A text card can hold at most %d characters',
	error_text_card_font        => 'That font is not one of the choices',
	error_text_card_size        => 'The size must be a whole number of points from %d to %d',
	error_text_card_colour      => 'A colour must be written #rrggbb',
	error_text_card_align       => 'The alignment must be left, center or right',
	error_text_card_options     => 'options must be given as an object',
	error_text_card_columns     => 'A text card has no columns to change',
	error_text_card_no_data     => 'A text card has no data to download',
	error_visual_not_text       => 'Only a text card can be removed',
	error_param_range           => "Parameter '%s' is out of range (min %s, max %s)",
	error_param_type            => "Parameter '%s' must be a number",
	error_map_source            => 'A map needs loc=<column> to geocode, or both lat= and lon= coordinate columns',
	error_map_coordinates       => 'A map with lat= needs lon= as well, and a map with lon= needs lat=',
	error_map_loc_column        => 'Column "%s" is not in this view, so there is nothing to geocode',
	error_map_coordinate_range  => 'Column "%s" holds only values outside the range of %s; check that lat= and lon= are not swapped',
	error_map_coordinate_numeric => 'Columns "%s" and "%s" hold no numeric coordinate pairs; a map needs numbers, or loc=<column> to geocode places',
	error_map_no_markers        => 'No row has a location that could be plotted',
	error_map_renderer_missing  => 'Drawing a map needs HTML::OSM 0.14 or later, and it is not installed',
	error_map_renderer_failed   => 'The map could not be drawn; the server log has the reason',
	error_map_renderer_old      => 'Drawing a map needs HTML::OSM 0.14 or later, but the installed HTML::OSM is %s',
	warn_join_schema_mismatch   => 'Column "%s" has type %s in %s but %s in %s; the join keeps both columns, so check which one a calculation uses',
	warn_map_coordinate_rows    => 'Plotted %d of %d rows; %d hold no usable coordinate',
	warn_map_markers_capped     => 'Showing the first %d of %d markers; add f= filters to see the rest',
	map_legend_empty            => 'Nothing in this view',
	map_bounds_layer            => '%s boundaries',
	map_bounds_noun_county      => 'county',
	map_bounds_noun_district    => 'district',
	map_bounds_noun_province    => 'province',
	map_bounds_noun_prefecture  => 'prefecture',
	map_bounds_noun_department  => 'department',
	map_bounds_noun_area        => 'area',
	map_bounds_total            => '%s: %s %s',
	map_bounds_row              => '%s: 1 row',
	map_bounds_rows             => '%s: %s rows',
	map_bounds_key_total        => '%s in each %s',
	map_bounds_key_rows         => 'Rows in each %s',
	map_bounds_key_range        => '%s to %s',
	warn_map_cache_unwritten    => 'The resolved places could not be remembered in the model store, so the next request will look them up again',
	error_map_tiles_unknown     => 'Unknown tile source "%s"; define it under tile_sources in database_bi.conf',
	error_map_geocode_mode      => 'geocode= must be "wait" (look places up before the page is sent) or "cached" (look nothing up), not "%s"',
	error_geo_lookup_place      => 'A lookup needs place= and the sig= the map page gave it',
	error_geo_lookup_unsigned   => 'This place was not listed by a map page, or the server has restarted since; open the map again',
	error_map_loc_text          => 'loc_text= is the text added to the end of each place, at most %d characters on one line, not "%s"',
	error_map_bounds_unknown    => 'bounds= must be "county", the only kind of boundary so far, not "%s"',
	warn_map_bounds_pending     => '%d of %d places have no county outline yet',
	warn_map_bounds_pending_one => '%d of %d places has no county outline yet',
	warn_map_bounds_offline     => '%d of %d places have no county outline: outlines come from OpenStreetMap, which this server does not ask (map_geocode_online is off, or LWP::UserAgent::Throttled is not installed)',
	warn_map_bounds_offline_one => '%d of %d places has no county outline: outlines come from OpenStreetMap, which this server does not ask (map_geocode_online is off, or LWP::UserAgent::Throttled is not installed)',
	warn_map_bounds_failed      => 'OpenStreetMap did not answer, so %d of %d places have no county outline; they are tried again next time',
	warn_map_bounds_failed_one  => 'OpenStreetMap did not answer, so %d of %d places has no county outline; it is tried again next time',
	error_geo_boundary_point    => 'A lookup needs point= and the sig= the map page gave it',
	error_geo_boundary_unsigned => 'This point was not listed by a map page, or the server has restarted since; open the map again',
	error_insights_no_data      => 'No data available to analyse',
	insights_insufficient_data  => 'Insufficient data for this insight type (need more rows or periods)',
	ask_unavailable    => 'Ask a question is not available: no AI provider is configured',
	ask_no_question    => 'Please enter a question',
	ask_question_too_long => 'The question is longer than %d characters; please shorten it',
	ai_limit_reached   => 'The AI provider has been asked %d times in the last hour, the most this server allows (ai_calls_per_hour); please try again later',
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
	error_filter_op             => 'Unknown filter operator "%s" in f=%s; expected one of: %s',
	error_filter_column         => 'There is no column called "%s" to filter on (f=%s); the columns are: %s',
	error_range_column_unknown  => 'There is no column called "%s" for the time range (rcol=%s); the columns are: %s',
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
Readonly my $LOOKUP_MAX_BYTES      => 8 * 1_048_576;	# a bigger file is a join, not a lookup
Readonly my $LOOKUP_NAME_RE        => qr/\A[A-Za-z_][A-Za-z0-9_]*\z/;
Readonly my $DEFAULT_MAP_GEOCODE_MAX => 500;   # new lookups per request (map_geocode_max)
# Places looked up online (OpenStreetMap's Nominatim) per request.  Nominatim
# allows one request a second, so this is roughly the seconds a page can wait
# for it: twenty keeps a page well inside hypnotoad's 50-second heartbeat, and
# script/bi-geocode, which has no page to hold, asks without a limit.
Readonly my $DEFAULT_MAP_GEOCODE_ONLINE_MAX => 20;   # map_geocode_online_max
Readonly my $DEFAULT_MAP_MAX_MARKERS => 2_000; # markers drawn per request (map_max_markers)
Readonly my $DEFAULT_MAP_POPUP_ROWS  => 10;    # rows listed in one marker's popup (map_popup_rows)
Readonly my $DEFAULT_MARKER_COLOR  => '#3388ff'; # Leaflet default blue
# A bubble map's size key: the bubbles' own colour when they have one, and
# this grey when the colour says something else (a colour column)
Readonly my $MAP_SIZE_KEY_COLOR  => '#888888';
Readonly my %NAMED_COLORS          => map { $_ => 1 } qw(
	red orange yellow green teal cyan blue navy purple
	magenta pink brown maroon olive silver gray grey gold lime white black
);
Readonly my $MAX_PREFIX_LEN        => 20;
Readonly my $DEFAULT_PER_PAGE      => 200;
Readonly my $MAX_PER_PAGE          => 2_000;
# The page sizes offered under a table or pivot and on /preferences; 0 is every
# row on one page.  The preference is the cookie $PAGE_SIZE_COOKIE (the server
# must see it before it reads the page), and only these values are taken from it.
Readonly my @PAGE_SIZES       => (25, 50, 100, 200, 0);
Readonly my %PAGE_SIZE_OK     => map { $_ => 1 } @PAGE_SIZES;
Readonly my $PAGE_SIZE_COOKIE => 'bi_per_page';
# per_page=0 (all rows) as a page size the arithmetic can use: one page that
# holds any table this application can read.
Readonly my $ALL_ROWS         => 2_000_000_000;
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

# The operators an f= filter may name (_apply_filter_spec), as written: an
# operator in capitals is refused with the rest, not read as another one.
Readonly my @FILTER_OPS => qw(eq ne contains starts lt le gt ge empty notempty between in);
Readonly my %FILTER_OP  => map { $_ => 1 } @FILTER_OPS;

# How many column names a refusal lists before it says how many more there are.
Readonly my $FILTER_COLUMNS_LISTED => 20;

# Allowed strptime-style date format patterns for the /dates/save endpoint, and
# the two time patterns that may be given beside one of them for a column that
# holds a clock time as well as a date.
Readonly my %ALLOWED_DATE_PATTERNS => map { $_ => 1 }
	qw(%m/%d/%Y %d/%m/%Y %d-%b-%Y);
Readonly my %ALLOWED_TIME_PATTERNS => map { $_ => 1 }
	qw(%H:%M %H:%M:%S);

# Default share token lifetime: 30 days in seconds.
Readonly my $SHARE_TOKEN_TTL => 30 * 86_400;

# The AI routes spend the configured ai_api_key on every call.  A question is
# at most this long, and each server process makes at most ai_calls_per_hour
# provider calls in any hour (0: no limit).
Readonly my $ASK_MAX_QUESTION      => 500;
Readonly my $AI_CALLS_PER_HOUR     => 60;
Readonly my $AI_WINDOW_S           => 3600;

# ---------------------------------------------------------------------------
# Protected helpers
# ---------------------------------------------------------------------------

# _whole_number($value) -> $integer | undef
#
# A request parameter as an integer, or undef if it does not spell one.  int()
# on the raw text warns on 'abc' and turns it into 0, and reads a long run of
# digits or '1e400' as infinity, which no LIMIT or OFFSET can use.
sub _whole_number {
	my $value = $_[0];
	return undef unless defined($value) && $value =~ /\A-?\d{1,$MAX_WHOLE_NUMBER_DIGITS}\z/;
	return $value + 0;
}

# _categorical_scheme($name) -> $name
# _sequential_scheme($name) -> $name
#
# A colour scheme the chart can use, or the default.  These must be checked here:
# HTML::D3 writes a categorical name into its script as SCHEMES['name'], so an
# unchecked value is script on the page, and it dies on a sequential name it does
# not know, which is a 500.  An unknown name has always drawn the default colours.
sub _categorical_scheme {
	my $name = $_[0];
	return (defined($name) && !ref($name) && $SCATTER_SCHEMES{$name}) ? $name : $DEFAULT_CATEGORICAL_SCHEME;
}

sub _sequential_scheme {
	my $name = $_[0];
	return (defined($name) && !ref($name) && $SEQUENTIAL_SCHEMES{$name}) ? $name : $DEFAULT_SEQUENTIAL_SCHEME;
}

# _optional_scheme($name) -> $name | undef
#
# A categorical scheme for a chart that draws its own colours without one:
# a histogram's bars are steelblue, a combo's bars and line steelblue and red,
# and a scheme replaces them with its first colours.  Unlike
# _categorical_scheme there is no scheme by default, so a name that is not one
# of the five is undef and the chart keeps the colours it had before scheme=
# existed.  /histogram, /combo and their canvas cards all read it here.
sub _optional_scheme {
	my $name = $_[0];
	return (defined($name) && !ref($name) && $SCATTER_SCHEMES{$name}) ? $name : undef;
}

# _scatter_radii($min, $max) -> ($min, $max)
#
# A scatter's bubble radius range in pixels: each value a whole number clamped
# to 1..40, anything else (absent, empty, 0, text) the default 3 or 15, and the
# pair put in order rather than refused.  /scatter and a canvas scatter card
# both read it here, so a card saved from the page draws the same bubbles.
sub _scatter_radii {
	my ($min, $max) = map { _whole_number(ref $_ ? undef : $_) } @_[0, 1];
	$min = 3  unless $min;
	$max = 15 unless $max;
	for ($min, $max) {
		$_ = 1  if $_ < 1;
		$_ = 40 if $_ > 40;
	}
	return $min > $max ? ($max, $min) : ($min, $max);
}

# _pagination($self) -> ($page, $per_page, $offset)
#
# Reads ?page= and ?per_page= from the current request, clamps them to sane
# ranges, and returns the 1-based page number, the page size, and the
# 0-based row offset.  Without per_page= the size is the reader's preference
# (_page_size_preference), else DEFAULT_PER_PAGE.  0 is every row: one page of
# $ALL_ROWS, so it bypasses MAX_PER_PAGE, which bounds only a number typed in
# the URL.
#
# Also stashes, for layouts/page_size.html.tt: page_size (0 for every row),
# page_size_asked (the URL named one) and page_size_choices.
sub _pagination {
	my $self = $_[0];

	my $asked_in_url = defined $self->param('per_page') && length $self->param('per_page');
	my $asked = _whole_number($self->param('per_page'));
	$asked = _page_size_preference($self) unless defined $asked;

	my ($per_page, $page);
	if (defined $asked && $asked == 0) {
		($per_page, $page) = ($ALL_ROWS, 1);
	} else {
		$per_page = $asked || $DEFAULT_PER_PAGE;
		$per_page = 1         if $per_page < 1;
		$per_page = $MAX_PER_PAGE if $per_page > $MAX_PER_PAGE;
		$page = _whole_number($self->param('page')) || 1;
		$page = 1 if $page < 1;
	}
	my $offset = ($page - 1) * $per_page;

	$self->stash(
		page_size         => ($per_page == $ALL_ROWS ? 0 : $per_page),
		page_size_asked   => ($asked_in_url ? 1 : 0),
		page_size_choices => [ @PAGE_SIZES ],
	);
	return ($page, $per_page, $offset);
}

# _page_size_preference($self) -> $size | undef
#
# The page size set on /preferences, from the bi_per_page cookie: one of
# @PAGE_SIZES (0 = every row), or undef when there is none or it is anything
# else.
sub _page_size_preference {
	my $self = $_[0];
	my $value = $self->cookie($PAGE_SIZE_COOKIE);
	return undef unless defined $value && $value =~ /\A\d{1,4}\z/;
	$value += 0;
	return $PAGE_SIZE_OK{$value} ? $value : undef;
}

# _message_text($key) -> $template | undef
#
# The %MESSAGES template for $key in the reader's language (Database::BI::I18N,
# which CGI::Lingua chose from the request's Accept-Language).  A plain function:
# the package-level checks (request_refusal, _outside_roots) have no $self.
sub _message_text ($key) {
	return Database::BI::I18N::text(__PACKAGE__, \%MESSAGES, $key);
}

# _i18n($self, $key, @sprintf_args) -> $string
#
# Purpose: Look up a user-visible string from %MESSAGES and apply sprintf
#          for positional arguments.  The entry point for future i18n
#          backend integration (e.g. Locale::Maketext).
# Entry:   $key must be a key in %MESSAGES; @args are sprintf positionals.
# Exit:    Returns the formatted string, or a fallback containing $key.
sub _i18n :Protected ($self, $key, @args) {
	my $tmpl = _message_text($key) // return "Internal error: unknown message key '$key'";
	return @args ? sprintf($tmpl, @args) : $tmpl;
}

# _file_roots($self) -> @roots
#
# Purpose: The folders a reader may browse, open files in and export to.
# Entry:   Config file_roots: unset or [] for the whole filesystem, else a list
#          of folders (a relative one is under the application home).
# Exit:    () when unrestricted; otherwise the realpath of each root that
#          exists, plus data_dir and uploads_dir, which the application itself
#          uses (the home page lists data_dir; dropped files go to uploads_dir).
sub _file_roots :Protected ($self) {
	my $roots = $self->app->config('file_roots');
	return () unless ref($roots) eq 'ARRAY' && @{$roots};
	return _real_folders($self, $roots, _data_dir_for($self->app), $self->app->_uploads_dir);
}

# _export_dirs($self) -> @realpaths
#
# Config export_dirs, as realpaths: the only folders POST /export may write
# in, and the Export panel may list, when set.  Empty when unset.
sub _export_dirs :Protected ($self) {
	my $dirs = $self->app->config('export_dirs');
	return () unless ref($dirs) eq 'ARRAY' && @{$dirs};
	return _real_folders($self, $dirs);
}

# _real_folders($self, \@configured, @always) -> @realpaths
#
# The configured folders (relative ones under the application home) and
# @always, resolved, without repeats.  A list none of which resolves gives a
# folder that cannot exist, so that it fences everything out rather than
# nothing.  Resolved as a requested path is (_resolved_path), so a folder
# configured through a link is compared as the folder it leads to: on
# Windows realpath keeps the link, while _resolved_path follows it, and every
# path inside such a folder was refused.
sub _real_folders {
	my ($self, $list, @always) = @_;
	my $home = $self->app->home;
	my @dirs = map { File::Spec->file_name_is_absolute($_) ? Mojo::File->new($_) : $home->child($_) }
		grep { defined && !ref && length } @{$list};
	my (%seen, @real);
	for my $dir (@dirs, @always) {
		next unless -e "$dir";
		my $real = _resolved_path("$dir") // next;
		push @real, $real unless $seen{$real}++;
	}
	return @real ? @real : ('/nonexistent-file-root');
}

# _inside_any($path, @folders) -> 1 | 0
#
# Whether a path, resolved as _resolved_path does, is one of the folders or
# inside one.
sub _inside_any {
	my ($path, @folders) = @_;
	my $abs = defined $path && length $path ? _resolved_path($path) : undef;
	return 0 unless defined $abs;
	$abs = _path_key($abs);
	for my $root (map { _path_key($_) } @folders) {
		return 1 if $root eq '/' || $abs eq $root
			|| index($abs, $root =~ m{/\z} ? $root : "$root/") == 0;
	}
	return 0;
}

# _path_key($path) -> $string
#
# A path in the form two spellings of one place share, for comparing.  On
# Windows, Cwd::realpath gives C:/dir while File::Spec gives C:\dir, and names
# are not case-sensitive, so separators become / and letters lower case.
sub _path_key {
	my ($path) = @_;
	return $path unless $^O eq 'MSWin32';
	(my $key = $path) =~ tr{\\}{/};
	return lc $key;
}

# _outside_export_dirs($self, $path) -> $message | undef
#
# Purpose: Refuse an export folder outside config export_dirs.
# Exit:    undef when export_dirs is unset or the folder is inside one.
sub _outside_export_dirs :Protected ($self, $path) {
	my @dirs = _export_dirs($self) or return undef;
	return undef if _inside_any($path, @dirs);
	return sprintf(_message_text('error_outside_export_dirs'), $path // '');
}

# _resolved_path($path) -> $absolute | undef
#
# Purpose: Where a path really leads, whether or not it exists, so that a
#          path outside the roots is refused the same way whether it names
#          something or not (else the refusal would say what exists there).
# Entry:   A path as given.
# Exit:    The realpath of its longest existing part, with the rest appended;
#          undef when the rest climbs with '..', which cannot be followed
#          without the folders it would climb out of, or when, on Windows,
#          the links it goes through loop.
sub _resolved_path {
	my ($path) = @_;
	my $abs = File::Spec->rel2abs($path);
	# Cwd::realpath on Windows leaves a symlink as it is (Strawberry Perl
	# 5.42 gives the link's own path back), so a link inside file_roots or
	# export_dirs that points outside would be taken as inside.  The links are
	# followed first, as _canonical_path does; a chain that loops is refused.
	if ($^O eq 'MSWin32') {
		$abs = _follow_links($abs) // return undef;
	}
	my @parts = File::Spec->splitdir($abs);
	my @rest;
	while (@parts) {
		my $try = File::Spec->catdir(@parts);
		$try = File::Spec->rootdir unless length $try;
		if (-e $try) {
			my $real = eval { Mojo::File->new($try)->realpath->to_string } // return undef;
			return undef if grep { $_ eq '..' } @rest;
			return @rest ? File::Spec->catdir($real, @rest) : $real;
		}
		unshift @rest, pop @parts;
	}
	return undef;
}

# _outside_roots($self, $path) -> $message | undef
#
# Purpose: Refuse a local path outside config file_roots.
# Entry:   A path a request named (a file or a folder).
# Exit:    undef when there are no roots or the path is inside one; otherwise
#          error_outside_roots naming the path as it was given.
sub _outside_roots :Protected ($self, $path) {
	my @roots = _file_roots($self) or return undef;
	return undef if _inside_any($path, @roots);
	return sprintf(_message_text('error_outside_roots'), $path // '');
}

# _first_root($self) -> $folder
#
# Where /browse and /api/dirs start with no path=: the home folder, unless
# that is outside the roots, when the first root is.
sub _first_root :Protected ($self) {
	my $home = $ENV{HOME} // File::Spec->rootdir;
	return $home unless _outside_roots($self, $home);
	return (_file_roots($self))[0];
}

# request_refusal($c) -> $message | undef
#
# Purpose: Refuse a request that a hostile web page made through the reader's
#          browser.  The application has no login, so whatever can reach it
#          can write files (POST /export) and read any file (/open); listening
#          on 127.0.0.1 keeps other machines out but not other sites' pages.
# Entry:   A controller of the application, before dispatch.
# Exit:    The refusal message, or undef to let the request through.
#
# Three checks:
#   * No password, so only this machine: a request from an address that is
#     not loopback (as a trusted proxy reports it) is refused.
#   * DNS rebinding.  A page on evil.example whose name is made to resolve to
#     127.0.0.1 is the same origin as this server to the browser, so it can
#     read the replies too.  It still names its own host, so the Host must be
#     localhost, *.localhost, an IP address, or a name in config allowed_hosts
#     (['*'] lets every name in).  Behind a trusted reverse proxy, whose Host is
#     whatever the proxy sends, only allowed_hosts is checked, when it is set.
#   * Cross-site writes.  A form POST from another site needs no preflight.
#     For any method but GET, HEAD and OPTIONS, Sec-Fetch-Site (set by the
#     browser, not the page) must be same-origin or none; without it, an
#     Origin must name this host and port.  A request with neither is a
#     script or an old browser, and is let through: it is not a page of
#     another site acting with the reader's browser.
sub request_refusal {
	my ($c) = @_;
	my $req = $c->req;

	# With no password, only this machine.  Startup already refuses to listen
	# anywhere else, but a reverse proxy on this machine can still bring other
	# machines' requests in; trusted, it names them in X-Forwarded-For, which
	# is what remote_address then reads.  A Unix socket has no address, and is
	# this machine.
	my $hash = $c->app->config('password_hash');
	unless (defined $hash && length $hash) {
		my $from = $c->tx->remote_address // '';
		return _message_text('error_remote_needs_password')
			unless $from eq '' || $from =~ /\A(?:::ffff:)?127\./i || $from eq '::1';
	}

	my $host = lc($req->url->to_abs->host // '');
	if (length $host) {
		my $allowed = $c->app->config('allowed_hosts');
		my @allowed = ref($allowed) eq 'ARRAY' ? map { lc } grep { defined && !ref } @{$allowed} : ();
		my $listed  = grep { $_ eq '*' || $_ eq $host || (/\A\*(\..+)\z/ && substr($host, -length $1) eq $1) } @allowed;
		my $local   = $host eq 'localhost' || $host =~ /\.localhost\z/
			|| $host =~ /\A\d{1,3}(?:\.\d{1,3}){3}\z/ || $host =~ /[:\[]/;
		my $ok = $req->reverse_proxy ? (!@allowed || $listed) : ($local || $listed);
		return sprintf(_message_text('error_host_refused'), $host) unless $ok;
	}

	return if $req->method =~ /\A(?:GET|HEAD|OPTIONS)\z/;

	my $headers = $req->headers;
	my $site    = lc($headers->header('Sec-Fetch-Site') // '');
	if (length $site) {
		return if $site eq 'same-origin' || $site eq 'none';
		return sprintf(_message_text('error_cross_site'), $site);
	}
	my $origin = $headers->origin;
	return unless defined $origin;
	my $from = lc(Mojo::URL->new($origin)->host_port // '');
	my $to   = lc($req->url->to_abs->host_port // '');
	my $fwd  = $req->reverse_proxy ? lc($headers->header('X-Forwarded-Host') // '') : '';
	return if length($from) && ($from eq $to || (length($fwd) && $from eq $fwd));
	return sprintf(_message_text('error_cross_site'), $origin);
}

# _is_safe_url($url) -> bool
#
# Purpose: The quick SSRF check on a URL a request names (/import, url:
#          specs), before anything is fetched, so the reader is told at once.
# Entry:   The URL.
# Exit:    0 for anything but http(s), no host, localhost or *.localhost, or a
#          host written as an address that is not public; else 1.
#
# It reads the URL as LWP will (URI: so http://user@127.0.0.1/ is host
# 127.0.0.1), and an address in every spelling the resolver accepts
# (2130706433, 0x7f000001, 0177.0.0.1, 127.1, [::ffff:127.0.0.1]).  It does not
# look names up: a name such as localtest.me, or one whose DNS answers
# 127.0.0.1, is refused when it is fetched, by Database::BI::SafeUA, which
# resolves each request (and each redirect), checks every address, and
# connects to the one it checked, so a second DNS answer cannot differ.
sub _is_safe_url {
	my ($url) = @_;
	return 0 unless defined $url && $url =~ m{\Ahttps?://}i;
	require URI;
	require Database::BI::SafeUA;
	my $uri  = URI->new($url);
	my $host = eval { lc($uri->host // '') } // '';
	$host =~ s/\.\z//;
	return 0 unless length $host;
	# A host that is neither a name nor an IPv6 address is not a URL LWP
	# would read the same way (http://::1/ has the host ':').
	return 0 unless $host =~ /\A[a-z0-9_](?:[a-z0-9_.-]*[a-z0-9_])?\z/
		|| ($host =~ /:/ && defined Database::BI::SafeUA::numeric_host($host));
	return 0 if $host eq 'localhost' || $host =~ /\.localhost\z/;
	my $ip = Database::BI::SafeUA::numeric_host($host);
	return 0 if defined $ip && Database::BI::SafeUA::blocked_address($ip);
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
	empty => 'is empty', notempty => 'is not empty', in => 'is one of',
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

# _preferences_url($c) -> $href
#
# Where the nav's Preferences link goes: /preferences?back=<this page>, so
# the preferences page's trail ends with a way back here.  This page is the
# last crumb of its trail; a page with no trail (Home, an error page) gets the
# plain link, and so does the preferences page, which keeps its own back=.
# A plain function, called from the before_render hook in Database::BI.
sub _preferences_url {
	my ($c) = @_;
	my $plain = '/preferences';
	return $plain unless ref $c && $c->isa(__PACKAGE__);
	my $trail = $c->stash('trail');
	return $plain unless ref $trail eq 'ARRAY' && @$trail;
	my $here = $trail->[-1]{url} // '';
	return $plain if !length($here) || Mojo::URL->new($here)->path->to_string eq $plain;
	return "$plain?back=" . url_escape(encode('UTF-8', $here));
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
		my ($file) = _split_path($1);
		return Mojo::URL->new('/browse?path=' . url_escape(Mojo::File->new($file)->dirname->to_string));
	}
	# Preferences came from the page whose nav link opened it (_preferences_url).
	if ($path eq '/preferences') {
		return $self->_crumb_local($q->param('back'));
	}
	# A canvas came from where its back= says, else from the list of canvases.
	if ($path =~ m{\A/a/}) {
		return $self->_crumb_local($q->param('back')) // Mojo::URL->new('/canvases');
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
		my $file = $q->param('path') // '';
		return undef unless length $file;
		my $name = Mojo::File->new($file)->basename;
		my $it   = $q->param('it');
		$name .= ": $it" if defined $it && length $it;
		return length $name ? "$name$view" : undef;
	}
	# Either route takes both joins and combined files.
	if ($path eq '/join' || $path eq '/combine') {
		my @names = map { _crumb_spec_name($_) } grep { /\A(?:table|path|url|redis|mariadb):/i }
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
	return 'Canvases' if $path eq '/canvases';
	return 'Tutorial' if $path eq '/tutorial';
	return 'Preferences' if $path eq '/preferences';
	return 'Log in'      if $path eq '/login';
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
	if ($spec =~ m{\Apath:(.+)\z}) {
		my ($file, $internal) = _split_path($1);
		my $name = Mojo::File->new($file)->basename;
		return defined $internal ? "$name: $internal" : $name;
	}
	return _crumb_spec_name_other($spec);
}

# _split_path($path) -> ($file, $internal)
#
# Purpose: What follows "path:" in a spec: the file, and the table it names
#          after a "#" (Database::BI::Model::DataSource::split_path).
sub _split_path {
	my ($path) = @_;
	require Database::BI::Model::DataSource;
	return Database::BI::Model::DataSource::split_path($path);
}

sub _crumb_spec_name_other {
	my ($spec) = @_;
	$spec //= '';
	return "$1: $2" if $spec =~ m{\Atable:([^/]+)/(.+)\z};
	return $1       if $spec =~ m{\Atable:(.+)\z};
	if ($spec =~ m{\Aurl:(.+)\z}i) {
		my $host = Mojo::URL->new($1)->host;
		return $host // $1;
	}
	return 'Redis' if $spec =~ /\Aredis:/i;
	return "$1: $2" if $spec =~ $MARIADB_SPEC_RE;
	return $1       if $spec =~ $MARIADB_SERVER_RE;
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
		# A list is JSON, which the crumb text pattern refuses: say how long it is.
		if ($op eq 'in') {
			my $n = () = _filter_in_values($val);
			push @bits, "$col $CRUMB_OP{in} $n value" . ($n == 1 ? '' : 's');
			next;
		}
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
		# loc= may repeat, for a place spread over columns (address, country).
		my $v = ($_ eq 'loc') ? join(', ', grep { length } @{ $q->every_param('loc') }) : ($q->param($_) // '');
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
# Exit:    Returns a two-letter ISO 639-1 language code string, or a code
#          and region (en-us) when the browser names that region and
#          templates/<platform>/<code>-<region>/ exists.
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

		# A regional variant (templates/web/en-us/ for a browser asking for
		# en-US) is chosen when it has a directory, otherwise the language
		# itself: en-GB, en-CA and plain en get en.  Database::BI::I18N makes
		# the same CGI::Lingua call for the messages, so the two agree.
		my $chosen = Database::BI::I18N::lingua_choice($accept, \@supported);
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

	# A directory that exists but may not be read holds nothing this application
	# can show, and must not take the home page with it.
	my $files = eval { $dir->list };
	unless ($files) {
		$self->app->log->error("Cannot read data_dir $dir: " . _tidy_error($@));
		return [];
	}
	return $files->map(sub {
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

# _tidy_error($error) -> $string
#
# Purpose: A backend error as a reader should see it: without the "at FILE line N"
#          that croak adds each time the error is passed up, or the list of
#          library directories perl adds when a module is missing.
sub _tidy_error {
	my $error = $_[0] // '';
	$error =~ s/\s*\(\@INC (?:contains|entries checked):.*?\)(?=\s+at\s|\s*\z)//sg;
	$error =~ s/(?:\s+at \S.*? line \d+\.?)+\s*\z//;
	return $error;
}

# _analysis_json_error($error) -> $string
#
# Purpose: The message for a canvas request whose body is not a JSON object.
#          Entry: the error from decode_json, which is empty when the body parsed
#          but was an array or a scalar, and otherwise ends in a library's path.
sub _analysis_json_error {
	my $reason = _tidy_error($_[0]);
	return sprintf(_message_text('error_analysis_json'), length($reason) ? $reason : 'expected a JSON object');
}

# ---------------------------------------------------------------------------
# Accelerated views (Phase 7 item 7.5)
#
# A dataset marked in models.json accelerated.<spec> is read from a SQLite copy
# of itself, built by script/bi-extract through Database::BI::Extract, as long
# as the copy's fingerprint (the spec, and the file's mtime and size) still
# matches the file.  When it does not, the file itself is read and the table
# page says the extract is stale: stale numbers are never served.  An extract is
# a cache.  Deleting <model_dir>/extracts/ only makes every accelerated dataset
# read its file again, and nothing is ever written under data_dir.
# ---------------------------------------------------------------------------

# _model_dir_of($app) -> Mojo::File
#
# Purpose: model_dir as a path: absolute as configured, or under the app home.
#          Nothing is created and nothing is checked; the writers check.
sub _model_dir_of {
	my ($app) = @_;
	my $cfg = Mojo::File->new($app->config('model_dir') // '.bi');
	return $cfg->is_abs ? $cfg : $app->home->child($cfg->to_string);
}

# _table_stem($data_dir, $name, @exts) -> $stem | undef
#
# Purpose: The file stem table:<name> means in data_dir: the name as written
#          when a file has it, else in lower case, which is what every reader
#          once looked for (so table:Orders still opens orders.csv); undef
#          when neither has a file with one of @exts (default @SUPPORTED_EXT).
#          Reading only the lower case made a file named with a capital,
#          BandMusic.csv, open on its own page (/view/BandMusic) and nowhere
#          else: a pivot, chart or merge of table:BandMusic was a 404.
sub _table_stem ($data_dir, $name, @exts) {
	@exts = @SUPPORTED_EXT unless @exts;
	for my $stem ($name, lc $name) {
		return $stem if grep { -f $data_dir->child("$stem.$_") } @exts;
	}
	return undef;	## no critic (ProhibitExplicitReturnUndef)
}

# _accel_file($self, $spec) -> $path | undef
#
# Purpose: The local file a spec can be accelerated from: table:<name> in
#          data_dir, or path:<file>.  An internal table, a remote path and
#          every other kind of spec have none.
sub _accel_file :Protected ($self, $spec) {
	$spec //= '';
	if ($spec =~ m{\Atable:([A-Za-z0-9_]+)\z}) {
		my $data_dir = _data_dir_for($self->app);
		my $stem     = _table_stem($data_dir, $1) // return undef;
		my ($file) = grep { -f } map { $data_dir->child("$stem.$_")->to_string } @SUPPORTED_EXT;
		return $file;
	}
	if ($spec =~ m{\Apath:(?!/\.\./)(.+)\z}) {
		my ($path) = _split_path($1);
		return undef if _outside_roots($self, $path);
		my $file = eval { Mojo::File->new($path)->realpath };
		return (defined $file && -f $file && $file->basename =~ $EXT_RE) ? $file->to_string : undef;
	}
	return undef;
}

# _accelerated_source($self, $spec) -> $DataSource | undef
#
# Purpose: The extract of an accelerated dataset, when it still matches the file.
# Exit:    The extract opened as a source, or undef: the spec is not accelerated,
#          or its extract is missing or stale, and the caller reads the file.
#          The first call in a request stashes acceleration => { state =>
#          'fresh' | 'stale', built => epoch, spec => $spec } for the table page.
sub _accelerated_source :Protected ($self, $spec) {
	return undef if $self->stash('_no_acceleration');
	return undef unless defined $spec && length $spec;
	# Only this application's controller has a model store; a bare controller
	# (a test's, calling _open_spec as a function) has nothing accelerated.
	return undef unless $self->isa(__PACKAGE__);
	$spec = canonical_spec($spec);
	my $entry = $self->_read_models->{accelerated}{$spec};
	return undef unless ref $entry eq 'HASH';
	my $file = $self->_accel_file($spec) // return undef;

	my @st = stat $file;
	my $cache = _extract_store($self->app);
	my $path  = $cache->get($spec, $st[9], $st[7]);
	my $src;
	if (defined $path) {
		my $x = Mojo::File->new($path);
		$src = eval { $self->open_table($x->basename =~ s/\.db\z//r, directory => $x->dirname->to_string,
			(ref $entry->{columns} eq 'ARRAY' ? (column_order => $entry->{columns}) : ())) };
	}
	require POSIX;
	my $built = $src ? (stat $path)[9] : $entry->{built};
	$self->stash(acceleration => {
		spec       => $spec,
		state      => ($src ? 'fresh' : 'stale'),
		built      => $built,
		built_text => (defined $built && $built =~ /\A\d+\z/ ? Database::BI::Util::minute_stamp(localtime $built) : ''),
	}) unless $self->stash('acceleration');
	return $src;
}

# _extract_store($app) -> Database::BI::Extract
#
# Purpose: The extract store, in the cache directory Database::BI::CacheDir
#          chooses (Object::Configure, CACHEDIR, CACHE_DIR, cache_dir in the
#          config), else in <model_dir>/extracts as before.  A cache directory
#          inside data_dir is not used for them: each extract is a .db file,
#          which the home page would list as a table of the user's own, and
#          nothing is written under data_dir.  They then go in model_dir, whose
#          own check (_calc_models_path) stops a store inside data_dir.
sub _extract_store {
	my ($app) = @_;
	require Database::BI::Extract;
	my $model_dir = _model_dir_of($app);
	my $store = Database::BI::Extract->new(
		model_dir => $model_dir->to_string,
		config    => $app->config,
		home      => $app->home->to_string,
	);
	if (_inside_dir(_canonical_path(Mojo::File->new($store->dir)), _canonical_path(_data_dir_for($app)))) {
		carp 'The cache directory is inside data_dir; extracts are kept in model_dir instead';
		$store = Database::BI::Extract->new(dir => $model_dir->child('extracts')->to_string);
	}
	return $store;
}

# _is_sqlite_file($path) -> $bool
#
# Purpose: True for a SQLite database, whatever its extension (a .db may be one).
sub _is_sqlite_file {
	my ($path) = @_;
	open my $fh, '<:raw', $path or return 0;
	my $n = read $fh, my $head, 16;
	close $fh;
	return ($n && $head eq "SQLite format 3\0") ? 1 : 0;
}

# accelerate($c, $spec) -> \%built
#
# Purpose: Mark a dataset accelerated and build its extract: the rows its file
#          gives, in a SQLite file in the extract store (_extract_store).  Called by
#          script/bi-extract; not a route.
# Entry:   $c is a controller of the application (Mojolicious build_controller);
#          $spec is a table: or path: spec naming a local, non-SQLite file.
# Exit:    { spec, path, rows, columns, built } -- the extract written and when.
#          The model store records accelerated.<spec> = { built, file, rows }.
#          Croaks error_accel_spec, error_accel_sqlite, error_accel_open,
#          error_accel_store or error_accel_build.
# Side Effects: Writes the extract, removes the one it replaces, and writes
#          models.json.
sub accelerate {
	my ($c, $spec) = @_;
	croak 'accelerate() needs a controller and a spec' unless ref $c && defined $spec;
	# Filed under the resolved spec, which is what the file's page asks for;
	# messages name the spec as the caller wrote it.
	my $key = canonical_spec($spec);
	my $file = $c->_accel_file($spec)
		// croak $c->_i18n('error_accel_spec', $spec);
	croak $c->_i18n('error_accel_sqlite', $spec) if $file =~ /\.(?:sql|sqlite3?)\z/i || _is_sqlite_file($file);
	defined $c->_calc_models_path or croak $c->_i18n('error_accel_store', $spec);

	# Read the file itself, not the extract being replaced.
	local $c->stash->{_no_acceleration} = 1;
	my @st = stat $file;
	my ($src) = $c->_open_spec($spec);
	croak $c->_i18n('error_accel_open', $spec, _tidy_error($c->stash('open_spec_error') // 'unreadable')) unless $src;
	my ($records, @columns);
	my $ok = eval {
		$records = $src->fetch_all;
		@columns = _get_columns($src, $records);
		1;
	};
	croak $c->_i18n('error_accel_open', $spec, _tidy_error($@)) unless $ok;
	my $bytes = eval { $c->_write_sqlite_db($records, \@columns, 'extract') };
	croak $c->_i18n('error_accel_build', $spec, _tidy_error($@)) unless defined $bytes;

	my $cache = _extract_store($c->app);
	my $path  = eval { $cache->put($key, $st[9], $st[7], $bytes) };
	croak $c->_i18n('error_accel_build', $spec, _tidy_error($@)) unless defined $path;

	my $models = $c->_read_models;
	my $old    = $models->{accelerated}{$key};
	my $name   = Mojo::File->new($path)->basename;
	if (ref $old eq 'HASH' && defined $old->{file} && $old->{file} ne $name && $old->{file} =~ /\A[0-9a-f]{32}\.db\z/) {
		unlink Mojo::File->new($path)->dirname->child($old->{file})->to_string;
	}
	my $built = time;
	# The file's own column order: the extract would list its columns alphabetically.
	$models->{accelerated}{$key} = { built => $built, file => $name, rows => scalar(@$records), columns => \@columns };
	$c->_write_models($models) or croak $c->_i18n('error_accel_store', $spec);
	return { spec => $key, path => $path, rows => scalar(@$records), columns => scalar(@columns), built => $built };
}

# unaccelerate($c, $spec) -> $bool
#
# Purpose: Stop reading a dataset from an extract, and remove its extract.
# Exit:    True when the spec was accelerated.
sub unaccelerate {
	my ($c, $spec) = @_;
	croak 'unaccelerate() needs a controller and a spec' unless ref $c && defined $spec;
	$spec = canonical_spec($spec);	# unaccelerate names no spec in a message
	my $models = $c->_read_models;
	my $entry  = delete $models->{accelerated}{$spec};
	return 0 unless ref $entry eq 'HASH';
	if (defined $entry->{file} && $entry->{file} =~ /\A[0-9a-f]{32}\.db\z/) {
		unlink Mojo::File->new(_extract_store($c->app)->dir)->child($entry->{file})->to_string;
	}
	$c->_write_models($models);
	return 1;
}

# accelerated_specs($c) -> @specs
#
# Purpose: Every spec marked accelerated, sorted, for script/bi-extract --all.
sub accelerated_specs {
	my ($c) = @_;
	croak 'accelerated_specs() needs a controller' unless ref $c;
	return sort keys %{ $c->_read_models->{accelerated} };
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
	# An accelerated dataset whose extract still matches its file is read from
	# the extract, under the file's own label.
	if (my $fast = _accelerated_source($self, $spec)) {
		my $label = $spec =~ m{\Atable:(.+)\z} ? (_table_stem(_data_dir_for($self->app), $1) // $1)
			: do { my ($f, $i) = _split_path($spec =~ s/\Apath://r); $i // Mojo::File->new($f)->basename };
		return ($fast, $label);
	}
	if ($spec =~ m{\Atable:([A-Za-z0-9_]+)(?:/([A-Za-z0-9_]+))?\z}) {
		my ($name, $internal) = ($1, $2);
		my $data_dir = _data_dir_for($self->app);
		my $table    = _table_stem($data_dir, $name) // return ();
		my $src = eval {
			$self->open_table($table, directory => $data_dir->to_string,
				defined $internal ? (internal_table => $internal) : ())
		};
		return ($src, defined $internal ? $internal : $table) if $src && !$@;
	} elsif ($spec =~ /\Apath:(.+)\z/) {
		# path:<file>#<table> names one table of the file, as table:<file>/<table>
		# does in data_dir.
		my ($path_arg, $internal) = _split_path($1);
		my @it = defined $internal ? (internal_table => $internal) : ();
		# Remote path: /../hostname/dir/file -- delegate to DataSource with host param.
		# No EXT_RE check: security comes from REMOTE_HOST_RE.  The original
		# extension (if any) is passed as file_ext so _init_backend tries it first.
		if ($path_arg =~ m{\A/\.\./([^/]+)((?:/.+)?)/([^/]+)\z}) {
			my ($host, $dir_part, $file) = ($1, $2 // '', $3);
			$dir_part = '/' unless length $dir_part;
			return () unless $host =~ $REMOTE_HOST_RE;
			my ($table, $ext) = $file =~ /\A(.+)\.([^.]+)\z/ ? ($1, $2) : ($file, undef);
			my $src = eval { $self->open_table($table, directory => $dir_part, host => $host,
				defined $ext ? (file_ext => $ext) : (), @it) };
			return ($src, $internal // $file) if $src && !$@;
			return ();
		}
		return () if _outside_roots($self, $path_arg);
		my $file = eval { Mojo::File->new($path_arg)->realpath };
		if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
			my $dir = $file->dirname->to_string;
			(my $table = $file->basename) =~ s/\.[^.]+\z//;
			my $src = eval { $self->open_table($table, directory => $dir, @it) };
			return ($src, $internal // $file->basename) if $src && !$@;
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
	} elsif($spec =~ $MARIADB_SPEC_RE) {
		my ($server, $table) = ($1, $2);
		my $src = eval { $self->open_table($table, mariadb => $server) };
		return ($src, $table) if $src;
		# A server has more ways to fail than a file has; /open says which.
		$self->stash(open_spec_error => _tidy_error($@));
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
	if ($spec =~ /\Apath:(.+)\z/) {
		my ($file, $internal) = _split_path($1);
		return '/open?path=' . url_escape($file) . (defined $internal ? '&it=' . url_escape($internal) : '');
	}
	return '/import?url=' . url_escape($1) if $spec =~ $URL_SPEC_RE;
	return '/' if $spec =~ $REDIS_SPEC_RE;
	return '/open?path=' . url_escape($spec) if $spec =~ $MARIADB_SPEC_RE;
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
#     List (val = a JSON array of strings; compared as eq is):
#       in -- lc(cell) is one of them; a val that is not such an array matches nothing
#     Range (val = lo:hi, both ends included, whichever is written first;
#       see _between_bounds for where a timestamp's colons leave it):
#       between -- two numbers compare as numbers, two dates or timestamps
#       as times (at the precision of the bounds), anything else as text,
#       case-insensitively
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
#          which is what CSV exports and SQLite text columns usually hold, and
#          one with a fraction of a second or a zone (Z, +01:00), which is what
#          JSON APIs write.  The time is taken as written (Util::iso_datetime).
sub _is_iso_date {
	return scalar(() = Database::BI::Util::iso_datetime($_[0])) ? 1 : 0;
}

# Convert M/D/YYYY or YYYY-MM-DD to YYYY-MM-DD; returns undef for other formats.
# A value that is already ISO is returned unchanged, including its time part: a
# timestamp cell is the caller's to compare, not this sub's to truncate.
sub _to_iso_date {
	my ($v) = @_;
	return unless defined $v;
	return $v if _is_iso_date($v);
	if (my ($m, $d, $y) = $v =~ m{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}) {
		return sprintf '%04d-%02d-%02d', $y, $m, $d;
	}
	return;
}

# _time_columns(\@columns, \@records) -> \@names
#
# Purpose: The columns a time range can be applied to: those whose every
#          non-empty cell on the page is a date or a date and time that the
#          range filter reads (_to_iso_date: YYYY-MM-DD, with an optional
#          "THH:MM[:SS]" or " HH:MM[:SS]", or M/D/YYYY), with a month and day
#          that can exist, and at least one such cell.  The dashboard offers
#          Time range only when this is not empty, and lists only these.
# Entry:   $columns is the page's column order; $records its rows (hashes).
# Exit:    Returns the qualifying names, in column order; [] when there are
#          none, no rows, or either argument is not an array.
# Notes:   It reads the rows drawn on the page, as the table's own date
#          detection does: reading every row of the view for this would cost a
#          second pass over the data on every page.
sub _time_columns {
	my ($columns, $records) = @_;
	return [] unless ref($columns) eq 'ARRAY' && ref($records) eq 'ARRAY';
	my @found;
	COLUMN: for my $col (@{$columns}) {
		next unless defined $col;
		my $seen = 0;
		for my $row (@{$records}) {
			next unless ref($row) eq 'HASH';
			my $v = $row->{$col};
			next unless defined $v;
			$v =~ s/\A\s+|\s+\z//g;
			next unless length $v;
			my $iso = _to_iso_date($v);
			next COLUMN unless defined $iso;
			my ($m, $d) = $iso =~ /\A\d{4}-(\d{2})-(\d{2})/;
			next COLUMN unless $m >= 1 && $m <= 12 && $d >= 1 && $d <= 31;
			$seen = 1;
		}
		push @found, $col if $seen;
	}
	return \@found;
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
	my ($day, $hour, $min, $sec) = Database::BI::Util::iso_datetime($value);
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
#          spec.  A between value is "lo:hi", and its colon has to be found
#          among a timestamp's own (_between_bounds; last_24_hours ends in
#          HH:MM:SS); one bound per spec needs no such search.  Two specs are
#          inclusive at both ends exactly once, whatever precision the bounds
#          carry.
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
			text   => sprintf(_message_text('error_range_name'), $name,
				join(', ', map { $_->{name} } @TIME_RANGES)),
			status => 400,
		);
		return 0;
	}
	unless (defined $col && length $col && $col !~ /:/) {
		$c->render(text => _message_text('error_range_column'), status => 400);
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

# _filter_request($c) -> bool
#
# Purpose: Refuse an f= filter whose operator is not one _apply_filter_spec
#          knows.  Until 0.021.0 such a filter kept every row, with nothing to
#          say it had done nothing (f=amount:GT:5, f=amount:gtx:5).  Registered
#          as a before_dispatch hook in Database::BI::startup beside the time
#          range's, so every route that reads f= refuses it the same way.
# Entry:   $c -- the controller for the request.
# Exit:    True when every filter names a known operator, or has no column or
#          operator at all (such a spec has always been skipped); otherwise
#          renders 400 (error_filter_op, which lists the operators) and
#          returns false.
# Notes:   A filter on a column the view does not have is refused later, once
#          the columns are known (_unknown_filter_column).  A canvas card's own
#          stored filters never come through here: they are ignored when stale,
#          by design.
sub _filter_request ($c) {
	for my $spec (@{ $c->every_param('f') // [] }) {
		my ($col, $op) = split /:/, $spec, 3;
		next unless length($col // '') && defined $op && length $op;
		next if $FILTER_OP{$op};
		$c->render(
			text   => sprintf(_message_text('error_filter_op'), $op, $spec, join(', ', @FILTER_OPS)),
			status => 400,
		);
		return 0;
	}
	return 1;
}

# _unknown_filter_column($self, \@columns, \%later) -> $message | undef
#
# Purpose: The refusal for a filter, or the time range, on a column the view
#          does not have.  Such a filter used to read every cell as empty and
#          keep no rows (or every row, for ne and empty), so a mistyped name
#          looked like an empty file.
# Entry:   \@columns -- the view's columns at the filter stage; \%later -- the
#          columns stages 6 and 7 will add (a filter on one waits for them).
# Exit:    undef when every filter names a column there, or when the columns
#          are not known (no list, or an empty one: a URL source's cache, or
#          a view with no rows); else the error_filter_column message (or
#          error_range_column_unknown for rcol=), naming the columns there.
# Notes:   A plain function, like _reduce_records, which calls it; _fetch_page
#          calls it too, for the table pages.
sub _unknown_filter_column {
	my ($self, $columns, $later) = @_;
	return undef unless ref $columns eq 'ARRAY' && @{$columns};
	my %known = ((map { $_ => 1 } @{$columns}), %{ $later // {} });
	my $listed = sub {
		my @names = @{$columns};
		return join(', ', @names) if @names <= $FILTER_COLUMNS_LISTED;
		return join(', ', @names[0 .. $FILTER_COLUMNS_LISTED - 1])
			. sprintf(' and %d more', @names - $FILTER_COLUMNS_LISTED);
	};
	for my $spec (@{ $self->every_param('f') // [] }) {
		my ($col, $op) = split /:/, $spec, 3;
		next unless length($col // '') && defined $op && length $op;
		next if $known{$col};
		return sprintf(_message_text('error_filter_column'), $col, $spec, $listed->());
	}
	my $range = $self->stash('time_range');
	if (ref $range eq 'HASH' && !$known{ $range->{col} // '' }) {
		return sprintf(_message_text('error_range_column_unknown'), $range->{col}, $range->{col}, $listed->());
	}
	return undef;
}

# _filter_in_values($val) -> @strings
#
# The values an f=col:in:<val> filter lists: $val is a JSON array, and only its
# plain scalars count (a null is the empty cell).  Anything else lists nothing,
# so a damaged link matches no row rather than every row.
sub _filter_in_values {
	my ($val) = @_;
	local $@;
	my $list;
	return () unless eval { $list = from_json($val // q{}); 1 };
	return () unless ref($list) eq 'ARRAY';
	return map { $_ // '' } grep { !ref } @{$list};
}

# _between_bounds($val) -> ($lo, $hi) | ()
#
# Purpose: Split a between value, "lo:hi", into its two bounds.  The
#          separator is a colon, and a timestamp holds colons of its own, so
#          the split is made where both sides read as dates or timestamps if
#          there is such a place, and at the first colon otherwise.
# Input:   $val - the filter value.
# Output:  The two bounds, both non-empty, in the order written; the empty
#          list when there is no colon or either side is empty.
sub _between_bounds {
	my ($val) = @_;
	return () unless defined $val;
	my @at;
	my $pos = -1;
	push @at, $pos while ($pos = index($val, ':', $pos + 1)) != -1;
	return () unless @at;
	for my $i (@at) {
		my ($lo, $hi) = (substr($val, 0, $i), substr($val, $i + 1));
		return ($lo, $hi) if _is_iso_date($lo) && _is_iso_date($hi);
	}
	my ($lo, $hi) = (substr($val, 0, $at[0]), substr($val, $at[0] + 1));
	return () unless length $lo && length $hi;
	return ($lo, $hi);
}

sub _apply_filter_spec {
	my ($records, $spec) = @_;
	my ($col, $op, $val) = split /:/, $spec, 3;
	return $records unless length($col // '') && defined $op && length $op;
	$val //= '';
	my $lval    = lc $val;	# precompute once; avoids O(N) redundant lc() inside grep
	my $between = $op eq 'between';
	my ($lo, $hi) = $between ? _between_bounds($val) : ();
	# A between is about times only when both its bounds are.
	my $is_date = $between
		? (defined $lo && _is_iso_date($lo) && _is_iso_date($hi))
		: _is_iso_date($val);
	# Compare at the precision the bound names: a bound with a time in it asks
	# about the second, a bare date asks about the day.  Without this, a date
	# bound compared against a column of timestamps drops every row on the
	# boundary day, because the cell string carries more characters than the
	# bound and "2026-10-27T09:15:00" sorts after "2026-10-27".
	my $prec = ($is_date && (grep { defined((Database::BI::Util::iso_datetime($_))[1]) }
		$between ? ($lo, $hi) : ($val))) ? 19 : 10;
	my $nval = $is_date && !$between ? (_date_key($val, $prec) // $val) : $val;
	# An order is a statement about numbers.  A blank or a word has no place in
	# one, so it matches none of the four, rather than counting as zero.
	my $by_number = !$is_date && $op =~ /\A(?:lt|le|gt|ge)\z/;
	my $num_val   = $by_number ? _numeric_cell($val) : undef;
	# A between of two numbers (a range of years, of prices) compares as
	# numbers, inclusive at both ends and whichever bound is written first;
	# "9" sorts after "10" as text.  Anything else keeps the text comparison.
	# Dates and text likewise: the bounds are put in order before they are
	# used, so "2026-12-31:2026-01-01" is the year, not nothing.
	my ($num_lo, $num_hi);
	if ($between && defined $lo) {
		if ($is_date) {
			($lo, $hi) = map { _date_key($_, $prec) // $_ } $lo, $hi;
		} else {
			($num_lo, $num_hi) = (_numeric_cell($lo), _numeric_cell($hi));
			($num_lo, $num_hi) = (undef, undef) unless defined $num_lo && defined $num_hi;
			($lo, $hi) = (lc $lo, lc $hi);
		}
		($num_lo, $num_hi) = ($num_hi, $num_lo) if defined $num_lo && $num_lo > $num_hi;
		($lo, $hi) = ($hi, $lo) if $lo gt $hi;
	}
	my %in_set    = $op eq 'in' ? (map { lc($_) => 1 } _filter_in_values($val)) : ();
	return [grep {
		my $cell  = $_->{$col} // '';
		my $num   = $by_number ? _numeric_cell($cell) : undef;
		my $both  = defined $num && defined $num_val;
		# Normalise M/D/YYYY cells to ISO for date comparisons so that the
		# ISO values produced by <input type="date"> match against either format.
		my $ncell = $is_date
			? (_date_key(_to_iso_date($cell) // $cell, $prec) // $cell)
			: $cell;
		$op eq 'eq'       ? ($is_date ? $ncell eq $nval  : lc($cell) eq $lval) :
		$op eq 'ne'       ? ($is_date ? $ncell ne $nval  : lc($cell) ne $lval) :
		$op eq 'contains' ? index(lc($cell), $lval) != -1                      :
		$op eq 'starts'   ? index(lc($cell), $lval) == 0                       :
		$op eq 'lt'       ? ($is_date ? $ncell lt $nval  : $both && $num <  $num_val) :
		$op eq 'le'       ? ($is_date ? $ncell le $nval  : $both && $num <= $num_val) :
		$op eq 'gt'       ? ($is_date ? $ncell gt $nval  : $both && $num >  $num_val) :
		$op eq 'ge'       ? ($is_date ? $ncell ge $nval  : $both && $num >= $num_val) :
		$op eq 'empty'    ? $cell eq ''                                         :
		$op eq 'notempty' ? $cell ne ''                                         :
		$op eq 'in'       ? $in_set{ lc($cell) }                                 :
		$op eq 'between' && defined $num_lo ? do {
			my $n = _numeric_cell($cell);
			defined $n && $n >= $num_lo && $n <= $num_hi
		} :
		$op eq 'between'  ? do {
			my $key = $is_date ? $ncell : lc $cell;
			defined $lo && $key ge $lo && $key le $hi
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

	# A filter on a column stage 6 or 7 will write has to wait for it: f=ytd:gt:50
	# selects rows by their running total, and must not change those totals.  So
	# every filter that can run first does, and the rest run last.
	my $crossing = (!$opts || !$opts->{no_cross_row}) && length($self->param('cs') // '');
	my %written  = $crossing ? map { $_ => 1 } _cross_row_written($self) : ();
	if (defined(my $why = _unknown_filter_column($self, $columns, \%written))) {
		croak $why;
	}
	my @late;
	for my $s (@{ _filter_specs($self) }) {
		if ($written{ (split /:/, $s, 2)[0] // '' }) {
			push @late, $s;
			next;
		}
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
	if ($crossing) {
		($records, $columns) = $self->_apply_cross_row($records, $columns);
		# Stage 7: the calculated fields stage 4 held back for these columns.
		($records, $columns) = $self->_apply_held_calc_fields($records, $columns);
		$records = _apply_filter_spec($records, $_) for @late;
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
#   in              -- Always residual (a list of values, matched as eq is).
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
			# A date compares by the day in Perl (a timestamp cell is on the
			# day it names); LIKE would want the cell to be the date exactly.
			if ($val =~ /[%_]/ || _is_iso_date($val)) {
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
	return Database::BI::Util::parse_number($_[0]);
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
	# TODO: remove this guard once SQL-Statement RT#181946 is fixed (last checked: 1.414, still the latest release, 2026-11-06).
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
		(@$by, (defined $val_col ? $val_col : ()), map { (split /:/, $_, 2)[0] // () } @f_specs);

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

# _rows_of_page(\@rows, $offset, $per_page) -> \@page
#
# One page of rows, in an array of its own.  The rows may be a backend's own
# read-only array, as they are from a DBI handle that is not SQLite, so they are
# copied and never spliced.
sub _rows_of_page {
	my ($rows, $offset, $per_page) = @_;
	# A negative offset would count from the end of the rows.
	$offset = 0 if $offset < 0;
	my $last = $offset + $per_page - 1;
	$last = $#$rows if $last > $#$rows;
	return [ @{$rows}[$offset .. $last] ];
}

# _page_count($total, $per_page) -> $pages
#
# How many pages $total rows make, for the table's "Page N of M".  No rows is
# still one page, the empty one the table shows.
sub _page_count {
	my ($total, $per_page) = @_;
	return 1 unless $total && $per_page && $per_page > 0;
	return int(($total + $per_page - 1) / $per_page);
}

# Where a cell with no date or number sorts: first, ascending, as -Infinity
# does in the browser.
Readonly my $NO_NUMBER => -9**9**9;

# _sort_records(\@rows, $column, $dir) -> \@sorted
#
# Every row, in the order the table's own header sort gives a page of them
# (biValueComparator in dashboard.html.tt), so the first page of a table too
# long for one page is the first page of the sorted rows rather than the first
# rows sorted.  The column sorts as dates when every non-empty cell is one
# (YYYY-MM-DD, or M/D/YYYY unless a cell shows the day comes first), else as
# numbers when every non-empty cell holds one (Util::parse_number, which the
# browser's parseAccounting copies: "$1,000" and "(5)" are numbers, "T27" is
# text), else as text the way localeCompare(..., { numeric: true, sensitivity:
# 'base' }) does: case and accents ignored, a run of digits compared as a
# number.  An empty cell sorts first, ascending.  Rows that compare equal keep
# their order, in either direction.  A new array: the rows may be read-only.
sub _sort_records ($rows, $column, $dir) {
	my @text = map {
		my $v = $_->{$column} // '';
		$v =~ s/\A\s+|\s+\z//g;
		$v;
	} @$rows;
	my @filled = grep { length } @text;

	my $key_of;	# cell text -> number; text sorts when there is none
	if (@filled && !(grep { !m{\A(?:\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{4})\z} } @filled)) {
		my $month_first = 1;
		for (@filled) {
			my ($p1, $p2) = m{\A(\d{1,2})/(\d{1,2})/} or next;
			if ($p1 > 12) { $month_first = 0; last }
			if ($p2 > 12) { last }
		}
		$key_of = sub ($v) {
			return $1 * 10_000 + $2 * 100 + $3 if $v =~ /\A(\d{4})-(\d{2})-(\d{2})\z/;
			if ($v =~ m{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}) {
				return $month_first ? $3 * 10_000 + $1 * 100 + $2 : $3 * 10_000 + $2 * 100 + $1;
			}
			return $NO_NUMBER;
		};
	} elsif (@filled && !(grep { !defined Database::BI::Util::parse_number($_) } @filled)) {
		$key_of = sub ($v) { Database::BI::Util::parse_number($v) // $NO_NUMBER };
	}

	# Equal rows keep their order in either direction, as the browser's stable
	# sort of -cmp does: the direction turns the comparison, not the result.
	my $sign = $dir eq 'desc' ? -1 : 1;
	my @order;
	if ($key_of) {
		my @key = map { $key_of->($_) } @text;
		@order = sort { $sign * ($key[$a] <=> $key[$b]) || $a <=> $b } 0 .. $#$rows;
	} else {
		my @key = map { _collation_key($_) } @text;
		@order = sort { $sign * _collate($key[$a], $key[$b]) || $a <=> $b } 0 .. $#$rows;
	}
	return [ @{$rows}[@order] ];
}

# _collation_key($text) -> \@tokens
#
# The text as localeCompare with sensitivity 'base' and numeric sees it: case
# and accents folded away, each run of digits one number, every other
# character ranked as ICU's root collation does -- spaces, then punctuation and
# symbols, then digits, then letters.
sub _collation_key ($text) {
	my $folded = CORE::fc(Unicode::Normalize::NFD($text));
	$folded =~ s/\p{Mn}+//g;
	my @tokens;
	while ($folded =~ /(\d+)|(.)/gs) {
		if (defined $1) {
			push @tokens, [2, $1 + 0];
		} else {
			my $c = $2;
			push @tokens, [ $c =~ /\s/ ? 0 : $c =~ /\p{L}/ ? 3 : 1, $c ];
		}
	}
	return \@tokens;
}

# _collate(\@a, \@b) -> -1 | 0 | 1
sub _collate ($x, $y) {
	my $n = @$x < @$y ? @$x : @$y;
	for my $i (0 .. $n - 1) {
		my ($p, $q) = ($x->[$i], $y->[$i]);
		my $c = $p->[0] <=> $q->[0]
			|| ($p->[0] == 2 ? $p->[1] <=> $q->[1] : $p->[1] cmp $q->[1]);
		return $c if $c;
	}
	return @$x <=> @$y;
}

# _fetch_page( $self, $source, \%params ) -> ( $records, $has_next )
#   (also stashes page_count, the number of pages: from the rows read, or on
#   the SQL fast path, which reads one page and a row, from the source's count)
#   params: per_page  -- page size (required)
#           offset    -- 0-based row offset (required)
#           dedup     -- truthy when ?d=1 dedup is requested
#           sort_col  -- column name to sort by (optional; default the request's
#                        sort= parameter)
#           sort_dir  -- 'asc' or 'desc' (default the request's dir=, else 'asc')
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
# Sort: a sort column takes the reduction path, and every row is sorted by
#   _sort_records -- after the fields, filters and cross-row columns, so any
#   column the table shows can be sorted on -- before the page is cut.  The
#   table's header sort works on the rows it was given, so on a table longer
#   than a page it sorted only those, and the page was not the first of the
#   sorted table; the page asks for sort= instead whenever there is more than
#   one page.  The backend's sort_by is not used: it compares as text, and
#   ignores a column whose name is not a safe identifier.  When the sort is
#   applied, stash sorted_by => { col, dir } tells the page what it shows.
#
# Returns (undef, 0) when the underlying fetch throws; the caller must handle
# $records being undef.
sub _fetch_page :Protected ($self, $source, $params) {
	my $per_page = $params->{per_page};
	my $offset   = $params->{offset};
	my $dedup    = $params->{dedup};
	my $sort_col = $params->{sort_col} // $self->param('sort');
	$sort_col = undef unless defined $sort_col && length $sort_col;
	my $sort_dir = ($params->{sort_dir} // $self->param('dir') // 'asc') =~ /\Adesc\z/i ? 'desc' : 'asc';

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
	my $is_sql = ($source->can('dbi_source') && $source->dbi_source)
		|| ($source->can('pages_on_server') && $source->pages_on_server);

	# A cross-row column is a column of the whole filtered set, so a request that
	# names one cannot take the N+1 fast path: it would see one page of rows and
	# restart every running total on page 2.
	my $cross = length($self->param('cs') // '') ? 1 : 0;

	unless (@f_specs || $dedup || $cross || defined $sort_col) {
		if ($is_sql) {
			# Fast path (SQL-backed): delegate LIMIT/OFFSET to the backend N+1 trick.
			# Copy before pop: D::A may return a read-only ref to its internal cache.
			my @records = @{ $source->selectall_arrayref(
				limit => $per_page + 1, offset => $offset,
			) // [] };
			my $has_next = (@records > $per_page) ? 1 : 0;
			pop @records if $has_next;
			# The number of pages needs the number of rows.  count() remembers a
			# file's until it changes, so only the first page of a big SQLite
			# file pays for the COUNT(*).  Only when there is more than one page:
			# a short table shows no pagination.  A count that fails costs the
			# page its "of M", never the page.
			if ($has_next || $offset > 0) {
				my $total;
				my $ok = eval { $total = $source->count; 1 };
				$self->stash(page_count => _page_count($total, $per_page))
					if $ok && defined $total && $total =~ /\A\d+\z/;
			}
			return (\@records, $has_next);
		}
		# Non-SQL fast path: fetch all, then paginate.  Every row is in hand, so
		# the number of pages costs nothing.
		my $all = $source->selectall_arrayref() // [];
		my $has_next = (@$all > $offset + $per_page) ? 1 : 0;
		$self->stash(page_count => _page_count(scalar(@$all), $per_page));
		return (_rows_of_page($all, $offset, $per_page), $has_next);
	}

	# Always fetch all rows in Perl and filter with _apply_filter_spec.
	# SQL criteria pushdown (passing %criteria to selectall_arrayref) is
	# intentionally avoided: on some Perl/D::A version combinations the WHERE
	# clause is silently dropped, returning the full unfiltered set.  The Perl
	# path is correct on every supported version.  Memory cost: bounded by the
	# source file size (the same as the dedup path already accepted).
	my $all = $source->selectall_arrayref() // [];

	# A stored date or time pattern is what makes a patterned column comparable
	# with the ISO bounds a relative time range carries, and it belongs to stage 2
	# of the pipeline -- before the filters of stage 5.  The rest of the
	# application reaches the filters through that order already; this path, which
	# filters before it paginates, is the one call site that would otherwise
	# compare the reader's format, so it normalises first, on exactly the rows the
	# specs are about to be applied to.
	$self->_apply_date_normalization($all, [_get_columns($source, $all)],
		$self->_calc_spec_key);

	# A failure below is a 400 about the request.  It is rendered here, and the
	# caller sees the stash and returns rather than drawing a page over it.
	my $refuse = sub {
		my ($why) = @_;
		$why =~ s/ at \S+ line \d+\.?\n?$//;
		$self->render(text => $why, status => 400);
		$self->stash('_cross_row_error' => $why);
		return;
	};

	# Stage 4.  The page's own fields run on the sliced page (_page_columns), which
	# is enough to show them, but a filter or a window that reads one needs it on
	# every row, and before them.  That pass then only repeats these, on one page.
	$all = [ @$all ];	# the backend's own array can be read-only
	my @cols_so_far;
	if (defined $params->{calc_spec_key}) {
		my @before = _get_columns($source, $all);
		my $span   = @before ? $self->_span_calc_spec(\@before, ()) : undef;
		if ($span && $span->{error}) {
			$refuse->($span->{error});
			return ();
		}
		my ($r, $c) = eval {
			$self->_calc_for_page($all, \@before, {
				spec_key => $params->{calc_spec_key},
				($span ? (calc => $span->{calc}) : ()),
			})
		};
		unless ($r) {
			$refuse->($@);
			return ();
		}
		($all, @cols_so_far) = ($r, @$c);
	}

	# A filter on a column stages 6 and 7 write waits for them.  See _reduce_records.
	my %written = $cross ? map { $_ => 1 } _cross_row_written($self) : ();
	my @filter_cols = @cols_so_far ? @cols_so_far : _get_columns($source, $all);
	if (defined(my $why = _unknown_filter_column($self, \@filter_cols, \%written))) {
		$refuse->($why);
		return ();
	}
	my @late    = grep { $written{ (split /:/, $_, 2)[0] } } @f_specs;
	$all = _apply_filter_spec($all, $_) for grep { !$written{ (split /:/, $_, 2)[0] } } @f_specs;

	if ($dedup) {
		my $cols = $source->columns;
		my @dcols = $cols ? @$cols : (keys %{ $all->[0] // {} });
		$all = _dedup_records($all, \@dcols);
	}

	# Stages 6 and 7, before the slice: a running total has to see every filtered
	# row, or page 2 would start again from zero.
	if ($cross) {
		my $cols  = $source->columns;
		my @xcols = @cols_so_far ? @cols_so_far
			: $cols ? @$cols : (sort keys %{ $all->[0] // {} });
		my $done = eval {
			my ($r, $c) = $self->_apply_cross_row($all, \@xcols);
			($all) = $self->_apply_held_calc_fields($r, $c);
			1;
		};
		unless ($done) {
			$refuse->($@);
			return ();
		}
		$all = _apply_filter_spec($all, $_) for @late;
	}

	# The whole reduced set, sorted, before the page is cut.  A column the view
	# does not have is left alone (the order is the file's), as the header sort
	# ignores one it cannot find.
	if (defined $sort_col) {
		my %known = map { $_ => 1 } (@cols_so_far ? @cols_so_far : _get_columns($source, $all)), keys %written;
		$known{$sort_col} = 1 if $cross && @$all && exists $all->[0]{$sort_col};
		if ($known{$sort_col}) {
			$all = _sort_records($all, $sort_col, $sort_dir);
			$self->stash(sorted_by => { col => $sort_col, dir => $sort_dir });
		}
	}

	my $total    = scalar @$all;
	my $has_next = ($total > $offset + $per_page) ? 1 : 0;
	my @page     = @{ _rows_of_page($all, $offset, $per_page) };
	$self->stash(page_count => _page_count($total, $per_page));

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

# _write_sqlite_db($self, $records, $columns, $table) -> $raw_bytes
#
# Purpose: $records as a SQLite database of one table, every column TEXT, as
#          the file's bytes.  Used by both _render_sqlite (HTTP download) and
#          export_write (filesystem write); Database::Join::Catalog writes it.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names;
#          $table names the table, "data" unless given.  An extract passes
#          "extract", which Database::Abstraction before 0.54 needed (it could
#          not read a table called "data"); extracts already built use it.
# Exit:    Returns scalar binary string.  Croaks when it cannot be written.
# Side Effects: Catalog makes and removes one temporary file under tmpdir.
sub _write_sqlite_db :Protected ($self, $records, $columns, $table = 'data') {
	# D~ fix: an empty column list would be "CREATE TABLE data ()", which is
	# invalid SQLite syntax; this message is the one readers have seen.
	croak 'Cannot export SQLite: result set has no columns'
		unless @$columns;

	require Database::Join::Catalog;
	return Database::Join::Catalog->sqlite_bytes(table => $table, columns => $columns, rows => $records);
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
	return canonical_spec($l) if length $l;
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
			next if $spec =~ /\A(?:path:|table:|url:|redis:|mariadb:)/i;
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

# _lookups_of_request($self, $spec_key) -> @lookups
#
# Purpose: The lookups this request applies, in order: those stored for
#          $spec_key, by name, then each lk=<name> stored for another dataset,
#          less every nolk=<name>.
# Entry:   $spec_key files the stored lookups (the l= spec, or a canvas's).
# Exit:    A list of { name => $name, %definition }.  Croaks error_lookup_unknown
#          for an lk= that names no stored lookup, and error_lookup_name for one
#          that is not an identifier.
sub _lookups_of_request :Protected ($self, $spec_key) {
	my $all  = $self->_read_models->{lookups};
	my %skip = map { $_ => 1 } @{ $self->every_param('nolk') // [] };
	my $own  = (length($spec_key // '') && ref $all->{$spec_key} eq 'HASH') ? $all->{$spec_key} : {};

	my (@lookups, %seen);
	for my $name (sort keys %$own) {
		next if $skip{$name} || ref $own->{$name} ne 'HASH';
		push @lookups, { %{ $own->{$name} }, name => $name };
		$seen{$name} = 1;
	}
	for my $name (@{ $self->every_param('lk') // [] }) {
		next if $seen{$name}++ || $skip{$name};
		croak $self->_i18n('error_lookup_name', $name) unless $name =~ $LOOKUP_NAME_RE;
		# Another dataset's lookup, the first by the order of the specs, so the
		# choice does not depend on how the store happens to be read.
		my ($def) = grep { ref $_ eq 'HASH' }
			map { $all->{$_}{$name} } sort keys %$all;
		croak $self->_i18n('error_lookup_unknown', $name) unless $def;
		push @lookups, { %$def, name => $name };
	}
	return @lookups;
}

# _lookup_file($self, $name, $file) -> $path
#
# Purpose: Resolve a lookup's file= to the file it reads.  A relative path is
#          under data_dir; an absolute one must be, after symlinks are resolved,
#          so a link inside data_dir cannot reach outside it.
# Entry:   $name names the lookup in the messages.
# Exit:    The resolved path as a string.  Croaks error_lookup_remote (a URL or
#          another source spec, or a remote /../host/ path), error_lookup_outside,
#          error_lookup_not_found (missing, or not a supported extension) or
#          error_lookup_too_large (over $LOOKUP_MAX_BYTES).
sub _lookup_file :Protected ($self, $name, $file) {
	$file //= '';
	# Two letters at least before the colon, so C:\data is still a path.
	croak $self->_i18n('error_lookup_remote', $name, $file)
		if $file =~ m{\A(?:[A-Za-z][A-Za-z0-9+.-]+:|/\.\./)};
	croak $self->_i18n('error_lookup_not_found', $name, $file) unless length $file;

	my $data_dir = _data_dir_for($self->app);
	my $given    = Mojo::File->new($file);
	my $path     = $given->is_abs ? $given : $data_dir->child($file);
	croak $self->_i18n('error_lookup_outside', $name, $file)
		unless _inside_dir(_canonical_path($path), _canonical_path($data_dir));
	croak $self->_i18n('error_lookup_not_found', $name, $file)
		unless -f $path && $path->basename =~ $EXT_RE;
	my $size = -s $path // 0;
	croak $self->_i18n('error_lookup_too_large', $name, $file, $size, $LOOKUP_MAX_BYTES)
		if $size > $LOOKUP_MAX_BYTES;
	return _canonical_path($path);
}

# _load_lookup($self, $lookup) -> \%entry
#
# Purpose: Read a lookup's file into a map from key to row, once per request.
# Entry:   $lookup is one entry of _lookups_of_request.
# Exit:    { map => { key => \%row }, fields => \@names, file => $basename }.
#          Keys are compared as strings after trimming, case-sensitively; a
#          duplicate key keeps its first row and is logged once.  Croaks one of
#          _lookup_file's errors, error_lookup_unreadable, error_lookup_key_unknown
#          or error_lookup_field_unknown.
# Side Effects: Caches the entry in the stash, keyed by name, path and mtime.
sub _load_lookup :Protected ($self, $lookup) {
	my $name = $lookup->{name};
	my $path = $self->_lookup_file($name, $lookup->{file});
	my $file = Mojo::File->new($path)->basename;
	my $memo = $self->stash('_lookup_maps') // {};
	my $tag  = join "\0", $name, $path, (stat $path)[9] // 0,
		$lookup->{key} // '', @{ ref $lookup->{fields} eq 'ARRAY' ? $lookup->{fields} : [] };
	return $memo->{$tag} if $memo->{$tag};

	(my $table = $file) =~ s/\.[^.]+\z//;
	my ($src, $rows);
	my $ok = eval {
		$src  = $self->open_table($table, directory => Mojo::File->new($path)->dirname->to_string);
		$rows = $src->fetch_all;
		1;
	};
	croak $self->_i18n('error_lookup_unreadable', $name, $file, _tidy_error($@)) unless $ok;

	my @columns = _get_columns($src, $rows);
	my %has     = map { $_ => 1 } @columns;
	my $key     = $lookup->{key} // '';
	croak $self->_i18n('error_lookup_key_unknown', $name, $key, $file) unless $has{$key};

	my @fields = ref $lookup->{fields} eq 'ARRAY' && @{ $lookup->{fields} }
		? @{ $lookup->{fields} }
		: grep { $_ ne $key } @columns;
	for my $f (@fields) {
		croak $self->_i18n('error_lookup_field_unknown', $name, $f, $file) unless $has{$f};
	}

	my (%map, $duplicates);
	for my $row (@$rows) {
		my $k = _lookup_key($row->{$key});
		next unless defined $k && length $k;
		if (exists $map{$k}) {
			$duplicates++;
			next;
		}
		$map{$k} = { map { $_ => $row->{$_} } @fields };
	}
	$self->app->log->warn($self->_i18n('warn_lookup_duplicate_key', $name, $duplicates, $file))
		if $duplicates;

	$memo->{$tag} = { map => \%map, fields => \@fields, file => $file };
	$self->stash('_lookup_maps' => $memo);
	return $memo->{$tag};
}

# _lookup_key($value) -> $key | undef
#
# Purpose: The form in which a lookup compares a key: the string, trimmed.  Case
#          and everything else are left as they are, so "ab" and "AB" are two keys.
sub _lookup_key {
	my ($v) = @_;
	return undef unless defined $v && !ref $v;
	(my $k = $v) =~ s/\A\s+|\s+\z//g;
	return $k;
}

# _apply_lookups($self, $records, \@cols, $spec_key) -> void
#
# Purpose: Stage 3 of the pipeline: each lookup the request applies adds its
#          fields to every row, read from the lookup file's row whose key equals
#          the row's own (col=, which defaults to the key's name).  A row whose
#          key is missing gets the lookup's default, or undef.
# Entry:   \@cols is the column list so far; it gains the new columns.
# Exit:    Rows are replaced through _extend_row where they must be.  The new
#          columns are virtual, so an aggregate that groups by one is folded in
#          Perl.  Croaks with a message for a bad lookup or a missing column.
# Notes:   A field lands under its own name unless a column has it, and then
#          under <lookup>_<field>; a source column is never overwritten.  The
#          columns this pass wrote do not count as taken when it runs again in
#          the same request, so the names a page gets do not depend on how
#          many times the stage has run over it.
sub _apply_lookups :Protected ($self, $records, $cols, $spec_key) {
	my @lookups = $self->_lookups_of_request($spec_key);
	return unless @lookups;

	my $written = $self->stash('_lookup_written') // {};
	my %taken   = map { $_ => 1 } grep { !$written->{$_} } @$cols;
	for my $lookup (@lookups) {
		my $name  = $lookup->{name};
		my $entry = $self->_load_lookup($lookup);
		my $col   = length($lookup->{col} // '') ? $lookup->{col} : $lookup->{key};
		croak $self->_i18n('error_lookup_col_unknown', $name, $col, $name)
			unless $taken{$col} || $written->{$col};

		my @out;
		for my $f (@{ $entry->{fields} }) {
			my $as = $taken{$f} ? "${name}_$f" : $f;
			croak $self->_i18n('error_lookup_name_taken', $name, $f, $as) if $taken{$as};
			$taken{$as} = 1;
			push @out, [ $f, $as ];
		}

		my $default = $lookup->{default};
		my $map     = $entry->{map};
		for my $i (0 .. $#$records) {
			my $k   = _lookup_key($records->[$i]{$col});
			my $hit = defined $k ? $map->{$k} : undef;
			for my $pair (@out) {
				$records->[$i] = _extend_row($records->[$i], $pair->[1],
					$hit ? $hit->{ $pair->[0] } : $default);
			}
		}

		my %have = map { $_ => 1 } @$cols;
		push @$cols, grep { !$have{$_} } map { $_->[1] } @out;
		$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
		for my $pair (@out) {
			$self->stash('_virtual_columns')->{ $pair->[1] } = 1;
			$written->{ $pair->[1] } = 1;
		}
	}
	$self->stash('_lookup_written' => $written);
	return;
}

# _compile_extraction($self, $name, \%definition) -> (\%compiled, \@fields)
#
# Purpose: Check a stored extraction and compile its pattern, the same way on
#          save and on every request.
# Exit:    The compiled pattern (Calc::compile_pattern) and the named groups it
#          writes: fields= when it was given, else every named group, in order.
#          Croaks error_extract_pattern (wrapping Calc's reason),
#          error_extract_no_names or error_extract_field.
sub _compile_extraction :Protected ($self, $name, $def) {
	require Database::BI::Calc;
	my $compiled = eval { Database::BI::Calc::compile_pattern($def->{pattern}) };
	croak $self->_i18n('error_extract_pattern', $name, _tidy_error($@)) unless $compiled;
	my @names = @{ $compiled->{names} };
	croak $self->_i18n('error_extract_no_names', $name) unless @names;
	my %named  = map { $_ => 1 } @names;
	my @fields = ref $def->{fields} eq 'ARRAY' && @{ $def->{fields} } ? @{ $def->{fields} } : @names;
	for my $f (@fields) {
		croak $self->_i18n('error_extract_field', $name, $f) unless $named{$f};
	}
	return ($compiled, \@fields);
}

# _apply_extractions($self, $records, \@cols, $spec_key) -> void
#
# Purpose: The stored extractions of $spec_key, after the lookups in stage 3:
#          each named group of a pattern becomes a column, read from the column
#          the extraction names.  A row the pattern does not match, or whose
#          cell is empty, gets '(unparseable)', so it groups visibly rather than
#          vanishing; a group that took no part in a match is ''.
# Entry:   \@cols is the column list so far; it gains the new columns.
# Exit:    Croaks with a message for a bad pattern or a missing column.
# Notes:   Columns are named as a lookup's are: the group's own name unless a
#          column has it, then <extraction>_<group>.  A capture is cut to 200
#          characters (Calc::capture_of).
sub _apply_extractions :Protected ($self, $records, $cols, $spec_key) {
	return unless length($spec_key // '');
	my $stored = $self->_read_models->{extractions}{$spec_key};
	return unless ref $stored eq 'HASH' && %$stored;

	my $written = $self->stash('_extract_written') // {};
	my %taken   = map { $_ => 1 } grep { !$written->{$_} } @$cols;
	for my $name (sort keys %$stored) {
		my $def = $stored->{$name};
		next unless ref $def eq 'HASH';
		my ($compiled, $fields) = $self->_compile_extraction($name, $def);
		my $col = $def->{col} // '';
		croak $self->_i18n('error_extract_col_unknown', $name, $col)
			unless $taken{$col} || $written->{$col};

		my @out;
		for my $f (@$fields) {
			my $as = $taken{$f} ? "${name}_$f" : $f;
			croak $self->_i18n('error_extract_name_taken', $name, $f, $as) if $taken{$as};
			$taken{$as} = 1;
			push @out, [ $f, $as ];
		}

		# The groups were checked against the pattern, so undef is a row it
		# does not match, and a group that took no part is ''.
		for my $i (0 .. $#$records) {
			my $v = $records->[$i]{$col};
			for my $pair (@out) {
				my $got = Database::BI::Calc::capture_of($compiled, $v, $pair->[0]);
				$records->[$i] = _extend_row($records->[$i], $pair->[1], $got // '(unparseable)');
			}
		}

		my %have = map { $_ => 1 } @$cols;
		push @$cols, grep { !$have{$_} } map { $_->[1] } @out;
		$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
		for my $pair (@out) {
			$self->stash('_virtual_columns')->{ $pair->[1] } = 1;
			$written->{ $pair->[1] } = 1;
		}
	}
	$self->stash('_extract_written' => $written);
	return;
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

# _write_calc_column($self, $records, \@cols, $name, $calc)
#
# Purpose: Evaluate one compiled calculated field over the rows and write it as
#          a column, recording it as virtual so _grouped_totals skips the SQL
#          push path.  \@cols gains the name if it is new.
sub _write_calc_column :Protected ($self, $records, $cols, $name, $calc) {
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
		$self->app->log->warn($self->_i18n('warn_calc_undef', $name, $undef_count));
	}
	push @$cols, $name unless grep { $_ eq $name } @$cols;
	$self->stash('_virtual_columns' => {}) unless $self->stash('_virtual_columns');
	$self->stash('_virtual_columns')->{$name} = 1;
	return;
}

# _apply_held_calc_fields($self, $records, \@columns, $card) -> ($records, \@columns)
#
# Purpose: Stage 7 of the pipeline: the calculated fields stage 4 held back,
#          now that the cross-row columns they name exist.  Each was checked
#          against those names when it was held, so a failure here is reported
#          as any other compile failure is.
# Entry:   $card is true for a canvas card.  A canvas holds a field for any
#          card's plan, so a field that does not compile against this card's
#          columns belongs to another card, and this card goes without it.
# Exit:    The rows and columns, extended.  The list is a new array, and both
#          come back as they arrived when nothing is held.
sub _apply_held_calc_fields :Protected ($self, $records, $columns, $card = 0) {
	my $held = $self->stash('_held_calc_fields');
	return ($records, $columns) unless $held && @$held;

	require Database::BI::Calc;
	my @cols = @{ $columns // [ sort keys %{ $records->[0] // {} } ] };
	for my $cs (@$held) {
		my $calc = Database::BI::Calc->new(
			expr    => $cs->{expr},
			columns => \@cols,
			params  => $cs->{params},
		);
		if ($calc->has_error) {
			next if $card;
			croak $self->_i18n('error_calc_compile', $cs->{name}, $calc->error);
		}
		$self->_write_calc_column($records, \@cols, $cs->{name}, $calc);
	}
	return ($records, \@cols);
}

# _cross_row_aliases(@specs) -> @names
#
# Purpose: The columns a list of cs= specs will add: the third field of each.
#          Only names are wanted, so a malformed spec simply has none; refusing
#          it is the work of _cross_row_specs_from.
sub _cross_row_aliases {
	return map { (split /:/, $_, 4)[2] // () } grep { defined && !ref && length } @_;
}

# _cross_row_written($self) -> @names
#
# Purpose: The columns this request writes at stages 6 and 7: the cs= aliases and
#          the calculated fields held back for them.  A filter on one of these
#          has to run after them.
sub _cross_row_written {
	my ($self) = @_;
	return (
		_cross_row_aliases(@{ $self->every_param('cs') // [] }),
		map { $_->{name} } @{ $self->stash('_held_calc_fields') // [] },
	);
}

# _canvas_window_columns($analysis, $params, \@more) -> \@names
#
# Purpose: Every column a cross-row plan may add on this canvas: the page's cs=,
#          read from $params, and each card's own plan.  \@more holds cards that
#          are not on the canvas yet: one being added, or being given a new plan.
sub _canvas_window_columns {
	my ($analysis, $params, $more) = @_;
	my @specs = @{ $params->every_param('cs') // [] };
	for my $vis (@{ $analysis->{visuals} // [] }, @{ $more // [] }) {
		next unless ref $vis eq 'HASH' && ref $vis->{cross_row} eq 'HASH'
			&& ref $vis->{cross_row}{cs} eq 'ARRAY';
		push @specs, @{ $vis->{cross_row}{cs} };
	}
	return [ _cross_row_aliases(@specs) ];
}

# _canvas_cross_filter($self, $records, \@columns, \@specs) -> ($records, \@late)
#
# Purpose: Apply a canvas's cross-filter to a card's rows, except any spec on a
#          column a cross-row plan writes.  That column does not exist yet, so
#          the spec comes back for _render_visual_html to apply after the pass.
sub _canvas_cross_filter :Protected ($self, $records, $columns, $specs) {
	my %written = map { $_ => 1 }
		@{ $self->stash('_canvas_window_names') // [] },
		map { $_->{name} } @{ $self->stash('_held_calc_fields') // [] };
	delete @written{ @$columns };
	my @late;
	for my $spec (@$specs) {
		if ($written{ (split /:/, $spec, 2)[0] // '' }) {
			push @late, $spec;
			next;
		}
		$records = _apply_filter_spec($records, $spec);
	}
	return ($records, \@late);
}

# _calc_specs_of_request($self) -> @specs
#
# Purpose: The calculated fields among the request's c= params, leaving out the
#          files it stacks, which share that parameter.
sub _calc_specs_of_request :Protected ($self) {
	return grep { !/\A(?:path|table|url|redis|mariadb):/i } @{ $self->every_param('c') // [] };
}

# _page_columns($self, $source, $records, $spec_key) -> ($records, \@columns) | ()
#
# Purpose: The columns of a table page from _fetch_page, with the calculated
#          fields and any span= bucket drawn on its rows.  A page is one slice,
#          so _fetch_page has already run them over the whole set if a filter or
#          a window needed them; this pass is what puts them on the page.
# Entry:   $spec_key files the stored fields: the page's left_spec.
# Exit:    The rows and columns; or the empty list after rendering a 400, and the
#          caller returns.
sub _page_columns :Protected ($self, $source, $records, $spec_key) {
	my @columns  = _get_columns($source, $records);
	my %seen_col = map { $_ => 1 } @columns;
	# Stage 6 wrote its columns onto the rows before the page was sliced, so the
	# list is what makes the table show them, and lets a field below read one.
	push @columns, grep { !$seen_col{$_}++ } @{ $self->stash('_cross_row_columns') // [] };
	# Nothing to draw a field from: a source with no declared columns and no rows.
	return ($records, \@columns) unless @columns;

	# span= adds a bucket column to the table rather than grouping it: a table has
	# no dimension to bucket *into*, so the reader gets the column and the raw
	# value beside it.  See _span_calc_spec.
	my $span = $self->_span_calc_spec(\@columns, ());
	if ($span && $span->{error}) {
		$self->render(text => $span->{error}, status => 400);
		return ();
	}

	my ($calc_records, $calc_columns) = eval {
		$self->_calc_for_page($records, \@columns, {
			spec_key => $spec_key,
			($span ? (calc => $span->{calc}) : ()),
		})
	};
	unless ($calc_records) {
		# Every location croak added on the way up, not only the last.
		$self->render(text => _tidy_error($@), status => 400);
		return ();
	}
	return ($calc_records, $calc_columns);
}

# _calc_for_page($self, $records, \@columns, \%extra) -> ($records, \@columns)
#
# Purpose: _apply_calc_fields for a table page, which must still be drawn when a
#          definition saved for its data cannot be applied -- a lookup file that
#          is gone, a column an extraction or a field reads that the file no
#          longer has.  Every chart and export of that data refuses with the
#          reason, and the panels that mend a definition are on the table page,
#          so a page that refused too would leave the reader no way back.
# Entry:   As _apply_calc_fields; $extra->{spec_key} files the definitions.
# Exit:    As _apply_calc_fields.  When the first pass croaks and a second one
#          without the saved fields, lookups and extractions succeeds, returns
#          that, with stash stored_error holding the first pass's reason and
#          _skip_stored set for the rest of the request.  Otherwise croaks with
#          the first pass's error, so a mistake in the request's own c= is the
#          400 it always was.
# Side Effects: The first pass runs on a copy of the rows when anything is
#          saved, so a pass that failed half way leaves nothing on them.
sub _calc_for_page :Protected ($self, $records, $columns, $extra) {
	my $stored = !$self->stash('_skip_stored') && $self->_has_stored_columns($extra->{spec_key});
	my $rows   = $stored ? [ map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$records ] : $records;
	my @got    = eval { $self->_apply_calc_fields($rows, $columns, $extra) };
	return @got if @got && $got[0];
	my $error = $@;
	croak $error unless $stored;

	$self->stash('_skip_stored' => 1);
	@got = eval { $self->_apply_calc_fields($records, $columns, $extra) };
	unless (@got && $got[0]) {
		$self->stash('_skip_stored' => 0);
		croak $error;
	}
	$self->stash(stored_error => _tidy_error($error));
	return @got;
}

# _has_stored_columns($self, $spec_key) -> $bool
#
# Purpose: Whether anything saved for $spec_key adds columns that can fail: a
#          calculated field, a lookup (its own, or another's through lk=) or an
#          extraction.
# Entry:   $spec_key may be undef, when the request's l= is the key.
# Exit:    True or false.
sub _has_stored_columns :Protected ($self, $spec_key) {
	$spec_key = canonical_spec($spec_key // $self->param('l') // '');
	return 1 if @{ $self->every_param('lk') // [] };
	return 0 unless length $spec_key;
	my $models = $self->_read_models;
	for my $kind (qw(fields lookups extractions)) {
		my $set = $models->{$kind}{$spec_key};
		return 1 if ref $set eq 'HASH' && %$set;
	}
	return 0;
}

# _apply_calc_fields($self, $records, \@columns, \%extra) -> ($records, \@columns)
#
# Reads ?c=<name>:<expression> params (those NOT matching a path:/table:/url:/redis:/mariadb:
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
#   window_columns => \@names -- the columns the cross-row pass will add, for a
#                          canvas, whose plans are not the request's own cs=.
#
# A field that needs a cross-row column cannot run yet: stage 6 comes after the
# filters this stage feeds.  So a field that fails to compile, and would compile
# once those columns exist, is held back for _apply_held_calc_fields.  Any other
# failure is still the error it always was, a mistyped name included, so holding
# cannot hide a mistake, and with no cs= nothing is ever held.
sub _apply_calc_fields :Protected ($self, $records, $columns, $extra = undef) {
	my $bound_params     = ($extra // {})->{params}   // {};
	my $spec_key_override = ($extra // {})->{spec_key};
	my $extra_calc        = ($extra // {})->{calc}    // [];

	# Normalise date columns before evaluating expressions so that date
	# functions (YEAR, MONTH, etc.) see ISO-8601 values even when the source
	# file uses a non-ISO format (e.g. M/D/YYYY).
	my $date_spec = defined $spec_key_override
		? $spec_key_override : ($self->param('l') // '');
	# A canvas dataset's spec comes from the stored canvas, not the request,
	# so the hook that spells the request's specs one way has not seen it.
	$date_spec = canonical_spec($date_spec);
	$self->_apply_date_normalization($records, $columns, $date_spec);

	# Stage 3: the stored lookups, so that a field, a filter, a bucket or a window
	# can read a looked-up column.  They join the column list from here on.
	# _skip_stored is set by _calc_for_page when one of them cannot be applied:
	# the table page is drawn without them, so its panels can mend them.
	my $skip_stored = $self->stash('_skip_stored');
	my @cols = @{$columns};
	unless ($skip_stored) {
		$self->_apply_lookups($records, \@cols, $date_spec);
		$self->_apply_extractions($records, \@cols, $date_spec);
	}

	# Build calc spec list: stored fields from models.json first (lower priority),
	# then URL ?c= params (higher priority -- they override stored fields of the
	# same name so the user can test a new expression without permanently saving).
	my (@calc_specs, %seen_calc);
	{
		my $sk = $date_spec;
		if (length $sk && !$skip_stored) {
			my $stored = ($self->_read_models)->{fields}{$sk} // {};
			for my $n (sort keys %{$stored}) {
				push @calc_specs, { name => $n, expr => $stored->{$n} };
				$seen_calc{$n} = $#calc_specs;
			}
		}
	}
	for my $spec (@{ $self->every_param('c') // [] }, @$extra_calc) {
		# Skip source specs handled by _run_pipeline_source.
		next if $spec =~ /\A(?:path:|table:|url:|redis:|mariadb:)/i;
		my ($name, $expr) = ($spec =~ /\A([A-Za-z_][A-Za-z0-9_]*):(.+)\z/s);
		next unless defined $name && defined $expr;
		if (exists $seen_calc{$name}) {
			$calc_specs[$seen_calc{$name}]{expr} = $expr; # URL overrides stored
		} else {
			push @calc_specs, { name => $name, expr => $expr };
			$seen_calc{$name} = $#calc_specs;
		}
	}

	my @window = $extra && $extra->{window_columns}
		? @{ $extra->{window_columns} }
		: _cross_row_aliases(@{ $self->every_param('cs') // [] });
	my @held;

	if (@calc_specs) {
		require Database::BI::Calc;
		for my $cs (@calc_specs) {
			my $name = $cs->{name};
			my $calc = Database::BI::Calc->new(
				expr    => $cs->{expr},
				columns => \@cols,
				params  => $bound_params,
			);
			if ($calc->has_error) {
				# The names of fields already held count too, so that a field
				# can build on one that is waiting.
				my $later = @window && Database::BI::Calc->new(
					expr    => $cs->{expr},
					columns => [ @cols, @window, map { $_->{name} } @held ],
					params  => $bound_params,
				);
				if ($later && !$later->has_error) {
					push @held, { %$cs, params => $bound_params };
					next;
				}
				croak $self->_i18n('error_calc_compile', $name, $calc->error);
			}

			$self->_write_calc_column($records, \@cols, $name, $calc);
		}
	}
	$self->stash('_held_calc_fields' => \@held);

	# Apply named value groups from models.json.
	# For each source column that has groups registered under the current l=
	# spec, add a virtual "${col}_group" column to every row.  Each row's value
	# is mapped to its group label; values not in any group become '(other)'.
	# The spec is the one the stored fields use, so a table page, which names
	# its spec rather than taking l=, shows the column its charts can draw.
	{
		my $spec_key = $date_spec;
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
	# Cwd::realpath on Windows does not follow symlinks: it gives undef for a
	# path through one, which would send the loop below to the link's parent
	# and keep the link's own name.  So the links are followed first.
	if ($^O eq 'MSWin32') {
		my $followed = _follow_links($abs->to_string);
		$abs = Mojo::File->new($followed) if defined $followed;
	}
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

# _follow_links($path) -> $path | undef
#
# Purpose: $path with every symlink in it replaced by what it points at, one
#          component at a time, as realpath does where it can.  For Windows,
#          whose realpath leaves links alone; it works the same anywhere, which
#          is how it is tested.
# Entry:   An absolute path.
# Exit:    The resolved absolute path; undef after 40 links, which is a loop.
sub _follow_links {
	my ($path) = @_;
	my ($vol, $dirs, $file) = File::Spec->splitpath($path);
	my @todo = grep { length } File::Spec->splitdir($dirs), $file;
	my @done;
	my $hops = 0;
	while (@todo) {
		my $part = shift @todo;
		next if $part eq '.';
		if ($part eq '..') { pop @done; next }
		my $here = File::Spec->catpath($vol, File::Spec->catdir(File::Spec->rootdir, @done, $part), '');
		if (-l $here) {
			return undef if ++$hops > 40;
			my $target = readlink $here;
			return undef unless defined $target && length $target;
			# Windows perls can give the NT form of an absolute target,
			# \??\C:\dir, or the long-path form \\?\C:\dir.
			$target =~ s{\A(?:\\\?\?\\|\\\\\?\\)}{};
			my ($tvol, $tdirs, $tfile) = File::Spec->splitpath($target);
			if (File::Spec->file_name_is_absolute($target)) {
				$vol  = $tvol if length $tvol;
				@done = ();
			}
			unshift @todo, grep { length } File::Spec->splitdir($tdirs), $tfile;
			next;
		}
		push @done, $part;
	}
	return File::Spec->catpath($vol, File::Spec->catdir(File::Spec->rootdir, @done), '');
}

# canonical_spec($spec) -> $spec
#
# Purpose: The one spelling of a path: spec that the model store files things
#          under.  /open names its file by its realpath, so a definition saved,
#          or an extract built, under a path reached through a symlink (macOS's
#          /var is /private/var) would never be found by the page it is for.
# Entry:   Any spec, or undef.
# Exit:    path:<realpath> when the spec is path:<file> and the file exists
#          locally; anything else -- another kind of spec, a remote /../host
#          path, a file that is not there, a name with a newline -- unchanged.
sub canonical_spec {
	my ($spec) = @_;
	return $spec unless defined $spec && $spec =~ m{\Apath:(?!/\.\./)([^\n]+)\z};
	my ($path, $internal) = _split_path($1);
	my $tail = defined $internal ? "#$internal" : '';
	# Windows' realpath leaves a symlink as it is, so a file reached through
	# one would be filed under a second key; follow the links first, as
	# _canonical_path does.
	if ($^O eq 'MSWin32') {
		my $followed = eval { _follow_links(Mojo::File->new($path)->to_abs->to_string) };
		$path = $followed if defined $followed;
	}
	return $spec unless -e $path;
	my $real = eval { Mojo::File->new($path)->realpath->to_string };
	return (defined $real && length $real) ? "path:$real$tail" : $spec;
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
	my $scaffold = { version => 1, fields => {}, groups => {}, date_patterns => {}, lookups => {}, extractions => {}, accelerated => {} };
	return $scaffold unless defined $path && -f $path;
	my $json = eval { Mojo::File->new($path)->slurp };
	return $scaffold unless $json && !$@;
	my $data = eval { decode_json($json) };
	return $scaffold unless ref $data eq 'HASH';
	# Callers go straight to ->{fields}{$spec}{$name}, so a hand-edited section of
	# the wrong shape would otherwise be a strict-refs crash on every page.
	for my $section (qw(fields groups date_patterns lookups extractions accelerated)) {
		$data->{$section} = {} unless ref $data->{$section} eq 'HASH';
		my $by_spec = $data->{$section};
		delete @{$by_spec}{ grep { ref $by_spec->{$_} ne 'HASH' } keys %$by_spec };
	}
	_canonical_store_keys($data->{$_}) for grep { ref $data->{$_} eq 'HASH' }
		qw(fields groups date_patterns lookups extractions accelerated geo);
	return $data;
}

# _canonical_store_keys(\%by_spec) -> void
#
# Purpose: File every path: entry of one section of the model store under
#          canonical_spec of its key, so that a reader asking with the resolved
#          spec finds an entry written under a symlinked spelling, by a version
#          before specs were resolved or by hand.  The next write persists it.
# Notes:   A geo key is <spec>|loc=<column>; only the spec part is resolved.
#          When both spellings are present the resolved one's names win.
sub _canonical_store_keys {
	my ($by_spec) = @_;
	for my $key (grep { /\Apath:/ } keys %$by_spec) {
		my ($spec, $rest) = split /\|/, $key, 2;
		my $new = canonical_spec($spec) . (defined $rest ? "|$rest" : '');
		next if $new eq $key;
		my $old = delete $by_spec->{$key};
		my $cur = $by_spec->{$new};
		$by_spec->{$new} = (ref $cur eq 'HASH' && ref $old eq 'HASH') ? { %$old, %$cur } : ($cur // $old);
	}
	return;
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
	$self->_set_aside_corrupt_store($path);
	my $ok = eval { Mojo::File->new($path)->spurt(encode_json($models)); 1 };
	$self->app->log->warn("Cannot write $path: $@") if !$ok && $@;
	return $ok ? 1 : 0;
}

# _set_aside_corrupt_store($self, $path) -> void
#
# Purpose: Keep a store that cannot be parsed from being overwritten.  A reader
#          treats such a file as empty, so without this the next save would
#          replace every saved canvas or model with the one change it carries.
# Entry:   $path is the store about to be written; it need not exist.
# Exit:    A file holding anything but a JSON object is renamed to
#          <path>.corrupt.<time>, for its owner to repair.
#          Only a plain file: a folder (or anything else) of that name is left
#          where it is, and the write then fails as it should.  Linux will not
#          read a folder, but the BSDs read its raw entries, which never parse,
#          so a folder was moved aside there and the write went ahead.
# Side Effects: Renames the file and logs where it went.
sub _set_aside_corrupt_store :Protected ($self, $path) {
	return unless -f $path && -s _;

	my $json = eval { Mojo::File->new($path)->slurp };
	return unless defined $json;
	return if ref(eval { decode_json($json) }) eq 'HASH';

	my $aside = "$path.corrupt." . time();
	if (rename $path, $aside) {
		$self->app->log->error("$path could not be parsed; kept it as $aside");
	} else {
		$self->app->log->error("$path could not be parsed, and could not be kept as $aside: $!");
	}
	return;
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
	my $data_dir = _data_dir_for($app);

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
	return { map { $_ => _tidy_analysis($data->{$_}) } grep { ref $data->{$_} eq 'HASH' } keys %$data };
}

# _tidy_analysis(\%doc) -> \%doc
#
# A stored canvas can hold anything: it may be hand-edited or older than a rule.
# Every page that reads one goes straight to ->{visuals}[0]{encode}{cat}, so the
# shape is put right here, once, and a part of the wrong shape is treated as
# absent: a canvas with one bad part still shows the rest, not a 500.  A visual
# of the wrong shape becomes an empty one rather than going away, because a
# visual's index is its identity in the layout and in /a/:id/visual/:n.
sub _tidy_analysis {
	my $doc = $_[0];

	delete $doc->{$_} for grep { ref $doc->{$_} ne 'ARRAY' } qw(datasets visuals joins measures combines bookmarks layout hierarchies);
	delete $doc->{$_} for grep { ref $doc->{$_} ne 'HASH' } qw(fields params);
	delete $doc->{$_} for grep { ref $doc->{$_} } qw(name updated);

	if ($doc->{datasets}) {
		$doc->{datasets} = [ grep { ref $_ eq 'HASH' && defined $_->{spec} && !ref $_->{spec} } @{ $doc->{datasets} } ];
		for my $ds (@{ $doc->{datasets} }) {
			delete $ds->{filters} if ref $ds->{filters} ne 'ARRAY';
		}
	}
	for my $key (grep { $doc->{$_} } qw(joins layout)) {
		$doc->{$key} = [ grep { ref $_ eq 'HASH' } @{ $doc->{$key} } ];
	}
	if ($doc->{visuals}) {
		$doc->{visuals} = [ map { ref $_ eq 'HASH' ? $_ : {} } @{ $doc->{visuals} } ];
		_tidy_visual($_) for @{ $doc->{visuals} };
	}
	if ($doc->{params}) {
		for my $def (values %{ $doc->{params} }) {
			$def = {} unless ref $def eq 'HASH';
		}
	}
	return $doc;
}

# _tidy_visual(\%visual) -> \%visual
#
# The same for one card, whose parts are read as blindly as the document's.
sub _tidy_visual {
	my $vis = $_[0];

	delete $vis->{$_} for grep { ref $vis->{$_} ne 'HASH' } qw(encode options);
	delete $vis->{filters} if ref $vis->{filters} ne 'ARRAY';
	delete $vis->{$_} for grep { ref $vis->{$_} } qw(kind title);
	return $vis;
}

# _write_analyses($self, \%analyses) -> 1 | 0 | nothing -- atomic write (temp + rename)
# Nothing means the store is switched off (see _analyses_path).
sub _write_analyses :Protected ($self, $analyses) {
	my $path = $self->_analyses_path;
	return unless defined $path;
	$self->_set_aside_corrupt_store($path);
	my $dir = Mojo::File->new($path)->dirname->to_string;
	my ($fh, $tmpfile) = eval { tempfile(DIR => $dir, UNLINK => 0) };
	if ($@ || !$fh) {
		$self->app->log->warn("Cannot create temp file in $dir: " . ($@ // $!));
		return;
	}
	my $ok = eval {
		print {$fh} encode_json($analyses) or croak "print: $!";
		close $fh or croak "close: $!";
		rename($tmpfile, $path) or croak "rename: $!";
		1;
	};
	unless ($ok) {
		$self->app->log->warn("Cannot write $path: $@");
		unlink $tmpfile;
		return 0;
	}
	return 1;
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

# _save_analyses_or_503($self, \%analyses) -> $bool
#
# Writes the store, or answers 503 and returns false, so that no route tells a
# client something was saved when it was not.
sub _save_analyses_or_503 :Protected ($self, $analyses) {
	return 1 if $self->_write_analyses($analyses);

	$self->render(json => { error => _message_text('error_analysis_storage') }, status => 503);
	return 0;
}

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
	for my $required (qw(name datasets)) {
		return "Missing required field: $required" unless defined $doc->{$required};
	}
	return $self->_validate_analysis_parts($doc);
}

# _drop_unknown_keys(\%doc) -> void
#
# Only these keys are ever read back, so anything else a client sends is not kept
# on any write: the POD promises this, and a store should not grow what nothing uses.
sub _drop_unknown_keys {
	my $doc = $_[0];

	delete @{$doc}{ grep { !$ANALYSIS_KEYS{$_} } keys %$doc };
}

# _validate_analysis_parts($self, \%doc) -> $error_string_or_undef
#
# Checks only the keys present, which is all a PATCH may be judged on.  This body
# is whatever a client sent, so nothing about the shape of a value is assumed.
sub _validate_analysis_parts :Protected ($self, $doc) {
	if (exists $doc->{name}) {
		return 'Missing required field: name'
			unless defined $doc->{name} && !ref $doc->{name} && length $doc->{name};
	}
	if (exists $doc->{datasets}) {
		return 'Missing required field: datasets'
			unless ref $doc->{datasets} eq 'ARRAY' && @{ $doc->{datasets} };
		for my $ds (@{ $doc->{datasets} }) {
			return 'Each dataset entry must have a spec field'
				unless ref $ds eq 'HASH' && defined $ds->{spec} && !ref $ds->{spec} && length $ds->{spec};
			return qq{"$ds->{spec}" is not a valid spec (must start with table:, path:, url:, or redis:, or be mariadb:server/table)}
				unless $ds->{spec} =~ m{\A(?:table:|path:|url:|redis:)} || $ds->{spec} =~ $MARIADB_SPEC_RE;
		}
	}
	if (defined $doc->{version}) {
		return sprintf(_message_text('error_analysis_version'), $doc->{version})
			unless !ref $doc->{version} && $doc->{version} =~ /\A\d+\z/ && $doc->{version} <= 1;
	}
	for my $key (qw( visuals joins measures combines bookmarks layout hierarchies )) {
		if (defined $doc->{$key}) {
			return "$key must be an array"
				unless ref $doc->{$key} eq 'ARRAY';
		}
	}
	for my $key (qw( visuals joins )) {
		next unless defined $doc->{$key};
		return "Each entry in $key must be an object"
			if grep { ref $_ ne 'HASH' } @{ $doc->{$key} };
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
		next unless ref $j eq 'HASH';
		my $right_spec = $spec_by_alias{ $j->{right} // '' } // '';
		next unless $right_spec;
		push @params, 'j=' . url_escape(
			join('|', $right_spec, $j->{left_key}//'', $j->{right_key}//'')
		);
	}

	# Filters from all datasets
	for my $ds (@datasets) {
		next unless ref $ds->{filters} eq 'ARRAY';
		for my $f (@{ $ds->{filters} }) {
			push @params, 'f=' . url_escape(encode('UTF-8', $f));
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
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf(_message_text('error_analysis_invalid'), $err) }, status => 400)
		if $err;

	my $analyses = $self->_read_analyses;
	unless ($self->_analyses_path) {
		return $self->render(json => { error => _message_text('error_analysis_storage') }, status => 503);
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
	_drop_unknown_keys($body);

	$analyses->{$id} = $body;
	$self->_save_analyses_or_503($analyses) or return;

	$self->res->headers->location("/api/analyses/$id");
	$self->render(json => { id => $id, created => 1 }, status => 201);
}

# GET /api/analyses/:id
sub analyses_get ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};

	$self->render(json => $analyses->{$id});
}

# PUT /api/analyses/:id  (full replace)
sub analyses_update ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf(_message_text('error_analysis_invalid'), $err) }, status => 400)
		if $err;

	_drop_unknown_keys($body);
	$body->{id}      = $id;
	$body->{version} //= 1;
	$body->{created} = $analyses->{$id}{created} // time();
	$body->{updated} = time();

	$analyses->{$id} = $body;
	$self->_save_analyses_or_503($analyses) or return;

	$self->render(json => { id => $id, updated => 1 });
}

# PATCH /api/analyses/:id  (partial update -- merges supplied keys)
sub analyses_patch ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	# Only the keys actually supplied are validated here: the canvas PATCHes
	# nothing but the layout (a drag) or the bookmarks, and a document that
	# fails on some other field it never mentioned is not this request's fault.
	my $perr = $self->_validate_analysis_parts($body);
	return $self->render(json => { error => sprintf(_message_text('error_analysis_invalid'), $perr) }, status => 400)
		if $perr;

	_drop_unknown_keys($body);
	my $existing = { %{ $analyses->{$id} } };
	for my $key (keys %$body) {
		next if $key eq 'id' || $key eq 'created';  # immutable
		$existing->{$key} = $body->{$key};
	}
	$existing->{updated} = time();

	$analyses->{$id} = $existing;
	$self->_save_analyses_or_503($analyses) or return;

	$self->render(json => { id => $id, updated => 1 });
}

# DELETE /api/analyses/:id
sub analyses_delete ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};

	delete $analyses->{$id};
	$self->_save_analyses_or_503($analyses) or return;

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
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	my $kind = $body->{kind} // '';
	my %supported = map { $_ => 1 }
		qw( table bar pie line graph scatter heatmap stacked combo treemap histogram map wordcloud text );
	return $self->render(json => { error => 'Unsupported visual kind' }, status => 400)
		unless $supported{$kind};

	for my $key (qw( encode options cross_row )) {
		return $self->render(json => { error => "$key must be an object" }, status => 400)
			if defined $body->{$key} && ref $body->{$key} ne 'HASH';
	}

	# A text card reads no data, so it can be added whatever state the canvas's
	# source is in.
	if ($kind eq 'text') {
		my ($options, $errors) = _text_card_options($body->{options});
		return $self->render(json => { error => $errors->[0] }, status => 400) if @$errors;

		my $vis = { kind => 'text', encode => {}, options => $options };
		$vis->{title} = $body->{title}
			if defined $body->{title} && !ref $body->{title} && length $body->{title};

		my $index = scalar @{ $a->{visuals} // [] };
		push @{ $a->{visuals} //= [] }, $vis;
		$a->{updated} = time();
		$self->_save_analyses_or_503($analyses) or return;

		return $self->render(json => _text_card_reply($id, $index, $vis), status => 201);
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
	my $ctx = $self->_canvas_render_context($a, $body->{query}, [$vis]);
	return $self->render(json => { error => $ctx->{error} }, status => $ctx->{status})
		if $ctx->{error};

	# The new card is never the cross-filter source: it did not exist when the
	# filter was made, so every cf applies to it, as it does to every card but
	# the source.
	my ($records, $late_cf) = $self->_canvas_cross_filter($ctx->{records}, $ctx->{columns}, $ctx->{cf_specs});

	# The index is known before the render, so the card's SVG and Leaflet ids
	# match the ones a later page load will give it.
	my $index = scalar @{ $a->{visuals} // [] };

	my $rendered = $self->_render_visual_html(
		$vis, $records, $ctx->{columns}, $ctx->{src}, $index, $ctx->{spec_key},
		(@{ $ctx->{cf_specs} } ? 1 : 0),
		$ctx->{cross_row},
		$late_cf,
	);
	return $self->render(json => { error => $rendered->{error} }, status => 400)
		if $rendered->{error};

	push @{ $a->{visuals} //= [] }, $vis;
	$a->{updated} = time();
	$self->_save_analyses_or_503($analyses) or return;

	return $self->render(
		json   => {
			id     => $id,
			visual => $index,
			kind   => $kind,
			title  => ($vis->{title} // $rendered->{title} // 'Visual ' . ($index + 1)),
			html   => $rendered->{html},
			head   => ($rendered->{head} // ''),
			# The nonce the card's scripts were written with: the page runs
			# only those that carry it (runCardScripts in canvas.html.tt).
			nonce  => $self->csp_nonce,
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
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my $index = $self->stash('visual') // '';
	return $self->render(json => { error => 'Visual index must be a number' }, status => 400)
		unless $index =~ /\A\d+\z/;
	$index += 0;
	return $self->render(json => { error => "No visual at index $index" }, status => 404)
		unless $index < scalar @{ $a->{visuals} // [] };

	my $body = eval { decode_json($self->req->body) };
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	# A text card's only settings are its options, and it reads no data.
	if (($a->{visuals}[$index]{kind} // '') eq 'text') {
		return $self->render(json => { error => _message_text('error_text_card_columns') }, status => 400)
			if exists $body->{encode} || exists $body->{cross_row};
		return $self->render(json => { error => _message_text('error_text_card_options') }, status => 400)
			unless ref $body->{options} eq 'HASH';

		my ($options, $errors) = _text_card_options($body->{options});
		return $self->render(json => { error => $errors->[0] }, status => 400) if @$errors;

		my $vis = { %{ $a->{visuals}[$index] }, options => $options };
		$a->{visuals}[$index] = $vis;
		$a->{updated} = time();
		$self->_save_analyses_or_503($analyses) or return;

		return $self->render(json => _text_card_reply($id, $index, $vis));
	}

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

	my $ctx = $self->_canvas_render_context($a, $body->{query}, [$vis]);
	return $self->render(json => { error => $ctx->{error} }, status => $ctx->{status})
		if $ctx->{error};

	# The card is drawn as it is on this page: a cross-filter applies to every
	# card but the one that made it, and this card may be that one.
	my $records      = $ctx->{records};
	my $prefiltered  = 0;
	my $late_cf      = [];
	if (@{ $ctx->{cf_specs} } && $ctx->{cf_source} != $index) {
		($records, $late_cf) = $self->_canvas_cross_filter($records, $ctx->{columns}, $ctx->{cf_specs});
		$prefiltered = 1;
	}

	my $rendered = $self->_render_visual_html(
		$vis, $records, $ctx->{columns}, $ctx->{src}, $index, $ctx->{spec_key},
		$prefiltered,
		$ctx->{cross_row},
		$late_cf,
	);
	return $self->render(json => { error => $rendered->{error} }, status => 400)
		if $rendered->{error};

	$a->{visuals}[$index] = $vis;
	$a->{updated} = time();
	$self->_save_analyses_or_503($analyses) or return;

	return $self->render(
		json => {
			id     => $id,
			visual => $index,
			kind   => ($vis->{kind} // ''),
			title  => ($vis->{title} // $rendered->{title} // 'Visual ' . ($index + 1)),
			html   => $rendered->{html},
			head   => ($rendered->{head} // ''),
			# The nonce the card's scripts were written with: the page runs
			# only those that carry it (runCardScripts in canvas.html.tt).
			nonce  => $self->csp_nonce,
			cf_col => (_vis_cf_col($vis) // ''),
		},
	);
}

# DELETE /api/analyses/:id/visuals/:visual  (remove a text card)
#
# A visual's index is its identity in the layout and in a cross-filter's cv=, so
# everything that names a later card moves down by one with it.  The page reloads
# afterwards, because the cards on screen carry the old numbers.
sub analyses_delete_visual ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my $index = $self->stash('visual') // '';
	return $self->render(json => { error => 'Visual index must be a number' }, status => 400)
		unless $index =~ /\A\d+\z/;
	$index += 0;
	return $self->render(json => { error => "No visual at index $index" }, status => 404)
		unless $index < scalar @{ $a->{visuals} // [] };
	return $self->render(json => { error => _message_text('error_visual_not_text') }, status => 400)
		unless ($a->{visuals}[$index]{kind} // '') eq 'text';

	$a->{visuals} = [ @{ $a->{visuals} }[ grep { $_ != $index } 0 .. $#{ $a->{visuals} } ] ];

	my @layout;
	for my $entry (@{ $a->{layout} // [] }) {
		my $n = $entry->{visual} // '';
		if ($n =~ /\A\d+\z/) {
			next if $n == $index;
			$entry = { %$entry, visual => $n - 1 } if $n > $index;
		}
		push @layout, $entry;
	}
	$a->{layout} = \@layout if $a->{layout};

	for my $bm (grep { ref $_ eq 'HASH' && defined $_->{state} && !ref $_->{state} } @{ $a->{bookmarks} // [] }) {
		$bm->{state} = _shift_card_param($bm->{state}, $index);
	}

	$a->{updated} = time();
	$self->_save_analyses_or_503($analyses) or return;

	return $self->render(json => { deleted => 1 });
}

# _shift_card_param($search, $removed) -> $search
#
# A saved query string with its cv= moved down if the card it names came after
# the one removed.  The canvas never makes a text card a cross-filter's source,
# but a bookmark is stored as PATCHed, so a cv= naming the removed card is
# dropped: kept, it would name the card that moved into its place.  A cv= of
# more than nine digits names no card (_cross_filter_source), so it is left
# as it is: arithmetic on it came back as cv=1e+20.  A search or index that is
# not one is returned unchanged.
sub _shift_card_param {
	my ($search, $removed) = @_;
	return $search unless defined($search) && !ref($search)
		&& defined($removed) && !ref($removed) && $removed =~ /\A[0-9]{1,9}\z/;
	$search =~ s{(?<![^?&])cv=(\d+)(&?)}{
		length($1) > 9 ? "cv=$1$2"
			: $1 == $removed ? ''
			: ('cv=' . ($1 > $removed ? $1 - 1 : $1) . $2)
	}ge;
	$search =~ s{&\z}{};
	return $search;
}

# _text_card_options($raw) -> (\%options, \@errors)
#
# Purpose: The one reader of a text card's settings.
# Entry:   Whatever is stored or was sent; it may be any shape.
# Exit:    The settings that are allowed, each in its one spelling, and a message
#          for each that was not.  Settings not asked for are absent.
# Notes:   A write refuses a card with errors.  A render ignores them and draws
#          what is left, because PUT, PATCH and import can store a card that
#          never came through here, and nothing else stands between a stored
#          value and a style attribute.
sub _text_card_options {
	my ($raw) = @_;
	$raw = {} unless ref $raw eq 'HASH';

	my (%clean, @errors);

	my $text = (defined $raw->{text} && !ref $raw->{text}) ? $raw->{text} : '';
	$text =~ s/\r\n?/\n/g;
	if ($text !~ /\S/) {
		push @errors, _message_text('error_text_card_empty');
	}
	elsif (length($text) > $MAX_TEXT_CHARS) {
		push @errors, sprintf(_message_text('error_text_card_long'), $MAX_TEXT_CHARS);
	}
	$clean{text} = $text;

	if (length(my $font = $raw->{font} // '')) {
		if (!ref $font && exists $TEXT_FONT_CSS{$font}) { $clean{font} = $font }
		else { push @errors, _message_text('error_text_card_font') }
	}

	if (length(my $size = $raw->{size} // '')) {
		if (!ref $size && $size =~ /\A\d{1,3}\z/ && $size >= $MIN_TEXT_POINTS && $size <= $MAX_TEXT_POINTS) {
			$clean{size} = $size + 0;
		}
		else {
			push @errors, sprintf(_message_text('error_text_card_size'), $MIN_TEXT_POINTS, $MAX_TEXT_POINTS);
		}
	}

	for my $key (qw(colour background)) {
		my $value = $raw->{$key} // '';
		next unless length $value;
		if (!ref $value && $value =~ /\A#[0-9a-fA-F]{6}\z/) { $clean{$key} = lc $value }
		else { push @errors, _message_text('error_text_card_colour') }
	}

	if (length(my $align = $raw->{align} // '')) {
		if (!ref $align && $TEXT_ALIGNS{$align}) { $clean{align} = $align }
		else { push @errors, _message_text('error_text_card_align') }
	}

	for my $key (qw(bold italic plain)) {
		$clean{$key} = 1 if $raw->{$key};
	}

	return (\%clean, \@errors);
}

# _text_card_markup(\%visual) -> $html
#
# The body of a text card.  The text is escaped and the style holds only values
# _text_card_options has checked.  Spaces and line ends are written as entities
# and <br>, not left to CSS, because the response minifier collapses whitespace
# and the embed page has none of this page's styles.
sub _text_card_markup {
	my ($vis) = @_;
	my ($o) = _text_card_options($vis->{options});

	my @style;
	push @style, "font-family:$TEXT_FONT_CSS{$o->{font}}" if $o->{font};
	push @style, "font-size:$o->{size}pt"                 if $o->{size};
	push @style, "color:$o->{colour}"                     if $o->{colour};
	push @style, "background-color:$o->{background}"      if $o->{background};
	push @style, 'font-weight:bold'                       if $o->{bold};
	push @style, 'font-style:italic'                      if $o->{italic};
	push @style, "text-align:$o->{align}"                 if $o->{align};
	my $style = @style ? ' style="' . xml_escape(join ';', @style) . '"' : '';

	my $text = xml_escape($o->{text});
	$text =~ s/\t/    /g;
	$text =~ s/^ /&#160;/mg;
	$text =~ s/ (?= )/&#160;/g;
	$text =~ s/\n/<br>/g;

	return qq{<div class="text-card-text"$style>$text</div>};
}

# _text_card_title(\%visual) -> $title
#
# What names a text card to the controls on it and to a screen reader: the start
# of its first line that has anything on it.
sub _text_card_title {
	my ($vis) = @_;
	my ($o) = _text_card_options($vis->{options});
	my ($line) = $o->{text} =~ /^[ \t]*(\S[^\n]*)/m;
	return 'Text' unless defined $line;
	$line =~ s/\s+\z//;
	return length($line) > $TEXT_TITLE_CHARS ? substr($line, 0, $TEXT_TITLE_CHARS) . '...' : $line;
}

# _text_card_plain(\%visual) -> $bool
#
# Whether the card hides its frame and header until it is pointed at.
sub _text_card_plain {
	my ($vis) = @_;
	return 0 unless ($vis->{kind} // '') eq 'text';
	my ($o) = _text_card_options($vis->{options});
	return $o->{plain} ? 1 : 0;
}

# _text_card_reply($id, $index, \%visual) -> \%json
sub _text_card_reply {
	my ($id, $index, $vis) = @_;
	return {
		id     => $id,
		visual => $index,
		kind   => 'text',
		title  => ($vis->{title} // _text_card_title($vis)),
		html   => _text_card_markup($vis),
		head   => '',
		cf_col => '',
		plain  => _text_card_plain($vis),
	};
}

# GET /api/analyses/:id/export
sub analyses_export ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
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
	return $self->render(json => { error => _analysis_json_error($@) }, status => 400)
		unless ref $body eq 'HASH';

	# Strip any id/timestamps from imported document; assign fresh ones below
	delete @{$body}{qw( id created updated )};
	_drop_unknown_keys($body);

	my $err = $self->_validate_analysis($body);
	return $self->render(json => { error => sprintf(_message_text('error_analysis_invalid'), $err) }, status => 400)
		if $err;

	unless ($self->_analyses_path) {
		return $self->render(json => { error => _message_text('error_analysis_storage') }, status => 503);
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
	$self->_save_analyses_or_503($analyses) or return;

	$self->res->headers->location("/api/analyses/$id");
	$self->render(json => { id => $id, imported => 1 }, status => 201);
}

# _cross_filter_source($cv) -> Int
#
# The index of the card a cross-filter came from (cv=), or -1 for none.  Only
# a whole number names a card: int('abc') is 0, which would draw the first
# card unfiltered as if it were the source.
sub _cross_filter_source {
	my $cv = shift;
	return (defined($cv) && $cv =~ /\A[0-9]{1,9}\z/) ? int($cv) : -1;
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
sub _canvas_render_context :Protected ($self, $a, $query, $more_cards = undef) {
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

	my $window_names = _canvas_window_columns($a, $params || Mojo::Parameters->new, $more_cards);
	$self->stash('_canvas_window_names' => $window_names);

	eval {
		($records, $columns) = $self->_apply_calc_fields(
			$records, $columns,
			{
				params   => \%param_values,
				spec_key => ($a->{datasets}[0]{spec} // ''),
				calc     => [ $params ? @{ $params->every_param('c') // [] } : () ],
				window_columns => $window_names,
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
	my $cf_source = _cross_filter_source($params ? $params->param('cv') : undef);

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
sub _render_visual_html :Protected ($self, $vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row = undef, $late_cf = undef) {
	my $rendered = $self->_render_visual_markup(
		$vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row, $late_cf,
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
# that saved a plan of its own uses that one instead.  $late_cf holds the
# cross-filter specs on columns a plan writes (_canvas_cross_filter); a card
# whose plan does not write the column has nothing to filter by, and ignores it.
sub _render_visual_markup :Protected ($self, $vis, $records, $columns, $src, $vis_id, $spec_key, $prefiltered, $cross_row = undef, $late_cf = undef) {
	my $kind    = $vis->{kind}    // '';
	return { html => _text_card_markup($vis), title => _text_card_title($vis) }
		if $kind eq 'text';

	# A stored card is not checked part by part (PUT and import keep a visual
	# as sent), so a part of the wrong shape is read as absent here rather than
	# dereferenced.
	my $encode  = ref($vis->{encode})  eq 'HASH'  ? $vis->{encode}  : {};
	my $options = ref($vis->{options}) eq 'HASH'  ? $vis->{options} : {};
	my $filters = ref($vis->{filters}) eq 'ARRAY' ? [ grep { defined && !ref } @{ $vis->{filters} } ] : [];
	my $title   = $vis->{title}   // '';

	# Every chart on a canvas needs an element id of its own: HTML::D3 names the
	# SVG after the chart kind by default, so two bar cards both write #bar_chart
	# and the second card's script draws into the first.  The id carries the
	# visual's index, which is stable across renders, so a saved canvas and a
	# card appended in place agree; the chart pages render one chart and keep
	# HTML::D3's default.
	my $svg_id = 'vis-' . (defined($vis_id) ? $vis_id : 'chart');

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

	# Apply per-visual filters on top of the base pipeline records.  One on a column
	# this card's plan writes waits for the pass, as it does on a table page.
	my %written = $plan
		? (map({ $_->{as} => 1 } @{ $plan->{specs} }),
			map({ $_->{name} => 1 } @{ $self->stash('_held_calc_fields') // [] }))
		: ();
	my $vis_recs = $records;
	my @late_filters;
	for my $f (@$filters) {
		if ($written{ (split /:/, $f, 2)[0] // '' }) {
			push @late_filters, $f;
			next;
		}
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
	if ($plan) {
		# The pass writes its column onto the rows it is handed, and a card is
		# handed the canvas's rows -- the same hashrefs every card draws from.  The
		# numbers a pass produces are that card's, so it runs on copies: without
		# them one card's running total is written into its neighbour's rows, and a
		# card that asked for no plan at all reads a column it never asked for.
		my $own = [ map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$vis_recs ];
		my ($crossed, $crossed_cols) = eval {
			my ($r, $c) = $self->_apply_cross_row($own, $columns, $plan);
			$self->_apply_held_calc_fields($r, $c, 1);
		};
		if (my $e = $@) {
			$e =~ s/ at \S+ line \d+\.?\n?$//;
			return { error => $e };
		}
		($vis_recs, $columns) = ($crossed, $crossed_cols);
	}

	my %col_set = map { $_ => 1 } @$columns;

	$vis_recs = _apply_filter_spec($vis_recs, $_)
		for @late_filters, grep { $col_set{ (split /:/, $_, 2)[0] // '' } } @{ $late_cf // [] };

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
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
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
		my $scheme = _categorical_scheme($options->{scheme});
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
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

		# encode.series is what /graph's "Add to canvas" saves from series=: one
		# line per value of that column, as on the page.  Without it every row
		# is one line, which runs through all the groups' points in turn.
		my $series_col = $encode->{series} // '';
		$series_col = '' if ref $series_col;
		return { error => "Column not found: $series_col" }
			if length $series_col && !$col_set{$series_col};

		# A card whose spec names a measure plots one point per x value rather
		# than one per row: the shape /graph?agg= draws, and the only shape that
		# makes sense when the x axis is a bucket.  The fold writes its result
		# back under the y column's own name, so the loop below is the same one
		# an unaggregated card runs, and the groups arrive in label order, which
		# for an ISO bucket is chronological order.  With a series the fold is
		# per x value and series value, so each line has its own totals.
		my $rows = $vis_recs;
		my $m;
		if (defined $agg_fn) {
			$m = _visual_measure($agg_fn, $y_col);
			return { error => $m->{error} } if $m->{error};
			my $agg = $self->_grouped_totals(
				{ source => undef, records => $vis_recs },
				{ by  => [ $x_col, (length $series_col ? $series_col : ()) ],
				  fn  => $m->{fn}, val => $m->{val}, as => 'value' },
			);
			$rows = [ map { { %$_, $y_col => $_->{value} } } @$agg ];
		}

		my $sn;
		if (length $series_col) {
			# The order /graph draws, so each line has the page's colour:
			# aggregated, lines by name and points by label; unaggregated, lines
			# as first met and each keeping its rows' order.
			my (%points_of, @names);
			for my $row (@$rows) {
				my $xv   = $row->{$x_col}      // ''; next unless length $xv;
				my $name = $row->{$series_col} // ''; next unless length $name;
				my $yn   = _numeric_cell($row->{$y_col} // ''); next unless defined $yn;
				$name = _decode_cell($name);
				push @names, $name unless $points_of{$name};
				push @{ $points_of{$name} }, { label => _decode_cell($xv), value => $yn };
			}
			return { error => 'No plottable data' } unless @names;
			my @series_data = map {
				my $points = $points_of{$_};
				$points = [ sort { $a->{label} cmp $b->{label} } @$points ] if $m;
				{ name => $_, data => $points };
			} ($m ? sort @names : @names);

			$title ||= $m ? "$m->{label} by $x_col and $series_col" : "$y_col vs $x_col by $series_col";
			$sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
				->render_multi_series_line_chart_snippet(\@series_data, { id => $svg_id });
		} else {
			my @pairs;
			for my $row (@$rows) {
				my $xv = $row->{$x_col} // ''; next unless length $xv;
				my $yn = _numeric_cell($row->{$y_col} // ''); next unless defined $yn;
				push @pairs, [_decode_cell($xv), $yn];
			}
			return { error => 'No plottable data' } unless @pairs;

			$title ||= $m ? "$m->{label} by $x_col" : "$y_col vs $x_col";
			$sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
				->render_zoomable_line_chart_snippet(\@pairs, { id => $svg_id });
		}
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

		# series and size are what /scatter's "Add to canvas" saves from series=
		# and size=; scheme, min_r and max_r come with them in options.  A
		# canvas stores a visual unchecked (PUT, PATCH, import), so the scheme
		# goes through _categorical_scheme -- HTML::D3 writes it into the script
		# -- and an unknown one draws the default colours, as on a pie card.
		my $series_col = $encode->{series} // '';
		my $size_col   = $encode->{size}   // '';
		$series_col = '' if ref $series_col;
		$size_col   = '' if ref $size_col;
		return { error => "Column not found: $series_col" }
			if length $series_col && !$col_set{$series_col};
		return { error => "Column not found: $size_col" }
			if length $size_col && !$col_set{$size_col};

		my @points;
		for my $row (@$vis_recs) {
			my $xv = _numeric_cell($row->{$x_col} // ''); next unless defined $xv;
			my $yv = _numeric_cell($row->{$y_col} // ''); next unless defined $yv;
			my %meta;
			$meta{series} = _decode_cell($row->{$series_col} // '') if length $series_col;
			if (length $size_col) {
				my $sv = _numeric_cell($row->{$size_col} // '');
				$meta{size} = $sv if defined $sv;
			}
			push @points, [$xv, $yv, {}, (%meta ? \%meta : ())];
		}
		return { error => 'No plottable data' } unless @points;

		$title ||= "$y_col vs $x_col";
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
			->render_scatter_chart_snippet(\@points, {
				x_label => $x_col,
				y_label => $y_col,
				id      => $svg_id,
				(length $series_col
					? (colour_by_series => 1, series_col => $series_col,
					   scheme => _categorical_scheme($options->{scheme}))
					: ()),
				(length $size_col
					? (size_col => $size_col,
					   radius_range => [ _scatter_radii($options->{min_r}, $options->{max_r}) ])
					: ()),
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
		my $scheme = _sequential_scheme($options->{scheme});
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
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
		my $scheme = _categorical_scheme($options->{scheme});
		my $orient = (_chart_orientation($options) eq 'horizontal') ? 'h' : 'v';
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
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
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
			->render_combo_snippet(\@data, {
				bar_label  => $bar_col,
				line_label => $line_col,
				id         => $svg_id,
				# What /combo saves from scheme=, checked again: a canvas stores it
				# unchecked.
				(_optional_scheme($options->{scheme}) ? (scheme => $options->{scheme}) : ()),
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

		# encode.color and options.color_agg / color_scheme are what /treemap
		# saves from color=, color_agg= and color_scheme=.  The function is
		# checked by _tile_colour_measure, as the page's is; the scheme falls back as the
		# heatmap's does, since HTML::D3 refuses a name it does not know.
		my $color_col = $encode->{color} // '';
		$color_col = '' if ref $color_col;
		my $color_m;
		if (length $color_col) {
			return { error => "Column not found: $color_col" } unless $col_set{$color_col};
			$color_m = $self->_tile_colour_measure($options->{color_agg}, $color_col);
			return { error => $color_m->{error} } if $color_m->{error};
		}

		my $agg = $self->_grouped_totals(
			{ source => $agg_src, records => $vis_recs },
			{ by  => [$cat_col],
			  fn  => $m->{fn},
			  val => $m->{val},
			  as  => 'value' },
		);
		return { error => 'No plottable data' } unless @$agg;
		my $colour_of = $color_m
			? $self->_tile_colours($agg_src, $vis_recs, $cat_col, $color_m)
			: {};

		$title ||= "$m->{label} by $cat_col" . ($color_m ? " coloured by $color_m->{label}" : q{});
		my $scheme = _categorical_scheme($options->{scheme});
		# The snippet takes one row per tile as { path, value }, the shape the
		# treemap page builds; a [label, value] pair is not a path and croaks.
		my @tiles = map {
			my $cv = $colour_of->{ $_->{$cat_col} // '' };
			+{ path => 'Root/' . _decode_cell($_->{$cat_col}), value => $_->{value},
			   (defined $cv ? (color_value => $cv) : ()) }
		} @$agg;
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
			->render_treemap_snippet(\@tiles, {
				scheme => $scheme,
				id     => $svg_id,
				($color_m
					? (color_scheme => _sequential_scheme($options->{color_scheme}),
					   color_label  => $color_m->{label})
					: ()),
			});
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

		my $bins = _whole_number($options->{bins}) // 10;
		$bins = 1   if $bins < 1;
		$bins = $MAX_HISTOGRAM_BINS if $bins > $MAX_HISTOGRAM_BINS;
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
		my $sn = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 480, height => 320, responsive => 1)
			->render_histogram_snippet(\@bin_data, {
				binned  => 1,
				x_label => $col,
				id      => $svg_id,
				# What /histogram saves from scheme=.  Stored unchecked, so it
				# goes through the same check as the page's.
				(_optional_scheme($options->{scheme}) ? (scheme => $options->{scheme}) : ()),
			});
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
		my $def     = ref $param_defs{$pname} eq 'HASH' ? $param_defs{$pname} : {};
		my $type    = $def->{type}    // 'string';
		my $default = $def->{default} // '';
		my $raw     = $lookup->("p.$pname");
		my $val     = defined $raw ? $raw : $default;

		if ($type eq 'number') {
			require Scalar::Util;
			# looks_like_number accepts these, and every comparison with NaN is
			# false, so it would walk straight past min and max below.
			unless (Scalar::Util::looks_like_number($val) && $val !~ /\A\s*[-+]?(?:nan|inf)/i) {
				push @errors, sprintf(_message_text('error_param_type'), $pname);
				next;
			}
			$val = $val + 0;
			my ($lo, $hi) = ($def->{min}, $def->{max});
			if (defined $lo && $val < $lo) {
				push @errors, sprintf(_message_text('error_param_range'),
					$pname, $lo, defined $hi ? $hi : '+inf');
				next;
			}
			if (defined $hi && $val > $hi) {
				push @errors, sprintf(_message_text('error_param_range'),
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
	return $self->render(text => _message_text('error_analysis_id_invalid'), status => 400)
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
			error_msg   => sprintf(_message_text('error_analysis_not_found'), $id),
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
			$freshness_msg   = _message_text('freshness_stale_msg');
			require POSIX;
			$freshness_source_mtime = Database::BI::Util::minute_stamp(gmtime($newest_src_mtime)) . ' UTC';
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
		my $window_names    = _canvas_window_columns($a, $self);
		$self->stash('_canvas_window_names' => $window_names);
		eval {
			($records, $columns) = $self->_apply_calc_fields(
				$records, $columns,
				{
					params         => \%bound_params,
					spec_key       => $canvas_spec_key,
					window_columns => $window_names,
				}
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
		my $cf_source = _cross_filter_source($self->param('cv'));
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
					$base .= $sep . 'f=' . url_escape(encode('UTF-8', $cf));
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
			my $late_cf  = [];
			if ($cf_active && $i != $cf_source) {
				($vis_recs, $late_cf) = $self->_canvas_cross_filter($records, $columns, \@cf_specs);
			}

			my $result = $self->_render_visual_html(
				$vis, $vis_recs, $columns, $src, $i, $canvas_spec_key,
				($cf_active && $i != $cf_source ? 1 : 0),
				$cross_row,
				$late_cf,
			);
			$canvas_map_head ||= $result->{head} // '';
			push @rendered, {
				id        => $i,
				title     => ($vis->{title} // $result->{title} // ('Visual ' . ($i + 1))),
				html      => $result->{html}  // '',
				error     => $result->{error} // '',
				kind      => $vis->{kind}     // '',
				plain     => _text_card_plain($vis),
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
			# The other sites the Share panel's embed code works on.
			embed_origins => [ Database::BI::_embed_frame_ancestors($self->app->config) ],
			canvas_data_url  => ($self->_analysis_to_url($a) // ''),
			canvas_columns_json => $canvas_columns_json,
			canvas_page_aliases_json => $canvas_page_aliases_json,
			# The same menu the table page's cross-row panel renders, so a card
			# can offer the functions the pass actually knows.
			cross_row_menu => \@CROSS_ROW_MENU,
			text_font_menu => \@TEXT_FONTS,
			text_min_points => $MIN_TEXT_POINTS,
			text_max_points => $MAX_TEXT_POINTS,
			text_max_chars  => $MAX_TEXT_CHARS,
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
	# The stash says the reply has gone.  Without it the caller takes the empty list
	# for "no such table" and renders a second time, and the client is left hanging
	# on a reply that never finishes.
	if ($span && $span->{error}) {
		$self->stash('_reduce_error' => 1);
		$self->render(text => $span->{error}, status => 400);
		return ();
	}

	eval { ($records, $columns) = $self->_apply_calc_fields($records, $columns,
		($span ? { calc => $span->{calc} } : undef)) };
	if ($@) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		$self->stash('_reduce_error' => 1);
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
		# By the same rule as the table pages (_sort_records returns a new
		# array: the backend's own can be read-only, as a SQLite one is).
		$records = _sort_records($records, $sort, $dir);
		$self->stash(sorted_by => { col => $sort, dir => $dir });
	} elsif (defined $sort) {
		carp $self->_i18n('error_sort_column', $sort);
	}

	# Server-side pagination for /export.
	if (defined $self->param('page') || defined $self->param('per_page')) {
		my ($page, $per_page, $offset) = $self->_pagination;
		my $total    = scalar @$records;
		my $has_next = ($total > $offset + $per_page) ? 1 : 0;
		my @page_recs = @{ _rows_of_page($records, $offset, $per_page) };
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
	my $data = eval { $self->_write_sqlite_db($records, $columns) };
	unless (defined $data) {
		$self->app->log->error('SQLite export failed: ' . _tidy_error($@));
		return $self->render(text => $self->_i18n('error_export_sqlite'), status => 500);
	}
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

None (reads C<data_dir> from application config, and C<BI_OPEN> and the
C<Referer> header).

=head4 OUTPUT

When C<BI_OPEN> is set and the request has no C<Referer> from this server,
redirects to C</open> for that path.  Otherwise renders C<home.html.tt> with:

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

  With BI_OPEN=/data/store.db and no Referer from this server:
  GET / -> 302 /open?path=%2Fdata%2Fstore.db

=cut

sub index ($self) {
	# A database named when the server was started is what a reader arriving
	# from outside sees first.  A Home link within the application carries this
	# server as its Referer and gets the list, so that stays reachable.  The
	# check needs no state, so it survives morbo restarting the application.
	if (defined $ENV{BI_OPEN} && length $ENV{BI_OPEN}) {
		my $from = $self->req->headers->referrer;
		my $here = $self->req->url->to_abs->host_port;
		return $self->redirect_to('/open?path=' . url_escape($ENV{BI_OPEN}))
			unless defined $from && (Mojo::URL->new($from)->host_port // '') eq $here;
	}

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

=head2 is_supported_file

Say whether a file's name has an extension C</open> will read.  C<script/database-bi>
asks this to refuse a file before the server starts, rather than show a 404.

=head3 API SPECIFICATION

=head4 INPUT

  $path  string, a file name or path; undef is allowed

=head4 OUTPUT

  1 when the name ends in a supported extension (any case), otherwise 0

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

  is_supported_file == lambda path . path =~ EXT_RE

=head3 EXAMPLE

  is_supported_file('data/store.db')   # 1
  is_supported_file('LICENSE')         # 0

=cut

sub is_supported_file ($path) {
	return (defined $path && $path =~ $EXT_RE) ? 1 : 0;
}

=head2 require_login / login_form / login / logout

The login, on only when config C<password_hash> is set (see
L<Database::BI/Logging in>).  C<require_login> is the C<under> every route but
C</login>, C</logout>, C</share/:id> and C</embed/:id> passes through; the
others are C<GET /login>, C<POST /login> and C<POST /logout>.

A session is logged in when its C<login> value is this password's mark (an
HMAC of the hash, keyed by the first secret), so a new password logs every
session out.  Wrong passwords are counted per remote address, in each server
process: the tenth within 15 minutes locks that address out for the rest of
the 15 minutes (C<429>), whether or not the next one is right.

=head3 API SPECIFICATION

=head4 INPUT

  require_login:  any request
  GET  /login:    return=  string, optional; a path on this site (default /)
  POST /login:    password= string; return= as above
  POST /logout:   none

=head4 OUTPUT

  require_login:  true when login is off or the session is logged in.  Otherwise
                  a browser's GET for a page is redirected (302) to
                  /login?return=<the page>, and anything else gets
                  401 application/json { "error": error_login_required }.
  GET  /login:    200 text/html, the form; 302 to return= when logged in; with
                  login off, 200 and a page that says no password is set.
  POST /login:    302 to return= when the password is right; 401 text/html, the
                  form with error_login_failed, when not; 429 with
                  error_login_locked after too many.
  POST /logout:   302 to /login (to / when login is off), the session ended.

return= is followed only when it is a path on this site (one /, not // or /\);
anything else goes to /.

=cut

# Wrong passwords per application (a test runs several) and remote address:
# epoch seconds of each, newest last.
my %LOGIN_FAILURES;
Readonly my $LOGIN_WINDOW   => 15 * 60;
Readonly my $LOGIN_ATTEMPTS => 10;

# _login_mark($self, $hash) -> $mark
#
# What a logged-in session holds: not the hash, which the readable cookie
# would hand to anyone who saw it, but an HMAC of it keyed by the secret.
sub _login_mark ($self, $hash) {
	return Digest::SHA::hmac_sha256_hex($hash, $self->app->secrets->[0]);
}

# _login_return($value) -> $path
#
# Where to go after logging in: a path on this site, never another site
# (//evil.example and /\evil.example are other sites to a browser).
sub _login_return {
	my ($value) = @_;
	return '/' unless defined $value && $value =~ m{\A/(?![/\\])} && $value !~ /[\x00-\x20\x7f\\]/;
	return '/' if $value =~ m{\A/log(?:in|out)\b};
	return $value;
}

# _login_hash($self) -> $hash | undef
sub _login_hash ($self) {
	my $hash = $self->app->config('password_hash');
	return (defined $hash && length $hash) ? $hash : undef;
}

sub _logged_in ($self) {
	my $hash = $self->_login_hash // return 1;
	return secure_compare($self->session('login') // '', $self->_login_mark($hash)) ? 1 : 0;
}

sub require_login ($self) {
	return 1 unless defined $self->_login_hash;
	if ($self->_logged_in) {
		$self->stash(logged_in => 1);
		return 1;
	}

	my $req = $self->req;
	$self->stash(buffer => 0);
	if ($req->method =~ /\A(?:GET|HEAD)\z/ && ($req->headers->accept // '') =~ m{text/html}
			&& $req->url->path->to_string !~ m{\A/api/}) {
		my $url = Mojo::URL->new('/login')->query(return => $req->url->path_query);
		$self->redirect_to($url);
		return undef;
	}
	$self->render(json => { error => _message_text('error_login_required') }, status => 401);
	return undef;
}

sub _render_login ($self, %args) {
	my ($platform, $language) = $self->_resolve_template;
	$self->stash(buffer => 0);
	return $self->render(
		template    => "$platform/$language/login",
		handler     => 'tt',
		format      => 'html',
		title       => 'Log in',
		language    => $language,
		return_to   => _login_return(scalar $self->param('return')),
		login_error => $args{error} // '',
		login_off   => $args{login_off} ? 1 : 0,
		status      => $args{status} // 200,
	);
}

sub login_form ($self) {
	# With no password set the page says so, rather than offering a form that
	# could never succeed.
	return $self->_render_login(login_off => 1) unless defined $self->_login_hash;
	return $self->redirect_to(_login_return(scalar $self->param('return'))) if $self->_logged_in;
	return $self->_render_login;
}

sub login ($self) {
	my $hash = $self->_login_hash;
	return $self->redirect_to('/') unless defined $hash;

	my $who      = $self->tx->remote_address // '';
	my $now      = time;
	my $failures = $LOGIN_FAILURES{ Scalar::Util::refaddr($self->app) } //= {};
	for my $addr (keys %{$failures}) {
		$failures->{$addr} = [ grep { $_ > $now - $LOGIN_WINDOW } @{ $failures->{$addr} } ];
		delete $failures->{$addr} unless @{ $failures->{$addr} };
	}
	my $seen = $failures->{$who} // [];
	if (@{$seen} >= $LOGIN_ATTEMPTS) {
		my $minutes = int(($seen->[0] + $LOGIN_WINDOW - $now + 59) / 60) || 1;
		return $self->_render_login(error => sprintf(_message_text('error_login_locked'), $minutes), status => 429);
	}

	unless (Database::BI::Password::verify_password(scalar($self->param('password')) // '', $hash)) {
		push @{ $failures->{$who} //= [] }, $now;
		$self->app->log->warn("Wrong password from $who");
		return $self->_render_login(error => _message_text('error_login_failed'), status => 401);
	}

	delete $failures->{$who};
	$self->session(login => $self->_login_mark($hash));
	return $self->redirect_to(_login_return(scalar $self->param('return')));
}

sub logout ($self) {
	$self->session(expires => 1);
	return $self->redirect_to(defined $self->_login_hash ? '/login' : '/');
}

=head2 preferences

C<GET /preferences> -- Render the page where a reader sets their preferences:
the light or dark theme, and how many rows a table shows on a page.

Preferences belong to the browser, not to the server, so this action only
renders the form.  The theme is kept in C<localStorage>; the script that
stores and applies it is in C<layouts/theme.html.tt>, which every page loads.
The page size is kept in the cookie C<bi_per_page> (25, 50, 100, 200, or 0 for
every row), because the server needs it before it reads the page; this action
reads it to show the current choice.

=head3 API SPECIFICATION

=head4 INPUT

  cookie bi_per_page   optional; the saved page size, shown as chosen

=head4 OUTPUT

  200 text/html   The preferences page.

=head3 FORMAL SPECIFICATION

  preferences
    response! : HTTP
    ──────────
    response!.status = 200

=cut

sub preferences ($self) {
	my ($platform, $language) = $self->_resolve_template;

	$self->render(
		template          => "$platform/$language/preferences",
		handler           => 'tt',
		format            => 'html',
		title             => 'Preferences',
		language          => $language,
		page_size         => _page_size_preference($self) // $DEFAULT_PER_PAGE,
		page_size_choices => [ @PAGE_SIZES ],
		page_size_cookie  => $PAGE_SIZE_COOKIE,
	);
}

=head2 tutorial

C<GET /tutorial> -- Render the tutorial that is part of the application.

The chapters, questions and glossary are data in L<Database::BI::Tutorial>.
They are not in this module's POD, so adding a feature means adding a chapter
there and no change to this action or to the template.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

  200 text/html   The tutorial page.  It is cached when page_cache_dir is set.

=head3 FORMAL SPECIFICATION

  tutorial
    response! : HTTP
    ──────────
    response!.status = 200

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
		$source = $self->_accelerated_source("table:$table") // $self->open_table($table);
		# Multi-table SQLite: flag redirect without fetching data.
		if ($source && $source->sqlite_tables && @{ $source->sqlite_tables } > 1) {
			$is_multi = 1;
		} else {
			# _fetch_page applies reduce-before-paginate: full-fetch + filter + dedup
			# + Perl paginate when f= or d=1 are set; N+1 trick otherwise.
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup,
				  calc_spec_key => "table:$table" });
		}
	};
	if ($@) {
		# No file by that name: a 404 that names the table, with the trail
		# and the navigation, rather than the home page and the backend's
		# message (which gives away the data directory).
		# A directory that may not be read has no file by that name to offer either.
		my $error   = $@;
		my $stem_of = sub { lc($_[0]->basename =~ s/\.[^.]+\z//r) };
		my $listing = eval { _data_dir_for($self->app)->list };
		$@ = $error;
		unless ($listing && grep { $stem_of->($_) eq lc $table } $listing->each) {
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
			error    => $self->_i18n('error_table_open', $table, _tidy_error($@)),
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
	# The page from _fetch_page is already reduced; this call is here for the chip
	# list only -- filter_specs (for export URLs) and filters_json (for the UI).
	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });

	# Calculated fields belong to the table, not only to its charts.  The table
	# action is addressed by :table rather than l=, so name the spec explicitly
	# when looking up the fields saved for it; otherwise a saved column would
	# appear in every chart and not in the table it was made from.
	my $page_columns;
	($records, $page_columns) = $self->_page_columns($source, $records, "table:$table");
	return unless $page_columns;
	my @columns = @$page_columns;

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
		combine_specs    => [ $self->_calc_specs_of_request ],
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
    let dir = realpath(param('path') // first_root) in
    pre  inside(dir, file_roots) /\ is_dir(dir)
    post render(browse, dirs: subdirs(dir), files: supported_files(dir))

=head3 EXAMPLE

  GET /browse                            -> 200, lists $HOME
  GET /browse?path=/tmp                  -> 200, lists /tmp
  GET /browse?path=/nonexistent/xyz      -> 404

=cut

sub browse ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $raw_path = $self->param('path') // _first_root($self);
	if (my $refusal = _outside_roots($self, $raw_path)) {
		return $self->render(text => $refusal, status => 403);
	}
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
			last if _outside_roots($self, $parent->to_string);
			$f = $parent;
		}
	}

	my $parent      = $dir->dirname;
	my $parent_href = $parent->to_string ne $dir->to_string && !_outside_roots($self, $parent->to_string)
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

	# A MariaDB server with no table named: list its tables.
	if ($file_path =~ $MARIADB_SERVER_RE) {
		return $self->redirect_to('/tables?l=' . url_escape($file_path));
	}

	# Redis spec: redis:tablename|redis://host:port -- delegate to _open_spec.
	# MariaDB spec: mariadb:server/table -- likewise.
	if ($file_path =~ $REDIS_SPEC_RE || $file_path =~ $MARIADB_SPEC_RE) {
		my $lspec = $file_path;
		my ($source, $label) = $self->_open_spec($lspec);
		unless ($source) {
			my $why = $self->stash('open_spec_error');
			return $self->reply->not_found unless defined $why;
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $lspec, $why),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		my $table = $label;
		my $dedup = $self->param('d') ? 1 : 0;
		my ($records, $has_next);
		eval {
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup, calc_spec_key => $lspec });
		};
		if ($@) {
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $label, _tidy_error($@)),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		# A cross-row spec that could not be honoured has already rendered its 400
		# inside _fetch_page; the page must not be drawn over it.
		return if $self->stash('_cross_row_error');

		$records //= [];
		my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });
		my $page_columns;
		($records, $page_columns) = $self->_page_columns($source, $records, $lspec);
		return unless $page_columns;
		my @columns = @$page_columns;
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
			combine_specs    => [ $self->_calc_specs_of_request ],
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
				{ per_page => $per_page, offset => $offset, dedup => $dedup, calc_spec_key => $lspec });
		};
		if ($@) {
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $filename, _tidy_error($@)),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		# A cross-row spec that could not be honoured has already rendered its 400
		# inside _fetch_page; the page must not be drawn over it.
		return if $self->stash('_cross_row_error');

		$records //= [];
		my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });
		my $page_columns;
		($records, $page_columns) = $self->_page_columns($source, $records, $lspec);
		return unless $page_columns;
		my @columns = @$page_columns;
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
			combine_specs    => [ $self->_calc_specs_of_request ],
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

	# A path that names a table after a "#", as a spec does, is that table.
	my ($named_file, $named_it) = _split_path($file_path);
	$file_path = $named_file if defined $named_it;
	if (my $refusal = _outside_roots($self, $file_path)) {
		return $self->render(text => $refusal, status => 403);
	}

	my $file = eval { Mojo::File->new($file_path)->realpath };
	return $self->reply->not_found
		unless defined $file && -f $file && $file->basename =~ $EXT_RE;

	my $dir      = $file->dirname;
	(my $table   = $file->basename) =~ s/\.[^.]+\z//;
	my $back     = '/browse?path=' . url_escape($dir->to_string);
	my $filename = $file->basename;
	my $lspec    = 'path:' . $file->to_string;

	my $it = $self->param('it') // $named_it;	# optional: select a specific internal table

	# A table opened from the schema browser belongs to a file in data_dir.  Name
	# it as table:store/sales so the join, filter and export panels keep the
	# chosen internal table instead of dropping back to the file's first table.
	if (defined $it && $it =~ $TABLE_NAME_RE) {
		my $data_dir = eval { _data_dir_for($self->app)->realpath };
		my $file_dir = eval { $file->dirname->realpath };
		$lspec = "table:$table/$it" if $data_dir && $file_dir && "$file_dir" eq "$data_dir";
	}
	# Elsewhere the spec names the table after a "#", so the panels and charts
	# keep it too.
	$lspec .= "#$it" if defined $it && length $it && $it !~ /[#\n]/ && $lspec =~ /\Apath:/;

	# Allow the tables view to override the default "Back to browser" link.
	my $back_override = _safe_back_url($self->param('back'));
	if ($back_override) {
		$back = $back_override;
	}
	my $back_label_default = $back_override ? ($self->param('back_label') // 'Back') : 'Back to browser';

	my $dedup = $self->param('d') ? 1 : 0;
	my ($source, $records, $has_next, $is_multi_local);
	eval {
		$source = (defined $it ? undef : $self->_accelerated_source($lspec))
			// $self->open_table($table, directory => $dir->to_string,
				defined $it ? (internal_table => $it) : ());
		# Multi-table SQLite without it=: flag redirect without fetching data.
		if (!defined $it && $source && $source->sqlite_tables
				&& @{ $source->sqlite_tables } > 1) {
			$is_multi_local = 1;
		} else {
			($records, $has_next) = $self->_fetch_page($source,
				{ per_page => $per_page, offset => $offset, dedup => $dedup, calc_spec_key => $lspec });
		}
	};
	if ($@) {
		# Provide a SQLite-specific hint when the error looks like a table-name
		# mismatch or a missing-tables failure so the user knows what to do.  A
		# table whose name cannot be used has its own advice in the message.
		my $hint;
		if ($filename =~ /\.(?:sql|sqlite|sqlite3|db)\z/i && $@ !~ /cannot be opened|can be opened/) {
			$hint = 'SQLite files must contain at least one user-defined table. '
				. 'The table name inside the database does not need to match the '
				. 'filename -- the application auto-detects and uses the first table it can open.';
		}
		return $self->render(
			template    => "$platform/$language/home",
			handler     => 'tt',
			format      => 'html',
			tables      => [],
			title       => 'Error',
			error       => $self->_i18n('error_file_open', $filename, _tidy_error($@)),
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
	my (undef, $filter_specs, $filters_json) = $self->_apply_filters($records, { chips_only => 1 });
	my $page_columns;
	($records, $page_columns) = $self->_page_columns($source, $records, $lspec);
	return unless $page_columns;
	my @columns = @$page_columns;

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
		combine_specs    => [ $self->_calc_specs_of_request ],
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

	my ($source, $records);
	my $ok = eval {
		$source  = $self->open_table('', url => $url, html_table_index => $idx);
		$records = $source->fetch_all;
		1;
	};
	return $err_home->('error_url_fetch', $url, _tidy_error($@)) unless $ok;

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
	my $path_internal;

	# Accept the unified spec format used by /join and /graph:
	# "table:name" or "path:/abs/path" -- mirrors _open_spec's parsing.
	if (!defined($table_name) && !defined($path)) {
		my $spec = $self->param('spec') // '';
		if ($spec =~ m{\Atable:([A-Za-z_][A-Za-z0-9_]*(?:/[A-Za-z_][A-Za-z0-9_]*)?)\z}) {
			$table_name = $1;
		} elsif ($spec =~ /\Apath:(.+)\z/s) {
			($path, $path_internal) = _split_path($1);
		}
	}

	my $source;
	if (($self->param('spec') // '') =~ $MARIADB_SPEC_RE) {
		($source) = $self->_open_spec($self->param('spec'));
	}
	elsif (defined $table_name && $table_name =~ m{\A([A-Za-z_][A-Za-z0-9_]*)(?:/([A-Za-z_][A-Za-z0-9_]*))?\z}) {
		my ($table, $internal) = ($1, $2);
		my $data_dir = _data_dir_for($self->app);
		my $stem     = _table_stem($data_dir, $table);
		return $self->render(json => { error => 'not found' }, status => 404)
			unless defined $stem;
		$source = eval {
			$self->open_table($stem, directory => $data_dir->to_string,
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
					defined $ext ? (file_ext => $ext) : (),
					defined $path_internal ? (internal_table => $path_internal) : ()) };
			}
		} elsif (my $refusal = _outside_roots($self, $path)) {
			return $self->render(json => { error => $refusal }, status => 403);
		} else {
			my $file = eval { Mojo::File->new($path)->realpath };
			if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
				my $dir = $file->dirname->to_string;
				(my $tbl = $file->basename) =~ s/\.[^.]+\z//;
				$source = eval { $self->open_table($tbl, directory => $dir,
					defined $path_internal ? (internal_table => $path_internal) : ()) };
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

C<GET /api/range> -- Return the min and max ISO date values for one column of
a view.  The view is the left source with any joins and combines applied, so
the column may come from a joined table, and an inner join's dropped rows do not
count.  Filters are not applied.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   Required. Data source spec ("table:name", "path:/abs/path", etc.).
  ?col=  string   Required. Column name to compute the range for.
  ?j=    string   Optional, repeatable. Join spec "<spec>|<lkey>|<rkey>".
  ?jtype= string  Optional. left (default), inner or outer.
  ?c=    string   Optional, repeatable. Source spec to stack under the view.

=head4 OUTPUT

  200 application/json   { "min": "YYYY-MM-DD", "max": "YYYY-MM-DD" }
  200 application/json   { "min": null, "max": null }  (no parseable dates)
  400 application/json   { "error": "..." }

=head3 FORMAL SPECIFICATION

  range_api == lambda self .
    let recs = _run_pipeline_source().records in
    pre  param('l') /= '' /\ col /= ''
    post render_json({ min: min_date(recs, col), max: max_date(recs, col) })

=cut

sub range_api ($self) {
	my $spec_str = $self->param('l') // '';
	my $col      = $self->param('col') // '';
	return $self->render(json => { error => 'l required'   }, status => 400) unless length $spec_str;
	return $self->render(json => { error => 'col required' }, status => 400) unless length $col;

	# The pipeline, so that the range is of the rows the page shows.  A join
	# that cannot be built croaks; this route answers "no range" instead.
	my (undef, $records, $columns) = eval { $self->_run_pipeline_source };
	return $self->render(json => { min => undef, max => undef })
		unless $records && grep { $_ eq $col } @$columns;

	my $mdy_re = qr|\A(\d{1,2})/(\d{1,2})/(\d{4})\z|;
	my @dates;
	for my $rec (@$records) {
		my $v = $rec->{$col} // '';
		next unless length $v;
		# A timestamp counts as the day it names, as the filters read it.
		if (defined(my $day = (Database::BI::Util::iso_datetime($v))[0])) {
			push @dates, $day;
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
	# combine route runs joins and combines together.  c= also carries calculated
	# fields, which do not stack anything and stay on this page.
	return $self->combine_tables
		if @{ $self->every_param('c') } > $self->_calc_specs_of_request;

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
			  sort_dir  => $dir,      calc_spec_key => $left_spec });
	};
	if ($@) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Error',
			error    => $self->_i18n('error_table_open', $left_label, _tidy_error($@)),
			language => $language,
		);
	}
	# A cross-row spec that could not be honoured has already rendered its 400
	# inside _fetch_page; the page must not be drawn over it.
	return if $self->stash('_cross_row_error');

	$records //= [];
	my $page_columns;
	($records, $page_columns) = $self->_page_columns($src, $records, $left_spec);
	return unless $page_columns;
	my @columns = @$page_columns;

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
		combine_specs    => [ $self->_calc_specs_of_request ],
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

	# Stage 4, for a table of stacked rows as for any other.
	my $span = $self->_span_calc_spec($cols_ref, ());
	return $self->render(text => $span->{error}, status => 400) if $span && $span->{error};
	my ($calc_records, $calc_columns) = eval {
		$self->_apply_calc_fields($records, $cols_ref, ($span ? { calc => $span->{calc} } : undef))
	};
	unless ($calc_records) {
		(my $e = $@) =~ s/ at \S+ line \d+\.?\n?$//;
		return $self->render(text => $e, status => 400);
	}
	($records, $cols_ref) = ($calc_records, $calc_columns);

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
		# A new array: the backend's own can be read-only, as a SQLite one is.
		$records = [ sort { ($a->{$sort} // '') cmp ($b->{$sort} // '') } @$records ];
		$records = [ reverse @$records ] if $dir eq 'desc';
	} elsif (defined $sort) {
		carp $self->_i18n('error_sort_column', $sort);
	}

	# Server-side pagination: slice the fully-reduced combined set.  The page
	# below is therefore reduced too, and asks for chips only.
	my ($page, $per_page, $offset) = $self->_pagination;
	my $total    = scalar @$records;
	my $has_next = ($total > $offset + $per_page) ? 1 : 0;
	my @page_recs = @{ _rows_of_page($records, $offset, $per_page) };
	$records = \@page_recs;
	$self->stash(page_count => _page_count($total, $per_page));

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
  500 text/plain                The SQLite file could not be built (no driver, no
                                temporary space); the reason goes to the log.

=head3 MESSAGES

  error_export_sqlite -- the SQLite file could not be built.

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
  dir=       string   Target directory (must exist; resolved via realpath).  Inside
                      config file_roots and export_dirs when they are set.
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
  403 application/json   { "error": "..." }  -- a hidden target; dir outside
                                                  file_roots or export_dirs; a name
                                                  that is a link, folder or anything
                                                  but a plain file; or a request
                                                  another site's page made
  401 application/json   { "error": "..." }  -- password_hash set, not logged in
  404 application/json   { "error": "..." }  -- bad dir or table not found
  415 application/json   { "error": "..." }  -- unsupported extension
  500 application/json   { "error": "..." }  -- write failure

=head3 MESSAGES

  error_dir_not_found   -- realpath of dir failed or result is not a directory.
  error_ext_required    -- filename extension is not .csv, .sql or .json.
  error_hidden_target   -- the directory, after realpath, or the filename has a
                           part starting with a dot (~/.config, .vscode/,
                           .profile.json): those hold settings, and
                           GET /api/dirs never offers them.
  error_outside_roots   -- dir is outside config file_roots.
  error_outside_export_dirs
                        -- dir is outside config export_dirs.
  error_export_not_file -- the name is already a link, a folder or another
                           non-file: a link could lead the export anywhere.
  error_cross_site, error_host_refused
                        -- from request_refusal, before this action runs.
  error_write_failed    -- DBI or filesystem write threw.

A refusal names the folder as C<dir> spelled it, though the checks are made
on its realpath.  The C<saved> path of a success is the realpath: where the
file is.

The file is written to a temporary file (C<.bi-export-XXXXXXXX>) in C<dir> and
renamed over the name, so a reader never sees half a file and a link made
after the check is replaced, not followed.  It gets the replaced file's mode,
or C<0666 & ~umask> for a new one; on failure the temporary file is removed.

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

	if (my $refusal = _outside_roots($self, $dir) // _outside_export_dirs($self, $dir)) {
		return $self->render(json => { error => $refusal }, status => 403);
	}
	my $dest_dir = eval { Mojo::File->new($dir)->realpath };
	unless (defined $dest_dir && -d $dest_dir) {
		return $self->render(
			json   => { error => $self->_i18n('error_dir_not_found', $dir) },
			status => 404,
		);
	}

	# A NUL is not part of any file name, only a way of hiding the real extension.
	$filename = '' if $filename =~ /\0/;

	# Strip any path separators the browser might include.
	($filename) = $filename =~ m{([^/\\]+)\z};

	# A dot-folder or dot-file holds some program's settings (~/.config, a
	# .vscode/settings.json), which a .json export could replace.  The folder
	# list the panel offers (GET /api/dirs) leaves them out too.
	# The checks read the resolved folder; a refusal names the one the reader
	# asked for, as every other message does (macOS's tempdir is under /var,
	# a link to /private/var, so the two differ there).
	my $asked = Mojo::File->new($dir);
	my @names = (File::Spec->splitdir($dest_dir->to_string), $filename // '');
	if (grep { /\A\./ && $_ ne '.' && $_ ne '..' } @names) {
		return $self->render(
			json   => { error => $self->_i18n('error_hidden_target', $asked->child($filename // '')->to_string) },
			status => 403,
		);
	}
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
	# A link (or a folder, a pipe) already at the name is not replaced: written
	# through, a link inside the folders would put the export wherever it
	# points, outside file_roots or export_dirs, or into a dot-file.
	if (-l $dest || (-e $dest && !-f $dest)) {
		return $self->render(json => { error => sprintf(_message_text('error_export_not_file'), $asked->child($filename)->to_string) }, status => 403);
	}
	my $tmp;
	my $ok = eval {
		my $bytes = $format eq 'csv' ? _serialize_csv($records, $columns)
		          : $format eq 'json' ? encode_json($records)
		          : $self->_write_sqlite_db($records, $columns);
		# Written beside it and renamed over it: a rename replaces whatever
		# is at the name, a link made since the check included, and never
		# follows it, and a reader never sees half a file.
		(my $fh, $tmp) = tempfile('.bi-export-XXXXXXXX', DIR => $dest_dir->to_string, UNLINK => 0);
		binmode $fh;
		print {$fh} $bytes or croak "$tmp: $!";
		close $fh or croak "$tmp: $!";
		# tempfile makes it 0600: give it the mode of the file it replaces, as
		# writing over that one did, or the mode a new file gets.
		my @old = stat $dest->to_string;
		chmod(@old ? $old[2] & oct('7777') : 0666 & ~umask(), $tmp);
		rename $tmp, $dest->to_string or croak "$dest: $!";
		undef $tmp;
		1;
	};
	my $err = $@;
	unlink $tmp if defined $tmp;
	return $self->render(
		json   => { error => $self->_i18n('error_write_failed', _tidy_error($err)) },
		status => 500,
	) unless $ok;

	$self->render(json => { saved => $dest->to_string });
}

=head2 dirs_api

C<GET /api/dirs> -- Return a JSON directory listing for the export panel.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Directory to list.  Default: the first config export_dirs
                    entry, else $HOME if it is inside file_roots, else the first
                    root.  Returns 404 when not a directory.  Hidden entries
                    (names starting with ".") are excluded.

=head4 OUTPUT

  200 application/json
    {
      "path":   "/abs/path",
      "parent": "/abs/parent" or null (at the filesystem root, or when the
                 parent is outside file_roots or export_dirs),
      "dirs":   [ { "name": "alpha", "path": "/abs/path/alpha" }, ... ]
    }

  403 application/json   { "error": "..." }  -- path outside file_roots or
                                                  export_dirs, whether or not it
                                                  exists
  404 application/json   { "error": "Not a directory" }

=head3 MESSAGES

  error_outside_roots, error_outside_export_dirs -- the 403 above.

=head3 FORMAL SPECIFICATION

  dirs_api == lambda self .
    let dir = realpath(param('path') // first(export_dirs) // first_root) in
    pre  inside(dir, file_roots) /\ inside(dir, export_dirs) /\ is_dir(dir)
    post render_json({ path: dir, parent: parent(dir), dirs: subdirs(dir) })

=head3 EXAMPLE

  GET /api/dirs?path=/home/user  -> {"path":"/home/user","parent":"/home","dirs":[...]}

=cut

sub dirs_api ($self) {
	my $raw = $self->param('path') // (_export_dirs($self))[0] // _first_root($self);
	if (my $refusal = _outside_roots($self, $raw) // _outside_export_dirs($self, $raw)) {
		return $self->render(json => { error => $refusal }, status => 403);
	}
	my $dir = eval { Mojo::File->new($raw)->realpath };
	return $self->render(json => { error => 'Not a directory' }, status => 404)
		unless defined $dir && -d $dir;

	my $listing = $self->_list_dir($dir, 0);
	my $parent  = $dir->dirname;
	my $up      = $parent->to_string ne $dir->to_string && !_outside_roots($self, $parent->to_string)
		&& !_outside_export_dirs($self, $parent->to_string);

	$self->render(json => {
		path   => $dir->to_string,
		parent => ($up ? $parent->to_string : undef),
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
	# used as a filesystem oracle to probe /etc/shadow, /root/.ssh/, etc.; and,
	# with file_roots, to files inside them, said the same way.
	return $self->render(json => { exists => \0, path => $path })
		unless defined $file && -f $file && $file->basename =~ $EXT_RE && !_outside_roots($self, $path);

	my @s = stat $file->to_string;

	# For SQLite files, count user tables so the home-page tooltip can show
	# "SQLite database - N tables". Silently omit the count if the file is
	# not actually a SQLite file (e.g. a Berkeley DB .db file).
	my $table_count;
	if ($file->basename =~ /\.(?:sql|sqlite|sqlite3|db)\z/i) {
		eval {
			require Database::Join::Catalog;
			$table_count = scalar @{ Database::Join::Catalog->tables(file => $file->to_string) };
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
	my $sub_dir = eval {
		$uploads_base->make_path unless -d $uploads_base;
		tempdir(DIR => $uploads_base->to_string, CLEANUP => 0);
	};
	unless (defined $sub_dir) {
		$self->app->log->error("Cannot stage an upload in $uploads_base: " . _tidy_error($@));
		return $self->render(
			json   => { error => $self->_i18n('error_upload_save') },
			status => 500,
		);
	}
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
	my $ok = eval {
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
		1;
	};
	unless ($ok) {
		$self->app->log->error("Cannot clear $uploads_dir: " . _tidy_error($@));
		return $self->render(json => { error => $self->_i18n('error_uploads_clear') }, status => 500);
	}

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
			$chart_html = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 1100, height => 580)
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
			$chart_html = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 1100, height => 580)
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
		my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 1100, height => 580)
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
		require Statistics::Lite;
		$min_y = Statistics::Lite::min(@y_vals);
		$max_y = Statistics::Lite::max(@y_vals);
		$avg_y = Statistics::Lite::mean(@y_vals);
	}

	# The trend line: a least-squares fit of Y against the point's place on the
	# axis.  The axis is a d3.scalePoint, which spaces the points evenly whatever
	# their labels say, so the place (0, 1, 2, ...) is what makes the fit a
	# straight line on this chart.  The page refits the points in view after a
	# zoom, the same way; this is the whole chart's.
	my $trend = _trend_line(\@y_vals);

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = "$y_col vs $x_col";
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 1100, height => 580)
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
		($trend ? (
			trend_slope     => sprintf('%.4g', $trend->{slope}),
			trend_intercept => sprintf('%.6g', $trend->{intercept}),
			trend_r2        => sprintf('%.2f', $trend->{r_squared}),
		) : ()),
		source_url       => $source_url,
		source_accessed  => $source_accessed,
		language         => $language,
	);
}

# _trend_line(\@y) -> { slope, intercept, r_squared } | undef
#
# The least-squares line through the values, each at its place 0, 1, 2, ...
# (Statistics::LineFit).  undef for fewer than two values, or when the fit
# fails.  A flat series has slope 0 and an R squared of 1 (LineFit's answer:
# the line passes through every point).
sub _trend_line {
	my ($ys) = @_;
	return undef unless ref $ys eq 'ARRAY' && @$ys >= 2;
	require Statistics::LineFit;
	my $fit = Statistics::LineFit->new;
	return undef unless $fit->setData([ 0 .. $#$ys ], $ys);
	my ($intercept, $slope) = $fit->coefficients;
	return undef unless defined $slope && defined $intercept;
	my $r2 = $fit->rSquared;
	return { slope => $slope, intercept => $intercept, r_squared => $r2 // 0 };
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
	my $topn_n = _whole_number($self->param('topn')) // 0;
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
	my $scheme  = _categorical_scheme($self->param('scheme'));
	my $title   = $count_mode ? "Count by $cat_col" : "$val_col by $cat_col";
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 600, height => 500)
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
	my $scheme    = _sequential_scheme($self->param('scheme'));
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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 900, height => 500)
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
	my $topn_n = _whole_number($self->param('topn')) // 0;
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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 800, height => 480)
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
Lists all internal tables with their columns; clicking a table opens it.  A
JSON file that is an object holding lists of objects has one table per list
(see L<Database::BI::Model::DataSource/json_lists>).

=head3 API SPECIFICATION

=head4 INPUT

  ?l=   string   Required.  Table spec: "table:name" (data_dir) or
                 "path:/abs/path" (filesystem path).  The file must be a
                 SQLite database or a .json file.

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
		my $data_dir   = _data_dir_for($self->app);
		my @exts       = qw(sql sqlite sqlite3 db json);
		my $table_name = _table_stem($data_dir, $1, @exts) // lc $1;
		for my $ext (@exts) {
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
		my ($path_arg) = _split_path($1);
		if (my $refusal = _outside_roots($self, $path_arg)) {
			return $self->render(text => $refusal, status => 403);
		}
		my $file = eval { Mojo::File->new($path_arg)->realpath };
		return $self->reply->not_found
			unless defined $file && -f $file && $file->basename =~ /\.(?:sql|sqlite|sqlite3|db|json)\z/i;
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
	} elsif ($spec =~ $MARIADB_SERVER_RE) {
		my $server = $1;
		$db_label   = $server;
		$back_url   = '/';
		$back_label = 'Home';
		my $found = eval {
			Database::BI::Model::DataSource->mariadb_tables($server,
				($self->app->config('mariadb_servers') // {})->{$server});
		};
		unless ($found) {
			return $self->render(
				template   => "$platform/$language/home",
				handler    => 'tt',
				format     => 'html',
				tables     => [],
				title      => 'Error',
				error      => $self->_i18n('error_file_open', $spec, _tidy_error($@)),
				back_url   => '/',
				back_label => 'Home',
				language   => $language,
			);
		}
		for my $found_table (@{$found}) {
			my ($name, $cols) = @{$found_table}{qw(name columns)};
			# Database::Abstraction refuses this name, so the card says so.
			if ($name !~ $TABLE_NAME_RE) {
				(my $safe = $name) =~ s/[^A-Za-z0-9_]/_/g;
				$safe = "_$safe" unless $safe =~ /\A[A-Za-z_]/;
				push @tables, { name => $name, columns => $cols, unusable => 1, safe_name => $safe, on_server => 1 };
				next;
			}
			my $open_url = '/open?path=' . url_escape("mariadb:$server/$name")
				. '&back=' . url_escape('/tables?l=' . $spec)
				. '&back_label=' . url_escape(ucfirst($db_label) . ' schema');
			push @tables, { name => $name, columns => $cols, href => $open_url };
		}
	} else {
		return $self->reply->not_found;
	}

	if (defined $file_path) {
		# A JSON file's tables are its lists of objects; a SQLite file's are
		# listed by Database::Join.
		my $schema = $file_path =~ /\.json\z/i
			? eval { Database::BI::Model::DataSource->json_lists($file_path) }
			: eval { require Database::Join::Catalog; Database::Join::Catalog->schema(file => $file_path) };
		return $self->reply->not_found unless $schema;
		for my $table_info (@{$schema}) {
			my $tname = $table_info->{name};
			my @cols  = @{ $table_info->{columns} };
			# Database::Abstraction refuses this name, so the card says so
			# rather than linking to an error.  A JSON list's name never
			# reaches SQL, so any name opens.
			if ($tname !~ $TABLE_NAME_RE && $file_path !~ /\.json\z/i) {
				(my $safe = $tname) =~ s/[^A-Za-z0-9_]/_/g;
				$safe = "_$safe" unless $safe =~ /\A[A-Za-z_]/;
				push @tables, { name => $tname, columns => \@cols, unusable => 1, safe_name => $safe };
				next;
			}
			my $open_url = '/open?path=' . url_escape($file_path)
				. '&it=' . url_escape($tname)
				. '&back=' . url_escape('/tables?l=' . $spec)
				. '&back_label=' . url_escape(ucfirst($db_label) . ' schema');
			push @tables, { name => $tname, columns => \@cols, href => $open_url };
		}
	}

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

=head3 API SPECIFICATION

=head4 INPUT

The query parameters above, with C<l=> required as well.

=head4 OUTPUT

  200 text/html (or the export format)   The grid.
  400 text/plain   'Missing l= parameter', error_pivot_rows_required,
                   error_pivot_measure_req, error_pivot_measure_invalid,
                   error_measure_column, error_pivot_dim_not_found or error_topn_col.
  404 text/plain   The source cannot be opened.

=head3 FORMAL SPECIFICATION

  pivot_view
    l?, rows?, m? : seq Char
    response! : HTTP
    ──────────
    l? = ⟨⟩ ∨ rows? = ⟨⟩ ∨ m? = ⟨⟩ ⇒ response!.status = 400
    l? ≠ ⟨⟩ ∧ ¬ opens(l?) ⇒ response!.status = 404

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
		my $topn_n   = _whole_number($self->param('topn')) // 0;
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
		page_count        => _page_count($total_row_groups, $per_page),
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

=head3 API SPECIFICATION

=head4 INPUT

The query parameters above, with C<l=> required.

=head4 OUTPUT

  200 text/html    The statistics.
  400 text/plain   'Missing l= parameter', or error_stats_percentile when p= is
                   not a whole number from 1 to 100.
  404 text/plain   The source cannot be opened.

=head3 FORMAL SPECIFICATION

  stats_view
    l?, p? : seq Char
    response! : HTTP
    ──────────
    l? = ⟨⟩ ⇒ response!.status = 400
    p? ≠ ⟨⟩ ∧ p? ∉ { "1" .. "100" } ⇒ response!.status = 400

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
	my $spec = canonical_spec($self->param('l') // '');
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
	my $spec = canonical_spec($self->param('l') // '');
	my $name = $self->param('name') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	delete $models->{fields}{$spec}{$name};
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

sub calc_list ($self) {
	my $spec = canonical_spec($self->param('l') // '');
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { fields => $models->{fields}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Named-group CRUD  (POST /groups/save, POST /groups/delete, GET /groups/list)
# ---------------------------------------------------------------------------

sub groups_save ($self) {
	my $spec       = canonical_spec($self->param('l')     // '');
	my $col        = $self->param('col')   // '';
	my $group_name = $self->param('group') // '';

	# The panel sends one values= holding a line for each value; a script may just
	# as well repeat the parameter.
	my @values = map { split /\r?\n/ } @{ $self->every_param('values') // [] };

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
	my $spec       = canonical_spec($self->param('l')     // '');
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
	my $spec = canonical_spec($self->param('l') // '');
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
	my $spec    = canonical_spec($self->param('l')       // '');
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
	my $spec = canonical_spec($self->param('l')   // '');
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
	my $spec = canonical_spec($self->param('l') // '');
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { patterns => $models->{date_patterns}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Stored-lookup CRUD  (POST /lookups/save, POST /lookups/delete, GET /lookups/list)
# ---------------------------------------------------------------------------

# lookups_save: POST /lookups/save?l=<spec>&name=<ident>&file=<path>&key=<col>
#               [&col=<col>][&fields=<col>[,<col>...]][&default=<value>]
# Stores models.json lookups.<spec>.<name>.  The file is read now, so a file
# outside data_dir, a missing one, one too large, and a key or field it does not
# have are all 400s here rather than on the next page.  fields= may repeat or
# hold a comma-separated list; without it every column but the key is added.
sub lookups_save ($self) {
	my $spec = canonical_spec($self->param('l')    // '');
	my $name = $self->param('name') // '';
	my $key  = $self->param('key')  // '';
	my $col  = $self->param('col')  // '';
	my @fields = grep { length } map { split /,/ } @{ $self->every_param('fields') // [] };

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => $self->_i18n('error_lookup_name', $name) }, status => 400)
		unless $name =~ $LOOKUP_NAME_RE;
	return $self->render(json => { error => 'key= required' }, status => 400)
		unless length $key;

	my %def = (
		file => $self->param('file') // '',
		key  => $key,
		(length $col ? (col => $col) : ()),
		(@fields ? (fields => \@fields) : ()),
		(defined $self->param('default') ? (default => $self->param('default')) : ()),
	);
	my $ok = eval { $self->_load_lookup({ %def, name => $name }); 1 };
	return $self->render(json => { error => _tidy_error($@) }, status => 400) unless $ok;

	my $models = $self->_read_models;
	$models->{lookups}{$spec}{$name} = \%def;
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# lookups_delete: POST /lookups/delete?l=<spec>[&name=<ident>]
# Removes one lookup, or every lookup of $spec when name= is absent.
sub lookups_delete ($self) {
	my $spec = canonical_spec($self->param('l')    // '');
	my $name = $self->param('name') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $name) {
		delete $models->{lookups}{$spec}{$name};
	} else {
		delete $models->{lookups}{$spec};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# lookups_list: GET /lookups/list?l=<spec>
# Returns { lookups: { name: { file, key, col?, fields?, default? }, ... } }.
sub lookups_list ($self) {
	my $spec = canonical_spec($self->param('l') // '');
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { lookups => $models->{lookups}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Stored-extraction CRUD  (POST /extract/save, POST /extract/delete, GET /extract/list)
# ---------------------------------------------------------------------------

# extract_save: POST /extract/save?l=<spec>&name=<ident>&col=<col>&pattern=<re>
#               [&fields=<group>[,<group>...]]
# Stores models.json extractions.<spec>.<name> = { col, pattern, fields }.  The
# pattern is compiled now, so one that is too long, uses a refused construct,
# does not compile or names no group is a 400 here.  fields= picks some of the
# named groups; without it every named group becomes a column.
sub extract_save ($self) {
	my $spec    = canonical_spec($self->param('l')       // '');
	my $name    = $self->param('name')    // '';
	my $col     = $self->param('col')     // '';
	my $pattern = $self->param('pattern') // '';
	my @fields  = grep { length } map { split /,/ } @{ $self->every_param('fields') // [] };

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => $self->_i18n('error_extract_name', $name) }, status => 400)
		unless $name =~ $LOOKUP_NAME_RE;
	return $self->render(json => { error => 'col= required' }, status => 400)
		unless length $col;
	return $self->render(json => { error => 'pattern= required' }, status => 400)
		unless length $pattern;

	my %def = (col => $col, pattern => $pattern, (@fields ? (fields => \@fields) : ()));
	my $fields;
	my $ok = eval { (undef, $fields) = $self->_compile_extraction($name, \%def); 1 };
	return $self->render(json => { error => _tidy_error($@) }, status => 400) unless $ok;
	$def{fields} = $fields;

	my $models = $self->_read_models;
	$models->{extractions}{$spec}{$name} = \%def;
	$self->_write_models($models);
	$self->render(json => { ok => 1, fields => $fields });
}

# extract_delete: POST /extract/delete?l=<spec>[&name=<ident>]
# Removes one extraction, or every extraction of $spec when name= is absent.
sub extract_delete ($self) {
	my $spec = canonical_spec($self->param('l')    // '');
	my $name = $self->param('name') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $name) {
		delete $models->{extractions}{$spec}{$name};
	} else {
		delete $models->{extractions}{$spec};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# extract_list: GET /extract/list?l=<spec>
# Returns { extractions: { name: { col, pattern, fields }, ... } }.
sub extract_list ($self) {
	my $spec = canonical_spec($self->param('l') // '');
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	$self->render(json => { extractions => $models->{extractions}{$spec} // {} });
}

# ---------------------------------------------------------------------------
# Geo column preferences CRUD  (POST /geo/save, POST /geo/delete, GET /geo/list)
#
# Stores the user's choice of lat/lon/loc columns for a given l= spec in
# models.json under geo.<spec>.columns.  The geocode cache itself lives under
# geo.<spec>.places and is written by _map_data independently.
# ---------------------------------------------------------------------------

# geo_save: POST /geo/save?l=<spec>&col=<col>&kind=lat|lon|location|location_suffix[&replace=1][&loc_text=<text>]
# location_suffix is the column whose cells follow the place's, after ", "
# (a country after an address).  loc_text= is the text the map adds to the end
# of each place ("Virginia, USA"); it is not a column, so it is kept beside
# them, as geo.<spec>.loc_text, and replace=1 forgets it too.
# col= and kind= may repeat, in pairs, so a latitude and a longitude are saved
# in one request.  replace=1 forgets the spec's saved columns first: the map
# panel's "Remember" sends it, so a new choice replaces the old one rather than
# leaving, say, a place-name column beside the latitude chosen after it.
sub geo_save ($self) {
	my $spec  = canonical_spec($self->param('l') // '');
	my @cols  = @{ $self->every_param('col')  // [] };
	my @kinds = @{ $self->every_param('kind') // [] };

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;
	return $self->render(json => { error => 'col= required' }, status => 400)
		unless @cols && !grep { !length } @cols;
	return $self->render(json => { error => 'kind must be lat, lon, location or location_suffix' }, status => 400)
		unless @kinds == @cols && !grep { !/\A(?:lat|lon|location|location_suffix)\z/ } @kinds;
	my $loc_text_raw = $self->param('loc_text') // '';
	my ($loc_text) = _map_loc_text($loc_text_raw);
	return $self->render(json => { error => $self->_i18n('error_map_loc_text', $Database::BI::Model::Geocode::PLACE_TEXT_MAX, $loc_text_raw) }, status => 400)
		unless defined $loc_text;

	my $models = $self->_read_models;
	if ($self->param('replace')) {
		delete $models->{geo}{$spec}{columns};
		delete $models->{geo}{$spec}{loc_text};
	}
	$models->{geo}{$spec}{columns}{ $cols[$_] } = { kind => $kinds[$_] } for 0 .. $#cols;
	$models->{geo}{$spec}{loc_text} = $loc_text if length $loc_text;
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# geo_delete: POST /geo/delete?l=<spec>&col=<col>
# Omit col= to clear all column preferences for the spec, and its loc_text.
sub geo_delete ($self) {
	my $spec = canonical_spec($self->param('l')   // '');
	my $col  = $self->param('col') // '';

	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	if (length $col) {
		delete $models->{geo}{$spec}{columns}{$col};
	} else {
		delete $models->{geo}{$spec}{columns};
		delete $models->{geo}{$spec}{loc_text};
	}
	$self->_write_models($models);
	$self->render(json => { ok => 1 });
}

# geo_list: GET /geo/list?l=<spec>
# Returns { columns: { col: { kind: "lat"|"lon"|"location"|"location_suffix" }, ... } },
# with loc_text: "<text>" when that is remembered too.
sub geo_list ($self) {
	my $spec = canonical_spec($self->param('l') // '');
	return $self->render(json => { error => 'l= required' }, status => 400)
		unless length $spec;

	my $models = $self->_read_models;
	my $loc_text = $models->{geo}{$spec}{loc_text};
	$self->render(json => {
		columns => $models->{geo}{$spec}{columns} // {},
		(defined($loc_text) && !ref($loc_text) && length($loc_text) ? (loc_text => $loc_text) : ()),
	});
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
	my ($min_r, $max_r) = _scatter_radii($self->param('min_r'), $self->param('max_r'));
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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 800, height => 480)
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
		# scheme= means nothing without series=, and is unchecked then, so it
		# is not saved: a canvas copy would otherwise carry ?scheme=Blues.  The
		# radii likewise only with size=.
		options => {
			(length $series_col ? (scheme => $scheme) : ()),
			(length $size_col   ? (min_r => $min_r, max_r => $max_r) : ()),
		},
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
	my $scheme    = _categorical_scheme($self->param('scheme'));
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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 900, height => 500)
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
	my $scheme     = _optional_scheme($self->param('scheme'));
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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 900, height => 500)
		->render_combo_snippet(\@data, {
			bar_label  => $eff_bar_lbl,
			line_label => $eff_line_lbl,
			($scheme ? (scheme => $scheme) : ()),
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind   => 'combo',
		title  => $title,
		encode => { x => $x_col, bar => $bar_col, line => $line_col },
		($scheme ? (options => { scheme => $scheme }) : ()),
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

# _tile_colour_measure($self, $fn, $col) -> \%measure | { error => $text }
#
# The measure a treemap's tiles are coloured by: $fn (color_agg=, or a card's
# options.color_agg) of $col, average when $fn is absent or empty, since a
# margin or a rating is read as an average rather than a total.  A name that
# is not an aggregate function comes back as { error }, worded as the
# function check elsewhere words it.  /treemap and a canvas treemap card both
# ask here, so they accept and refuse the same names.
sub _tile_colour_measure :Protected ($self, $fn, $col) {
	$fn = (defined $fn && !ref $fn) ? lc $fn : '';
	$fn = 'avg' unless length $fn;
	return { error => $self->_i18n('error_agg_fn', $fn, join(' ', @MEASURE_FNS)) }
		unless _measure_fn_ok($fn);
	return _visual_measure($fn, $col);
}

# _tile_colours($self, $source, \@records, $cat_col, \%measure) -> \%colour_of
#
# The number each treemap tile is coloured by: the measure (from
# _visual_measure) folded per value of $cat_col, keyed by the raw value.  With
# $cat_col undef it is one total over every row, under the key ''.  A group
# whose result is not a finite number has no entry, and its tile is drawn
# grey.  /treemap and a canvas treemap card both fold here, so a card saved
# from the page is coloured by the same numbers.
sub _tile_colours :Protected ($self, $source, $records, $cat_col, $m) {
	my $rows = $self->_grouped_totals(
		{ source => $source, records => $records },
		{ by  => [ defined $cat_col ? ($cat_col) : () ],
		  fn  => $m->{fn}, val => $m->{val}, as => 'colour' },
	);
	my %colour_of;
	for my $r (@$rows) {
		my $v = $r->{colour};
		next unless defined $v && Scalar::Util::looks_like_number($v) && $v !~ /\A\s*[-+]?(?:nan|inf)/i;
		$colour_of{ defined $cat_col ? ($r->{$cat_col} // '') : '' } = $v + 0;
	}
	return \%colour_of;
}

sub treemap_view ($self) {
	# ?group= is the canonical spec name; ?cat= is the legacy alias (keep both).
	my $cat_col   = $self->param('group') // $self->param('cat') // '';
	# ?size= is the canonical spec name; ?val= is the legacy alias (keep both).
	my $val_col   = $self->param('size')  // $self->param('val') // '';
	my $scheme    = _categorical_scheme($self->param('scheme'));
	my $back      = _safe_back_url($self->param('back')) // '/';
	my $back2     = _safe_back_url($self->param('back2'));
	my $back2_lbl = $self->param('back2_label') // '';

	# ?color= shades each tile by a second column, folded per tile with
	# ?color_agg= (default avg: a margin or a rating is read as an average, not
	# a total) on the sequential ?color_scheme=, as the heatmap's cells are.
	my $color_col    = $self->param('color') // '';
	my $color_m      = length $color_col
		? $self->_tile_colour_measure($self->param('color_agg'), $color_col)
		: undef;
	my $color_scheme = _sequential_scheme($self->param('color_scheme'));

	return $self->render(text => 'Missing group= parameter', status => 400) unless length $cat_col;
	return $self->render(text => $color_m->{error}, status => 400) if $color_m && $color_m->{error};

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
	return $self->render(text => "Column not found: $color_col", status => 400)
		if length $color_col && !$col_set{$color_col};

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

	my $colour_of = $color_m
		? $self->_tile_colours($src, $records, $cat_col, $color_m)
		: {};

	# Top-N: keep the highest-N tiles, aggregate the rest as "Other".
	my $topn_n = _whole_number($self->param('topn')) // 0;
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
			if (@$other && defined $other->[0]{value}) {
				push @top_agg, { $cat_col => 'Other', value => $other->[0]{value} };
				# Other's colour is its own rows', not an average of averages.
				# The key is the tile, so a category itself named Other is
				# drawn with this one, as its area already is.
				$colour_of->{Other} = $self->_tile_colours(undef, $other_rec, undef, $color_m)->{''}
					if $color_m;
			}
		}
		$agg_rows = \@top_agg;
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid data in the selected column.',
		status => 200,
	) unless @$agg_rows;

	my @data = map {
		my $cv = $colour_of->{ $_->{$cat_col} // '' };
		+{ path => 'Root/' . _decode_cell($_->{$cat_col}), value => $_->{value},
		   (defined $cv ? (color_value => $cv) : ()) }
	} @$agg_rows;

	my ($source_url, $source_accessed) = $self->_url_attribution;

	require HTML::D3;
	my $title   = $count_mode ? "Treemap of $cat_col by count" : "Treemap of $cat_col by $val_col";
	$title     .= " coloured by $color_m->{label}" if $color_m;
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 800, height => 500)
		->render_treemap_snippet(\@data, {
			scheme => $scheme,
			($color_m ? (color_scheme => $color_scheme, color_label => $color_m->{label}) : ()),
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'treemap',
		title   => $title,
		encode  => { cat => $cat_col, value => $val_col,
			($color_m ? (color => $color_col) : ()) },
		options => { scheme => $scheme,
			($color_m ? (color_agg => $color_m->{fn}, color_scheme => $color_scheme) : ()) },
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
	my $scheme    = _optional_scheme($self->param('scheme'));
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

	$bins = _whole_number($bins) // ($bins =~ /\A\d+\z/ ? $MAX_HISTOGRAM_BINS : 1);	# more digits than a number holds is a lot of bins
	$bins = 1   if $bins < 1;
	$bins = $MAX_HISTOGRAM_BINS if $bins > $MAX_HISTOGRAM_BINS;

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
	my $snippet = HTML::D3->new(nonce => $self->csp_nonce, title => $title, width => 800, height => 480)
		->render_histogram_snippet(\@bin_data, {
			binned  => 1,
			x_label => $col,
			($scheme ? (scheme => $scheme) : ()),
		});

	my $chart_html = $snippet->{html};
	utf8::decode($chart_html) unless utf8::is_utf8($chart_html);

	my %chart_spec = (
		kind    => 'histogram',
		title   => $title,
		encode  => { value => $col },
		options => { bins => $bins, ($scheme ? (scheme => $scheme) : ()) },
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

# _map_loc_columns($loc) -> @columns
#
# The place-name columns of a map, in order, from loc: one name (a canvas card
# saved before a place could span columns), or a list of them (loc= repeated,
# or a card's encode.loc array).  Empty and non-string entries are dropped, and
# a column named twice is used once.
sub _map_loc_columns {
	my $loc = shift;
	my @names = ref($loc) eq 'ARRAY' ? @{$loc} : ($loc);
	my %seen;
	return grep { defined($_) && !ref($_) && length($_) && !$seen{$_}++ } @names;
}

# _map_loc_text($value) -> ($text) | ()
#
# The text added to the end of each place (loc_text=, a card's
# encode.loc_text): "Virginia, USA" for a column of county names, tidied by
# Geocode->place_text, as bi-geocode's --text is.  Nothing is returned for a
# value that is not one short line, which the map page refuses and a card,
# stored unchecked, leaves out.
sub _map_loc_text {
	my ($value) = @_;
	require Database::BI::Model::Geocode;
	return Database::BI::Model::Geocode->place_text($value);
}

# How many outlines holding several markers the map page lists, the fullest
# first; a map of shops has thousands, and the list is for looking into a few.
Readonly my $MAP_OUTLINE_GROUPS_MAX => 50;

# _map_outline_groups($outlines, \@markers, \@records, \@columns) -> @groups
#
# Purpose: Why a map has fewer outlines than markers, for the reader to look
#          into: which outlines hold more than one marker, and which markers
#          are in no outline.  Geocoded places that land in the wrong county
#          show up here, as two places in one outline.
# Entry:   $outlines as Boundary's outlines() returns it; each marker has
#          lat, lon, row_indexes (or first_row) and, when it was geocoded,
#          value (the place); the columns that tell rows apart, for the links.
# Exit:    One entry for each outline holding two markers or more, the
#          fullest first, at most $MAP_OUTLINE_GROUPS_MAX of them, then one
#          with none => 1 for the markers in no outline, when there are any:
#          { name, markers, places => [text, ...], rows, filters }.  A marker
#          still waiting for its outline is in neither.  () when every marker
#          has an outline to itself.
# Side effects: none.
sub _map_outline_groups {
	my ($outlines, $markers, $records, $columns) = @_;

	require Database::BI::Model::Boundary;
	my $inside  = $outlines->{inside} // {};
	my %waiting = map { $_ => 1 } @{ $outlines->{pending} // [] };
	my (%held, @none);
	for my $marker (@{$markers}) {
		my $key = Database::BI::Model::Boundary->point_key($marker->{lat}, $marker->{lon});
		next if !defined($key) || $waiting{$key};
		if (defined(my $osm = $inside->{$key})) { push @{ $held{$osm} }, $marker }
		else                                    { push @none, $marker }
	}

	my $group = sub {
		my ($name, $in, %more) = @_;
		my @rows = map { @{ $_->{row_indexes} // [ $_->{first_row} ] } } @{$in};
		return {
			name    => $name,
			markers => scalar(@{$in}),
			# A geocoded marker is known by its place, another by where it is
			places  => [ map {
				(defined($_->{value}) && !ref($_->{value}) && length($_->{value}))
					? $_->{value} : "$_->{lat}, $_->{lon}"
			} @{$in} ],
			rows    => scalar(@rows),
			filters => [ _map_rows_filters($records, \@rows, $columns) ],
			%more,
		};
	};

	my @shared = grep { @{ $held{ $_->{properties}{osm} // '' } // [] } > 1 } @{ $outlines->{features} };
	@shared = sort {
		@{ $held{ $b->{properties}{osm} } } <=> @{ $held{ $a->{properties}{osm} } }
	} @shared;
	splice(@shared, $MAP_OUTLINE_GROUPS_MAX) if @shared > $MAP_OUTLINE_GROUPS_MAX;

	return (
		(map { $group->($_->{properties}{name} // '', $held{ $_->{properties}{osm} }) } @shared),
		(@none ? $group->('', \@none, none => 1) : ()),
	);
}

# _map_rows_filters(\@records, \@row_indexes, \@columns) -> @filters
#
# Purpose: Filters that select exactly the given rows, for a link from the
#          map to them in the table.
# Entry:   Indexes into @records; the columns that tell the rows apart (the
#          place columns, or latitude and longitude).
# Exit:    One "col:in:[...]" filter a column, listing the cells those rows
#          hold.  () when together they would select another row too (two
#          columns' lists can pair up into a row that was not asked for), or
#          when no row or column is given: a link must not show the wrong rows.
# Side effects: none.
sub _map_rows_filters {
	my ($records, $indexes, $columns) = @_;

	my @rows = grep { ref($_) eq 'HASH' } map { $records->[$_] } @{$indexes};
	return () unless @rows && @{$columns};

	my @filters = map {
		my $col = $_;
		my %cells = map { my $cell = $_->{$col}; ((defined($cell) && !ref($cell)) ? $cell : '') => 1 } @rows;
		"$col:in:" . to_json([ sort keys %cells ]);
	} @{$columns};

	# Tried on every row: the filters are kept only if they find just these
	my $hit = [ grep { ref($_) eq 'HASH' } @{$records} ];
	$hit = _apply_filter_spec($hit, $_) for @filters;
	return scalar(@{$hit}) == scalar(@rows) ? @filters : ();
}

# _map_unplotted(\@records, \@places, $loc_col, \@loc_cols, \%resolved)
#     -> (\@entries, \@all_filters)
#
# The places a geocoded map could not plot, so that the page can say which
# they are: one entry for each, in the order of the first row that names it,
# as { place, rows, reason, filters }.  reason is 'empty' (no place in the
# row), 'refused' (not a place name: a bare number), 'not_found', or 'later'
# (not looked up yet: past a cap, or waiting for OpenStreetMap).  filters are
# f= specs that select the place's rows in the table, built from the cells of
# its first row: one for each place column, eq that cell, or empty.
#
# @all_filters select every unplotted row at once: for each place column, in
# the list of its cells in those rows.  Columns filtered apart can pair a cell
# of one row with a cell of another, which may name a place that was plotted,
# so the filters are tried on the rows and kept only when they select exactly
# the unplotted ones; otherwise @all_filters is empty.
sub _map_unplotted {
	my ($records, $places, $loc_col, $loc_cols, $resolved) = @_;

	my %reason;
	for my $value (@{ $resolved->{skipped} // [] }) {
		my $key = (defined($value) && !ref($value)) ? $value : '';
		$reason{$key} = length($key) ? 'refused' : 'empty';
	}
	$reason{$_} = 'not_found' for grep { defined } @{ $resolved->{unresolved}    // [] };
	$reason{$_} = 'later'     for grep { defined } @{ $resolved->{not_attempted} // [] };

	my (%rows, %first, %cells);
	my $total = 0;
	for my $index (0 .. $#{$places}) {
		my $place = $places->[$index];
		my $value = ref($place) eq 'HASH' ? $place->{$loc_col} : undef;
		my $key   = (defined($value) && !ref($value)) ? $value : '';
		next unless exists $reason{$key};
		$rows{$key}++;
		$total++;
		$first{$key} //= $index;

		my $row = $records->[$index];
		for my $col (@{$loc_cols}) {
			my $cell = ref($row) eq 'HASH' ? $row->{$col} : undef;
			$cells{$col}{ (defined($cell) && !ref($cell)) ? $cell : '' } = 1;
		}
	}

	my @all_filters;
	if ($total) {
		@all_filters = map { "$_:in:" . to_json([ sort keys %{ $cells{$_} } ]) } @{$loc_cols};
		# Only rows can be filtered; one that is not is never selected.
		my $hit = [ grep { ref($_) eq 'HASH' } @{$records} ];
		$hit = _apply_filter_spec($hit, $_) for @all_filters;
		@all_filters = () unless scalar(@{$hit}) == $total;
	}

	my @entries = map {
		my $row = $records->[ $first{$_} ];
		$row = {} unless ref($row) eq 'HASH';
		+{
			place   => $_,
			rows    => $rows{$_},
			reason  => $reason{$_},
			filters => [ map {
				my $cell = $row->{$_};
				(defined($cell) && !ref($cell) && length($cell)) ? "$_:eq:$cell" : "$_:empty";
			} @{$loc_cols} ],
		};
	} sort { $first{$a} <=> $first{$b} } keys %first;

	return (\@entries, \@all_filters);
}

# _map_region($config) -> $region or undef
#
# The country hint for the local geocoder: config map_region when it is two
# letters, else none.
sub _map_region {
	my $cfg = shift;
	my $region = $cfg->{map_region};

	return (defined($region) && !ref($region) && $region =~ /\A[A-Za-z]{2}\z/) ? $region : undef;
}

# _map_geocoder($self, $online) -> Database::BI::Model::Geocode
#
# The geocoder a map asks, built from the config the same way for the map page,
# a canvas card and /geo/lookup.  The geocoder is a config seam first and a
# recommended dependency second: a deployment may hand in an object, and a test
# does exactly that.  With neither, the model reports the module as unavailable
# and the map is still the map.
#
# map_geocode_online => 0 keeps every lookup on this machine: a place the local
# data does not know is then not sent to OpenStreetMap.  A false $online does
# the same for one request (the progress run, once Nominatim has failed).
# Geo::Coder::List keeps its answers in files, so a place Nominatim found is not
# asked again by another request, worker or restart.  Geocode->new chooses the
# directory (Object::Configure, CACHEDIR, CACHE_DIR, cache_dir in this config,
# then <model_dir>/geocode-cache).  A model_dir that is refused (inside
# data_dir) gives no default, and with nothing else set the module falls back
# on a cache in this process's memory.
sub _map_geocoder :Protected ($self, $online) {
	require Database::BI::Model::Geocode;

	my $cfg         = $self->app->config;
	my $models_path = $self->_calc_models_path;
	my $injected    = $cfg->{geocoder};

	return Database::BI::Model::Geocode->new(
		(defined($models_path)
			? (model_dir => Mojo::File->new($models_path)->dirname->to_string)
			: ()),
		config => $cfg,
		home   => $self->app->home->to_string,
		(defined($injected) && ref($injected) && $injected->can('geocode_many')
			? (geocoder => $injected) : ()),
		(defined($cfg->{openaddr}) && length($cfg->{openaddr})
			? (openaddr => $cfg->{openaddr}) : ()),
		online     => (($online && ($cfg->{map_geocode_online} // 1)) ? 1 : 0),
		online_max => _map_limit($cfg->{map_geocode_online_max}, $DEFAULT_MAP_GEOCODE_ONLINE_MAX),
	);
}

# _map_boundary($self, $level, $online) -> Database::BI::Model::Boundary
#
# What finds the outline around each marker, for the map and /geo/boundary
# alike.  It asks OpenStreetMap only when the operator allows the geocoder to
# (map_geocode_online), and at most map_geocode_online_max times a request.
# Its answers are kept beside the geocode cache, under model_dir, so they
# outlive the process and are shared by every worker; with no model_dir it
# keeps them in memory.  Config map_bounds_ranks adds or changes the place rank
# that is a county in a country (checked at startup).
sub _map_boundary :Protected ($self, $level, $online) {
	require Database::BI::Model::Boundary;

	my $cfg         = $self->app->config;
	my $models_path = $self->_calc_models_path;
	my $cache;
	if (defined $models_path) {
		my $dir = Mojo::File->new($models_path)->dirname->to_string;
		$cache = eval { Database::BI::Model::Boundary->file_cache($dir) };
	}

	return Database::BI::Model::Boundary->new(
		level      => $level,
		online     => (($online && ($cfg->{map_geocode_online} // 1)) ? 1 : 0),
		online_max => _map_limit($cfg->{map_geocode_online_max}, $DEFAULT_MAP_GEOCODE_ONLINE_MAX),
		(defined($cache) ? (cache => $cache) : ()),
		(ref($cfg->{map_bounds_ranks}) eq 'HASH' ? (ranks => $cfg->{map_bounds_ranks}) : ()),
	);
}

# The colours of county outlines on a heat map, low to high: green, amber,
# red, as the top of the heat layer's own gradient (lime, yellow, red).  An
# outline's colour is one of $OUTLINE_STEPS steps between them, so outlines of
# about the same total share a layer.
Readonly my @OUTLINE_STOPS => ([ 0x1a, 0x98, 0x50 ], [ 0xf5, 0xa6, 0x23 ], [ 0xd7, 0x30, 0x27 ]);
Readonly my $OUTLINE_STEPS => 9;
# How an outline is drawn: thin and grey on a plain map, heavier when its
# colour carries a meaning, so the colour can be told apart on a busy map.
Readonly my %OUTLINE_PLAIN => (colour => '#555555', weight => 1.5, opacity => 0.8);
Readonly my %OUTLINE_HEAT  => (weight => 2.5, opacity => 0.9);
# Colour shade (shade=): each outline filled in a shade of one colour, darker
# for a larger total, as a census map is.  $SHADE_STEPS shades, the lightest
# $SHADE_LIGHTEST of the way from white to the colour so that it still shows;
# the fill lets the map underneath through.
Readonly my $SHADE_STEPS         => 5;
Readonly my $SHADE_LIGHTEST      => 0.15;
Readonly my $SHADE_OPACITY       => 0.65;
Readonly my $DEFAULT_SHADE_COLOR => '#d94801';
# A key's totals are rounded to $KEY_FIGURES significant figures, from
# $KEY_ROUND_FROM up; smaller ones are short enough as they are.
Readonly my $KEY_FIGURES    => 2;
Readonly my $KEY_ROUND_FROM => 100;
# The HTML::OSM whose marker key can leave an entry out while a layer is shown
# (a legend entry's unless_layer).
Readonly my $OSM_KEY_WAITS_VERSION => '0.19';

# _map_outline_layers($self, $outlines, \@markers, $records, $weight_col)
#     -> list of { features, colour, weight, opacity }
#
# The county outlines as layers for add_geojson.  Without the heat layer
# ($weight_col undef) they are one grey layer.  With it, each outline is
# coloured by the total of what is in it: the weight column summed over every
# row of every marker inside it (a cell that is not a number adds nothing), or,
# with no weight column (''), its rows counted.  _outline_shares places each
# total between green and red.  A lone outline, or totals all alike, stays
# grey with no key, having nothing to be compared with; $noun is what an
# outline is called there, for the key's title.  The layers go from low to high, so where two
# outlines share a border the higher is drawn on top; the first carries the
# key to the colours, high to low with the totals each covers.  Each popup names the
# outline and its total.  Leaflet reads a popup as HTML, and a name from
# OpenStreetMap is text, so it is escaped.
sub _map_outline_layers :Protected ($self, $outlines, $markers, $records, $weight_col, $noun) {
	return () unless $outlines && @{ $outlines->{features} };

	my @features = @{ $outlines->{features} };
	my $named = sub {
		my ($feature, $text) = @_;
		# osm stays, so the fill (shade=) can find the outline's total
		return { %{$feature}, properties => { name => xml_escape($text), osm => $feature->{properties}{osm} } };
	};

	# No heat layer: nothing to total, so one grey layer and no key.
	unless (defined $weight_col) {
		return {
			features => [ map { $named->($_, $_->{properties}{name} // '') } @features ],
			%OUTLINE_PLAIN,
		};
	}

	my $total  = $self->_map_outline_totals($outlines->{inside} // {}, $markers, $records, $weight_col);
	my @totals = map { $total->{ $_->{properties}{osm} } // 0 } @features;

	my %seen;
	my @distinct = grep { !$seen{$_}++ } sort { $a <=> $b } @totals;

	# One outline, or totals all alike: there is nothing to compare, so a
	# colour would mean nothing.  Grey, with no key, but the popups still
	# give the totals.
	if (@distinct < 2) {
		return {
			features => [ map {
				$named->($features[$_], $self->_map_outline_popup(
					$features[$_]{properties}{name} // '', $totals[$_], $weight_col))
			} 0 .. $#features ],
			%OUTLINE_PLAIN,
		};
	}
	my $share_of = _outline_shares(\@distinct);

	# Lowest first: a layer is made the first time its step is met, so the
	# layers come out in the order they must be drawn.
	my (%layer_of, @layers);
	for my $i (sort { $totals[$a] <=> $totals[$b] } 0 .. $#features) {
		my $share = $share_of->{ $totals[$i] };
		my $step  = int($share * ($OUTLINE_STEPS - 1) + 0.5);
		my $layer = $layer_of{$step} //= do {
			push @layers, { features => [], totals => [],
				colour => _outline_colour($step / ($OUTLINE_STEPS - 1)), %OUTLINE_HEAT };
			$layers[-1];
		};
		# Sorted already, so each layer's totals are low to high for the key.
		push @{ $layer->{totals} }, $totals[$i];
		my $feature = $features[$i];
		push @{ $layer->{features} }, $named->($feature,
			$self->_map_outline_popup($feature->{properties}{name} // '', $totals[$i], $weight_col));
		# Drawn inside its own edge (HTML::OSM 0.17's bands), so a neighbour of
		# another colour is beside it, not over it.
		$layer->{features}[-1]{properties}{colours} = [ $layer->{colour} ];
		$layer->{bands} = 1;
	}

	# HTML::OSM 0.16 shows one key a layer name and hides it with the layer;
	# an older copy ignores it.  The totals were only for the key.
	$layers[0]{key} = $self->_map_outline_key(\@layers, $weight_col, $noun);
	delete $_->{totals} for @layers;
	return @layers;
}

# _map_outline_marker_layers($self, $outlines, \@markers)
#     -> list of { features, colour, weight, opacity, bands }
#
# Purpose: The outlines coloured as the markers in them, for a map whose
#          markers are coloured by a column.
# Entry:   $outlines as Boundary's outlines() returns it, or undef; each
#          coloured marker has lat, lon and colour (#rgb or #rrggbb).
# Exit:    One layer for each distinct list of colours, the outlines of one
#          colour first.  An outline whose markers differ lists every colour,
#          the one most of its markers have first (the earliest on a tie), in
#          its feature's "colours" property.  A coloured layer has bands set:
#          HTML::OSM 0.17 then draws each outline just inside its own edge, a
#          line of each colour side by side, the first outermost, so
#          neighbours of different colours are beside each other; "colour"
#          (the first) is what an older HTML::OSM draws, along the edge.  () when there is nothing to draw or no marker has a
#          colour, so the caller can fall back.
# Side effects: none.
sub _map_outline_marker_layers :Protected ($self, $outlines, $markers) {
	return () unless $outlines && @{ $outlines->{features} };

	require Database::BI::Model::Boundary;
	my $inside = $outlines->{inside} // {};
	# How many markers of each colour are in each outline, in the order the
	# colours were first met there.
	my (%count, %order);
	for my $marker (@{$markers}) {
		my $colour = $marker->{colour} // next;
		# The script takes #rrggbb only, so #rgb is written out in full
		$colour =~ s/\A#(.)(.)(.)\z/#$1$1$2$2$3$3/;
		my $key = Database::BI::Model::Boundary->point_key($marker->{lat}, $marker->{lon});
		my $osm = defined($key) ? $inside->{$key} : undef;
		next unless defined $osm;
		push @{ $order{$osm} }, $colour unless $count{$osm}{$colour}++;
	}
	return () unless %count;

	my (%layer_of, @layers);
	for my $feature (@{ $outlines->{features} }) {
		my $osm  = $feature->{properties}{osm} // '';
		my $seen = $order{$osm} // [];
		my %place = map { $seen->[$_] => $_ } 0 .. $#{$seen};
		my @colours = sort { $count{$osm}{$b} <=> $count{$osm}{$a} || $place{$a} <=> $place{$b} } @{$seen};
		# An outline none of whose markers is coloured stays grey
		my $style = @colours ? { colour => $colours[0], %OUTLINE_HEAT } : { %OUTLINE_PLAIN };
		my $layer = $layer_of{"@colours"} //= do {
			push @layers, { features => [], %{$style}, bands => (@colours ? 1 : 0), mixed => (@colours > 1 ? 1 : 0) };
			$layers[-1];
		};
		# Leaflet reads a popup as HTML, and a name from OpenStreetMap is text
		push @{ $layer->{features} }, {
			%{$feature},
			properties => { name => xml_escape($feature->{properties}{name} // ''), colours => \@colours, osm => $osm },
		};
	}
	# Those of several colours last: only an older HTML::OSM, which draws every
	# outline along its edge, can draw one over another, and then they show.
	return sort { $a->{mixed} <=> $b->{mixed} } @layers;
}

# _map_outline_shade($self, \@layers, $outlines, \@markers, $records, $col, $colour, $noun, $lower)
#     -> list of layers, each with fill
#
# Purpose: Colour shade: fill each outline in a shade of a colour, by the
#          total of $col in it.
# Entry:   @layers as _map_outline_layers or _map_outline_marker_layers made
#          them (each feature keeps its osm and an escaped name); $col is a
#          column of $records.  $colour is the one colour to shade, as
#          _parse_color takes one, or undef for the default.  $lower, when a
#          hashref, says the markers are coloured and no colour was asked for:
#          each outline is then shaded in its own line colour (its markers'),
#          and $lower->{<#rrggbb>} is true for a colour whose rule is "less
#          than", where the smaller total is the stronger.
# Exit:    Each layer split by shade, so every part has one line style and
#          one "fill" (#rrggbb), in the order given.  One colour: darker for a
#          larger total, across every outline.  The markers' colours: each
#          colour is a scale of its own over the outlines of that colour,
#          stronger the further the total is into what the colour stands for
#          (larger, or smaller for a "less than" colour), so a county well
#          under a "below 20,000" rule is greener than one just under it; a
#          colour with one total is its middle shade.  The shade follows
#          _outline_shares, as the heat colours do.  Each popup names the
#          outline and its total; the first layer carries the key, every
#          shade in use by size, the largest totals first, drawn as boxes (HTML::OSM 0.18; an older copy
#          draws lines).  () with one colour when fewer than two totals
#          differ: nothing to compare, so the caller leaves the outlines
#          unfilled.
# Side effects: none.
sub _map_outline_shade :Protected ($self, $layers, $outlines, $markers, $records, $col, $colour, $noun, $lower) {
	return () unless $outlines && @{$layers};

	my $total  = $self->_map_outline_totals($outlines->{inside} // {}, $markers, $records, $col);
	my $amount = sub { return $total->{ $_[0]{properties}{osm} // '' } // 0 };
	my $one    = _color_hex(_parse_color($colour // '') // $DEFAULT_SHADE_COLOR);

	# The colour each layer is shaded in: the one colour, or its own line's.
	# Written out as #rrggbb, which _shade_colour reads.
	my $hue_of = sub {
		my $hue = $lower ? $_[0]{colour} : $one;
		$hue =~ s/\A#(.)(.)(.)\z/#$1$1$2$2$3$3/;
		return lc $hue;
	};

	# Each colour's totals, then where each sits on that colour's scale.
	my (%totals_of, @hues);
	for my $layer (@{$layers}) {
		my $hue = $hue_of->($layer);
		push @hues, $hue unless $totals_of{$hue};
		$totals_of{$hue}{ $amount->($_) } = 1 for @{ $layer->{features} };
	}
	return () if !$lower && keys(%{ $totals_of{ $hues[0] } }) < 2;
	my %share_of;
	for my $hue (@hues) {
		my @distinct = sort { $a <=> $b } keys %{ $totals_of{$hue} };
		my $shares   = @distinct > 1 ? _outline_shares(\@distinct) : { $distinct[0] => 0.5 };
		# A "less than" colour is the stronger the smaller the total
		$shares = { map { $_ => 1 - $shares->{$_} } keys %{$shares} } if $lower && $lower->{$hue};
		$share_of{$hue} = $shares;
	}

	my (@shaded, %amounts);
	for my $layer (@{$layers}) {
		my $hue = $hue_of->($layer);
		my (%part, @steps);
		for my $feature (@{ $layer->{features} }) {
			my $sum  = $amount->($feature);
			my $step = int($share_of{$hue}{$sum} * ($SHADE_STEPS - 1) + 0.5);
			push @steps, $step unless $part{$step};
			push @{ $amounts{$hue}{$step} }, $sum;
			# The name is escaped already; the column is text of the reader's
			push @{ $part{$step} }, {
				%{$feature},
				properties => {
					%{ $feature->{properties} },
					name => $self->_i18n('map_bounds_total',
						$feature->{properties}{name} // '', _map_total_text($sum), xml_escape($col)),
				},
			};
		}
		push @shaded, map {
			+{ %{$layer}, features => $part{$_}, fill => _shade_colour($hue, $_ / ($SHADE_STEPS - 1)) }
		} sort { $a <=> $b } @steps;
	}

	# One key for the fills, in place of any the lines had: for each colour
	# the shades in use, strongest first as _map_outline_key lists them,
	# drawn as boxes.
	delete $_->{key} for @shaded;
	# They are listed by size whatever their colour, the largest totals at the
	# top, so a key of red above 100,000 and green below 20,000 runs from the
	# strongest red down to the strongest green.
	my @in_use = sort { $a->{totals}[-1] <=> $b->{totals}[-1] || $a->{totals}[0] <=> $b->{totals}[0] } map {
		my $hue = $_;
		map {
			+{ colour => _shade_colour($hue, $_ / ($SHADE_STEPS - 1)),
				totals => [ sort { $a <=> $b } @{ $amounts{$hue}{$_} } ] }
		} keys %{ $amounts{$hue} };
	} @hues;
	$shaded[0]{key} = { %{ $self->_map_outline_key(\@in_use, $col, $noun) }, shape => 'box' };
	return @shaded;
}

# _shade_colour($hex, $share) -> '#rrggbb': $hex (#rrggbb) at its full
# strength for a share of 1, down to $SHADE_LIGHTEST of the way from white for
# a share of 0.
sub _shade_colour {
	my ($hex, $share) = @_;
	$share = 0 if $share < 0;
	$share = 1 if $share > 1;
	my $strength = $SHADE_LIGHTEST + (1 - $SHADE_LIGHTEST) * $share;
	return sprintf('#%02x%02x%02x',
		map { int(255 + (hex($_) - 255) * $strength + 0.5) } $hex =~ /\A#(..)(..)(..)\z/);
}

# _map_outline_totals($self, \%inside, \@markers, $records, $weight_col) -> \%total
#
# Purpose: What is in each outline, for its colour.
# Entry:   %inside maps a point key to the osm of the outline it is in (from
#          Boundary's outlines()); each marker has lat, lon and row_indexes
#          (or first_row); $weight_col is a column, or '' to count rows.
# Exit:    { osm => total }; an outline no marker is in has no entry.
# Side effects: none.  Rows are only read, so locked SQL rows are safe.
sub _map_outline_totals :Protected ($self, $inside, $markers, $records, $weight_col) {
	require Database::BI::Model::Boundary;
	my %total;
	for my $marker (@{$markers}) {
		my $key = Database::BI::Model::Boundary->point_key($marker->{lat}, $marker->{lon});
		my $osm = defined($key) ? $inside->{$key} : undef;
		next unless defined $osm;
		# A marker stands for every row at its place, not only the first.
		for my $index (@{ $marker->{row_indexes} // [ $marker->{first_row} ] }) {
			my $row = $records->[$index];
			next unless ref($row) eq 'HASH';
			# A cell that is not a number adds nothing, as on the heat layer.
			$total{$osm} += length($weight_col) ? (_numeric_cell($row->{$weight_col} // '') // 0) : 1;
		}
	}
	return \%total;
}

# _map_outline_popup($self, $name, $total, $weight_col) -> $text
#
# Purpose: The text of a coloured outline's popup: its name and its total.
# Entry:   $weight_col is the column totalled, or '' when rows were counted.
# Exit:    Plain text (the caller escapes it); one row is "1 row", not "1 rows".
# Side effects: none.
sub _map_outline_popup :Protected ($self, $name, $total, $weight_col) {
	return $self->_i18n('map_bounds_total', $name, _map_total_text($total), $weight_col) if length $weight_col;
	return $total == 1
		? $self->_i18n('map_bounds_row', $name)
		: $self->_i18n('map_bounds_rows', $name, _map_total_text($total));
}

# _map_outline_key($self, \@layers, $weight_col) -> { title, entries }
#
# Purpose: The key to the outline colours, for add_geojson's key option.
# Entry:   Each layer has its colour and its totals, low to high; the layers
#          are low to high too, and there is at least one.
# Exit:    The entries are the highest colour first, each labelled with the
#          total it covers, or the range when it covers unequal totals.
# Side effects: none.
sub _map_outline_key :Protected ($self, $layers, $weight_col, $noun) {
	my @entries = map {
		my ($low, $high) = @{ $_->{totals} }[0, -1];
		+{
			colour => $_->{colour},
			# Round figures: a key is read at a glance, and the popups
			# give each outline's exact total.
			label  => (_map_key_number($low) eq _map_key_number($high) ? _map_key_number($low)
				: $self->_i18n('map_bounds_key_range', _map_key_number($low), _map_key_number($high))),
		};
	} reverse @{$layers};
	return {
		title   => (length($weight_col)
			? $self->_i18n('map_bounds_key_total', $weight_col, $noun)
			: $self->_i18n('map_bounds_key_rows', $noun)),
		entries => \@entries,
	};
}

# _outline_shares(\@distinct) -> { total => share }
#
# Purpose: Where each total sits between the lowest (0) and the highest (1),
#          which decides its colour.
# Entry:   At least two distinct totals, sorted low to high.
# Exit:    When every total is above zero, the share is by size on a log
#          scale: each step up the colours is the same multiple, so totals
#          close in size share a colour and totals far apart do not.  A
#          straight scale would leave most outlines green, because such totals
#          are skewed (Fairfax County has 500 times the people of Highland).
#          A total of zero or less has no logarithm, so then the share is by
#          rank: evenly spread in order, whatever the sizes.
# Side effects: none.
sub _outline_shares {
	my ($distinct) = @_;
	my %share;
	if ($distinct->[0] > 0) {
		my ($low, $high) = (log $distinct->[0], log $distinct->[-1]);
		# The ends are set exactly, so rounding cannot push them off the scale.
		%share = map { $_ => (log($_) - $low) / ($high - $low) } @{$distinct};
		@share{ $distinct->[0], $distinct->[-1] } = (0, 1);
	} else {
		%share = map { $distinct->[$_] => $_ / $#{$distinct} } 0 .. $#{$distinct};
	}
	return \%share;
}

# _map_outline_noun($self, $outlines) -> $word
#
# Purpose: What the outlines drawn are called ("county", "district"), for the
#          layer's checkbox, the key and the summary line.
# Entry:   $outlines as Boundary's outlines() returns it, or undef.
# Exit:    The word for the one kind drawn; "area" when the map mixes kinds
#          (a county and a province); "county" when nothing is drawn.
# Side effects: none.
sub _map_outline_noun :Protected ($self, $outlines) {
	my %called = map { ($_->{properties}{called} // 'county') => 1 } @{ $outlines ? $outlines->{features} : [] };
	my @kinds = keys %called;
	my $kind  = @kinds > 1 ? 'area' : ($kinds[0] // 'county');
	return $self->_i18n("map_bounds_noun_$kind");
}

# _outline_colour($share) -> '#rrggbb' at $share (0..1) along @OUTLINE_STOPS
sub _outline_colour {
	my ($share) = @_;
	$share = 0 if $share < 0;
	$share = 1 if $share > 1;
	my $at   = $share * $#OUTLINE_STOPS;
	my $from = int($at);
	$from = $#OUTLINE_STOPS - 1 if $from >= $#OUTLINE_STOPS;
	my $part = $at - $from;
	my ($lo, $hi) = @OUTLINE_STOPS[ $from, $from + 1 ];
	return sprintf('#%02x%02x%02x', map { int($lo->[$_] + ($hi->[$_] - $lo->[$_]) * $part + 0.5) } 0 .. 2);
}

# _map_key_number($n) -> a total as a key shows it: rounded to two figures
# ("330,000" for 330,818, "1,200,000" for 1,150,309), since a key gives ranges
# to be read at a glance.  A total under 100 is given as it is.
sub _map_key_number {
	my ($n) = @_;
	return _map_total_text($n) if abs($n) < $KEY_ROUND_FROM;
	my $unit = 10 ** (POSIX::floor(log(abs($n)) / log(10)) - ($KEY_FIGURES - 1));
	return _map_total_text(POSIX::floor($n / $unit + 0.5) * $unit);
}

# _map_total_text($n) -> the total as a popup shows it: thousands separated,
# and at most two decimal places ("1,150,309", "12.5").
sub _map_total_text {
	my ($n) = @_;
	my $text = sprintf('%.2f', $n);
	$text =~ s/\.?0+\z// if $text =~ /\./;
	# A small negative total rounds to nothing; say 0, not "-0".
	$text = '0' if $text eq '-0';
	my ($whole, $fraction) = split /\./, $text, 2;
	1 while $whole =~ s/^(-?\d+)(\d{3})/$1,$2/;
	return defined($fraction) ? "$whole.$fraction" : $whole;
}

# _map_bounds_level($value) -> the level, or undef when $value names none
#
# bounds= on the map page, and a map card's options.bounds, which is stored
# unchecked.
sub _map_bounds_level {
	my ($value) = @_;
	return unless defined($value) && !ref($value) && length($value);
	require Database::BI::Model::Boundary;
	return (grep { $_ eq $value } Database::BI::Model::Boundary->levels) ? $value : undef;
}

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
	$spec_key = canonical_spec($spec_key);
	$encode  //= {};
	$options //= {};

	# loc may name several columns, in order: the place is their cells joined
	# with ", " (an address and then its country).  $loc_col is that list's
	# name, which is what the page and the geocoder are told.
	my @loc_cols = _map_loc_columns($encode->{loc});
	my $loc_col = join(', ', @loc_cols);
	my $lat_col = $encode->{lat} // '';
	my $lon_col = $encode->{lon} // '';
	my $by_location = length $loc_col;
	my ($loc_text) = _map_loc_text($encode->{loc_text});
	$loc_text = '' unless defined($loc_text) && $by_location;

	return { error => $self->_i18n('error_map_source'), status => 400 }
		unless $by_location || length($lat_col) || length($lon_col);
	return { error => $self->_i18n('error_map_coordinates'), status => 400 }
		if !$by_location && (!length($lat_col) || !length($lon_col));

	my %col_set = map { $_ => 1 } @$columns;
	my $cfg     = $self->app->config;

	my %loc_set = map { $_ => 1 } @loc_cols;
	my @popup = grep {
		defined($_) && !ref($_) && length($_) && !$loc_set{$_} && $col_set{$_}
	} @{ ref($options->{popup}) eq 'ARRAY' ? $options->{popup} : [] };

	# Default: when no popup columns are requested, show every column that is
	# not a coordinate column so the marker tooltip is informative out of the box.
	unless (@popup) {
		my %coord_set = map { $_ => 1 }
			grep { defined($_) && length($_) } (@loc_cols, $lat_col, $lon_col);
		@popup = grep { !$coord_set{$_} } @$columns;
	}

	my ($backend, $plotted_rows) = (undef, 0);
	my (@markers, @messages, @unplotted, @unplotted_filters, @pending);

	# How many rows a popup lists, and where the rest are: the map page passes
	# rows_url, which makes a table link from filters; a canvas card has none.
	my $popup_rows = _map_limit($cfg->{map_popup_rows}, $DEFAULT_MAP_POPUP_ROWS);
	my $rows_url   = ref($options->{rows_url}) eq 'CODE' ? $options->{rows_url} : undef;

	if ($by_location) {
		for my $col (@loc_cols) {
			return { error => $self->_i18n('error_map_loc_column', $col), status => 400 }
				unless $col_set{$col};
		}

		require Database::BI::Model::Geocode;

		# What the geocoder is given: one cell a row, under $loc_col, in the
		# rows' own order, so a marker's first_row still indexes $records.
		my ($places) = Database::BI::Model::Geocode->place_rows($records, \@loc_cols, $loc_text);

		my $geocode = $self->_map_geocoder(1);

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
		my $region     = _map_region($cfg);

		# lookup => 0 (the map page in a browser) asks nothing here: the
		# places not cached yet come back as pending, and the page looks them
		# up one at a time through /geo/lookup, with a progress bar.
		my $result = $geocode->resolve_column(
			$places, $loc_col,
			cache => \%cache,
			(defined($region) ? (region => $region) : ()),
			max   => _map_limit($cfg->{map_geocode_max}, $DEFAULT_MAP_GEOCODE_MAX),
			lookup => ((defined($options->{lookup}) && !$options->{lookup}) ? 0 : 1),
		);
		@pending = @{ $result->{pending} // [] };

		push @messages, @{ $result->{messages} };
		$backend      = $result->{backend};
		$plotted_rows = $result->{counts}{plotted};
		my ($entries, $all) = _map_unplotted($records, $places, $loc_col, \@loc_cols, $result);
		@unplotted         = @{$entries};
		@unplotted_filters = @{$all};

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

		# Every row at a place, keyed as the geocoder keyed the place, so its
		# popup can list them all and not only the first.
		my %rows_at;
		for my $index (0 .. $#{$places}) {
			my $place = $places->[$index];
			my $value = ref($place) eq 'HASH' ? $place->{$loc_col} : undef;
			push @{ $rows_at{ (defined($value) && !ref($value)) ? $value : '' } }, $index;
		}

		for my $marker (@{ $result->{markers} }) {
			my @at  = @{ $rows_at{ $marker->{value} } // [] };
			my $row = $records->[ $at[0] // $marker->{first_row} ];
			$row = {} unless ref($row) eq 'HASH';
			my $more_url = $rows_url ? $rows_url->([ map {
				my $cell = $row->{$_};
				(defined($cell) && !ref($cell) && length($cell)) ? "$_:eq:$cell" : "$_:empty";
			} @loc_cols ]) : '';
			push @markers, {
				%{ $marker },
				'row_indexes' => \@at,
				'label' => _map_popup(
					$marker->{value}, [ @{$records}[@at] ], \@popup, $popup_rows, $more_url,
				),
			};
		}

	} else {
		return { error => "Column not found: $lat_col", status => 400 }
			unless $col_set{$lat_col};
		return { error => "Column not found: $lon_col", status => 400 }
			unless $col_set{$lon_col};

		my (%by_key, %rows_at, $out_of_lat, $out_of_lon, $unusable);

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
			push @{ $rows_at{$key} }, $index;
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
			my $key = sprintf('%.6f,%.6f', $marker->{lat}, $marker->{lon});
			$marker->{row_indexes} = $rows_at{$key};
			my $row = $records->[ $marker->{first_row} ];
			my $more_url = $rows_url ? $rows_url->([
				"$lat_col:eq:" . ($row->{$lat_col} // ''),
				"$lon_col:eq:" . ($row->{$lon_col} // ''),
			]) : '';
			$marker->{label} = _map_popup(
				sprintf('%.6f, %.6f', $marker->{lat}, $marker->{lon}),
				[ @{$records}[ @{ $rows_at{$key} } ] ], \@popup, $popup_rows, $more_url,
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

	# The outline of the county around each marker (bounds=county).  Those
	# not known yet are looked up here, up to the online limit, unless the
	# caller said lookup => 0: the map page in a browser lists them for its
	# progress bar instead, as it does places.
	my $bounds_level = _map_bounds_level($options->{bounds});
	my ($outlines, @bounds_pending);
	my $bounds_coloured = 0;	# set when the outlines are coloured by their totals
	my $bounds_as_markers = 0;	# set when they take their markers' colours
	my $bounds_shade = '';	# the column they are filled by (shade=), when they are
	my $bounds_shade_as = '';	# 'one' colour, or the 'markers' colours
	my (@bounds_left_filters, $bounds_left_rows);	# the rows whose marker has no outline
	my @bounds_groups;	# why there are fewer outlines than markers (_map_outline_groups)
	if (defined($bounds_level) && @markers) {
		my $lookup = (defined($options->{lookup}) && !$options->{lookup}) ? 0 : 1;
		$outlines = $self->_map_boundary($bounds_level, 1)->outlines(
			[ map { [ $_->{lat}, $_->{lon} ] } @markers ],
			lookup => $lookup,
		);
		@bounds_pending = @{ $outlines->{pending} };
		if (@bounds_pending) {
			# The rows behind the markers left without an outline, for a link
			# to them in the table, as the rows not plotted have.
			require Database::BI::Model::Boundary;
			my %left = map { $_ => 1 } @bounds_pending;
			my @rows = map { @{ $_->{row_indexes} // [ $_->{first_row} ] } } grep {
				my $key = Database::BI::Model::Boundary->point_key($_->{lat}, $_->{lon});
				defined($key) && $left{$key};
			} @markers;
			$bounds_left_rows    = scalar @rows;
			@bounds_left_filters = _map_rows_filters($records, \@rows,
				[ $by_location ? @loc_cols : ($lat_col, $lon_col) ]);
			my $key = $outlines->{offline} ? 'warn_map_bounds_offline'
				: $outlines->{failed}      ? 'warn_map_bounds_failed'
				:                            'warn_map_bounds_pending';
			push @messages, {
				key  => $key,
				# One place "has" no outline; the key stays the plural's
				text => $self->_i18n($key . (@bounds_pending == 1 ? '_one' : ''),
					scalar(@bounds_pending), $outlines->{counts}{points}),
			};
		}
		@bounds_groups = _map_outline_groups($outlines, \@markers, $records,
			[ $by_location ? @loc_cols : ($lat_col, $lon_col) ]);
	}

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
			# The renderer is a third-party module: whatever it does, the page
			# reports it and survives, as it does when the module is absent.
			# The map page passes the colour and size columns as options; a
			# canvas card has them in its encode, as the page saved them.  A
			# card's are stored unchecked, so one that names no column is
			# left out rather than refused.
			my $color_col = $options->{color_col} // $encode->{color} // '';
			$color_col = '' if ref($color_col) || !$col_set{$color_col};
			# A card's rules are stored unchecked: one that is not a rule is
			# left out rather than read as one.
			my $color_rules   = [ grep { ref($_) eq 'HASH' }
				@{ ref($options->{color_rules}) eq 'ARRAY' ? $options->{color_rules} : [] } ];
			my $color_default = $options->{color_default} // $DEFAULT_MARKER_COLOR;
			my $size_col = $options->{size} // $encode->{size} // '';
			$size_col = '' if ref($size_col) || !$col_set{$size_col};

			# The scale bar, and the key on the map: colours and bubble sizes.
			my $size_range = [ _map_size_range($records, \@markers, $size_col) ];
			# When the outlines are shaded in the markers' colours by the column
			# the colours read, the shade key lists every colour with its totals,
			# so a second key of the same colours would only repeat it.  Shaded by
			# another column, or in one colour, the marker key is still the only
			# place the colours are explained.  Bubble sizes are listed either way.
			my $shade_covers = length($color_col) && $outlines && @{ $outlines->{features} }
				&& !ref($options->{shade} // '') && ($options->{shade} // '') eq $color_col
				&& !defined($options->{shade_color});
			# HTML::OSM 0.19 can leave a key entry out while a layer is shown and
			# bring it back when the reader hides the layer, so the markers are
			# never left without a key; an older copy cannot, and gets no colour
			# entries at all.
			my $key_waits = $shade_covers
				&& eval { version->parse($osm_version) >= version->parse($OSM_KEY_WAITS_VERSION) };
			my %key = $self->_map_key((($shade_covers && !$key_waits) ? '' : $color_col), $color_rules,
				$color_default, defined($options->{scheme}), $size_col, $size_range);
			if ($key_waits) {
				my $layer = $self->_i18n('map_bounds_layer', ucfirst $self->_map_outline_noun($outlines));
				$_->{unless_layer} = $layer for grep { defined $_->{group} } @{ $key{legend} // [] };
			}
			$osm_args{scale} = 1;
			# Every <script> the map writes carries the page's nonce.
			$osm_args{nonce} = $self->csp_nonce;
			# Without a zoom the map opens on every marker, as the panel promises
			$osm_args{fit} = 1 unless defined $options->{zoom};
			%osm_args = (%osm_args, %key) if @{ $key{legend} // [] };

			my $drawn = eval {
				my $map = HTML::OSM->new(%osm_args);

				# Bubble maps: one radius per marker, scaled across the plotted
				# values.  Circle markers keep their pixel size as the reader
				# zooms, which is what makes them comparable.
				my ($size_min, $size_max) = @{$size_range};

				for my $marker (@markers) {
					my $row = $records->[ $marker->{first_row} ];
					my ($color, $group);
					if (length $color_col) {
						my $cval = (defined($row) ? $row->{$color_col} : undef) // '';
						$color = _apply_color_rule($cval, $color_rules, $color_default);
						# Which key entry the marker belongs to, so the key lists
						# only what is in view
						my $index = _color_rule_index($cval, $color_rules);
						$group = defined($index) ? "rule$index" : 'other';
						# Kept for the outline round it, which is drawn to match
						$marker->{colour} = _color_hex($color);
					}
					if (length $size_col) {
						my $sv = defined($row)
							? _numeric_cell($row->{$size_col} // '') : undef;
						$map->add_circle_marker(
							[ $marker->{lat}, $marker->{lon} ],
							html   => $marker->{label},
							radius => _map_radius($sv, $size_min, $size_max),
							(defined($color) ? (colour => _color_hex($color)) : ()),
							(defined($group) ? (group  => $group)            : ()),
						);
					} else {
						$map->add_marker(
							[ $marker->{lat}, $marker->{lon} ],
							html => $marker->{label},
							(defined($color) ? (icon => _marker_icon($color)) : ()),
							(defined($group) ? (group => $group)              : ()),
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

				# The county outlines, under the markers, with a checkbox on
				# the map to hide them (HTML::OSM 0.15; an older copy ignores
				# name and draws them always).  Grey, or with heat=1 coloured
				# by what the heat layer weighs in each, one layer a colour
				# under one name, so one checkbox still hides them all.
				# When the markers are coloured, each outline takes the colours
				# of the markers in it, so the two never disagree; the heat
				# layer's own scale is for a map whose markers are all alike.
				my $noun = $self->_map_outline_noun($outlines);
				my @outline_layers = length($color_col)
					? $self->_map_outline_marker_layers($outlines, \@markers) : ();
				$bounds_as_markers = 1 if @outline_layers;
				# Colour shade fills each outline by a column's total.  It says
				# what the heat layer's line colours would, so those stay grey.
				my $shade_col = $options->{shade} // '';
				$shade_col = '' if ref($shade_col) || !$col_set{$shade_col};
				@outline_layers = $self->_map_outline_layers($outlines, \@markers, $records,
					(($options->{heat} && !length($shade_col)) ? ($options->{weight} // '') : undef), $noun)
					unless @outline_layers;
				if (length $shade_col) {
					# Coloured markers and no colour asked for: each outline is
					# shaded in its markers' colour.  When the shade is of the
					# column the rules read, a "less than" rule's colour is the
					# stronger the smaller the total.
					my $lower;
					if ($bounds_as_markers && !defined($options->{shade_color})) {
						$lower = {};
						for my $rule ($shade_col eq $color_col ? @{$color_rules} : ()) {
							my $hue = _color_hex($rule->{color});
							$hue =~ s/\A#(.)(.)(.)\z/#$1$1$2$2$3$3/;
							$lower->{ lc $hue } //= (($rule->{op} // '') =~ /\Al[te]\z/) ? 1 : 0;
						}
					}
					my @shaded = $self->_map_outline_shade(\@outline_layers, $outlines, \@markers,
						$records, $shade_col, $options->{shade_color}, $noun, $lower);
					if (@shaded) {
						@outline_layers  = @shaded;
						$bounds_shade    = $shade_col;
						$bounds_shade_as = $lower ? 'markers' : 'one';
					}
				}
				for my $layer (@outline_layers) {
					# Only a layer with a key was coloured to mean something;
					# a shaded map's key is for its fills.
					$bounds_coloured = 1 if $layer->{key} && !length($bounds_shade);
					$map->add_geojson(
						{ type => 'FeatureCollection', features => $layer->{features} },
						style => { color => $layer->{colour}, weight => $layer->{weight},
							opacity => $layer->{opacity},
							($layer->{fill}
								? (fill => \1, fillColor => $layer->{fill}, fillOpacity => $SHADE_OPACITY)
								: (fill => \0)) },
						popup => 'name',
						name  => $self->_i18n('map_bounds_layer', ucfirst $noun),
						($layer->{key} ? (key => $layer->{key}) : ()),
						# HTML::OSM 0.17 draws each colour as a line of its own,
						# inside the outline's edge; an older copy ignores this
						# and draws the first alone, along the edge.
						($layer->{bands} ? (bands => 'colours') : ()),
					);
				}

				($map_head, $map_body) = $map->onload_render();
				($map_head, $map_body) = _canvas_map_html($map_head, $map_body, $id_suffix)
					if defined($id_suffix) && length($id_suffix);
				1;
			};
			unless ($drawn) {
				$self->app->log->error('The map could not be drawn: ' . _tidy_error($@));
				($map_head, $map_body) = ();
				push @messages, {
					key  => 'error_map_renderer_failed',
					text => $self->_i18n('error_map_renderer_failed'),
				};
			}
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
		encode => ($by_location
			? { loc => (@loc_cols == 1 ? $loc_cols[0] : [ @loc_cols ]),
			    (length($loc_text) ? (loc_text => $loc_text) : ()) }
			: { lat => $lat_col, lon => $lon_col }),
	);
	$chart_spec{options}{popup} = \@popup if @popup;
	$chart_spec{options}{max}   = $options->{max}
		if defined($options->{max}) && $options->{max} =~ /\A\d+\z/ && $options->{max} > 0;
	$chart_spec{options}{zoom}  = $options->{zoom}  if defined $options->{zoom};
	$chart_spec{options}{heat}  = 1                 if $options->{heat};
	$chart_spec{options}{bounds} = $bounds_level    if defined $bounds_level;
	$chart_spec{options}{shade}  = $options->{shade}
		if defined($options->{shade}) && !ref($options->{shade}) && length($options->{shade});
	$chart_spec{options}{shade_color} = $options->{shade_color}
		if defined($chart_spec{options}{shade}) && defined($options->{shade_color}) && !ref($options->{shade_color});
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
		loc_text     => $loc_text,
		lat_col      => ($by_location ? undef    : $lat_col),
		lon_col      => ($by_location ? undef    : $lon_col),
		backend      => $backend,
		chart        => \%chart_spec,
		unplotted    => \@unplotted,
		unplotted_filters => \@unplotted_filters,
		pending      => \@pending,
		bounds_level   => $bounds_level,
		bounds_pending => \@bounds_pending,
		bounds_drawn   => ($outlines ? $outlines->{counts}{drawn} : 0),
		bounds_noun    => $self->_map_outline_noun($outlines),
		# Coloured by the heat layer's weight column, or its rows when it has
		# none; not when the outlines had nothing to compare and stayed grey.
		bounds_heat    => $bounds_coloured,
		bounds_weight  => ($bounds_coloured ? ($options->{weight} // '') : ''),
		bounds_as_markers => $bounds_as_markers,
		bounds_shade   => $bounds_shade,
		bounds_shade_as => $bounds_shade_as,
		bounds_left_filters => \@bounds_left_filters,
		bounds_groups  => \@bounds_groups,
		bounds_left_rows    => $bounds_left_rows // 0,
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
	my @loc_cols  = _map_loc_columns($self->every_param('loc'));
	my $loc_col   = join(', ', @loc_cols);
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
	my $bounds_raw   = $self->param('bounds')   // '';
	my $loc_text_raw = $self->param('loc_text') // '';
	my $weight_col   = $self->param('weight')   // '';
	my $shade_col    = $self->param('shade')    // '';
	my $shade_color  = _parse_color($self->param('shade_color') // '');
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

	my ($loc_text) = _map_loc_text($loc_text_raw);
	return $self->render(text => $self->_i18n('error_map_loc_text', $Database::BI::Model::Geocode::PLACE_TEXT_MAX, $loc_text_raw), status => 400)
		unless defined $loc_text;

	my $bounds_level;
	if (length $bounds_raw) {
		$bounds_level = _map_bounds_level($bounds_raw);
		return $self->render(text => $self->_i18n('error_map_bounds_unknown', $bounds_raw), status => 400)
			unless defined $bounds_level;
	}

	return $self->render(text => $self->_i18n('error_map_source'), status => 400)
		unless $by_location || length($lat_col) || length($lon_col);
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

	# geocode= says when the places not in the cache yet are looked up: 'wait'
	# in this request, before the page is sent; 'cached' not at all, so the map
	# shows what the cache knows (where Cancel leads).  Without it, a page a
	# browser navigated to (a GET whose Accept names text/html, which fetch()
	# and scripts do not send) asks nothing here: it lists the places for the
	# page, which looks them up one at a time with a progress bar.  Any other
	# client waits, as every client did before.
	my $geocode_mode = $self->param('geocode') // '';
	return $self->render(text => $self->_i18n('error_map_geocode_mode', $geocode_mode), status => 400)
		unless $geocode_mode =~ /\A(?:wait|cached|)\z/;
	my $progress = ($by_location || defined($bounds_level)) && !length($geocode_mode)
		&& $self->req->method eq 'GET'
		&& ($self->req->headers->accept // '') =~ m{\btext/html\b};

	return unless $self->_reduce_or_render(\$records, \$columns);

	my %col_set = map { $_ => 1 } @{ $columns };
	my %loc_set = map { $_ => 1 } @loc_cols;
	my @popup = grep { length($_) && !$loc_set{$_} && $col_set{$_} }
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
	$options{bounds}   = $bounds_level   if defined $bounds_level;
	$options{weight}   = $weight_col     if length($weight_col) && $col_set{$weight_col};
	# Colour shade: a column to fill the outlines by, and the colour to shade
	$options{shade}    = $shade_col      if length($shade_col) && $col_set{$shade_col};
	$options{shade_color} = $shade_color if defined($shade_color) && defined($options{shade});
	$options{lookup}   = 0               if $progress || $geocode_mode eq 'cached';

	# Each place that could not be plotted, and each marker with more rows
	# than its popup lists, links to its rows in the table, as a bar drills
	# into its category: the table this map came from, with
	# the place's filters added, and back2= to return here.
	my $rows_base = ($back =~ m{\A(?:https?://[^/]+)?/(?:open\?|view/)}) ? $back
		: $self->_spec_to_url($self->param('l') // '');
	my $here = $self->req->url->path_query;
	my $rows_url = sub {
		my ($filters) = @_;
		return '' if $rows_base eq '/' || !@{$filters};
		my $sep = ($rows_base =~ /\?/) ? '&' : '?';
		return $rows_base . $sep . join('&',
			(map { 'f=' . url_escape(encode('UTF-8', $_)) } @{$filters}),
			'back2=' . url_escape($here),
			'back2_label=' . url_escape('Back to map'),
		);
	};
	$options{rows_url} = $rows_url;

	my $result = $self->_map_data(
		$records, $columns,
		($by_location ? { loc => [ @loc_cols ], loc_text => $loc_text } : { lat => $lat_col, lon => $lon_col }),
		\%options,
		$self->param('l') // '',
		undef,
	);

	return $self->render(text => $result->{error}, status => $result->{status})
		if $result->{error};

	my ($source_url, $source_accessed) = $self->_url_attribution;
	my ($platform, $language) = $self->_resolve_template;

	my @unplotted = map {
		my $entry = { %{$_} };
		$entry->{url} = $rows_url->($entry->{filters});
		$entry;
	} @{ $result->{unplotted} // [] };
	my $unplotted_rows = 0;
	$unplotted_rows += $_->{rows} for @unplotted;

	# This page with geocode= set to $mode, or without it for undef.
	my $here_with = sub {
		my ($mode) = @_;
		my $url = $self->req->url->clone;
		$url->query->remove('geocode');
		$url->query->append(geocode => $mode) if defined $mode;
		return $url->path_query;
	};

	# The places to look up, each signed so that /geo/lookup asks only what a
	# map page listed: without that, any page on the web could post a string
	# for this server to send to OpenStreetMap.
	my @pending = $progress ? @{ $result->{pending} // [] } : ();
	# The points whose county outline is not known yet go on the same list,
	# after the places, each signed with its level for /geo/boundary.
	my @bounds_pending = $progress ? @{ $result->{bounds_pending} // [] } : ();
	my @messages = @{ $result->{messages} };
	@messages = grep { $_->{key} ne 'warn_map_bounds_pending' } @messages if @bounds_pending;
	my %progress;
	if (@pending || @bounds_pending) {
		my $json = to_json([
			(map { { place => $_, sig => $self->_geo_lookup_sig($_) } } @pending),
			(map { {
				point => $_,
				level => $result->{bounds_level},
				sig   => $self->_geo_boundary_sig($result->{bounds_level}, $_),
			} } @bounds_pending),
		]);
		$json =~ s{</}{<\\/}g;
		%progress = (
			geocode_pending      => scalar(@pending) + scalar(@bounds_pending),
			geocode_places       => scalar @pending,
			geocode_outlines     => scalar @bounds_pending,
			geocode_pending_json => $json,
			geocode_done_url     => $here_with->(undef),
			geocode_cached_url   => $here_with->('cached'),
			geocode_wait_url     => $here_with->('wait'),
		);
	}

	# After Cancel, the places left are offered again.
	$progress{geocode_retry_url} = $here_with->(undef)
		if $geocode_mode eq 'cached' && grep { $_->{reason} eq 'later' } @unplotted;

	$self->render(
		handler         => 'tt',
		template        => "$platform/$language/map",
		%progress,
		unplotted       => \@unplotted,
		unplotted_rows  => $unplotted_rows,
		unplotted_url   => $rows_url->($result->{unplotted_filters} // []),
		# Where the outlines and the markers do not pair off, each with a link
		# to its rows
		bounds_groups   => [ map { +{ %{$_}, url => $rows_url->($_->{filters}) } } @{ $result->{bounds_groups} // [] } ],
		# The rows whose place has no county outline, and this page again to
		# look those outlines up (as it was opened: waiting, or with progress)
		bounds_left_url  => $rows_url->($result->{bounds_left_filters} // []),
		bounds_left_rows => $result->{bounds_left_rows},
		bounds_left      => scalar(@{ $result->{bounds_pending} // [] }),
		bounds_retry_url => $here_with->($geocode_mode eq 'wait' ? 'wait' : undef),
		format          => 'html',
		title           => $result->{title},
		extra_head      => $result->{map_head},
		map_body        => $result->{map_body},
		messages        => \@messages,
		marker_count    => $result->{marker_count},
		bounds_drawn    => $result->{bounds_drawn},
		bounds_heat     => $result->{bounds_heat},
		bounds_noun     => $result->{bounds_noun},
		bounds_as_markers => $result->{bounds_as_markers},
		bounds_shade    => $result->{bounds_shade},
		bounds_shade_as => $result->{bounds_shade_as},
		bounds_weight   => $result->{bounds_weight},
		row_count       => $result->{row_count},
		source_rows     => $result->{source_rows},
		loc_col         => $result->{loc_col},
		loc_many        => (@loc_cols > 1 ? 1 : 0),
		loc_text        => $result->{loc_text},
		lat_col         => $result->{lat_col},
		lon_col         => $result->{lon_col},
		backend         => $result->{backend},
		chart           => $result->{chart},
		chart_json      => $self->_chart_json($result->{chart}),
		back_url        => ($back2 // $back),
		back_label      => ($back2 ? ($back2_lbl || 'Back') : 'Back to table'),
		($back2 ? (back2_url => $back, back2_label => 'Back to table') : ()),
		source_url      => $source_url,
		source_accessed => $source_accessed,
		language        => $language,
	);
}

# _geo_lookup_sig($self, $place) -> $hex
#
# What the map page signs each place it lists with, and /geo/lookup checks.
# The key is the application's secret, which BI.pm makes at random for each
# start unless the config names one, so a list outlives neither a restart nor
# another installation.
sub _geo_lookup_sig :Protected ($self, $place) {
	return hmac_sha1_sum(encode('UTF-8', "geo-lookup\0$place"), $self->app->secrets->[0]);
}

# _geo_boundary_sig($self, $level, $point) -> $hex
#
# The same for a point whose outline the map page lists.  Its own prefix, so a
# place's signature is never a point's.
sub _geo_boundary_sig :Protected ($self, $level, $point) {
	return hmac_sha1_sum(encode('UTF-8', "geo-boundary\0$level\0$point"), $self->app->secrets->[0]);
}

# ---------------------------------------------------------------------------
# POST /geo/boundary  point=<lat,lon>&level=county&sig=<sig>[&online=0]
#
# One point's outline, for the map page's progress bar: found as the map would
# find it, and remembered at once, so a run that is cancelled keeps what it
# found.  The point must carry the signature the map page gave it, or any page
# on the web could have this server send coordinates to OpenStreetMap.
# online=0 asks nothing, after OpenStreetMap has failed once.
#
# Replies 200 JSON:
#   { point, status => 'found' | 'nowhere' | 'held', stored => 0|1,
#     online_failed => 0|1, name }
# 'nowhere' is a point in no county (at sea); 'held' could not be settled now
# and is asked again next time.
# 400 JSON { error } without point= or sig=, or with an unknown level=;
# 403 JSON { error } for a bad sig=.
# ---------------------------------------------------------------------------
sub geo_boundary ($self) {
	my $point = $self->param('point') // '';
	my $sig   = $self->param('sig')   // '';
	my $level = _map_bounds_level($self->param('level') // 'county');

	return $self->render(json => { error => $self->_i18n('error_geo_boundary_point') }, status => 400)
		unless length($point) && length($sig) && defined($level);
	return $self->render(json => { error => $self->_i18n('error_geo_boundary_unsigned') }, status => 403)
		unless secure_compare($sig, $self->_geo_boundary_sig($level, $point));

	my $online = ($self->param('online') // 1) ? 1 : 0;
	my $answer = eval { $self->_map_boundary($level, $online)->lookup_point($point) };
	return $self->render(json => { error => $self->_i18n('error_geo_boundary_point') }, status => 400)
		unless $answer;

	return $self->render(json => {
		point         => $point,
		status        => $answer->{status},
		stored        => ($answer->{status} eq 'held' ? 0 : 1),
		online_failed => (($answer->{status} eq 'held' && $answer->{asked}) ? 1 : 0),
		name          => $answer->{name},
	});
}

# ---------------------------------------------------------------------------
# POST /geo/lookup  place=<place>&sig=<sig>[&online=0]
#
# One place, for the map page's progress bar: looked up as the map would, and
# its answer saved in the shared place cache straight away, so a run that is
# cancelled or interrupted keeps every place it found.  The place must carry the
# signature the map page gave it.  online=0 keeps the lookup on this machine;
# the page sends it once OpenStreetMap has failed, so that each place left does
# not wait for it again.
#
# Replies 200 JSON:
#   { place, status => 'found' | 'not_found' | 'held' | 'refused',
#     stored => 0|1, online_failed => 0|1, messages => [ text ... ] }
# 'held' is a place that could not be looked up now (OpenStreetMap did not
# answer, or the geocoder is missing); it is not remembered, so the next map
# asks again.  stored says that the answer is in the cache: a found or
# not-found place the store refused to keep is 0.
# 400 JSON { error } without place= or sig=; 403 JSON { error } for a bad sig=.
# ---------------------------------------------------------------------------
sub geo_lookup ($self) {
	my $place = $self->param('place') // '';
	my $sig   = $self->param('sig')   // '';

	return $self->render(json => { error => $self->_i18n('error_geo_lookup_place') }, status => 400)
		unless length($place) && length($sig);
	return $self->render(json => { error => $self->_i18n('error_geo_lookup_unsigned') }, status => 403)
		unless secure_compare($sig, $self->_geo_lookup_sig($place));

	my $cfg     = $self->app->config;
	my $geocode = $self->_map_geocoder(($self->param('online') // 1) ? 1 : 0);
	my $models  = $self->_read_models;
	my $region  = _map_region($cfg);

	my $result = $geocode->resolve_values(
		[ $place ],
		cache => Database::BI::Model::Geocode->shared_cache_from_models($models),
		(defined($region) ? (region => $region) : ()),
		max   => 1,
	);

	my $status = $result->{points}{$place}		? 'found'
		: (grep { $_ eq $place } @{ $result->{unresolved} })	? 'not_found'
		: (grep { $_ eq $place } @{ $result->{skipped} })	? 'refused'
		:							  'held';

	# A place another tab answered meanwhile is in the cache already.
	my $stored = ($status eq 'found' || $status eq 'not_found') && !$result->{counts}{attempted};

	if ($result->{counts}{attempted} && $status ne 'held') {
		my $backend = $result->{backend};
		$stored = $self->_write_models(Database::BI::Model::Geocode->models_with_shared_cache(
			$models, { $place => $result->{cache}{$place} },
			(defined($backend) ? (backend => $backend) : ()),
			built => _iso8601_utc(),
		)) ? 1 : 0;
	}

	my @messages = map { $_->{text} } grep {
		$_->{key} ne 'warn_map_geocoder_unavailable_data'
	} @{ $result->{messages} };

	return $self->render(json => {
		place         => $place,
		status        => $status,
		stored        => $stored ? 1 : 0,
		online_failed => (grep { $_->{key} eq 'warn_map_geocoder_online_failed' } @{ $result->{messages} }) ? 1 : 0,
		messages      => \@messages,
	});
}

# _map_popup($heading, \@rows, \@columns, $limit, $more_url) -> $html
#
# The popup for one marker: what it is, how many rows it stands for, and the
# rows themselves.  A value every row shares is said once, as "Column: value";
# the columns that differ are a small table of at most $limit rows, in a box
# that scrolls, so a place with many rows does not cover the map.  The rest
# are counted, with a link to them in the table when $more_url is given.
# Leaflet treats a popup string as HTML, and a value out of a user's file is
# not markup, so every value is escaped here.
sub _map_popup {
	my ($heading, $rows, $columns, $limit, $more_url) = @_;

	my @rows = grep { ref($_) eq 'HASH' } @{ ref($rows) eq 'ARRAY' ? $rows : [] };
	my @cols = grep { defined($_) && !ref($_) && length($_) } @{ ref($columns) eq 'ARRAY' ? $columns : [] };
	$limit = _map_limit($limit, $DEFAULT_MAP_POPUP_ROWS);
	my $cell = sub { my $v = $_[0]->{ $_[1] }; (defined($v) && !ref($v)) ? $v : '' };

	my @lines = '<strong>' . xml_escape($heading // '') . '</strong>';
	push @lines, scalar(@rows) . ' rows' if @rows > 1;

	# The same in every row, or not.
	my (@shared, @differ);
	for my $col (@cols) {
		my %seen = map { $cell->($_, $col) => 1 } @rows;
		if (keys(%seen) > 1) { push @differ, $col }
		elsif (@rows)        { push @shared, [ $col, $cell->($rows[0], $col) ] }
	}
	push @lines, map { xml_escape($_->[0]) . ': ' . xml_escape($_->[1]) }
		grep { length $_->[1] } @shared;

	my $html = join('<br>', @lines);
	return $html unless @differ;

	# The box keeps its size and scroll inline, one style a marker, so a page
	# without the stylesheet still cannot be covered; the cells' spacing is
	# .bi-map-popup-rows in the page's stylesheet, not repeated in every cell.
	my @shown = @rows > $limit ? @rows[0 .. $limit - 1] : @rows;
	$html .= '<div class="bi-map-popup-rows" style="max-height:14em;overflow:auto">'
		. '<table><tr>' . join('', map { '<th>' . xml_escape($_) . '</th>' } @differ) . '</tr>'
		. join('', map {
			my $row = $_;
			'<tr>' . join('', map { '<td>' . xml_escape($cell->($row, $_)) . '</td>' } @differ) . '</tr>';
		} @shown)
		. '</table></div>';

	if (my $more = @rows - @shown) {
		$html .= "<div>and $more more"
			. ((defined($more_url) && length($more_url))
				? ': <a href="' . xml_escape($more_url) . '">show all ' . scalar(@rows) . ' in the table</a>'
				: '')
			. '</div>';
	}

	return $html;
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

	return $default unless defined($value) && ($value =~ /\A\d{1,$MAX_WHOLE_NUMBER_DIGITS}\z/) && ($value > 0);

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

# _map_colour_entries($color_col, \@rules, $default, $is_series) -> @entries
#
# The colour key of a map, as { color, label, group }: one entry for each rule,
# and Other for the default colour.  A series (series= with a scheme) is
# listed by value, with no Other: its values past the palette's two cycles
# take a palette colour but are not listed.  group names the entry for
# _color_rule_index's answer ("rule<N>", or "other"), which is how HTML::OSM
# lists only the entries in view.
sub _map_colour_entries {
	my ($color_col, $rules, $default, $is_series) = @_;

	my %op_label = (gt => '>', ge => '>=', lt => '<', le => '<=', eq => '=', ne => '!=');
	my @entries;
	$rules = [] unless ref($rules) eq 'ARRAY';
	for my $index (0 .. $#{$rules}) {
		my $rule = $rules->[$index];
		next unless ref($rule) eq 'HASH';
		my $val  = $rule->{val} // '';
		push @entries, {
			color => $rule->{color},
			label => $is_series
				? (length($val) ? $val : '(blank)')
				: "$color_col " . ($op_label{ $rule->{op} // '' } // $rule->{op} // '') . " $val",
			group => "rule$index",
		};
	}
	push @entries, { color => $default, label => 'Other', group => 'other' }
		if @entries && !$is_series;
	return @entries;
}

# _map_key($self, $color_col, \@rules, $default, $is_series, $size_col, \@range)
#     -> (legend => \@entries, legend_title => $title, legend_empty => $text)
#
# What HTML::OSM is given to draw a map's key: the colour entries, each with
# its group so the key lists only what is in view, then two or three bubble
# sizes when a size column is set (those are always listed: they say what a
# size means, wherever the reader is).  The title is the colour column, or
# the size column when there is no colour; with both, each size is labelled
# with its column.  The colours go to HTML::OSM as hex, which is all it takes.
sub _map_key :Protected ($self, $color_col, $rules, $default, $is_series, $size_col, $range) {
	my @legend = map {
		{ label => $_->{label}, colour => _color_hex($_->{color}), group => $_->{group} }
	} (length($color_col) ? _map_colour_entries($color_col, $rules, $default, $is_series) : ());

	my ($min, $max) = @{ $range // [] };
	if (length($size_col) && defined($min)) {
		my @values = ($max > $min) ? ($min, ($min + $max) / 2, $max) : ($min);
		for my $value (@values) {
			my $text = 0 + sprintf('%.4g', $value);
			push @legend, {
				label  => (@legend && length($color_col) ? "$size_col $text" : "$text"),
				colour => (length($color_col) ? $MAP_SIZE_KEY_COLOR : _color_hex($default)),
				radius => _map_radius($value, $min, $max),
			};
		}
	}

	return () unless @legend;
	return (
		legend       => \@legend,
		legend_title => (length($color_col) ? $color_col : $size_col),
		legend_empty => $self->_i18n('map_legend_empty'),
	);
}

# _color_rule_index($value, \@rules) -> $index | undef
#
# The index of the first rule that matches $value, or undef when none does
# (the marker takes the default colour).  _apply_color_rule says the colour.
sub _color_rule_index {
	my ($value, $rules) = @_;
	$value //= '';
	$rules = [] unless ref($rules) eq 'ARRAY';
	for my $index (0 .. $#{$rules}) {
		next unless ref($rules->[$index]) eq 'HASH';
		my ($op, $threshold) = @{ $rules->[$index] }{qw(op val)};
		$op        //= '';
		$threshold //= '';
		my $match;
		if (	$value     =~ /\A-?\d+(?:\.\d+)?\z/ &&
			$threshold =~ /\A-?\d+(?:\.\d+)?\z/) {
			my ($num_val, $num_thr) = ($value + 0, $threshold + 0);
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
		return $index if $match;
	}
	return undef;
}

# _apply_color_rule($value, \@rules, $default_color) -> $color
#
# Returns the first colour whose rule matches $value, or $default_color.
# Numeric comparisons are used when both sides look like plain numbers.
sub _apply_color_rule {
	my ($value, $rules, $default) = @_;
	my $index = _color_rule_index($value, $rules);
	return defined($index) ? $rules->[$index]{color} : $default;
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
	return Database::BI::Util::iso8601_utc();
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
	my $mtime_str = $mtime ? Database::BI::Util::minute_stamp(gmtime($mtime)) . ' UTC' : '';

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

=head2 canvases_view

C<GET /canvases> -- The saved canvases, as cards that open, select and delete,
with Import canvas.  The main navigation's Canvases link.  The list is the one
the home page shows (C<layouts/canvas_list.html.tt>); here it also says when
there are none, and how to make one.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

C<200> with the HTML page.  The cards are drawn by the page from
C<GET /api/analyses>.

=cut

sub canvases_view ($self) {
	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler        => 'tt',
		template       => "$platform/$language/canvases",
		format         => 'html',
		title          => 'Canvases',
		canvases_empty => 'There are no saved canvases yet. To make one, open a table and click New canvas..., or import a canvas from a file.',
		language       => $language,
	);
}

# _share_secret($self) -> $secret_string
#
# The key share and embed tokens are signed with: config share_secret, else
# one derived from the application's first secret.  It used to fall back to a
# fixed string, the same on every install, so anyone could sign a token for
# any canvas, with any expiry, and read it without the password.  The first
# secret is random for each start unless config secrets sets it, so without
# either a restart ends every link (_share_links_last says which).  It is
# derived, not the secret itself, so a token is never a signature that the
# session cookie or a map list would also accept.
sub _share_secret :Protected ($self) {
	my $s = $self->app->config('share_secret') // '';
	return $s if !ref($s) && length $s;
	require Digest::SHA;
	return Digest::SHA::hmac_sha256_hex('Database::BI share tokens', $self->app->secrets->[0]);
}

# _share_links_last($self) -> 1 | 0
#
# Whether a share link outlives a restart: true when share_secret or secrets
# is configured, so the key is the same next time.
sub _share_links_last :Protected ($self) {
	my $s       = $self->app->config('share_secret') // '';
	my $secrets = $self->app->config('secrets');
	return (!ref($s) && length $s) || (ref($secrets) eq 'ARRAY' && @{$secrets}) ? 1 : 0;
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
	return undef unless length($hmac) == length($expected);
	# Every character is compared, so the time taken says nothing about how
	# much of a guessed signature was right.
	my $diff = 0;
	$diff |= ord(substr($hmac, $_, 1)) ^ ord(substr($expected, $_, 1)) for 0 .. length($expected) - 1;
	return undef if $diff;
	return 1;
}

# POST /api/analyses/:id/share
sub analyses_share ($self) {
	my $id = $self->stash('id') // '';
	return $self->render(json => { error => _message_text('error_analysis_id_invalid') }, status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(json => { error => sprintf(_message_text('error_analysis_not_found'), $id) }, status => 404)
		unless exists $analyses->{$id};

	my $expires = time() + $SHARE_TOKEN_TTL;
	my $token   = $self->_make_share_token($id, $expires);
	my $url     = $self->req->url->base->to_string . "/share/$id?token=" . url_escape($token);

	$self->render(json => {
		token => $token, url => $url, expires => $expires,
		lasts_restart => $self->_share_links_last ? Mojo::JSON::true() : Mojo::JSON::false(),
	});
}

# GET /share/:id?token=...
sub share_view ($self) {
	my $id    = $self->stash('id') // '';
	my $token = $self->param('token') // '';
	return $self->render(text => _message_text('error_analysis_id_invalid'), status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => _message_text('error_token_missing'), status => 401)
		unless length $token;
	unless ($self->_verify_share_token($id, $token)) {
		return $self->render(text => _message_text('error_token_invalid'), status => 403);
	}

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf(_message_text('error_analysis_not_found'), $id), status => 404)
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
	return $self->render(text => _message_text('error_analysis_id_invalid'), status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => _message_text('error_token_missing'), status => 401)
		unless length $token;
	unless ($self->_verify_share_token($id, $token)) {
		return $self->render(text => _message_text('error_token_invalid'), status => 403);
	}

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf(_message_text('error_analysis_not_found'), $id), status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	# Every HTML page gets this from the after_dispatch hook in Database::BI;
	# the page made to be framed says it itself, so it never depends on that.
	# The sites embed_frame_ancestors names are allowed by frame-ancestors,
	# which the browsers that know it follow in place of this header; those
	# that know only this header refuse them, which is the safe way to fail.
	$self->res->headers->header('X-Frame-Options' => 'SAMEORIGIN');
	my @framers = Database::BI::_embed_frame_ancestors($self->app->config);
	$self->stash(csp_frame_ancestors => \@framers) if @framers;

	my @visuals = @{ $a->{visuals} // [] };
	unless (@visuals) {
		return $self->render(text => 'This shared analysis has no visuals', status => 404);
	}

	# Drawn as on the canvas page, each card through its own failure: one card that
	# cannot be drawn says so, and leaves the others.
	my $ctx = $self->_canvas_render_context($a, $self->req->url->query->to_string);
	return $self->render(text => $ctx->{error}, status => $ctx->{status})
		if $ctx->{error};

	my (@rendered, $head);
	for my $i (0 .. $#visuals) {
		my $vis  = $visuals[$i];
		my $card = eval {
			$self->_render_visual_html(
				$vis, $ctx->{records}, $ctx->{columns}, $ctx->{src}, $i, $ctx->{spec_key}, 0, $ctx->{cross_row},
			);
		} // { error => _tidy_error($@) };
		$head //= $card->{head} if length($card->{head} // '');
		push @rendered, {
			id    => $i,
			title => ($vis->{title} // $card->{title} // ''),
			html  => $card->{html},
			error => $card->{error},
			kind  => ($vis->{kind} // ''),
			plain => _text_card_plain($vis),
		};
	}

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
		card_head   => ($head // ''),
		language    => $language,
	);
}

# GET /a/:id/visual/:n/:format
sub visual_download ($self) {
	my $id     = $self->stash('id')     // '';
	my $n      = $self->stash('n')      // 0;
	my $format = $self->stash('fmt') // '';

	return $self->render(text => _message_text('error_analysis_id_invalid'), status => 400)
		unless $id =~ /\A[A-Za-z0-9]+\z/;
	return $self->render(text => 'Format must be csv or png', status => 400)
		unless $format =~ /\A(?:csv|png)\z/;
	return $self->render(text => 'Visual index must be a non-negative integer', status => 400)
		unless $n =~ /\A\d+\z/;

	my $analyses = $self->_read_analyses;
	return $self->render(text => sprintf(_message_text('error_analysis_not_found'), $id), status => 404)
		unless exists $analyses->{$id};
	my $a = $analyses->{$id};

	my @visuals = @{ $a->{visuals} // [] };
	return $self->render(text => "Visual $n not found", status => 404)
		unless $n < scalar @visuals;
	return $self->render(text => _message_text('error_text_card_no_data'), status => 404)
		if ($visuals[$n]{kind} // '') eq 'text';

	if ($format eq 'csv') {
		$self->stash(buffer => 0);
		# The canvas names its own source: l= on this URL is no way to reach another.
		my $ctx = $self->_canvas_render_context($a, $self->req->url->query->to_string);
		return $self->render(text => $ctx->{error}, status => $ctx->{status})
			if $ctx->{error};
		my $records = $ctx->{records};
		for my $spec (@{ $visuals[$n]{filters} // [] }) {
			$records = _apply_filter_spec($records, $spec);
		}
		$self->res->headers->content_disposition(
			"attachment; filename=\"visual-$n.csv\""
		);
		return $self->render(data => _serialize_csv($records, $ctx->{columns}), format => 'txt');
	}

	# PNG: not implemented in the server (canvas/SVG rendering is client-side).
	# Return 501 with a descriptive message.
	return $self->render(
		text   => 'PNG download requires the browser SVG renderer; use the PNG button on the card',
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
	return $self->render(json => { error => _message_text('ask_unavailable') }, status => 503)
		unless length $api_key;

	my $left_spec = $self->param('l') // '';
	return $self->render(json => { error => 'Missing required parameter: l' }, status => 400)
		unless length $left_spec;

	my $question = $self->param('q') // '';
	return $self->render(json => { error => _message_text('ask_no_question') }, status => 400)
		unless length $question;
	return $self->render(json => { error => sprintf(_message_text('ask_question_too_long'), $ASK_MAX_QUESTION) }, status => 400)
		if length($question) > $ASK_MAX_QUESTION;

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

	return $self->render(json => { error => sprintf(_message_text('ai_limit_reached'), _ai_calls_per_hour($self)) }, status => 429)
		unless _ai_call_allowed($self);

	my $result = Database::BI::Ask::ask(
		question  => $question,
		spec_key  => $left_spec,
		label     => $left_label // $left_spec,
		columns   => $typed_cols,
		ai_config => $ai_config,
	);

	if (my $err = $result->{error}) {
		my ($status, $msg) =
			$err eq 'ask_unavailable'              ? (503, _message_text('ask_unavailable'))
		  : $err eq 'ask_no_question'              ? (400, _message_text('ask_no_question'))
		  : $err eq 'ask_provider_error'           ? (502, _message_text('ask_provider_error'))
		  : $err eq 'ask_unparseable'              ? (422, _message_text('ask_unparseable'))
		  : $err =~ /\Aask_invalid_spec:(.+)\z/   ? (422, sprintf(_message_text('ask_invalid_spec'), $1))
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
	(my $label = $left_spec) =~ s/\A(?:table:|path:|url:|mariadb:|redis:[^|]+\|)//;

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
		ai_allowed => sub { _ai_call_allowed($self) },
	);

	return $self->render(json => $result);
}

# _ai_calls_per_hour($c) -> $n
#
# Config ai_calls_per_hour, else $AI_CALLS_PER_HOUR; 0 means no limit.
sub _ai_calls_per_hour {
	my ($c) = @_;
	my $n = $c->app->config('ai_calls_per_hour');
	return defined($n) && $n =~ /\A\d+\z/ ? $n : $AI_CALLS_PER_HOUR;
}

# _ai_call_allowed($c) -> 1 | 0
#
# Takes one provider call from this process's budget: the times of the calls
# in the last hour, kept per application (tests build many in one process).
# Returns 0, taking nothing, when the hour's calls are used up.
my %AI_CALLS;
sub _ai_call_allowed {
	my ($c) = @_;
	my $max = _ai_calls_per_hour($c);
	return 1 unless $max;
	my $now   = time;
	my $calls = $AI_CALLS{ Scalar::Util::refaddr($c->app) } //= [];
	@{$calls} = grep { $_ > $now - $AI_WINDOW_S } @{$calls};
	return 0 if @{$calls} >= $max;
	push @{$calls}, $now;
	return 1;
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
	(my $left_label = $left_spec) =~ s/\A(?:table:|path:|url:|mariadb:|redis:[^|]+\|)//;

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
                  - Export buttons for SVG, PNG and PDF (legend is composited in).
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
  500 application/json   { "error": "Could not clear the uploaded files" }

The 500 is for a staging directory the application may not read or change; the
reason goes to the log.  C<freed> is the total number of bytes removed.  C<count> is the number of
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
  scheme=<name>   Take the bar colour and the line colour from the first two
                  colours of a categorical scheme: tableau10, category10, set2,
                  set3 or paired.  Any other name keeps steel blue and red.
  back=<url>      URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l         spec    Required.  Left table spec.
  cat       string  Required.  X-axis categorical column name (x= also accepted).
  bar_val   string  Required.  Numeric bar-measure column (bar= also accepted).
  line_val  string  Required.  Numeric line-measure column (line= also accepted).
  scheme    string  Optional.  Categorical scheme name; ignored unless one of
                               the five.  Saved in data-chart when used.
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

  GET /combo?l=table:sales&cat=month&bar_val=revenue&line_val=units&scheme=set2
    -> the same chart, bars #66c2a5 and line #fc8d62

=cut

=head2 treemap_view

C<GET /treemap> -- Render a D3.js treemap where tile area encodes a numeric column.

Accepts the same C<l=>, C<j=>, C<f=> pipeline params as C</join>, plus:

  group=<col>   Tile-label categorical column (required; cat= is a backwards-compat alias)
  size=<col>    Tile-area numeric column, summed (val= is a backwards-compat
                alias); absent, each tile is its count of rows
  topn=N        Keep only the top-N tiles by size; remainder collapsed into "Other"
  scheme=<name> D3 categorical colour scheme (default tableau10)
  color=<col>   Shade each tile by a second column instead, folded over the
                tile's rows; the Other tile is folded over the rows it holds
  color_agg=<fn>    How color= is folded: avg (the default), sum, min, max,
                    median, count, ... (any aggregate function)
  color_scheme=<name> Sequential scale for color=: YlOrRd (the default), Blues,
                    Greens, Purples, RdPu or YlGnBu
  back=<url>    URL for the "Back to table" breadcrumb link

=head3 API SPECIFICATION

=head4 INPUT

  l       spec    Required.  Left table spec.
  group   string  Required.  Tile-label categorical column (cat= also accepted).
  size    string  Optional.  Tile-area numeric column (val= also accepted);
                             absent or __count__ counts rows.
  topn    int     Optional.  Keep top-N tiles; 0 or absent means no limit.
  scheme  string  Optional.  D3 categorical scheme name; any other is tableau10.
  color   string  Optional.  Column each tile is shaded by.
  color_agg    string  Optional.  Aggregate function for color=; default avg,
                                  case-insensitive.  Ignored without color=.
  color_scheme string  Optional.  Sequential scale; any other name is YlOrRd.
  back    url     Optional.  Safe back-link URL.

=head4 OUTPUT

  200 text/html    Rendered treemap page.
  400 text/plain   Missing group= parameter.
  400 text/plain   Unknown aggregate function "<fn>"... (color_agg=, with color=).
  400 text/plain   Column not found: <col> (group=, size= or color=).
  404 text/plain   "Could not open data source".

=head3 FORMAL SPECIFICATION

  treemap_view == lambda self .
    pre  length(group_col) > 0 /\ length(size_col) > 0
         /\ group_col in columns /\ size_col in columns
         /\ (color_col = '' \/ (color_col in columns /\ color_fn in MEASURE_FNS))
    let tiles = _grouped_totals(records, group_col, [], size_sum) in
    let top   = topn > 0 ? top_n(tiles, topn) : tiles in
    let shade = color_col = '' ? {} :
                { t -> color_fn(rows_of(t), color_col) | t in top } in
    post render(treemap, top, shade, color_scheme)

=head3 EXAMPLE

  GET /treemap?l=table:sales&group=product&size=amount&topn=10
    -> 200 HTML page containing D3 treemap SVG

  GET /treemap?l=table:sales&group=region&size=amount&color=amount&color_agg=max&color_scheme=Blues
    -> tiles sized by total amount, shaded by the largest sale, on a blue scale

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

A browser is not kept waiting for the geocoder.  The page it navigated to (a
GET whose Accept names C<text/html>) plots what the cache knows and lists the
places not cached yet, each signed with the application's secret.  Its script
then posts them, one at a time, to C<POST /geo/lookup> (L</geo_lookup>), with a
progress bar naming each place and a Cancel button.  When the last answer is
in, it draws the page again; after Cancel, or when a place could not be settled
(not answered, or the store refused it), it draws it with C<geocode=cached>,
whose notes link back to the page without it.  Any other client, and
C<geocode=wait>, waits for the lookups as before.

The map page never shows the L<HTML::OSM> Nominatim search box: C<search => 0>
is always passed, so nothing typed on the page leaves the reader's machine.
L<HTML::OSM> 0.14 or later is the renderer; with an older optional install (or
none at all) the page still renders the marker count and a warning, rather than
failing.

Accepts the same C<l=>, C<j=>, C<c=> and C<f=> pipeline params as every other
visual, so the map shows the filtered, calculated view.

  loc=<col>       Location column to geocode (required unless lat= and lon= are given);
                  repeatable: the place is the columns' cells joined with ", ",
                  in order, empty ones left out (loc=Address&loc=Country)
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
  geocode=wait    Look up places not cached yet before the page is sent
                  (the default for a client that is not a browser)
  geocode=cached  Look nothing up; plot what the cache knows
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
C<map_geocode_online> (0 keeps every lookup local; default 1, which asks
OpenStreetMap's Nominatim about places the local data does not know),
C<map_geocode_online_max> (places asked of Nominatim per request, default 20;
the progress bar asks one place a request),
C<map_max_markers> (markers per request, default 2000), C<map_region> (a
two-letter country hint for ambiguous place names), C<map_max_zoom> (the tile
layer's default maxZoom), C<tile_sources> (a hashref of named tile sources,
each C<< { url => ... } >>), C<tile_url> (the single default tile layer) and
C<geocoder> (an object to use instead of the L<Geo::Coder::List> chain; the seam
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
  geocode  string  Optional.  'wait' or 'cached'; see above.
  back     url     Optional.  Safe back-link URL (sanitised by _safe_back_url).

=head4 OUTPUT

  200 text/html    Rendered map page; for a browser, with the progress bar
                   when places are not cached yet.
  400 text/plain   geocode= other than wait or cached.
  400 text/plain   No loc=, or lat= without lon=.
  400 text/plain   Column not found: <col>  (or the geocode message naming it).
  400 text/plain   Coordinate column wholly out of range, naming it.
  400 text/plain   Unknown tile source "<name>".
  400 text/plain   Unknown colour scheme: <name>.
  400 text/plain   Use either color= or series=, not both.
  404 text/plain   "Could not open data source" when l= is absent/invalid.

=head3 EXAMPLE

  GET /map?l=table:sales&loc=place
  GET /map?l=table:houses&loc=Address&loc=Country
    -> 200 HTML page containing Leaflet markers for the places that resolved

=cut

=head2 geo_lookup

C<POST /geo/lookup> -- Look up one place for the map page's progress bar.

The place is looked up as C<GET /map> would look it up (the same geocoder,
file cache and region), and the answer goes into the model store's shared place
cache before the reply is sent.  A run that is cancelled or interrupted
therefore keeps every place it found.  Only a place a map page listed is
accepted: the page signs each one with the application's secret, so no other
site can have this server send a string to OpenStreetMap.

=head3 API SPECIFICATION

=head4 INPUT

  place   string  Required.  The place, as the map page listed it.
  sig     string  Required.  The signature the map page gave it.
  online  bool    Optional.  0 keeps the lookup on this machine (sent once
                  OpenStreetMap has failed in the run).  Default 1.

=head4 OUTPUT

  200 application/json
    { place         => $place,
      status        => 'found' | 'not_found' | 'held' | 'refused',
      stored        => 0 | 1,     # the answer is in the shared cache
      online_failed => 0 | 1,     # OpenStreetMap did not answer
      messages      => [ $text, ... ] }
  400 application/json  { error }  place= or sig= missing.
  403 application/json  { error }  sig= is not this server's for the place
                                   (or the server has restarted since).

C<held> is a place that could not be looked up now; it is not remembered, so
the next map asks again.  C<refused> is a value the geocoder does not take for
a place.  A found or not-found place that the store would not keep has
C<stored> 0.

=head3 EXAMPLE

  POST /geo/lookup  place=Brezje%208%2C%20Cerknica&sig=...
    -> { "place": "Brezje 8, Cerknica", "status": "found", "stored": 1,
         "online_failed": 0, "messages": [] }

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

=head2 analyses_list / analyses_create / analyses_get / analyses_update / analyses_patch / analyses_delete / analyses_import / analyses_export / analyses_add_visual / analyses_update_visual / analyses_delete_visual

C</api/analyses> -- CRUD and import/export for saved analyses.  Documents are
validated on write: unknown top-level keys are dropped and a document that is
not a JSON object is refused.  Import accepts a document exported by
C<GET /api/analyses/:id/export> and creates a new id.  A document on disc that
has been edited into the wrong shape is read with the bad parts treated as
absent, so it is still served.

=head3 API SPECIFICATION

=head4 INPUT / OUTPUT

  GET    /api/analyses                 -> 200 { analyses: [ { id, name, datasets, updated }, ... ] }
  POST   /api/analyses                 <- JSON document; 201 { id, created: 1 } or 400 { error }
  POST   /api/analyses/import          <- JSON document, or upload "file"; 201 { id, imported: 1 } or 400 { error }
  GET    /api/analyses/:id             -> 200 document, 400 invalid id, 404 unknown
  PUT    /api/analyses/:id             <- JSON document; 200 { id, updated: 1 }, 400, 404
  PATCH  /api/analyses/:id             <- partial JSON document; 200 { id, updated: 1 }, 400, 404
  DELETE /api/analyses/:id             -> 200 { deleted: 1 }, 400, 404
  GET    /api/analyses/:id/export      -> 200 JSON document, 400, 404
  POST   /api/analyses/:id/visuals     <- JSON visual { kind, encode, options, title, cross_row, query };
                                       201 { visual, html, head, title, ... }, 400, 404, 422
  PATCH  /api/analyses/:id/visuals/:visual  <- { encode, cross_row, query }; 200, 400, 404, 422
                                       a text card takes { options } instead
  DELETE /api/analyses/:id/visuals/:visual  -> 200 { deleted: 1 }; 400 unless a text card, 404

A C<text> card reads no data.  Its C<options> are C<text> (required), C<font>,
C<size> (points), C<colour> and C<background> (C<#rrggbb>; absent follows the
theme), C<align>, C<bold>, C<italic> and C<plain> (hide the frame and header
until the card is pointed at).  Only a text card can be removed.

PATCH checks only the keys it is given.  Every write answers 503 with
C<error_analysis_storage> when the model store is not writable, and then nothing
has been saved.

=head2 analyses_share / share_view / embed_view / visual_download

C<POST /api/analyses/:id/share> issues a signed read-only token that lasts a
fixed time; C<GET /share/:id?token=...> renders the canvas without edit controls,
and C<GET /embed/:id?token=...> renders its cards without page chrome for an
iframe.  C<GET /a/:id/visual/:n/csv> downloads the rows behind one visual as CSV,
always from the canvas's own dataset, with that card's filters applied; the
C<png> form is not rendered server-side and returns 501, because the chart pages
rasterise their own SVG in the browser.

=head3 API SPECIFICATION

=head4 INPUT / OUTPUT

  POST /api/analyses/:id/share   -> 200 { token, url, expires, lasts_restart }, 400 invalid id, 404 unknown
                                    (lasts_restart: false when neither share_secret nor
                                    secrets is set, so a restart ends the link)
  GET  /share/:id?token=...      -> 200 text/html, 400 invalid id, 401 missing token,
                                    403 bad or expired token, 404 unknown or no visuals
  GET  /embed/:id?token=...      -> as /share/:id, plus 422 when the data cannot be opened;
                                    a card that cannot be drawn shows its error in place
  GET  /a/:id/visual/:n/:fmt     -> 200 text/csv for fmt=csv; 501 for fmt=png;
                                    400 bad format or visual index; 404 unknown analysis or visual;
                                    422 when the data cannot be opened

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
  q        string  Required.  The question.  At most 500 characters.
  f        string  Optional, repeatable.  Result filters.

=head4 OUTPUT

  200 application/json  { spec, url, valid => 1 }
  400 application/json  { error } (missing l or q; q over 500 characters:
                                   ask_question_too_long)
  401 application/json  { error } (password_hash set, not logged in)
  404 application/json  { error } (unopenable source)
  429 application/json  { error } (ai_calls_per_hour provider calls already made
                                   in the last hour, shared with summary_api:
                                   ai_limit_reached)
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

  200 application/json  { text, source, cached }
        source: template (no ai, or no key), llm, template_fallback (the
                provider failed), or template_limited (ai_calls_per_hour
                reached: the template text, not cached)
        cached: 1 when the text came from the hour's cache, which costs no call
  400 application/json  { error }
  401 application/json  { error } (password_hash set, not logged in)
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
                            -> 200 { ok: 1 }, 400 { error }
  POST /geo/delete          <- l=, col= (omit col to clear the spec)
                            -> 200 { ok: 1 }, 400 { error }

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
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "..." }  (compile error or hostile input)

=head4 calc_delete (POST /calc/delete)

  INPUT:  l=<spec>   (required)
          name=<id>  (required)
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /calc/save  l=path:/data/sales.csv&name=margin&expr=amount-cost
    -> 200 { "ok": 1 }
  GET /calc/list?l=path:/data/sales.csv
    -> 200 { "fields": { "margin": "amount-cost" } }

=cut

=head2 groups_list / groups_save / groups_delete

C<GET /groups/list>, C<POST /groups/save>, C<POST /groups/delete> -- Manage
named value groups that produce virtual C<${col}_group> columns.

=head3 API SPECIFICATION

=head4 groups_list (GET /groups/list)

  INPUT:  l=<spec>  (required)
  OUTPUT: 200 application/json  { "groups": { "<col>": { "<label>": ["<val>", ...], ... }, ... } }
          400 application/json  { "error": "l= required" } or "col= required"

=head4 groups_save (POST /groups/save)

  INPUT:  l=<spec>, col=<col>, group=<label>, values=<newline-separated values, and/or repeated>
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "..." }

=head4 groups_delete (POST /groups/delete)

  INPUT:  l=<spec>, col=<col>, group=<label>  (omit group= for all of col's groups, and col= as well for all of the spec's)
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /groups/save  l=path:/data/sales.csv&col=region&group=North&values=MN%0AWI%0AIA
    -> 200 { "ok": 1 }
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
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /dates/save  l=path:/data/sales.csv&col=sale_date&pattern=%m/%d/%Y
    -> 200 { "ok": 1 }
  GET /dates/list?l=path:/data/sales.csv
    -> 200 { "patterns": { "sale_date": "%m/%d/%Y" } }

=cut

=head2 lookups_list / lookups_save / lookups_delete

C<GET /lookups/list>, C<POST /lookups/save>, C<POST /lookups/delete> -- Manage
the stored lookups of a dataset: C<models.json> C<lookups.E<lt>specE<gt>.E<lt>nameE<gt>>.
Each is applied at stage 3 of the pipeline by C<_apply_lookups>, after dates
are normalised and before calculated fields, so every later stage can read the
columns it adds.  C<lk=> and C<nolk=> on any data route add or skip one for a
single request.

=head3 API SPECIFICATION

=head4 lookups_list (GET /lookups/list)

  INPUT:  l=<spec>  (required)
  OUTPUT: 200 application/json
            { "lookups": { "<name>": { "file": "<path>", "key": "<col>",
                                       "col": "<col>", "fields": ["<col>", ...],
                                       "default": "<value>" }, ... } }
          400 application/json  { "error": "l= required" }

=head4 lookups_save (POST /lookups/save)

  INPUT:  l=<spec>, name=<identifier>, file=<path under data_dir>, key=<col>
          optional: col=<dataset column, default key>,
                    fields=<col>[,<col>...] (repeatable; default every column but key),
                    default=<value for a key not in the file>
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "..." } -- l=, name= or key= missing or
              invalid; the file remote, outside data_dir, missing, unsupported,
              over 8 MiB or unreadable; key= or a field not in the file

=head4 lookups_delete (POST /lookups/delete)

  INPUT:  l=<spec>, name=<identifier>  (omit name= to delete every lookup of the spec)
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /lookups/save  l=table:orders&name=shops&file=shops.csv&key=code&col=shop
    -> 200 { "ok": 1 }
  GET /export?l=table:orders&format=json
    -> 200 [ { "shop": "LDN", "city": "London", ... }, ... ]
  GET /export?l=table:orders&format=json&nolk=shops
    -> 200 [ { "shop": "LDN", ... }, ... ]

=head3 NOTES

Keys are compared as strings after trimming, case-sensitively.  A duplicate key
keeps the first row and is logged once per request
(C<warn_lookup_duplicate_key>).  A field whose name the dataset already has is
written as C<E<lt>nameE<gt>_E<lt>fieldE<gt>>; when that is taken too, the request
is a 400.  The file is read once per request, through the same loader as any
data file.

=cut

=head2 accelerate / unaccelerate / accelerated_specs

Package functions, not routes, called by C<script/bi-extract> with a
controller of the application.  An accelerated dataset is
C<models.json> C<accelerated.E<lt>specE<gt> = { built, file, rows, columns }>;
the page reads its extract (C<_accelerated_source>, from C<_open_spec>,
C<view> and C<open_file>) while L<Database::BI::Extract>'s fingerprint still
matches the file, and the file otherwise, stashing C<acceleration> for the
table page's note either way.

=head3 API SPECIFICATION

=head4 INPUT

	accelerate:        ($c, $spec)   # $spec: table:<name> or path:<local file>, not SQLite
	unaccelerate:      ($c, $spec)
	accelerated_specs: ($c)

=head4 OUTPUT

	accelerate:        { spec => 'string', path => 'string', rows => 'integer',
	                     columns => 'integer', built => 'integer (epoch)' }
	                   croaks error_accel_spec | error_accel_sqlite | error_accel_open
	                        | error_accel_store | error_accel_build
	unaccelerate:      1 when the spec was accelerated (its extract is removed), else 0
	accelerated_specs: the accelerated specs, sorted

C<accelerate> reads the file itself, never the extract it replaces, and removes
the extract it replaces.  The extract's table is C<extract>, not C<data>:
L<Database::Abstraction> cannot read a table called C<data>.  The file's column
order is stored with it and passed back as C<column_order>, because a SQLite
backend lists columns alphabetically.

=cut

=head2 request_refusal

A package function, not a route: the first C<before_dispatch> hook in
L<Database::BI> calls it for every request, and answers C<403> with its message
when it returns one.  It keeps other machines away when there is no password,
and keeps another site's page, acting through the reader's browser (where a
logged-in session goes with it), away from C<POST /export> (which writes
files), C</open> (which reads them) and every other route.

=over 4

=item * B<No password, this machine only.>  With no C<password_hash>, a request
whose remote address is not loopback (C<127.0.0.0/8>, C<::1>) is refused, as is
one a trusted reverse proxy says came from such an address.  Startup already
refuses to listen anywhere else without a password; this catches a proxy on
this machine that brings other machines' requests in.

=item * B<DNS rebinding.>  The C<Host> must be C<localhost>, a name ending in
C<.localhost>, an IP address, or a name in config C<allowed_hosts>
(C<*.example.com> for its subdomains, C<*> for every name).  Behind a trusted
reverse proxy (C<MOJO_REVERSE_PROXY>, hypnotoad's C<proxy>), only a configured
C<allowed_hosts> is checked.

=item * B<Cross-site writes.>  For every method but C<GET>, C<HEAD> and
C<OPTIONS>: a C<Sec-Fetch-Site> must be C<same-origin> or C<none>; without one,
an C<Origin> must name this host and port (or, behind a trusted proxy,
C<X-Forwarded-Host>).  A request with neither header did not come from a page,
and is let through.

=back

=head3 API SPECIFICATION

=head4 INPUT

	($c)   # a controller of the application

=head4 OUTPUT

	undef                       # let the request through
	error_remote_needs_password (string) # no password, and not from this machine
	error_host_refused (string) # the Host is not one this server answers to
	error_cross_site (string)   # another site's page sent a write

=cut

=head2 canonical_spec

The one spelling of a C<path:> spec in the model store: C<path:> followed by the
realpath of its file, the name C<open_file> gives it.  The request is left as
the reader wrote it, so pages, forms and messages show their own spelling; only
the store key is resolved.  The store routes (C</calc>, C</groups>, C</dates>,
C</lookups>, C</extract>, C</geo>) and the readers (C<_calc_spec_key>,
C<_apply_calc_fields>, C<_has_stored_columns>, C<_map_data>,
C<_accelerated_source>, C<accelerate>, C<unaccelerate>) pass their key through
it.  C<_read_models> files an entry written under another spelling under the
resolved one, so an older store is still read.

=head3 API SPECIFICATION

=head4 INPUT

	$spec   # any spec string, or undef

=head4 OUTPUT

	'path:<realpath>' when $spec is path:<file> and the file exists locally;
	otherwise $spec unchanged (other kinds of spec, remote /../host paths,
	missing files, a name holding a newline, undef)

=cut

=head2 extract_list / extract_save / extract_delete

C<GET /extract/list>, C<POST /extract/save>, C<POST /extract/delete> -- Manage
the stored field extractions of a dataset: C<models.json>
C<extractions.E<lt>specE<gt>.E<lt>nameE<gt>>.  Each is applied by
C<_apply_extractions> straight after the lookups, so every later stage can read
the columns it adds.

=head3 API SPECIFICATION

=head4 extract_list (GET /extract/list)

  INPUT:  l=<spec>  (required)
  OUTPUT: 200 application/json
            { "extractions": { "<name>": { "col": "<col>", "pattern": "<re>",
                                           "fields": ["<group>", ...] }, ... } }
          400 application/json  { "error": "l= required" }

=head4 extract_save (POST /extract/save)

  INPUT:  l=<spec>, name=<identifier>, col=<col>, pattern=<regular expression>
          optional: fields=<group>[,<group>...] (repeatable; default every named group)
  OUTPUT: 200 application/json  { "ok": 1, "fields": ["<group>", ...] }
          400 application/json  { "error": "..." } -- l=, name=, col= or pattern=
              missing or invalid; the pattern too long, using a refused
              construct, not compiling or naming no group; a field not a group

=head4 extract_delete (POST /extract/delete)

  INPUT:  l=<spec>, name=<identifier>  (omit name= to delete every extraction of the spec)
  OUTPUT: 200 application/json  { "ok": 1 }
          400 application/json  { "error": "l= required" }

=head3 EXAMPLE

  POST /extract/save  l=table:invoices&name=parts&col=ref
                      &pattern=^(?<country>[A-Z]{2})-(?<year>\d{4})-
    -> 200 { "ok": 1, "fields": ["country", "year"] }
  GET /export?l=table:invoices&format=json
    -> 200 [ { "ref": "GB-2026-001", "country": "GB", "year": "2026", ... },
             { "ref": "unknown", "country": "(unparseable)", "year": "(unparseable)", ... } ]

=head3 NOTES

The column the extraction reads is checked on every request; one the dataset
does not have is a 400 (C<error_extract_col_unknown>).  A row that does not
match is C<(unparseable)> in every column; a group that took no part is C<''>.
The pattern is compiled by L<Database::BI::Calc/Regular expressions>, which
has no timeout.

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
  in        case-insensitive equality with any value of a JSON array of
            strings, e.g. C<f=place:in:["Paris","Rome"]>; a value that is
            not such an array matches no row

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

A calculated field runs before the filters, so it can feed the pass:
C<cs=> can read a C<?c=> field, a stored field or a C<span=> bucket.  One that
names a cross-row column cannot run that early, so it waits and runs straight
after the pass: C<cs=amount:running_total:ytd&order=day&c=half:ytd/2>.  This is
stage 7, and it needs a C<cs=> that adds the column.  Without one the name is
unknown, the 400 it always was, and any other fault in the field is reported at
once.  A field cannot be both: C<cs=> cannot read a field that is itself waiting
for a cross-row column.  On a canvas each card runs the waiting fields after its
own pass, and a card whose plan lacks the column goes without the field.

The filters come first, so a window is over the rows they leave, with one
exception.  A filter naming a column stage 6 or 7 writes runs after them:
C<f=ytd:gt:50> selects rows by their running total and does not change it.  The
same goes for a card's own filters on a canvas and for a cross-filter, which a
card whose plan does not write the column ignores.  Such a filter also keeps an
aggregate from being pushed to SQL, as any filter on a virtual column does.

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
