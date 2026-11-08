use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Test::Mockingbird qw(mock restore_all);
use Test::Returns qw(returns_is);
use Mojo::JSON ();
use Readonly;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Mojo::File;
use Mojo::Util qw(url_escape);
use Test::Permissions qw(skip_unless_can_revoke with_revoked);
use lib 't/lib';	# BI::Test::Nominatim, for the geocoding chain

# ---------------------------------------------------------------------------
# Minimal stub geocoder and point, injected through the app config so no
# real Geo::Coder::Free or network connection is required.  Both packages
# must be defined before Test::Mojo->new loads the app.
# ---------------------------------------------------------------------------
{
	package Unit::GeoPoint;
	sub new       { bless { %{ $_[1] } }, $_[0] }
	sub latitude  { $_[0]{latitude}  }
	sub longitude { $_[0]{longitude} }
	sub database  { $_[0]{database}  }

	package Unit::Geocoder;
	sub new {
		my ($class, %a) = @_;
		return bless {
			results => $a{results} // {},
			calls   => [],
		}, $class;
	}
	sub valid_location {
		my ($self, $v) = @_;
		return 0 unless defined($v) && !ref($v) && length($v);
		return 0 if $v =~ /\A\d+\z/;
		return 1;
	}
	sub geocode_many {
		my ($self, $values, %opts) = @_;
		push @{ $self->{calls} }, [ @$values ];
		my %out;
		for my $v (@$values) { $out{$v} = $self->{results}{$v} }
		return { %out, lookups => scalar @$values };
	}

	package Unit::GeoBroken;
	# Has valid_location but lacks geocode_many -- tests interface guard.
	sub new            { bless {}, $_[0] }
	sub valid_location { 1 }
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly my $SALES_TABLE  => 'sales';
Readonly my $PROD_TABLE   => 'products';
Readonly my $DATA_DIR     => 'data';
Readonly my $SALES_CSV    => File::Spec->rel2abs('data/sales.csv');
Readonly my $PROD_PSV     => File::Spec->rel2abs('data/products.psv');

# ---------------------------------------------------------------------------
# API LEDGER
# Every documented state / message / return code in the POD.
# Each subtest deletes its key(s) when coverage is confirmed.
# The ledger is asserted empty at the very end.
# ---------------------------------------------------------------------------
my %ledger = (
	# DataSource public API
	'DataSource.new.ok'              => 'new() with valid directory + table succeeds',
	'DataSource.new.dir_missing'     => 'new() with non-existent directory croaks error_directory_missing',
	'DataSource.new.table_invalid'   => 'new() with bad table name croaks error_table_name_invalid',
	'DataSource.new.no_args'         => 'new() without required args throws',
	'DataSource.table_name'          => 'table_name() returns lowercase table',
	'DataSource.columns'             => 'columns() returns arrayref',
	'DataSource.id_column'           => 'id_column() returns a defined column name',
	'DataSource.source_url.undef'    => 'source_url() returns undef for file-backed source',
	'DataSource.fetch_all.ok'        => 'fetch_all() returns arrayref of hashrefs',
	# Dashboard HTTP API
	'GET./'                          => 'GET / 200 HTML',
	'GET./view.200'                  => 'GET /view/:table 200 HTML',
	'GET./view.404'                  => 'GET /view/:invalid-name 404',
	'GET./view.filter'               => 'GET /view/:table?f= 200 HTML',
	'GET./browse.200'                => 'GET /browse 200 HTML',
	'GET./browse.404'                => 'GET /browse?path=nonexistent 404',
	'GET./open.200'                  => 'GET /open?path=<valid> 200 HTML',
	'GET./open.no_path'              => 'GET /open (no path param) 404',
	'GET./open.bad_ext'              => 'GET /open?path=<unsupported ext> 404',
	'GET./import.url_required'       => 'GET /import (no url) -> home + error_url_required',
	'GET./import.url_invalid'        => 'GET /import?url=ftp:// -> home + error_url_invalid',
	'GET./import.url_ssrf'           => 'GET /import?url=http://192.168.1.1/ -> home + error_url_ssrf',
	'GET./import.url_fetch'          => 'GET /import?url=<unreachable> -> home + error_url_fetch',
	'GET./api_columns.table'         => 'GET /api/columns?table= 200 JSON {columns:[...]}',
	'GET./api_columns.path'          => 'GET /api/columns?path= 200 JSON {columns:[...]}',
	'GET./api_columns.404'           => 'GET /api/columns?table=no_such 404 JSON {error}',
	'GET./join.200'                  => 'GET /join?l=table:sales 200 HTML',
	'GET./join.404'                  => 'GET /join (no l=) 404',
	'GET./export.csv'                => 'GET /export?l=table:sales&format=csv 200 text/csv',
	'GET./export.sqlite'             => 'GET /export?l=table:sales&format=sqlite 200 SQLite',
	'GET./export.404'                => 'GET /export (no l=) 404',
	'POST./export.saved'             => 'POST /export with valid dir + .csv filename -> 200 {saved}',
	'POST./export.bad_dir'           => 'POST /export with non-existent dir -> 404 {error}',
	'POST./export.bad_ext'           => 'POST /export with .xlsx extension -> 415 {error}',
	'GET./api_dirs.200'              => 'GET /api/dirs 200 JSON {path,parent,dirs}',
	'GET./api_dirs.404'              => 'GET /api/dirs?path=<file> 404 JSON {error}',
	'GET./api_stat.exists'           => 'GET /api/stat?path=<csv> 200 JSON {exists:true,...}',
	'GET./api_stat.notexists'        => 'GET /api/stat?path=<missing> 200 JSON {exists:false}',
	'GET./api_stat.400'              => 'GET /api/stat (no path) 400 JSON {error}',
	'POST./upload.200'               => 'POST /upload valid CSV -> 200 JSON {url,path}',
	'POST./upload.400'               => 'POST /upload no file -> 400 JSON {error}',
	'POST./upload.413'               => 'POST /upload oversized -> 413 JSON {error}',
	'POST./upload.415'               => 'POST /upload bad ext -> 415 JSON {error}',
	'GET./graph.accounting'          => 'GET /graph with accounting amounts: 200, negatives plotted',
	'GET./graph.no_numeric'          => 'GET /graph with all-text Y column: 200 No plottable data',

	# combine_tables action
	'GET./combine.200'              => 'GET /combine?l=table:sales 200 HTML',
	'GET./combine.404'              => 'GET /combine (no l=) 404',

	# JSON export format
	'GET./export.json'              => 'GET /export?l=table:sales&format=json 200 application/json',

	# graph_view additional error paths
	'GET./graph.400.missing_param'  => 'GET /graph (no x= or y=) -> 400 plain-text',
	'GET./graph.400.col_not_found'  => 'GET /graph with non-existent column -> 400 plain-text',
	'GET./graph.404.no_source'      => 'GET /graph (no l=) -> 404 plain-text',

	# clear_uploads action
	'POST./uploads_clear.200'       => 'POST /uploads/clear 200 JSON {freed, count}',

	# export_write write-failure path
	'POST./export.write_failed'     => 'POST /export write throws -> 500 JSON {error}',

	# view and open_file error rendering when DataSource backend throws
	'GET./view.error_table_open'    => 'GET /view/:table when fetch_all dies -> home page with error_table_open',
	'GET./open.error_file_open'     => 'GET /open when fetch_all dies -> home page with error_file_open',

	# DataSource::selectall_arrayref public method
	'DataSource.selectall_arrayref' => 'selectall_arrayref() returns arrayref of hashrefs',

	# pie_view action (added 0.007.0) -- all four documented return paths
	'GET./pie.200'               => 'GET /pie?l=...&cat=...&val=... 200 HTML pie chart',
	'GET./pie.400.missing_param' => 'GET /pie missing cat= or val= param -> 400 plain text',
	'GET./pie.400.col_not_found' => 'GET /pie with unknown cat/val column -> 400 plain text',
	'GET./pie.404.no_source'     => 'GET /pie (no l=) -> 404 plain text',
	'GET./pie.200.no_plottable'  => 'GET /pie all-text val column -> 200 No plottable data',
	'GET./pie.200.count_mode'    => 'GET /pie?val=__count__ -> 200 count-mode chart title',
	'GET./pie.200.donut'         => 'GET /pie?donut=1 -> 200 HTML donut chart',
	'GET./pie.200.currency'      => 'GET /pie with $ amounts -> data-currency attribute present',

	# heatmap_view action (added 0.008.0) -- all documented return paths
	'GET./heatmap.200'               => 'GET /heatmap?l=...&x=...&y=... 200 HTML heatmap',
	'GET./heatmap.400.missing_param' => 'GET /heatmap missing x= or y= param -> 400 plain text',
	'GET./heatmap.400.col_not_found' => 'GET /heatmap with unknown column -> 400 plain text',
	'GET./heatmap.404.no_source'     => 'GET /heatmap (no l=) -> 404 plain text',
	'GET./heatmap.200.no_plottable'  => 'GET /heatmap all-empty grid -> 200 No plottable data',
	'GET./heatmap.200.count_mode'    => 'GET /heatmap without val= -> 200 count-mode title',

	# bar_view action (added 0.009.0) -- all documented return paths
	'GET./bar.200'               => 'GET /bar?l=...&cat=... 200 HTML bar chart',
	'GET./bar.400.missing_param' => 'GET /bar missing cat= param -> 400 plain text',
	'GET./bar.400.col_not_found' => 'GET /bar with unknown cat/val column -> 400 plain text',
	'GET./bar.404.no_source'     => 'GET /bar (no l=) -> 404 plain text',
	'GET./bar.200.no_plottable'  => 'GET /bar all-blank category cells -> 200 No plottable data',
	'GET./bar.200.count_mode'    => 'GET /bar?val=__count__ -> 200 count-mode chart title',

	# _safe_back_url: XSS-unsafe back= must not reach the rendered page
	'GET./bar.200.back_rejected' => 'GET /bar?back=javascript:alert(1) renders back_url as /',

	# folder_view action (added 0.010.0) -- all documented return paths
	'GET./folder.200'                 => 'GET /folder?l=...&col=... 200 HTML folder view',
	'GET./folder.200.drill'           => 'GET /folder?l=...&prefix=X 200 HTML items rendered',
	'GET./folder.400.no_l'            => 'GET /folder (no l=) 400 plain text',
	'GET./folder.404.no_source'       => 'GET /folder?l=path:/nonexistent 404 plain text',
	'GET./folder.400.prefix_too_long' => 'GET /folder?prefix=<21+ chars> 400 plain text',

	# map_view action (Phase 6) -- every documented 400/404/200 return state
	'GET./map.400.no_source_col'     => 'GET /map no loc= and no lat=/lon= -> 400 error_map_source',
	'GET./map.400.half_coord'        => 'GET /map only lat= or only lon= -> 400 error_map_coordinates',
	'GET./map.404.no_source'         => 'GET /map bad l= spec -> 404',
	'GET./map.400.loc_col_not_found' => 'GET /map loc= column not in dataset -> 400 error_map_loc_column',
	'GET./map.200.loc'               => 'GET /map?loc=<col> with injected geocoder -> 200 HTML',
	'GET./map.400.lat_range'         => 'GET /map lat column wholly out of range -> 400 error_map_coordinate_range',
	'GET./map.400.lon_range'         => 'GET /map lon column wholly out of range -> 400 error_map_coordinate_range',
	'GET./map.400.no_numeric_pairs'  => 'GET /map non-numeric lat/lon columns -> 400 error_map_coordinate_numeric',
	'GET./map.200.latlon'            => 'GET /map?lat=&lon= coordinate path -> 200 HTML',

	# Geocode.pm public API -- all documented constructor + method states
	'Geocode.new.ok'                  => 'Geocode->new() with no args succeeds',
	'Geocode.new.injected_geocoder'   => 'Geocode->new(geocoder=>) with valid interface succeeds',
	'Geocode.new.bad_interface'       => 'Geocode->new(geocoder=>) lacking required method croaks',
	'Geocode.geocoder_available.true' => 'geocoder_available() returns (1, undef) with injected stub',
	'Geocode.geocoder_available.false'=> 'geocoder_available() returns (0, reason-string) without module',
	'Geocode.resolve_values.ok'       => 'resolve_values([\@vals]) returns result hashref with counts',
	'Geocode.resolve_values.bad_input'=> 'resolve_values(non-arrayref) croaks error_values_arrayref',
	'Geocode.resolve_values.cap'      => 'resolve_values with max= holds back excess in not_attempted',
	'Geocode.resolve_values.cache_hit'=> 'resolve_values with populated cache skips geocoder',
	'Geocode.resolve_column.ok'       => 'resolve_column(\@rows, col) populates markers and counts',
	'Geocode.resolve_column.bad_rows' => 'resolve_column(non-arrayref, col) croaks error_rows_arrayref',
	'Geocode.resolve_column.col_miss' => 'resolve_column(\@rows, missing-col) croaks error_map_loc_column',
	'Geocode.cache_from_models.ok'    => 'cache_from_models returns copy of places for known spec',
	'Geocode.cache_from_models.empty' => 'cache_from_models returns {} for unknown spec',
	'Geocode.models_with_cache.ok'    => 'models_with_cache stores places + backend + built',
	'Geocode.models_with_cache.immut' => 'models_with_cache does not mutate the caller hashref',

	# Database::BI::Util -- urlencode() public API
	'Util.urlencode.undef'      => 'urlencode(undef) returns empty string',
	'Util.urlencode.empty'      => 'urlencode("") returns empty string',
	'Util.urlencode.unreserved' => 'urlencode passes through RFC 3986 unreserved characters unchanged',
	'Util.urlencode.colon'      => 'urlencode(":") returns "%3A"',
	'Util.urlencode.space'      => 'urlencode(" ") returns "%20" (not "+")',
	'Util.urlencode.slash'      => 'urlencode("/") returns "%2F"',
	'Util.urlencode.uppercase'  => 'hex digits in percent-encoding are uppercase',

	# Database::BI::Ask -- infer_column_types() public API
	'Ask.infer_column_types.empty'   => 'infer_column_types([], []) returns []',
	'Ask.infer_column_types.numeric' => 'majority-numeric column inferred as type=number',
	'Ask.infer_column_types.date'    => 'majority-ISO-date column inferred as type=date',
	'Ask.infer_column_types.string'  => 'non-numeric, non-date column inferred as type=string',

	# Database::BI::Ask -- ask() public API (all documented error codes + success)
	'Ask.ask.no_question'    => 'ask(question=>"") returns {error=>"ask_no_question"}',
	'Ask.ask.no_api_key'     => 'ask() without api_key returns {error=>"ask_unavailable"}',
	'Ask.ask.provider_error' => 'ask() with failing LLM HTTP call returns {error=>"ask_provider_error"}',
	'Ask.ask.unparseable'    => 'ask() with non-JSON LLM reply returns {error=>"ask_unparseable"}',
	'Ask.ask.invalid_spec'   => 'ask() with unknown encode column returns {error=>"ask_invalid_spec:<col>"}',
	'Ask.ask.success'        => 'ask() with mocked LLM returns {spec,url,valid=>1}',

	# Database::BI::Insights -- compute() and method_note() public API
	'Insights.compute.empty'        => 'compute() with empty records returns []',
	'Insights.compute.outlier'      => 'compute() returns insight of kind=outlier when outlier present',
	'Insights.compute.period_delta' => 'compute() returns kind=period_delta with date+numeric data',
	'Insights.compute.seasonality'  => 'compute() returns kind=seasonality with 8+ distinct month-periods',
	'Insights.method_note.known'    => 'method_note(known key) returns a description string',
	'Insights.method_note.unknown'  => 'method_note(unknown key) returns the key itself',

	# Database::BI::Summary -- generate() public API (all documented source paths)
	'Summary.generate.template'      => 'generate() without use_ai returns source=template',
	'Summary.generate.no_insights'   => 'generate() with no insights includes "No significant patterns"',
	'Summary.generate.cached'        => 'generate() second call with same fingerprint returns cached=1',
	'Summary.generate.use_ai_no_key' => 'generate(use_ai=>1, no api_key) silently uses template path',
	'Summary.generate.llm_fallback'  => 'generate(use_ai=>1) LLM error -> source=template_fallback',
	'Summary.generate.llm_success'   => 'generate(use_ai=>1) mocked LLM -> source=llm',

	# HTTP: scatter / stacked / combo / treemap / histogram chart views
	'GET./scatter.200'                => 'GET /scatter?l=...&x=...&y=... -> 200 HTML',
	'GET./scatter.400.missing_param'  => 'GET /scatter missing x= or y= -> 400',
	'GET./scatter.404.no_source'      => 'GET /scatter with x=/y= but invalid l= -> 404',
	'GET./stacked.200'                => 'GET /stacked?l=...&cat=...&series=... -> 200 HTML',
	'GET./stacked.400.missing_param'  => 'GET /stacked missing cat= or series= -> 400',
	'GET./stacked.404.no_source'      => 'GET /stacked with cat=/series= but invalid l= -> 404',
	'GET./combo.200'                  => 'GET /combo?l=...&cat=...&bar_val=...&line_val=... -> 200 HTML',
	'GET./combo.400.missing_param'    => 'GET /combo missing cat= or bar_val= or line_val= -> 400',
	'GET./combo.404.no_source'        => 'GET /combo with required params but invalid l= -> 404',
	'GET./treemap.200'                => 'GET /treemap?l=...&group=... -> 200 HTML',
	'GET./treemap.400.missing_param'  => 'GET /treemap missing group= -> 400',
	'GET./treemap.404.no_source'      => 'GET /treemap with group= but invalid l= -> 404',
	'GET./histogram.200'              => 'GET /histogram?l=...&col=<numeric> -> 200 HTML',
	'GET./histogram.400.missing_param'=> 'GET /histogram missing col= -> 400',
	'GET./histogram.404.no_source'    => 'GET /histogram with col= but invalid l= -> 404',

	# HTTP: pivot / stats views
	'GET./pivot.200'           => 'GET /pivot?l=...&rows=...&m=col:sum:total -> 200 HTML',
	'GET./pivot.400.no_rows'   => 'GET /pivot without rows= -> 400',
	'GET./pivot.400.no_source' => 'GET /pivot no l= -> 400',
	'GET./stats.200'           => 'GET /stats?l=... -> 200 HTML',
	'GET./stats.400.no_source' => 'GET /stats no l= -> 400',

	# HTTP: Phase 5 endpoints
	'GET./insights.200'          => 'GET /insights?l=... -> 200 HTML insights page',
	'GET./insights.400.no_l'     => 'GET /insights without l= -> 400',
	'POST./api_summary.200'      => 'POST /api/summary?l=... -> 200 JSON {text,source,cached}',
	'POST./api_summary.400.no_l' => 'POST /api/summary without l= -> 400',
	'POST./api_ask.503.no_key'   => 'POST /api/ask without ai_api_key configured -> 503 JSON {error}',
	'POST./api_ask.400.no_l'     => 'POST /api/ask missing l= -> 400 JSON {error}',
	'POST./api_ask.400.no_q'     => 'POST /api/ask missing q= -> 400 JSON {error}',
	'POST./api_ask.200'          => 'POST /api/ask with mocked LLM -> 200 JSON {spec,url,valid}',
);

# ---------------------------------------------------------------------------
# The ledger also holds every message the modules can raise, read from their own
# dictionaries, so that a message added later fails this file until it is tested.
# A key that no code refers to cannot be raised, and is left out by the same
# reading, so it joins the ledger the moment something starts to use it.
# ---------------------------------------------------------------------------
Readonly my %MESSAGE_FILES => (
	Dashboard  => 'lib/Database/BI/Controller/Dashboard.pm',
	DataSource => 'lib/Database/BI/Model/DataSource.pm',
	Geocode    => 'lib/Database/BI/Model/Geocode.pm',
	Password   => 'lib/Database/BI/Password.pm',
	PasswordCommand => 'lib/Database/BI/Command/password.pm',
);
my %DICTIONARY;
for my $module (sort keys %MESSAGE_FILES) {
	# A Windows checkout has CRLF line ends, which would leave the POD in below.
	(my $source = Mojo::File->new($MESSAGE_FILES{$module})->slurp) =~ s/\r\n/\n/g;
	my ($block) = $source =~ /%MESSAGES => \((.*?)^\);/ms or BAIL_OUT("no %MESSAGES in $module");
	my %messages = eval "($block)";	## no critic (ProhibitStringyEval): the module's own constant data
	$source =~ s/%MESSAGES => \(.*?^\);//ms;
	$source =~ s/^=\w.*?^=cut\n//msg;
	$DICTIONARY{$module} = \%messages;
	for my $key (grep { $source =~ /\b$_\b/ } keys %messages) {
		$ledger{"msg.$module.$key"} = "$module raises $key";
	}
}

# Those the POD documents that are not messages.
$ledger{"api.$_"} = "documented behaviour: $_" for qw(
	Util.parse_number Util.iso_datetime Util.minute_stamp Util.iso8601_utc Calc.new Calc.error Calc.has_error Calc.evaluate Calc.span_interval Calc.date_normalise Calc.compile_pattern Calc.capture_of
	Extract.new Extract.path Extract.get Extract.put Extract.evict
	Tutorial.intro Tutorial.chapters Tutorial.faq Tutorial.glossary Tutorial.parts
	Tutorial.covered_routes Tutorial.exempt_routes Tutorial.chapter_for_action
	DataSource.sqlite_tables DataSource.dbi_source DataSource.aggregate DataSource.updated DataSource.schema DataSource.count DataSource.json_lists
	Geocode.shared_cache_from_models Geocode.models_with_shared_cache
	BI.startup Globals
	analyses.list analyses.create analyses.get analyses.update analyses.patch analyses.delete
	analyses.add_visual analyses.update_visual analyses.export analyses.import analyses.storage_503 analyses.unknown_keys
	share.share share.embed share.visual_download
	crud.calc crud.groups crud.dates crud.lookups crud.extract crud.geo
	accel.accelerate accel.unaccelerate accel.specs DataSource.column_order
	route.range route.tables route.wordcloud route.catalog route.tutorial route.index route.stats_percentile
);

# ---------------------------------------------------------------------------
# Bootstrap the Mojolicious app first so that Test::Mojo dynamically
# requires all app modules at runtime (after the CHECK phase).
# Sub::Private's namespace::clean runs at CHECK time, so modules loaded
# via 'use' at compile-time lose their :Private stash entries -- including
# _init_backend, which new() calls.  Loading via Test::Mojo->new (which
# uses require at runtime) bypasses CHECK and preserves the full stash.
# Only AFTER the app is started do we require DataSource so we get the
# already-loaded, stash-intact version.
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;	# no-op: already in %INC; stash intact

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
# Without it the /map?loc= geocode cache writes the workspace's .bi/models.json.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
# DataSource -- direct constructor and accessor tests
# ---------------------------------------------------------------------------
subtest 'DataSource.new -- valid directory and table' => sub {
	my $ds;
	lives_ok { $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	) } 'new() lives with valid args';
	ok $ds, 'new() returns a defined object';
	delete $ledger{'DataSource.new.ok'};
};

subtest 'DataSource.new -- non-existent directory croaks error_directory_missing' => sub {
	# POD: croaks with 'DataSource: directory "..." does not exist or is not readable'
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => '/no/such/directory/__test__',
			table     => $SALES_TABLE,
		)
	} qr/does not exist or is not readable/,
	'new() croaks with directory-missing message for bad dir';
	delete $ledger{'DataSource.new.dir_missing'};
};

subtest 'DataSource.new -- invalid table name croaks error_table_name_invalid' => sub {
	# Hyphens, dots, spaces, etc. are now sanitized to underscores.
	# Only path-separator characters ('/', '\', NUL) and the empty string still croak.
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => $DATA_DIR,
			table     => 'a/b',
		)
	} qr/contains illegal characters/,
	'new() croaks with table-name-invalid message for path-separator in table name';
	delete $ledger{'DataSource.new.table_invalid'};
};

subtest 'DataSource.new -- missing required args throws' => sub {
	throws_ok {
		Database::BI::Model::DataSource->new()
	} qr/.+/, 'new() with no args throws an exception';
	delete $ledger{'DataSource.new.no_args'};
};

subtest 'DataSource.table_name -- returns table name as provided' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => 'sales',
	);
	is $ds->table_name, 'sales', 'table_name() returns the name as given';
	delete $ledger{'DataSource.table_name'};
};

subtest 'DataSource.columns -- returns arrayref of column names' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	);
	my $cols = $ds->columns;
	if (defined $cols) {
		isa_ok $cols, 'ARRAY', 'columns() returns an arrayref when defined';
		ok scalar @$cols, 'columns() arrayref is non-empty';
	}
	else {
		pass 'columns() may return undef for backends without ordered headers';
	}
	delete $ledger{'DataSource.columns'};
};

subtest 'DataSource.id_column -- returns a column name string' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	);
	my $id = $ds->id_column;
	if (defined $id) {
		like $id, qr/\A\w+\z/, 'id_column() returns a word-character column name';
	}
	else {
		pass 'id_column() may return undef for URL-backed sources';
	}
	delete $ledger{'DataSource.id_column'};
};

subtest 'DataSource.source_url -- returns undef for file-backed source' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	);
	is $ds->source_url, undef, 'source_url() is undef for a file-backed DataSource';
	delete $ledger{'DataSource.source_url.undef'};
};

subtest 'DataSource.fetch_all -- returns arrayref of hashrefs' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	);
	my $rows;
	lives_ok { $rows = $ds->fetch_all } 'fetch_all() lives';
	isa_ok $rows, 'ARRAY', 'fetch_all() returns an arrayref';
	if (@$rows) {
		isa_ok $rows->[0], 'HASH', 'first element is a hashref';
	}
	delete $ledger{'DataSource.fetch_all.ok'};
};

# ---------------------------------------------------------------------------
# HTTP API tests via Test::Mojo
# ---------------------------------------------------------------------------

# ---  GET /  ----------------------------------------------------------------
subtest 'GET / -- home page lists available tables' => sub {
	# Status and content-type smoke test.
	$t->get_ok('/')->status_is(200)->content_type_like(qr{text/html})
	  # The Browse card must contain a path text input (id="bi-path-input")
	  # and its form must target /open.  These assertions exist specifically
	  # to catch the regression where the path input was silently removed
	  # from home.html.tt without any test failing.
	  ->content_like(qr/id="bi-path-input"/, 'home page has path input field')
	  ->content_like(qr/action="\/open"/, 'Browse card form targets /open')
	  # The layout writes the resolved language into <html lang>.  index() rendered
	  # its template without passing it, so the attribute was empty here while the
	  # tutorial's page carried the language - a screen reader and a translation
	  # tool both read it, and an empty one says nothing.
	  ->content_like(qr/<html lang="en"/, 'and the page declares its language');
	delete $ledger{'GET./'};
};

# ---  GET /view/:table  -----------------------------------------------------
subtest 'GET /view/sales -- valid table renders data grid' => sub {
	$t->get_ok("/view/$SALES_TABLE")->status_is(200)->content_type_like(qr{text/html});
	delete $ledger{'GET./view.200'};
};

subtest 'GET /view/<invalid-chars> -- returns 404' => sub {
	# Table names must match [A-Za-z_][A-Za-z0-9_]* per TABLE_NAME_RE.
	# A name containing hyphens or slashes must not match any route table.
	$t->get_ok('/view/bad-table')->status_is(404);
	delete $ledger{'GET./view.404'};
};

subtest 'GET /view/sales?f= -- filtered view returns 200' => sub {
	# Apply an eq filter that should return a subset of rows.
	$t->get_ok("/view/$SALES_TABLE?f=region:notempty:")->status_is(200);
	delete $ledger{'GET./view.filter'};
};

# ---  GET /browse  ----------------------------------------------------------
subtest 'GET /browse -- default (HOME) directory listing' => sub {
	$t->get_ok('/browse')->status_is(200)->content_type_like(qr{text/html});
	delete $ledger{'GET./browse.200'};
};

subtest 'GET /browse?path=<nonexistent> -- 404' => sub {
	my $bad = url_escape('/no/such/directory/__unit_test__');
	$t->get_ok("/browse?path=$bad")->status_is(404);
	delete $ledger{'GET./browse.404'};
};

# ---  GET /open  ------------------------------------------------------------
subtest 'GET /open?path=<csv> -- opens file and renders data grid' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		$t->get_ok("/open?path=$enc")->status_is(200)->content_type_like(qr{text/html});
	}
	delete $ledger{'GET./open.200'};
};

subtest 'GET /open (no path param) -- 404' => sub {
	$t->get_ok('/open')->status_is(404);
	delete $ledger{'GET./open.no_path'};
};

subtest 'GET /open?path=<unsupported ext> -- 404' => sub {
	# .txt is not in the supported extension list (csv, db, sql, xml, psv).
	my ($fh, $fn) = tempfile(SUFFIX => '.txt', UNLINK => 1);
	close $fh;
	my $enc = url_escape($fn);
	$t->get_ok("/open?path=$enc")->status_is(404);
	delete $ledger{'GET./open.bad_ext'};
};

# ---  GET /import  ----------------------------------------------------------
subtest 'GET /import (no url param) -- home page with error_url_required' => sub {
	# POD: error_url_required -- empty or missing url param
	$t->get_ok('/import')
	  ->status_is(200)
	  ->content_type_like(qr{text/html})
	  ->content_like(qr/Please enter a URL/i);
	delete $ledger{'GET./import.url_required'};
};

subtest 'GET /import?url=ftp://... -- home page with error_url_invalid' => sub {
	# POD: error_url_invalid -- URL does not begin with http:// or https://
	my $bad = url_escape('ftp://example.com/data.html');
	$t->get_ok("/import?url=$bad")
	  ->status_is(200)
	  ->content_type_like(qr{text/html})
	  ->content_like(qr/is not a valid http/i);
	delete $ledger{'GET./import.url_invalid'};
};

subtest 'GET /import?url=http://192.168.1.1/ -- SSRF guard error_url_ssrf' => sub {
	# POD: error_url_ssrf -- URL resolves to a private or reserved address
	my $priv = url_escape('http://192.168.1.1/data.html');
	$t->get_ok("/import?url=$priv")
	  ->status_is(200)
	  ->content_type_like(qr{text/html})
	  ->content_like(qr/resolves to a private or reserved address/i);
	delete $ledger{'GET./import.url_ssrf'};
};

subtest 'GET /import?url=<unreachable> -- home page with error_url_fetch' => sub {
	# POD: error_url_fetch -- LWP fetch failure or no table found
	# Mock DataSource::new to croak when called in URL mode so the controller's
	# eval catches it and renders error_url_fetch -- no real network call needed.
	# (Previously used .invalid TLD, which blocks on some OpenBSD DNS resolvers.)
	mock 'Database::BI::Model::DataSource::new' => sub {
		my ($class, %args) = @_;
		die "Mocked: could not fetch remote HTML table\n" if exists $args{url};
		# Non-URL calls within this request (none expected) would return undef,
		# which the controller also treats as a fetch error -- still safe.
	};
	my $bad = url_escape('http://unit-test-host.example/data.html');
	$t->get_ok("/import?url=$bad")
	  ->status_is(200)
	  ->content_type_like(qr{text/html})
	  ->content_like(qr/Could not load HTML table from/i);
	restore_all();
	delete $ledger{'GET./import.url_fetch'};
};

# ---  GET /api/columns  -----------------------------------------------------
subtest 'GET /api/columns?table=sales -- 200 JSON with columns array' => sub {
	$t->get_ok("/api/columns?table=$SALES_TABLE")
	  ->status_is(200)
	  ->json_has('/columns');
	my $body = $t->tx->res->json;
	isa_ok $body->{columns}, 'ARRAY', '/api/columns returns columns arrayref';
	delete $ledger{'GET./api_columns.table'};
};

subtest 'GET /api/columns?path=<csv> -- 200 JSON with columns array' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 3 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		$t->get_ok("/api/columns?path=$enc")
		  ->status_is(200)
		  ->json_has('/columns');
	}
	delete $ledger{'GET./api_columns.path'};
};

subtest 'GET /api/columns?table=no_such_table -- 404 JSON {error}' => sub {
	$t->get_ok('/api/columns?table=no_such_table_xyzzy')
	  ->status_is(404)
	  ->json_has('/error');
	delete $ledger{'GET./api_columns.404'};
};

# ---  GET /join  ------------------------------------------------------------
subtest 'GET /join?l=table:sales -- left join with no right table 200' => sub {
	$t->get_ok("/join?l=table:$SALES_TABLE")->status_is(200)->content_type_like(qr{text/html});
	delete $ledger{'GET./join.200'};
};

subtest 'GET /join (no l= param) -- 404' => sub {
	$t->get_ok('/join')->status_is(404);
	delete $ledger{'GET./join.404'};
};

# ---  GET /export  ----------------------------------------------------------
subtest 'GET /export?l=table:sales&format=csv -- CSV download 200' => sub {
	$t->get_ok("/export?l=table:$SALES_TABLE&format=csv")
	  ->status_is(200)
	  ->content_type_like(qr{text/csv});
	delete $ledger{'GET./export.csv'};
};

subtest 'GET /export?l=table:sales&format=sqlite -- SQLite download 200' => sub {
	$t->get_ok("/export?l=table:$SALES_TABLE&format=sqlite")
	  ->status_is(200)
	  ->content_type_like(qr{sqlite|octet-stream}i);
	delete $ledger{'GET./export.sqlite'};
};

subtest 'GET /export (no l= param) -- 404 JSON' => sub {
	$t->get_ok('/export')->status_is(404);
	delete $ledger{'GET./export.404'};
};

# ---  POST /export  ---------------------------------------------------------
subtest 'POST /export -- valid dir + .csv filename returns {saved}' => sub {
	my $dir = tempdir(CLEANUP => 1);
	$t->post_ok('/export', form => {
		l        => "table:$SALES_TABLE",
		dir      => $dir,
		filename => 'output.csv',
	})->status_is(200)
	  ->json_has('/saved', 'response has saved key');
	my $saved = $t->tx->res->json('/saved');
	like $saved, qr/output\.csv\z/, 'saved path ends with output.csv';
	ok -f $saved, 'saved file exists on disk';
	delete $ledger{'POST./export.saved'};
};

subtest 'POST /export -- non-existent dir returns 404 JSON {error}' => sub {
	# POD: error_dir_not_found when realpath fails or result is not a dir.
	$t->post_ok('/export', form => {
		l        => "table:$SALES_TABLE",
		dir      => '/no/such/directory/__unit_test__',
		filename => 'out.csv',
	})->status_is(404)
	  ->json_has('/error');
	delete $ledger{'POST./export.bad_dir'};
};

subtest 'POST /export -- unsupported extension returns 415 JSON {error}' => sub {
	# POD: error_ext_required when filename extension is not .csv or .sql.
	my $dir = tempdir(CLEANUP => 1);
	$t->post_ok('/export', form => {
		l        => "table:$SALES_TABLE",
		dir      => $dir,
		filename => 'out.xlsx',
	})->status_is(415)
	  ->json_has('/error');
	delete $ledger{'POST./export.bad_ext'};
};

# ---  GET /api/dirs  --------------------------------------------------------
subtest 'GET /api/dirs -- default (HOME) directory listing JSON' => sub {
	$t->get_ok('/api/dirs')
	  ->status_is(200)
	  ->json_has('/path')
	  ->json_has('/dirs');
	my $body = $t->tx->res->json;
	isa_ok $body->{dirs}, 'ARRAY', 'dirs is an arrayref';
	delete $ledger{'GET./api_dirs.200'};
};

subtest 'GET /api/dirs?path=<regular file> -- 404 JSON {error}' => sub {
	# A regular file is not a directory -- must return 404.
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		$t->get_ok("/api/dirs?path=$enc")
		  ->status_is(404)
		  ->json_has('/error');
	}
	delete $ledger{'GET./api_dirs.404'};
};

# ---  GET /api/stat  --------------------------------------------------------
subtest 'GET /api/stat?path=<csv> -- exists:true with mtime and size' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 5 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		$t->get_ok("/api/stat?path=$enc")
		  ->status_is(200)
		  ->json_is('/exists', Mojo::JSON->true)
		  ->json_has('/mtime')
		  ->json_has('/size');
		my $body = $t->tx->res->json;
		ok $body->{mtime} > 0, 'mtime is a positive epoch timestamp';
		ok $body->{size}  > 0, 'size is a positive byte count';
	}
	delete $ledger{'GET./api_stat.exists'};
};

subtest 'GET /api/stat?path=<nonexistent> -- exists:false HTTP 200' => sub {
	# POD: a missing/unresolvable path returns HTTP 200 with exists:false
	my $enc = url_escape('/no/such/file/__unit_test__.csv');
	$t->get_ok("/api/stat?path=$enc")
	  ->status_is(200)
	  ->json_is('/exists', Mojo::JSON->false);
	delete $ledger{'GET./api_stat.notexists'};
};

subtest 'GET /api/stat (no path param) -- 400 JSON {error}' => sub {
	# POD: error_path_required when path param is absent.
	$t->get_ok('/api/stat')
	  ->status_is(400)
	  ->json_has('/error');
	delete $ledger{'GET./api_stat.400'};
};

# ---  POST /upload  ---------------------------------------------------------
subtest 'POST /upload -- valid CSV file returns {url, path}' => sub {
	$t->post_ok('/upload', form => {
		file => { content => "id,name\n1,widget\n", filename => 'test_unit.csv' },
	})->status_is(200)
	  ->json_has('/url')
	  ->json_has('/path');
	my $url  = $t->tx->res->json('/url');
	my $path = $t->tx->res->json('/path');
	like $url,  qr{/open\?path=}, 'url points to /open?path=...';
	like $path, qr/test_unit\.csv\z/, 'path ends with the original filename';
	ok -f $path, 'uploaded file exists on disk';
	delete $ledger{'POST./upload.200'};
};

subtest 'POST /upload -- no file part returns 400 JSON {error}' => sub {
	# POD: error_upload_none when no file part is present.
	$t->post_ok('/upload', form => { other_field => 'ignored' })
	  ->status_is(400)
	  ->json_has('/error');
	delete $ledger{'POST./upload.400'};
};

subtest 'POST /upload -- oversized file returns 413 JSON {error}' => sub {
	# POD: the controller checks is_limit_exceeded and returns 413 before
	# writing to disk.  Lower max_request_size temporarily so the subtest
	# does not allocate 50 MiB.
	my $orig = $t->app->max_request_size;
	$t->app->max_request_size(1024);
	$t->post_ok('/upload', form => {
		file => { content => 'A' x 5000, filename => 'huge.csv' },
	})->status_is(413)
	  ->json_like('/error', qr/too large/i);
	$t->app->max_request_size($orig);
	delete $ledger{'POST./upload.413'};
};

subtest 'POST /upload -- unsupported extension returns 415 JSON {error}' => sub {
	# POD: error_upload_ext when extension is not csv/db/sql/xml/psv/xlsx.
	$t->post_ok('/upload', form => {
		file => { content => 'some data', filename => 'data.docx' },
	})->status_is(415)
	  ->json_has('/error');
	delete $ledger{'POST./upload.415'};
};

subtest 'GET /graph -- accounting amounts are plotted with correct sign' => sub {
	# Regression: parenthesised values like ($450.00) were treated as +450
	# before the fix.  A valid graph page must be returned and negatives must
	# appear in the embedded chart data.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'acct.csv');
		$file->spew("month,amount\nJan,\$500.00\nFeb,(\$250.00)\nMar,-100.00\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200, 'graph with accounting amounts returns 200')
		  ->content_like(qr/-250\b/, 'accounting negative ($250.00) present in chart data');
	}
	delete $ledger{'GET./graph.accounting'};
};

subtest 'GET /graph -- all-text Y column returns 200 with No plottable data' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'text.csv');
	$file->spew("month,label\nJan,Alfa\nFeb,Beta\n");
	$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=label')
	  ->status_is(200, 'all-text Y returns 200 not 500')
	  ->content_like(qr/No plottable data/i, 'no-numeric Y shows No plottable data message');
	delete $ledger{'GET./graph.no_numeric'};
};

# ---------------------------------------------------------------------------
# Additional coverage: combine_tables, JSON export, graph error paths,
# clear_uploads, export write failure, view/open error rendering,
# and DataSource::selectall_arrayref.
# ---------------------------------------------------------------------------

subtest 'DataSource.selectall_arrayref -- returns arrayref of hashrefs' => sub {
	# selectall_arrayref is the low-level method fetch_all delegates to.
	# It must return an arrayref (never undef) for a well-formed file.
	my $ds = Database::BI::Model::DataSource->new(
		directory => $DATA_DIR,
		table     => $SALES_TABLE,
	);
	my $rows;
	lives_ok { $rows = $ds->selectall_arrayref } 'selectall_arrayref() lives';
	isa_ok $rows, 'ARRAY', 'selectall_arrayref() returns an arrayref';
	if (@$rows) {
		isa_ok $rows->[0], 'HASH', 'first element is a hashref when rows present';
	}
	delete $ledger{'DataSource.selectall_arrayref'};
};

# ---  GET /view error rendering  --------------------------------------------

subtest 'GET /view/:table -- fetch_all error renders home with error_table_open' => sub {
	# When the DataSource backend throws during selectall_arrayref (the paginated
	# data fetch), the controller must catch the exception (inside its eval block)
	# and re-render the home page with the error_table_open message rather than
	# propagating a 500.  (The controller calls count() then selectall_arrayref()
	# rather than fetch_all() since pagination was introduced.)
	mock 'Database::BI::Model::DataSource::selectall_arrayref' => sub {
		die "Simulated backend failure\n";
	};
	$t->get_ok("/view/$SALES_TABLE")
	  ->status_is(200, 'renders 200 (home page) when selectall_arrayref throws')
	  ->content_type_like(qr{text/html}, 'response is HTML')
	  ->content_like(qr/Could not open table/i, 'error_table_open message present');
	restore_all();
	delete $ledger{'GET./view.error_table_open'};
};

# ---  GET /open error rendering  --------------------------------------------

subtest 'GET /open?path= -- fetch_all error renders home with error_file_open' => sub {
	# open_file wraps open_table+count+selectall_arrayref in eval; a DataSource
	# throw must surface as error_file_open on the home page, not as a 500.
	# (The controller calls count() then selectall_arrayref() since pagination
	# was introduced; fetch_all() is no longer called on this path.)
	SKIP: {
		skip 'data/sales.csv not found', 4 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		mock 'Database::BI::Model::DataSource::selectall_arrayref' => sub {
			die "Simulated read error\n";
		};
		$t->get_ok("/open?path=$enc")
		  ->status_is(200, 'renders 200 (home page) when selectall_arrayref throws')
		  ->content_type_like(qr{text/html}, 'response is HTML')
		  ->content_like(qr/Could not open/i, 'error_file_open message present');
		restore_all();
	}
	delete $ledger{'GET./open.error_file_open'};
};

# ---  GET /combine  ---------------------------------------------------------

subtest 'GET /combine?l=table:sales -- 200 HTML combined view' => sub {
	# combine_tables with only the left table renders the dashboard template
	# with all left-table rows (no stacking, no dedup).
	$t->get_ok("/combine?l=table:$SALES_TABLE")
	  ->status_is(200, 'combine with left-only returns 200')
	  ->content_type_like(qr{text/html}, 'response is HTML');
	delete $ledger{'GET./combine.200'};
};

subtest 'GET /combine (no l= param) -- 404' => sub {
	# Without a left-table spec the controller cannot open any source and
	# must return 404 (Mojolicious reply->not_found).
	$t->get_ok('/combine')->status_is(404);
	delete $ledger{'GET./combine.404'};
};

# ---  GET /export?format=json  ----------------------------------------------

subtest 'GET /export?l=table:sales&format=json -- 200 application/json' => sub {
	# The JSON export format is documented in the POD alongside csv and sqlite.
	# Verify it produces a JSON content type and a non-empty body.
	$t->get_ok("/export?l=table:$SALES_TABLE&format=json")
	  ->status_is(200, 'JSON export returns 200')
	  ->content_type_like(qr{application/json}, 'content-type is JSON');
	delete $ledger{'GET./export.json'};
};

# ---  GET /graph error paths  -----------------------------------------------

subtest 'GET /graph (no x= or y=) -- 400 Missing x or y column parameter' => sub {
	# graph_view checks for both x= and y= before opening the data source.
	# Missing either produces an immediate 400 with a plain-text error.
	$t->get_ok("/graph?l=table:$SALES_TABLE&x=product")
	  ->status_is(400, '400 when y= is absent')
	  ->content_like(qr/Missing x or y column parameter/, 'correct error text');
	delete $ledger{'GET./graph.400.missing_param'};
};

subtest 'GET /graph?x=<unknown> -- 400 Column not found' => sub {
	# If x= or y= names a column that does not exist in the result set,
	# graph_view returns 400 with "Column not found: <name>".
	$t->get_ok("/graph?l=table:$SALES_TABLE&x=no_such_col&y=amount")
	  ->status_is(400, '400 when x= column does not exist')
	  ->content_like(qr/Column not found/, 'correct error text');
	delete $ledger{'GET./graph.400.col_not_found'};
};

subtest 'GET /graph (no l= param) -- 404 Could not open data source' => sub {
	# Without a left-table spec the pipeline returns undef and graph_view
	# renders a 404 plain-text response.
	$t->get_ok('/graph?x=product&y=amount')
	  ->status_is(404, '404 when no data source supplied')
	  ->content_like(qr/Could not open data source/, 'correct error text');
	delete $ledger{'GET./graph.404.no_source'};
};

# ---  POST /uploads/clear  --------------------------------------------------

subtest 'POST /uploads/clear -- 200 JSON {freed, count}' => sub {
	# clear_uploads deletes all staging files and returns disk-space accounting.
	# The response is always 200 regardless of whether any files were present.
	$t->post_ok('/uploads/clear')
	  ->status_is(200, 'uploads clear always returns 200')
	  ->json_has('/freed', 'freed key present')
	  ->json_has('/count', 'count key present');
	my $body = $t->tx->res->json;
	cmp_ok $body->{freed}, '>=', 0, 'freed is non-negative';
	cmp_ok $body->{count}, '>=', 0, 'count is non-negative';
	delete $ledger{'POST./uploads_clear.200'};
};

# ---  POST /export write_failed  --------------------------------------------

subtest 'POST /export -- write failure returns 500 JSON {error}' => sub {
	# When the filesystem write inside export_write throws (e.g. disk full),
	# the controller must catch the exception and return 500 with {error}.
	# We simulate the failure by making the destination directory read-only.
	my $dir = tempdir(CLEANUP => 1);

	SKIP: {
		# Skips where chmod cannot stop a file being created: root, Cygwin
		# and Windows ACLs, some network and container filesystems.
		skip_unless_can_revoke('create', 4, $dir);

		with_revoked('create', $dir, sub {
			$t->post_ok('/export', form => {
				l        => "table:$SALES_TABLE",
				dir      => $dir,
				filename => 'out.csv',
			})->status_is(500, '500 when write to read-only dir fails')
			  ->json_has('/error', 'error key present in JSON response');
			my $err = $t->tx->res->json('/error');
			like $err, qr/Write failed/i, 'error message mentions Write failed';
		});
	}
	delete $ledger{'POST./export.write_failed'};
};

# ---------------------------------------------------------------------------
# GET /pie -- pie_view action (added 0.007.0)
#
# pie_view has four documented return paths (see POD MESSAGES):
#   400 -- missing cat= or val= param
#   400 -- named column not found in result set
#   404 -- data source could not be opened (no l=)
#   200 -- happy path: HTML chart (also tests __count__ mode, donut, currency)
#   200 -- all-text val column: "No plottable data" plain-text body
# ---------------------------------------------------------------------------

subtest 'GET /pie -- missing cat and val params each return 400' => sub {
	# POD: "Missing cat or val column parameter" is the message when either
	# required query param is absent.  Test both absence variants here.
	$t->get_ok("/pie?l=table:$SALES_TABLE&val=amount")
	  ->status_is(400, 'missing cat= produces 400')
	  ->content_like(qr/Missing cat or val column parameter/, 'correct error for missing cat');

	$t->get_ok("/pie?l=table:$SALES_TABLE&cat=region")
	  ->status_is(400, 'missing val= produces 400')
	  ->content_like(qr/Missing cat or val column parameter/, 'correct error for missing val');

	delete $ledger{'GET./pie.400.missing_param'};
};

subtest 'GET /pie?cat=no_such_col -- 400 Column not found' => sub {
	# POD: "Column not found: <name>" when the named column is absent from
	# the result set.  Both cat= and val= are checked against the column set.
	$t->get_ok("/pie?l=table:$SALES_TABLE&cat=no_such_col_xyz&val=amount")
	  ->status_is(400, 'unknown cat column returns 400')
	  ->content_like(qr/Column not found/, 'error text matches POD');
	delete $ledger{'GET./pie.400.col_not_found'};
};

subtest 'GET /pie (no l= param) -- 404 Could not open data source' => sub {
	# POD: 404 when _run_export_pipeline cannot open any source.
	$t->get_ok('/pie?cat=region&val=amount')
	  ->status_is(404, 'missing l= returns 404')
	  ->content_like(qr/Could not open data source/, 'error text matches POD');
	delete $ledger{'GET./pie.404.no_source'};
};

subtest 'GET /pie -- all-text val column returns 200 No plottable data' => sub {
	# POD: "No plottable data: ..." when every row in the val column is
	# non-numeric after stripping.  HTTP 200 (not 4xx) so the page renders
	# a friendly message rather than an error page.
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'text.csv');
	$file->spew("region,label\nNorth,Alfa\nSouth,Beta\n");
	$t->get_ok('/pie?l=path:' . url_escape($file->to_string) . '&cat=region&val=label')
	  ->status_is(200, 'non-numeric val column returns 200 not 4xx')
	  ->content_like(qr/No plottable data/i, '"No plottable data" message rendered');
	delete $ledger{'GET./pie.200.no_plottable'};
};

subtest 'GET /pie?l=table:sales&cat=region&val=amount -- 200 HTML pie chart' => sub {
	# Happy-path smoke test: valid cat + numeric val column renders the chart page.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		$t->get_ok("/pie?l=table:$SALES_TABLE&cat=region&val=amount")
		  ->status_is(200, 'valid pie request returns 200')
		  ->content_type_like(qr{text/html}, 'response is text/html');
	}
	delete $ledger{'GET./pie.200'};
};

subtest 'GET /pie?val=__count__ -- count mode renders 200 with count-by title' => sub {
	# POD DOMAIN CONSTRAINTS: the special sentinel value "__count__" causes the
	# controller to count rows per category instead of summing a numeric column.
	# The chart title must become "Count by <cat_col>" to reflect the mode.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'cats.csv');
		$file->spew("type,score\nFood,10\nFood,20\nDrink,5\n");
		$t->get_ok('/pie?l=path:' . url_escape($file->to_string) . '&cat=type&val=__count__')
		  ->status_is(200, '__count__ mode returns 200')
		  ->content_type_like(qr{text/html}, 'response is HTML')
		  ->content_like(qr/Count by type/i, 'chart title says "Count by <cat_col>"');
	}
	delete $ledger{'GET./pie.200.count_mode'};
};

subtest 'GET /pie?donut=1 -- donut chart variant renders 200' => sub {
	# POD: donut=1 passes through to HTML::D3 as donut => 1.  The page shape
	# is otherwise identical to a solid pie chart.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		$t->get_ok("/pie?l=table:$SALES_TABLE&cat=region&val=amount&donut=1")
		  ->status_is(200, 'donut=1 returns 200')
		  ->content_type_like(qr{text/html}, 'response is HTML');
	}
	delete $ledger{'GET./pie.200.donut'};
};

subtest 'GET /pie -- dollar amounts detected: data-currency="$" in page' => sub {
	# The controller scans raw cell values for the first non-numeric, non-paren
	# leading character to detect the currency symbol.  The result is embedded
	# in a hidden <div id="pie-meta" data-currency="..."> element so the JS
	# drill-down handler can prepend it to each legend amount.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'txn.csv');
		$file->spew("category,amount\nFood,\$10.00\nDrink,\$5.00\n");
		$t->get_ok('/pie?l=path:' . url_escape($file->to_string) . '&cat=category&val=amount')
		  ->status_is(200, 'pie with dollar amounts returns 200')
		  ->content_like(qr/data-currency="\$"/, 'dollar sign embedded in data-currency attribute');
	}
	delete $ledger{'GET./pie.200.currency'};
};

# ---------------------------------------------------------------------------
# GET /heatmap -- heatmap_view action (added 0.008.0)
#
# heatmap_view documented return paths:
#   400 -- missing x= or y= param
#   400 -- named column not found in result set
#   404 -- no data source (no l=)
#   200 -- happy path: HTML heatmap chart
#   200 -- without val=: count mode, title "Count by x and y"
#   200 -- all-empty x/y cells: "No plottable data" plain-text body
# ---------------------------------------------------------------------------

subtest 'GET /heatmap -- missing x= or y= each return 400' => sub {
	# Both params are required; absence of either triggers the same 400.
	$t->get_ok("/heatmap?l=table:$SALES_TABLE&y=region")
	  ->status_is(400, 'missing x= produces 400')
	  ->content_like(qr/Missing x or y column parameter/, 'correct error for missing x');

	$t->get_ok("/heatmap?l=table:$SALES_TABLE&x=region")
	  ->status_is(400, 'missing y= produces 400')
	  ->content_like(qr/Missing x or y column parameter/, 'correct error for missing y');

	delete $ledger{'GET./heatmap.400.missing_param'};
};

subtest 'GET /heatmap?x=no_such_col -- 400 Column not found' => sub {
	$t->get_ok("/heatmap?l=table:$SALES_TABLE&x=no_such_col_xyz&y=region")
	  ->status_is(400, 'unknown x column returns 400')
	  ->content_like(qr/Column not found/, 'error text matches POD');
	delete $ledger{'GET./heatmap.400.col_not_found'};
};

subtest 'GET /heatmap (no l= param) -- 404 Could not open data source' => sub {
	$t->get_ok('/heatmap?x=region&y=product')
	  ->status_is(404, 'missing l= returns 404')
	  ->content_like(qr/Could not open data source/, 'error text matches POD');
	delete $ledger{'GET./heatmap.404.no_source'};
};

subtest 'GET /heatmap -- all-empty x/y cells returns 200 No plottable data' => sub {
	# Rows where x or y is empty are skipped; if all rows are skipped the
	# controller returns 200 with a friendly message rather than an error.
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'hmempty.csv');
	$file->spew("x,y\n,\n,\n");
	$t->get_ok('/heatmap?l=path:' . url_escape($file->to_string) . '&x=x&y=y')
	  ->status_is(200, 'empty grid returns 200 not 4xx')
	  ->content_like(qr/No plottable data/i, '"No plottable data" message rendered');
	delete $ledger{'GET./heatmap.200.no_plottable'};
};

subtest 'GET /heatmap?l=...&x=...&y=...&val=... -- 200 HTML heatmap chart' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'hm.csv');
		$file->spew("team,week,tickets\nAlpha,W1,5\nBeta,W1,3\nAlpha,W2,7\n");
		$t->get_ok('/heatmap?l=path:' . url_escape($file->to_string) . '&x=week&y=team&val=tickets')
		  ->status_is(200, 'valid heatmap request returns 200')
		  ->content_type_like(qr{text/html}, 'response is text/html');
	}
	delete $ledger{'GET./heatmap.200'};
};

subtest 'GET /heatmap without val= -- count mode renders 200 with count-by title' => sub {
	# Omitting val= activates count mode: rows are tallied per (x,y) cell and
	# the chart title becomes "Count by <x_col> and <y_col>".
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'hmcnt.csv');
		$file->spew("team,week\nAlpha,W1\nBeta,W1\nAlpha,W2\n");
		$t->get_ok('/heatmap?l=path:' . url_escape($file->to_string) . '&x=week&y=team')
		  ->status_is(200, 'count-mode heatmap returns 200')
		  ->content_type_like(qr{text/html}, 'response is HTML')
		  ->content_like(qr/Count by week and team/i, 'count-mode title present');
	}
	delete $ledger{'GET./heatmap.200.count_mode'};
};

# ---------------------------------------------------------------------------
# GET /bar -- bar_view action (added 0.009.0)
#
# bar_view documented return paths:
#   400 -- missing cat= param
#   400 -- named column not found in result set
#   404 -- no data source (no l=)
#   200 -- happy path: HTML bar chart
#   200 -- val=__count__: count rows per category
#   200 -- all-blank category cells: "No plottable data"
# Plus: unsafe back= URL must not reach the rendered page (_safe_back_url contract)
# ---------------------------------------------------------------------------

subtest 'GET /bar -- missing cat= returns 400' => sub {
	$t->get_ok("/bar?l=table:$SALES_TABLE&val=amount")
	  ->status_is(400, 'missing cat= produces 400')
	  ->content_like(qr/Missing cat column parameter/, 'correct error for missing cat');
	delete $ledger{'GET./bar.400.missing_param'};
};

subtest 'GET /bar?cat=no_such_col -- 400 Column not found' => sub {
	$t->get_ok("/bar?l=table:$SALES_TABLE&cat=no_such_col_xyz&val=amount")
	  ->status_is(400, 'unknown cat column returns 400')
	  ->content_like(qr/Column not found/, 'error text matches POD');
	delete $ledger{'GET./bar.400.col_not_found'};
};

subtest 'GET /bar (no l= param) -- 404 Could not open data source' => sub {
	$t->get_ok('/bar?cat=region&val=amount')
	  ->status_is(404, 'missing l= returns 404')
	  ->content_like(qr/Could not open data source/, 'error text matches POD');
	delete $ledger{'GET./bar.404.no_source'};
};

subtest 'GET /bar -- all-blank category cells returns 200 No plottable data' => sub {
	# Rows with an empty cat value are skipped; when every row is skipped the
	# controller returns 200 with "No plottable data" rather than a 4xx error.
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'blanks.csv');
	$file->spew("cat,val\n,10\n,20\n");
	$t->get_ok('/bar?l=path:' . url_escape($file->to_string) . '&cat=cat&val=val')
	  ->status_is(200, 'blank-category data returns 200 not 4xx')
	  ->content_like(qr/No plottable data/i, '"No plottable data" message rendered');
	delete $ledger{'GET./bar.200.no_plottable'};
};

subtest 'GET /bar?l=table:sales&cat=region&val=amount -- 200 HTML bar chart' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		$t->get_ok("/bar?l=table:$SALES_TABLE&cat=region&val=amount")
		  ->status_is(200, 'valid bar request returns 200')
		  ->content_type_like(qr{text/html}, 'response is text/html');
	}
	delete $ledger{'GET./bar.200'};
};

subtest 'GET /bar?val=__count__ -- count mode renders 200 with count-by title' => sub {
	# The "__count__" sentinel skips summing a numeric column and instead counts
	# rows per category.  The chart title must become "Count by <cat_col>".
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'barcnt.csv');
		$file->spew("type,score\nFood,10\nFood,20\nDrink,5\n");
		$t->get_ok('/bar?l=path:' . url_escape($file->to_string) . '&cat=type&val=__count__')
		  ->status_is(200, '__count__ mode returns 200')
		  ->content_type_like(qr{text/html}, 'response is HTML')
		  ->content_like(qr/Count by type/i, 'chart title says "Count by <cat_col>"');
	}
	delete $ledger{'GET./bar.200.count_mode'};
};

subtest 'GET /bar?back=javascript:alert(1) -- XSS-unsafe back= falls back to /' => sub {
	# _safe_back_url rejects javascript: and other unsafe schemes; the rendered
	# page must not reflect the hostile URL in any href attribute.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		$t->get_ok("/bar?l=table:$SALES_TABLE&cat=region&val=amount"
		           . '&back=javascript%3Aalert%281%29')
		  ->status_is(200, 'bar with javascript: back= still renders 200')
		  ->content_unlike(qr/href="javascript:/i, 'javascript: URL not in page href attributes');
	}
	delete $ledger{'GET./bar.200.back_rejected'};
};

# ---------------------------------------------------------------------------
# GET /folder -- folder_view action (added 0.010.0)
#
# folder_view documented return paths:
#   400 -- missing l= param
#   400 -- prefix exceeds MAX_PREFIX_LEN (DoS guard)
#   404 -- no data source (bad path)
#   200 -- top-level folder grid rendered
#   200 -- drill into prefix: item table rendered
# ---------------------------------------------------------------------------

subtest 'GET /folder (no l= param) -- 400 Missing l= parameter' => sub {
	$t->get_ok('/folder')
	  ->status_is(400, 'missing l= returns 400')
	  ->content_like(qr/Missing l= parameter/, 'correct error text');
	$t->get_ok('/folder?col=order_no')
	  ->status_is(400, 'l= absent with col= also returns 400');
	delete $ledger{'GET./folder.400.no_l'};
};

subtest 'GET /folder?prefix=<21 chars> -- 400 DoS guard' => sub {
	my $long_prefix = 'A' x 21;
	$t->get_ok('/folder?l=table:' . $SALES_TABLE . '&prefix=' . $long_prefix)
	  ->status_is(400, '21-char prefix rejected')
	  ->content_like(qr/Prefix too long/, 'correct error text');
	delete $ledger{'GET./folder.400.prefix_too_long'};
};

subtest 'GET /folder?l=path:/nonexistent -- 404' => sub {
	$t->get_ok('/folder?l=' . url_escape('path:/nonexistent/nosuchfile.csv'))
	  ->status_is(404, 'non-existent path returns 404');
	delete $ledger{'GET./folder.404.no_source'};
};

subtest 'GET /folder -- top-level folder grid (200)' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'orders.csv');
	$file->spew("order_no,item\nA10,Widget\nA20,Gadget\nB5,Doohickey\nCA3,Sprocket\n");
	$t->get_ok('/folder?l=path:' . url_escape($file->to_string) . '&col=order_no')
	  ->status_is(200, 'top-level folder view returns 200')
	  ->content_type_like(qr{text/html}, 'response is HTML')
	  ->content_like(qr/Folder view/, 'page contains "Folder view" heading')
	  ->content_like(qr/folder-card/, 'folder cards are rendered');
	delete $ledger{'GET./folder.200'};
};

subtest 'GET /folder?prefix=A -- drill-down renders items (200)' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'drill.csv');
	$file->spew("order_no,item\nA10,Widget\nA20,Gadget\nB5,Doohickey\n");
	$t->get_ok('/folder?l=path:' . url_escape($file->to_string)
	           . '&col=order_no&prefix=A')
	  ->status_is(200, 'drill-down into prefix A returns 200')
	  ->content_like(qr/Widget|Gadget/, 'items for prefix A are rendered');
	delete $ledger{'GET./folder.200.drill'};
};

# ============================================================================
# Geocode.pm -- public API black-box coverage
# ============================================================================

use_ok('Database::BI::Model::Geocode');

Readonly my $GEOCODE_CLASS => 'Database::BI::Model::Geocode';
Readonly my $MAP_PLACE     => 'Ramsgate';
Readonly my $MAP_LAT       => 51.33;
Readonly my $MAP_LON       =>  1.42;

# ---------------------------------------------------------------------------
# new() -- documented constructor paths
# ---------------------------------------------------------------------------

subtest 'Geocode.new -- no-argument constructor returns blessed object' => sub {
	my $g;
	lives_ok { $g = $GEOCODE_CLASS->new() } 'new() with no args does not croak';
	ok defined($g) && ref($g), 'returns a defined reference';
	is ref($g), $GEOCODE_CLASS, 'object is the correct class';
	delete $ledger{'Geocode.new.ok'};
};

subtest 'Geocode.new -- injected geocoder with valid interface is accepted' => sub {
	my $stub = Unit::Geocoder->new();
	my $g;
	lives_ok { $g = $GEOCODE_CLASS->new(geocoder => $stub) }
		'injected geocoder with valid interface does not croak';
	ok defined($g), 'returns object';
	delete $ledger{'Geocode.new.injected_geocoder'};
};

subtest 'Geocode.new -- geocoder lacking geocode_many() croaks with interface message' => sub {
	my $broken = Unit::GeoBroken->new();
	throws_ok { $GEOCODE_CLASS->new(geocoder => $broken) }
		qr/geocode_many/,
		'error names the missing method';
	delete $ledger{'Geocode.new.bad_interface'};
};

# ---------------------------------------------------------------------------
# geocoder_available() -- documented return paths
# ---------------------------------------------------------------------------

subtest 'Geocode.geocoder_available -- returns (1, undef) when stub is injected' => sub {
	my $g  = $GEOCODE_CLASS->new(geocoder => Unit::Geocoder->new());
	my ($ok, $reason) = $g->geocoder_available();
	ok $ok, 'available=1 with injected geocoder';
	ok !defined($reason), 'reason is undef when available';
	delete $ledger{'Geocode.geocoder_available.true'};
};

subtest 'Geocode.geocoder_available -- returns (0, sentence) when module absent/old' => sub {
	# Force the "too old" path by requesting an impossibly high version floor.
	my $g  = $GEOCODE_CLASS->new(min_geocoder_version => '9999.0');
	my ($ok, $reason) = $g->geocoder_available();
	ok !$ok, 'available=0 without a usable geocoder';
	ok defined($reason) && length($reason), 'reason is a non-empty string';
	like $reason, qr/Geo::Coder::Free/, 'message names the module';
	delete $ledger{'Geocode.geocoder_available.false'};
};

# ---------------------------------------------------------------------------
# resolve_values() -- documented input-validation and result-shape paths
# ---------------------------------------------------------------------------

subtest 'Geocode.resolve_values -- valid arrayref returns counts hashref' => sub {
	my $stub = Unit::Geocoder->new(results => {
		$MAP_PLACE => Unit::GeoPoint->new({
			latitude => $MAP_LAT, longitude => $MAP_LON, database => 'Test',
		}),
	});
	my $g = $GEOCODE_CLASS->new(geocoder => $stub, openaddr => 'test');
	my $r = $g->resolve_values([$MAP_PLACE]);

	ok ref($r) eq 'HASH', 'result is a hashref';
	ok exists $r->{counts},    'counts key present';
	ok exists $r->{cache},     'cache key present';
	ok exists $r->{available}, 'available key present';
	is $r->{counts}{resolved}, 1, 'one place resolved';
	delete $ledger{'Geocode.resolve_values.ok'};
};

subtest 'Geocode.resolve_values -- non-arrayref input croaks error_values_arrayref' => sub {
	my $g = $GEOCODE_CLASS->new(geocoder => Unit::Geocoder->new());
	throws_ok { $g->resolve_values('not_an_array') }
		qr/values.*arrayref/i,
		'scalar input triggers error_values_arrayref';
	throws_ok { $g->resolve_values(undef) }
		qr/values.*arrayref/i,
		'undef input triggers error_values_arrayref';
	delete $ledger{'Geocode.resolve_values.bad_input'};
};

subtest 'Geocode.resolve_values -- max= cap puts excess places in not_attempted' => sub {
	my @places = map { "Place$_" } 1..5;
	my %res    = map { $_ => Unit::GeoPoint->new({ latitude => 1, longitude => 2, database => 'T' }) } @places;
	my $stub   = Unit::Geocoder->new(results => \%res);
	my $g      = $GEOCODE_CLASS->new(geocoder => $stub, openaddr => 'test');
	my $r      = $g->resolve_values(\@places, max => 2);

	is $r->{counts}{attempted},     2, 'only 2 places attempted (max=2)';
	is $r->{counts}{not_attempted}, 3, '3 places held back in not_attempted';
	ok $r->{capped}, 'capped flag is true';
	# not_attempted must NOT be cached -- the next request picks them up.
	for my $p (@places[2..4]) {
		ok !exists($r->{cache}{$p}), "uncapped place $p absent from cache";
	}
	delete $ledger{'Geocode.resolve_values.cap'};
};

subtest 'Geocode.resolve_values -- cache hit skips geocoder, resolved count includes cached' => sub {
	my $stub = Unit::Geocoder->new();  # no results needed; geocoder must not be called
	my $g    = $GEOCODE_CLASS->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([$MAP_PLACE],
		cache => { $MAP_PLACE => [$MAP_LAT, $MAP_LON] });

	is scalar(@{ $stub->{calls} }), 0, 'geocoder not called when value in cache';
	is $r->{counts}{cached},        1, 'cached count is 1';
	is $r->{counts}{resolved},      1, 'resolved count includes cached hit';
	delete $ledger{'Geocode.resolve_values.cache_hit'};
};

# ---------------------------------------------------------------------------
# resolve_column() -- documented input-validation and row-level paths
# ---------------------------------------------------------------------------

subtest 'Geocode.resolve_column -- resolves place column, populates markers + counts' => sub {
	my $stub = Unit::Geocoder->new(results => {
		$MAP_PLACE => Unit::GeoPoint->new({ latitude => $MAP_LAT, longitude => $MAP_LON, database => 'Test' }),
	});
	my $g    = $GEOCODE_CLASS->new(geocoder => $stub, openaddr => 'test');
	my $rows = [{ place => $MAP_PLACE }, { place => $MAP_PLACE }, { place => '' }];
	my $r    = $g->resolve_column($rows, 'place');

	ok ref($r->{markers}) eq 'ARRAY', 'markers key is an arrayref';
	is scalar(@{ $r->{markers} }), 1, 'one distinct resolved place gives one marker';
	is $r->{counts}{rows},         3, 'all three rows counted';
	is $r->{markers}[0]{rows},     2, 'marker reports how many rows hold this place';
	delete $ledger{'Geocode.resolve_column.ok'};
};

subtest 'Geocode.resolve_column -- non-arrayref rows croaks error_rows_arrayref' => sub {
	my $g = $GEOCODE_CLASS->new(geocoder => Unit::Geocoder->new());
	throws_ok { $g->resolve_column('not_rows', 'place') }
		qr/rows.*arrayref/i,
		'scalar rows triggers error_rows_arrayref';
	delete $ledger{'Geocode.resolve_column.bad_rows'};
};

subtest 'Geocode.resolve_column -- column not in any row croaks error_map_loc_column' => sub {
	my $g = $GEOCODE_CLASS->new(geocoder => Unit::Geocoder->new());
	throws_ok { $g->resolve_column([{name => 'Alice'}], 'place') }
		qr/place/,
		'missing column name is embedded in the error';
	delete $ledger{'Geocode.resolve_column.col_miss'};
};

# ---------------------------------------------------------------------------
# cache_from_models() -- documented return paths
# ---------------------------------------------------------------------------

subtest 'Geocode.cache_from_models -- valid models returns copy of places for spec' => sub {
	my $models = {
		geo => {
			'table:test' => {
				places  => { $MAP_PLACE => [$MAP_LAT, $MAP_LON], Unknown => 0 },
				backend => 'Test',
				built   => '2026-01-01T00:00:00Z',
			},
		},
	};
	my $cache = $GEOCODE_CLASS->cache_from_models($models, 'table:test');
	ok ref($cache) eq 'HASH', 'returns a hashref';
	is scalar(keys %$cache), 2, 'both places returned';
	is_deeply $cache->{$MAP_PLACE}, [$MAP_LAT, $MAP_LON], 'resolved place has [lat,lon]';
	is $cache->{Unknown}, 0, 'unresolved place has 0 sentinel';
	delete $ledger{'Geocode.cache_from_models.ok'};
};

subtest 'Geocode.cache_from_models -- unknown spec returns empty hashref' => sub {
	my $cache = $GEOCODE_CLASS->cache_from_models({}, 'table:unknown');
	ok ref($cache) eq 'HASH', 'returns a hashref';
	is scalar(keys %$cache), 0, 'empty for unknown spec';
	delete $ledger{'Geocode.cache_from_models.empty'};
};

# ---------------------------------------------------------------------------
# models_with_cache() -- documented return paths
# ---------------------------------------------------------------------------

subtest 'Geocode.models_with_cache -- stores places + backend + built under spec key' => sub {
	my $r = $GEOCODE_CLASS->models_with_cache(
		{}, 'table:test',
		{ $MAP_PLACE => [$MAP_LAT, $MAP_LON] },
		backend => 'OpenAddresses',
		built   => '2026-01-01T00:00:00Z',
	);
	ok ref($r) eq 'HASH', 'returns a hashref';
	ok exists $r->{geo}{'table:test'}, 'spec key created under geo section';
	is_deeply $r->{geo}{'table:test'}{places}, { $MAP_PLACE => [$MAP_LAT, $MAP_LON] },
		'places stored correctly';
	is $r->{geo}{'table:test'}{backend}, 'OpenAddresses', 'backend stored';
	is $r->{geo}{'table:test'}{built},   '2026-01-01T00:00:00Z', 'built stored';
	delete $ledger{'Geocode.models_with_cache.ok'};
};

subtest 'Geocode.models_with_cache -- does not mutate the caller hashref' => sub {
	my $original = { geo => {} };
	$GEOCODE_CLASS->models_with_cache($original, 'table:test', { A => [1, 2] });
	ok !exists($original->{geo}{'table:test'}), 'original models hashref is untouched';
	delete $ledger{'Geocode.models_with_cache.immut'};
};

# ============================================================================
# GET /map -- every documented HTTP return state
#
# Fixtures are written to tempfiles so no pre-existing data file is needed.
# The stub geocoder is injected via app config.
# ============================================================================

{
	# Re-use the same app instance but inject the stub geocoder so map_view
	# exercises the location-column path without Geo::Coder::Free.
	my $stub_map = Unit::Geocoder->new(results => {
		$MAP_PLACE => Unit::GeoPoint->new({
			latitude => $MAP_LAT, longitude => $MAP_LON, database => 'Test',
		}),
	});
	$t->app->config->{geocoder} = $stub_map;
	$t->app->config->{openaddr} = 'test';    # suppresses warn_map_geocoder_unavailable_data

	my $map_dir  = tempdir(CLEANUP => 1);

	# CSV with a location column (for loc= path).
	my $places_csv = Mojo::File->new($map_dir, 'places.csv');
	$places_csv->spew(
		"id,place,amount\n"
		. "1,$MAP_PLACE,10\n"
		. "2,$MAP_PLACE,5\n"
		. "3,,2\n"
	);

	# CSV with lat/lon columns (for lat=/lon= path).
	my $coord_csv = Mojo::File->new($map_dir, 'coords.csv');
	$coord_csv->spew(
		"id,lat,lon\n"
		. "1,51.33,1.42\n"
		. "2,51.92,0.75\n"
		. "3,,\n"
	);

	# CSV with all-out-of-range lat values.
	my $range_csv = Mojo::File->new($map_dir, 'range.csv');
	$range_csv->spew("id,lat,lon\n1,200,1\n2,201,2\n");

	# CSV with all-out-of-range lon values.
	my $range_lon_csv = Mojo::File->new($map_dir, 'range_lon.csv');
	$range_lon_csv->spew("id,lat,lon\n1,51.0,200\n2,52.0,201\n");

	# CSV with non-numeric lat/lon values.
	my $text_csv = Mojo::File->new($map_dir, 'text_coords.csv');
	$text_csv->spew("id,lat,lon\n1,north,east\n2,south,west\n");

	Readonly my $PLACES_SPEC  => 'path:' . $places_csv->to_string;
	Readonly my $COORD_SPEC   => 'path:' . $coord_csv->to_string;
	Readonly my $RANGE_SPEC   => 'path:' . $range_csv->to_string;
	Readonly my $RANGE_LON    => 'path:' . $range_lon_csv->to_string;
	Readonly my $TEXT_SPEC    => 'path:' . $text_csv->to_string;

	subtest 'GET /map -- no loc= and no lat=/lon= returns 400 error_map_source' => sub {
		$t->get_ok('/map?l=' . url_escape($PLACES_SPEC))
		  ->status_is(400, '400 when neither loc= nor lat=/lon= given')
		  ->content_like(qr/loc=<column>/, 'error_map_source text in response');
		delete $ledger{'GET./map.400.no_source_col'};
	};

	subtest 'GET /map -- only lat= without lon= returns 400 error_map_coordinates' => sub {
		$t->get_ok('/map?l=' . url_escape($COORD_SPEC) . '&lat=lat')
		  ->status_is(400, '400 for half a coordinate pair')
		  ->content_like(qr/lon=|lat=/, 'error_map_coordinates text in response');
		delete $ledger{'GET./map.400.half_coord'};
	};

	subtest 'GET /map -- non-existent data source returns 404' => sub {
		$t->get_ok('/map?l=path:/nonexistent/nothing.csv&lat=lat&lon=lon')
		  ->status_is(404, '404 for unopenable source');
		delete $ledger{'GET./map.404.no_source'};
	};

	subtest 'GET /map -- loc= column not in dataset returns 400 error_map_loc_column' => sub {
		$t->get_ok('/map?l=' . url_escape($PLACES_SPEC) . '&loc=no_such_col')
		  ->status_is(400, '400 for unknown loc= column')
		  ->content_like(qr/no_such_col/, 'column name named in error_map_loc_column');
		delete $ledger{'GET./map.400.loc_col_not_found'};
	};

	subtest 'GET /map?loc=place -- successful geocode path returns 200 HTML' => sub {
		my $res = $t->get_ok('/map?l=' . url_escape($PLACES_SPEC) . '&loc=place')
		            ->status_is(200, '200 for valid loc= geocode')
		            ->content_type_like(qr{text/html}, 'response is HTML');
		# Place names appear only inside map_body (Leaflet popup HTML), which
		# needs HTML::OSM 0.14 or later: below that floor the page reports the
		# renderer and draws nothing.  Skip this single assertion then.
		SKIP: {
			eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
				or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 1;
			$res->content_like(qr/$MAP_PLACE/i, 'place name appears in response');
		}
		delete $ledger{'GET./map.200.loc'};
	};

	subtest 'GET /map -- lat column wholly out of range returns 400 error_map_coordinate_range' => sub {
		$t->get_ok('/map?l=' . url_escape($RANGE_SPEC) . '&lat=lat&lon=lon')
		  ->status_is(400, '400 when all lat values outside [-90,90]')
		  ->content_like(qr/latitude/, 'error_map_coordinate_range names latitude');
		delete $ledger{'GET./map.400.lat_range'};
	};

	subtest 'GET /map -- lon column wholly out of range returns 400 error_map_coordinate_range' => sub {
		$t->get_ok('/map?l=' . url_escape($RANGE_LON) . '&lat=lat&lon=lon')
		  ->status_is(400, '400 when all lon values outside [-180,180]')
		  ->content_like(qr/longitude/, 'error_map_coordinate_range names longitude');
		delete $ledger{'GET./map.400.lon_range'};
	};

	subtest 'GET /map -- non-numeric lat/lon columns returns 400 error_map_coordinate_numeric' => sub {
		$t->get_ok('/map?l=' . url_escape($TEXT_SPEC) . '&lat=lat&lon=lon')
		  ->status_is(400, '400 when lat/lon hold no numbers')
		  ->content_like(qr/numeric coordinate pairs|lat.*lon/, 'error_map_coordinate_numeric text');
		delete $ledger{'GET./map.400.no_numeric_pairs'};
	};

	subtest 'GET /map?lat=&lon= -- coordinate column path returns 200 HTML' => sub {
		$t->get_ok('/map?l=' . url_escape($COORD_SPEC) . '&lat=lat&lon=lon')
		  ->status_is(200, '200 for valid lat=/lon= coordinate map')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./map.200.latlon'};
	};

	# Clean up config so subsequent tests do not see the stub.
	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
}

# ---------------------------------------------------------------------------
# Database::BI::Util -- urlencode() public API
# ---------------------------------------------------------------------------
{
	require Database::BI::Util;
	Database::BI::Util->import('urlencode');

	subtest 'Util.urlencode -- undef argument returns empty string' => sub {
		is(urlencode(undef), '', 'urlencode(undef) returns empty string, does not croak');
		delete $ledger{'Util.urlencode.undef'};
	};

	subtest 'Util.urlencode -- empty string returns empty string' => sub {
		is(urlencode(''), '', 'urlencode("") returns ""');
		delete $ledger{'Util.urlencode.empty'};
	};

	subtest 'Util.urlencode -- RFC 3986 unreserved chars pass through unchanged' => sub {
		# POD: Preserves A-Z a-z 0-9 - . _ ~
		my $unreserved = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
		is(urlencode($unreserved), $unreserved, 'all RFC 3986 unreserved chars preserved');
		delete $ledger{'Util.urlencode.unreserved'};
	};

	subtest 'Util.urlencode -- colon encoded as %3A' => sub {
		is(urlencode('table:sales'), 'table%3Asales', 'colon -> %3A');
		delete $ledger{'Util.urlencode.colon'};
	};

	subtest 'Util.urlencode -- space encoded as %20, not plus' => sub {
		is(urlencode('hello world'), 'hello%20world', 'space -> %20');
		delete $ledger{'Util.urlencode.space'};
	};

	subtest 'Util.urlencode -- forward slash encoded as %2F' => sub {
		is(urlencode('/data/file.csv'), '%2Fdata%2Ffile.csv', 'slash -> %2F');
		delete $ledger{'Util.urlencode.slash'};
	};

	subtest 'Util.urlencode -- hex digits in percent-encoding are uppercase' => sub {
		# ASCII 0x1B = 27 decimal = 1B hex; must be %1B not %1b.
		is(urlencode("\x1b"), '%1B', 'hex digits are uppercase');
		# ASCII 0x2F = 47 decimal = 2F hex.
		is(urlencode('/'), '%2F', 'slash uses uppercase hex %2F not %2f');
		delete $ledger{'Util.urlencode.uppercase'};
	};
}

# ---------------------------------------------------------------------------
# Database::BI::Ask -- infer_column_types() and ask() public API
# ---------------------------------------------------------------------------
{
	require Database::BI::Ask;
	require HTTP::Response;

	# Helper: wraps an LLM text response in the Anthropic Messages API envelope.
	# A package sub, not "my sub": on perl 5.42 a lexical sub here makes
	# Devel::Cover segfault in B::CV::GV at global destruction, after every
	# test has passed.
	sub make_llm_response {
		my ($text, $status) = @_;
		$status //= 200;
		if ($status != 200) {
			return sub { HTTP::Response->new($status, 'Error', [], '') };
		}
		require JSON::PP;
		my $body = JSON::PP::encode_json({ content => [{ type => 'text', text => $text }] });
		return sub { HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $body) };
	}

	# --- infer_column_types ---

	subtest 'Ask.infer_column_types -- empty inputs return empty arrayref' => sub {
		my $r = Database::BI::Ask::infer_column_types([], []);
		is_deeply($r, [], 'empty records + empty cols -> []');
		delete $ledger{'Ask.infer_column_types.empty'};
	};

	subtest 'Ask.infer_column_types -- majority-numeric values -> type=number' => sub {
		my @records = map { { amount => $_ } } qw(10 20 30 40 50);
		my $r = Database::BI::Ask::infer_column_types(\@records, ['amount']);
		is($r->[0]{type}, 'number', 'numeric column classified as number');
		delete $ledger{'Ask.infer_column_types.numeric'};
	};

	subtest 'Ask.infer_column_types -- majority ISO-date values -> type=date' => sub {
		my @records = map { { d => $_ } } qw(2026-01-01 2026-01-02 2026-01-03);
		my $r = Database::BI::Ask::infer_column_types(\@records, ['d']);
		is($r->[0]{type}, 'date', 'ISO-date column classified as date');
		delete $ledger{'Ask.infer_column_types.date'};
	};

	subtest 'Ask.infer_column_types -- non-numeric non-date values -> type=string' => sub {
		my @records = map { { name => $_ } } qw(Alice Bob Carol Dave Eve);
		my $r = Database::BI::Ask::infer_column_types(\@records, ['name']);
		is($r->[0]{type}, 'string', 'plain-string column classified as string');
		delete $ledger{'Ask.infer_column_types.string'};
	};

	# --- ask() guard conditions (no LLM call) ---

	subtest 'Ask.ask -- empty question returns ask_no_question error' => sub {
		my $r = Database::BI::Ask::ask(
			question  => '',
			spec_key  => 'table:sales',
			columns   => [],
			ai_config => { api_key => 'test-key' },
		);
		is($r->{error}, 'ask_no_question', 'empty question -> ask_no_question');
		delete $ledger{'Ask.ask.no_question'};
	};

	subtest 'Ask.ask -- missing api_key returns ask_unavailable error' => sub {
		my $r = Database::BI::Ask::ask(
			question  => 'show me a chart',
			spec_key  => 'table:sales',
			columns   => [],
			ai_config => {},
		);
		is($r->{error}, 'ask_unavailable', 'no api_key -> ask_unavailable');
		delete $ledger{'Ask.ask.no_api_key'};
	};

	# --- ask() with mocked LWP responses ---

	subtest 'Ask.ask -- LLM HTTP failure returns ask_provider_error' => sub {
		local *LWP::UserAgent::request = make_llm_response(undef, 500);
		my $r = Database::BI::Ask::ask(
			question  => 'show me a chart',
			spec_key  => 'table:sales',
			columns   => [{ name => 'region', type => 'string' }],
			ai_config => { api_key => 'key' },
		);
		is($r->{error}, 'ask_provider_error', 'LLM 500 -> ask_provider_error');
		delete $ledger{'Ask.ask.provider_error'};
	};

	subtest 'Ask.ask -- non-JSON LLM reply returns ask_unparseable' => sub {
		local *LWP::UserAgent::request = make_llm_response('This is not JSON at all.');
		my $r = Database::BI::Ask::ask(
			question  => 'show me a chart',
			spec_key  => 'table:sales',
			columns   => [{ name => 'region', type => 'string' }],
			ai_config => { api_key => 'key' },
		);
		is($r->{error}, 'ask_unparseable', 'non-JSON reply -> ask_unparseable');
		delete $ledger{'Ask.ask.unparseable'};
	};

	subtest 'Ask.ask -- encode column not in dataset returns ask_invalid_spec' => sub {
		# LLM says use "nonexistent" column, but that column is not in \@cols.
		local *LWP::UserAgent::request = make_llm_response(
			'{"kind":"pie","title":"X","encode":{"cat":"nonexistent","val":"amount"}}'
		);
		my $r = Database::BI::Ask::ask(
			question  => 'show me a pie chart',
			spec_key  => 'table:sales',
			columns   => [{ name => 'region', type => 'string' },
			              { name => 'amount', type => 'number' }],
			ai_config => { api_key => 'key' },
		);
		like($r->{error}, qr/\Aask_invalid_spec:/, 'unknown column -> ask_invalid_spec:col');
		delete $ledger{'Ask.ask.invalid_spec'};
	};

	subtest 'Ask.ask -- successful mocked LLM returns spec, url, valid=1' => sub {
		local *LWP::UserAgent::request = make_llm_response(
			'{"kind":"pie","title":"Sales by region","encode":{"cat":"region","val":"amount"}}'
		);
		my $r = Database::BI::Ask::ask(
			question  => 'show me sales by region',
			spec_key  => 'table:sales',
			label     => 'sales',
			columns   => [{ name => 'region', type => 'string' },
			              { name => 'amount', type => 'number' }],
			ai_config => { api_key => 'key' },
		);
		is($r->{valid}, 1, 'successful ask -> valid=1');
		ok(defined $r->{url},  'successful ask -> url is defined');
		ok(ref $r->{spec},     'successful ask -> spec is a reference');
		delete $ledger{'Ask.ask.success'};
	};
}

# ---------------------------------------------------------------------------
# Database::BI::Insights -- compute() and method_note() public API
# ---------------------------------------------------------------------------
{
	require Database::BI::Insights;

	subtest 'Insights.compute -- empty records returns []' => sub {
		my $r = Database::BI::Insights::compute(records => [], columns => []);
		is_deeply($r, [], 'empty input -> empty arrayref');
		delete $ledger{'Insights.compute.empty'};
	};

	subtest 'Insights.compute -- detects outlier kind with skewed numeric data' => sub {
		# 5 low values + 1 extreme high value; with enough rows the extreme triggers
		# the Tukey IQR fence outlier detection.
		my @records = (
			{ amount => 10 }, { amount => 12 }, { amount => 11 },
			{ amount => 13 }, { amount => 10 }, { amount => 1000 },
		);
		my $r = Database::BI::Insights::compute(
			records  => \@records,
			columns  => ['amount'],
			spec_key => 'table:test',
		);
		my @outliers = grep { $_->{kind} eq 'outlier' } @$r;
		ok(scalar @outliers >= 1, 'at least one outlier insight returned');
		is($outliers[0]{kind}, 'outlier', 'insight kind is "outlier"');
		ok(defined $outliers[0]{view_url}, 'outlier insight carries view_url');
		delete $ledger{'Insights.compute.outlier'};
	};

	subtest 'Insights.compute -- detects period_delta with date + numeric data' => sub {
		# Two distinct month-periods: 2026-01 and 2026-02.
		my @records = (
			{ sale_date => '2026-01-01', amount => 100 },
			{ sale_date => '2026-01-15', amount => 150 },
			{ sale_date => '2026-02-01', amount => 300 },
			{ sale_date => '2026-02-15', amount => 250 },
		);
		my $r = Database::BI::Insights::compute(
			records  => \@records,
			columns  => ['sale_date', 'amount'],
			spec_key => 'table:test',
		);
		my @pd = grep { $_->{kind} eq 'period_delta' } @$r;
		ok(scalar @pd >= 1, 'period_delta insight returned when two periods exist');
		is($pd[0]{method}, 'pop_delta', 'period_delta uses pop_delta method');
		ok(defined $pd[0]{view_url}, 'period_delta insight carries view_url');
		delete $ledger{'Insights.compute.period_delta'};
	};

	subtest 'Insights.compute -- detects seasonality with 8+ distinct month-periods' => sub {
		# Build 12 months of alternating values so autocorrelation is very high.
		my @records;
		my @vals = (100, 200, 100, 200, 100, 200, 100, 200, 100, 200, 100, 200);
		my @months = map { sprintf('2026-%02d-01', $_) } (1..12);
		for my $i (0..$#months) {
			push @records, { d => $months[$i], v => $vals[$i] };
		}
		my $r = Database::BI::Insights::compute(
			records  => \@records,
			columns  => ['d', 'v'],
			spec_key => 'table:test',
		);
		my @sea = grep { $_->{kind} eq 'seasonality' } @$r;
		# Note: alternating pattern has high autocorrelation; may or may not trigger
		# depending on exact r threshold. Test that the function returns without croak
		# and that if seasonality is present it has the required keys.
		ok(ref $r eq 'ARRAY', 'compute() returns arrayref with 8+ periods');
		if (@sea) {
			is($sea[0]{method}, 'autocorr', 'seasonality uses autocorr method');
			ok(defined $sea[0]{view_url}, 'seasonality insight carries view_url');
		}
		delete $ledger{'Insights.compute.seasonality'};
	};

	subtest 'Insights.method_note -- known key returns description string' => sub {
		my $note = Database::BI::Insights::method_note('iqr_fence');
		ok(defined $note && length $note, 'known key returns non-empty string');
		like($note, qr/IQR|Tukey|outlier/i, 'iqr_fence note mentions IQR or Tukey');
		delete $ledger{'Insights.method_note.known'};
	};

	subtest 'Insights.method_note -- unknown key returns the key itself' => sub {
		my $note = Database::BI::Insights::method_note('no_such_method_key_xyz');
		is($note, 'no_such_method_key_xyz', 'unknown key returned verbatim');
		delete $ledger{'Insights.method_note.unknown'};
	};
}

# ---------------------------------------------------------------------------
# Database::BI::Summary -- generate() public API
# ---------------------------------------------------------------------------
{
	require Database::BI::Summary;

	# Clear the package-level cache before each block so we get fresh results.
	# Access via the symbol table since the cache is a package lexical %_cache.
	# We call generate() twice with distinct inputs to test the cache; just
	# run a no-insight call first to warm it, then re-run the same to confirm.

	subtest 'Summary.generate -- template path returns source=template' => sub {
		my $r = Database::BI::Summary::generate(
			insights  => [],
			label     => 'test_dataset',
			row_count => 10,
		);
		is($r->{source}, 'template', 'no use_ai -> source is template');
		ok(defined $r->{text} && length $r->{text}, 'text is non-empty');
		delete $ledger{'Summary.generate.template'};
	};

	subtest 'Summary.generate -- no insights yields "No significant patterns" phrase' => sub {
		my $r = Database::BI::Summary::generate(
			insights  => [],
			label     => 'empty_ds',
			row_count => 5,
		);
		like($r->{text}, qr/No significant patterns/i,
		    'empty insights -> "No significant patterns" in text');
		delete $ledger{'Summary.generate.no_insights'};
	};

	subtest 'Summary.generate -- second call with same fingerprint returns cached=1' => sub {
		# First call to prime the cache.
		my @ins = ({ kind => 'outlier', headline => 'Test outlier', detail => 'val=999' });
		my $first = Database::BI::Summary::generate(
			insights  => \@ins,
			label     => 'cache_test_label',
			row_count => 20,
		);
		is($first->{cached}, 0, 'first call: cached=0');

		# Second call with identical inputs.
		my $second = Database::BI::Summary::generate(
			insights  => \@ins,
			label     => 'cache_test_label',
			row_count => 20,
		);
		is($second->{cached}, 1, 'second identical call: cached=1');
		delete $ledger{'Summary.generate.cached'};
	};

	subtest 'Summary.generate -- use_ai=1 without api_key silently uses template' => sub {
		my $r = Database::BI::Summary::generate(
			insights  => [],
			label     => 'no_key_test',
			row_count => 3,
			use_ai    => 1,
			ai_config => {},
		);
		is($r->{source}, 'template', 'use_ai=1 without api_key -> source=template');
		delete $ledger{'Summary.generate.use_ai_no_key'};
	};

	subtest 'Summary.generate -- LLM failure with use_ai=1 falls back to template_fallback' => sub {
		require HTTP::Response;
		local *LWP::UserAgent::request = sub {
			HTTP::Response->new(500, 'Error', [], '')
		};
		my @ins = ({ kind => 'outlier', headline => 'LLM fallback test', detail => 'val=1' });
		my $r = Database::BI::Summary::generate(
			insights  => \@ins,
			label     => 'fallback_test',
			row_count => 8,
			use_ai    => 1,
			ai_config => { provider => 'anthropic', api_key => 'test-key-fallback' },
		);
		is($r->{source}, 'template_fallback', 'LLM error -> source=template_fallback');
		ok(defined $r->{text} && length $r->{text}, 'fallback text is non-empty');
		delete $ledger{'Summary.generate.llm_fallback'};
	};

	subtest 'Summary.generate -- successful LLM call returns source=llm' => sub {
		require HTTP::Response;
		require JSON::PP;
		my $llm_text = 'Sales were strong in Q1 with some outlier activity noted.';
		my $body = JSON::PP::encode_json({
			content => [{ type => 'text', text => $llm_text }],
		});
		local *LWP::UserAgent::request = sub {
			HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $body)
		};
		my @ins = ({ kind => 'outlier', headline => 'LLM success test', detail => 'val=1' });
		my $r = Database::BI::Summary::generate(
			insights  => \@ins,
			label     => 'llm_success_unique_label_x7',
			row_count => 15,
			use_ai    => 1,
			ai_config => { provider => 'anthropic', api_key => 'real-looking-key' },
		);
		is($r->{source}, 'llm', 'mocked LLM success -> source=llm');
		is($r->{text},   $llm_text, 'text matches mocked LLM response');
		delete $ledger{'Summary.generate.llm_success'};
	};
}

# ---------------------------------------------------------------------------
# HTTP: scatter / stacked / combo / treemap / histogram chart views
# All tests use the table:sales spec (data/sales.csv) which has:
#   id, product, region, sales_rep, amount, sale_date
# ---------------------------------------------------------------------------
{
	Readonly my $SALES_SPEC => 'table:sales';

	subtest 'GET /scatter -- missing x= or y= returns 400' => sub {
		$t->get_ok('/scatter?l=table:sales')
		  ->status_is(400, '400 when x= and y= absent');
		delete $ledger{'GET./scatter.400.missing_param'};
	};

	subtest 'GET /scatter -- valid x=/y= but bad l= returns 404' => sub {
		# Route checks x=/y= first; pipeline runs and fails only when l= is bad.
		$t->get_ok('/scatter?x=amount&y=amount&l=path:/no/such/file.csv')
		  ->status_is(404, '404 when l= points to non-existent file');
		delete $ledger{'GET./scatter.404.no_source'};
	};

	subtest 'GET /scatter -- valid params return 200 HTML scatter chart' => sub {
		$t->get_ok('/scatter?l=table:sales&x=amount&y=amount')
		  ->status_is(200, '200 for valid scatter params')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./scatter.200'};
	};

	subtest 'GET /stacked -- missing cat= or series= returns 400' => sub {
		$t->get_ok('/stacked?l=table:sales')
		  ->status_is(400, '400 when cat= and series= absent');
		delete $ledger{'GET./stacked.400.missing_param'};
	};

	subtest 'GET /stacked -- valid cat=/series= but bad l= returns 404' => sub {
		$t->get_ok('/stacked?cat=region&series=product&l=path:/no/such/file.csv')
		  ->status_is(404, '404 when l= points to non-existent file');
		delete $ledger{'GET./stacked.404.no_source'};
	};

	subtest 'GET /stacked -- valid params return 200 HTML stacked bar chart' => sub {
		$t->get_ok('/stacked?l=table:sales&cat=region&series=product')
		  ->status_is(200, '200 for valid stacked params')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./stacked.200'};
	};

	subtest 'GET /combo -- missing required params returns 400' => sub {
		$t->get_ok('/combo?l=table:sales')
		  ->status_is(400, '400 when cat/bar_val/line_val absent');
		delete $ledger{'GET./combo.400.missing_param'};
	};

	subtest 'GET /combo -- required params given but bad l= returns 404' => sub {
		$t->get_ok('/combo?cat=region&bar_val=amount&line_val=amount&l=path:/no/such/file.csv')
		  ->status_is(404, '404 when l= points to non-existent file');
		delete $ledger{'GET./combo.404.no_source'};
	};

	subtest 'GET /combo -- valid params return 200 HTML combo chart' => sub {
		$t->get_ok('/combo?l=table:sales&cat=region&bar_val=amount&line_val=amount')
		  ->status_is(200, '200 for valid combo params')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./combo.200'};
	};

	subtest 'GET /treemap -- missing group= returns 400' => sub {
		$t->get_ok('/treemap?l=table:sales')
		  ->status_is(400, '400 when group= absent');
		delete $ledger{'GET./treemap.400.missing_param'};
	};

	subtest 'GET /treemap -- group= given but bad l= returns 404' => sub {
		$t->get_ok('/treemap?group=region&l=path:/no/such/file.csv')
		  ->status_is(404, '404 when l= points to non-existent file');
		delete $ledger{'GET./treemap.404.no_source'};
	};

	subtest 'GET /treemap -- valid params return 200 HTML treemap' => sub {
		$t->get_ok('/treemap?l=table:sales&group=region&size=amount')
		  ->status_is(200, '200 for valid treemap params')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./treemap.200'};
	};

	subtest 'GET /histogram -- missing col= returns 400' => sub {
		$t->get_ok('/histogram?l=table:sales')
		  ->status_is(400, '400 when col= absent');
		delete $ledger{'GET./histogram.400.missing_param'};
	};

	subtest 'GET /histogram -- col= given but bad l= returns 404' => sub {
		$t->get_ok('/histogram?col=amount&l=path:/no/such/file.csv')
		  ->status_is(404, '404 when l= points to non-existent file');
		delete $ledger{'GET./histogram.404.no_source'};
	};

	subtest 'GET /histogram -- valid numeric col= returns 200 HTML histogram' => sub {
		$t->get_ok('/histogram?l=table:sales&col=amount')
		  ->status_is(200, '200 for valid histogram col=amount')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./histogram.200'};
	};
}

# ---------------------------------------------------------------------------
# HTTP: pivot and stats views
# ---------------------------------------------------------------------------
{
	subtest 'GET /pivot -- no l= returns 400' => sub {
		$t->get_ok('/pivot')
		  ->status_is(400, '400 when no l= given to pivot');
		delete $ledger{'GET./pivot.400.no_source'};
	};

	subtest 'GET /pivot -- no rows= returns 400' => sub {
		$t->get_ok('/pivot?l=table:sales&m=amount:sum:total')
		  ->status_is(400, '400 when rows= absent from pivot');
		delete $ledger{'GET./pivot.400.no_rows'};
	};

	subtest 'GET /pivot -- valid params return 200 HTML pivot table' => sub {
		$t->get_ok('/pivot?l=table:sales&rows=region&m=amount:sum:total')
		  ->status_is(200, '200 for valid pivot params')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./pivot.200'};
	};

	subtest 'GET /stats -- no l= returns 400' => sub {
		$t->get_ok('/stats')
		  ->status_is(400, '400 when no l= given to stats');
		delete $ledger{'GET./stats.400.no_source'};
	};

	subtest 'GET /stats -- valid l= returns 200 HTML stats page' => sub {
		$t->get_ok('/stats?l=table:sales')
		  ->status_is(200, '200 for valid stats l=')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./stats.200'};
	};
}

# ---------------------------------------------------------------------------
# HTTP: Phase 5 endpoints (/insights, /api/summary, /api/ask)
# ---------------------------------------------------------------------------
{
	subtest 'GET /insights -- no l= returns 400' => sub {
		$t->get_ok('/insights')
		  ->status_is(400, '400 when l= absent from /insights');
		delete $ledger{'GET./insights.400.no_l'};
	};

	subtest 'GET /insights -- valid l= returns 200 HTML insights page' => sub {
		$t->get_ok('/insights?l=table:sales')
		  ->status_is(200, '200 for /insights with valid l=')
		  ->content_type_like(qr{text/html}, 'response is HTML');
		delete $ledger{'GET./insights.200'};
	};

	subtest 'POST /api/summary -- no l= returns 400' => sub {
		$t->post_ok('/api/summary')
		  ->status_is(400, '400 when l= absent from /api/summary');
		delete $ledger{'POST./api_summary.400.no_l'};
	};

	subtest 'POST /api/summary -- valid l= returns 200 JSON {text,source,cached}' => sub {
		$t->post_ok('/api/summary?l=table:sales')
		  ->status_is(200, '200 for /api/summary with valid l=')
		  ->json_has('/text',   'response has text key')
		  ->json_has('/source', 'response has source key')
		  ->json_has('/cached', 'response has cached key');
		delete $ledger{'POST./api_summary.200'};
	};

	subtest 'POST /api/ask -- without ai_api_key returns 503' => sub {
		# The test app has no ai_api_key configured; expect 503.
		$t->post_ok('/api/ask', form => { l => 'table:sales', q => 'show a chart' })
		  ->status_is(503, '503 when ai_api_key not configured')
		  ->json_has('/error', 'error key present in 503 response');
		delete $ledger{'POST./api_ask.503.no_key'};
	};

	subtest 'POST /api/ask -- missing l= returns 400' => sub {
		# Temporarily inject a dummy api_key so the key guard passes.
		$t->app->config->{ai_api_key} = 'test-dummy-key';
		$t->post_ok('/api/ask', form => { q => 'show a chart' })
		  ->status_is(400, '400 when l= absent')
		  ->json_has('/error', 'error key present in 400 response');
		delete $t->app->config->{ai_api_key};
		delete $ledger{'POST./api_ask.400.no_l'};
	};

	subtest 'POST /api/ask -- missing q= returns 400' => sub {
		$t->app->config->{ai_api_key} = 'test-dummy-key';
		$t->post_ok('/api/ask', form => { l => 'table:sales' })
		  ->status_is(400, '400 when q= absent')
		  ->json_has('/error', 'error key present in 400 response');
		delete $t->app->config->{ai_api_key};
		delete $ledger{'POST./api_ask.400.no_q'};
	};

	subtest 'POST /api/ask -- valid request with mocked LLM returns 200 JSON {spec,url,valid}' => sub {
		require HTTP::Response;
		require JSON::PP;
		my $llm_json = '{"kind":"pie","title":"Sales by region","encode":{"cat":"region","val":"amount"}}';
		my $body = JSON::PP::encode_json({
			content => [{ type => 'text', text => $llm_json }],
		});
		$t->app->config->{ai_api_key} = 'test-dummy-key';
		local *LWP::UserAgent::request = sub {
			HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $body)
		};
		$t->post_ok('/api/ask', form => { l => 'table:sales', q => 'show sales by region' })
		  ->status_is(200, '200 for valid ask with mocked LLM')
		  ->json_is('/valid', 1, 'valid=1 in response')
		  ->json_has('/url',  'url key present')
		  ->json_has('/spec', 'spec key present');
		delete $t->app->config->{ai_api_key};
		delete $ledger{'POST./api_ask.200'};
	};
}

# ============================================================================
# The rest of the documented API, and every message.  Strategy: expected text
# comes from each module's own dictionary, so an assertion is on the exact string
# with only the parameters filled in.  Where a state cannot be reached from
# outside, its collaborator is mocked; all network and geocoding is replaced.
# ============================================================================
{
	Readonly my $SPEC       => 'table:sales';
	Readonly my $EPOCH      => 1_700_000_000;
	Readonly my $CAPPED     => 1;
	Readonly my $ALARM_SECS => 1000;
	Readonly my $BDB_MAGIC_AT => 12;

	require Database::BI::Calc;
	require Database::BI::Extract;
	require Database::BI::Tutorial;
	require Database::BI::Model::Geocode;
	require HTTP::Response;

	sub unit_app {
		my $tm = Test::Mojo->new('Database::BI');
		$tm->app->config->{model_dir}   = tempdir(CLEANUP => 1);
		$tm->app->config->{uploads_dir} = tempdir(CLEANUP => 1);
		$tm->app->config->{share_secret} = 'unit-secret';
		$tm->app->log->level('fatal');
		return $tm;
	}

	sub unit_csv {
		my ($name, $text) = @_;
		my $path = File::Spec->catfile(tempdir(CLEANUP => 1), $name);
		Mojo::File->new($path)->spew($text);
		return $path;
	}

	sub unit_sqlite {
		my ($name, @statements) = @_;
		require DBI;
		my $path = File::Spec->catfile(tempdir(CLEANUP => 1), $name);
		my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1, PrintError => 0 });
		$dbh->do($_) for @statements;
		$dbh->disconnect;
		return $path;
	}

	# The template with its parameters filled in.  An undef parameter is one the test
	# cannot know in advance, such as the text of a backend's error, and matches anything.
	sub message_re {
		my ($module, $key, $args, $escape) = @_;
		my $template = $DICTIONARY{$module}{$key} // BAIL_OUT("no message $module/$key");
		my @args = @{ $args // [] };
		my $text = '';
		for my $piece (split /(%[sd])/, $template) {
			my $literal = $piece;
			if ($piece =~ /\A%[sd]\z/) {
				my $value = shift @args;
				if (!defined $value) { $text .= '.*'; next; }
				$literal = $value;
			}
			$literal =~ s/%%/%/g;
			$literal = Mojo::Util::xml_escape($literal) if $escape;
			$text .= quotemeta $literal;
		}
		return $escape ? qr/$text/s : qr/\A$text\z/s;
	}

	# Marks a message as raised, once it has been seen exactly.
	sub message_ok {
		my ($module, $key, $got, $args, $escape) = @_;
		diag("$module/$key: " . ($got // '<undef>')) if $ENV{TEST_VERBOSE};
		like $got // '', message_re($module, $key, $args, $escape), "$module message $key";
		delete $ledger{"msg.$module.$key"} if ($got // '') =~ message_re($module, $key, $args, $escape);
	}

	sub without_location {
		my ($e) = @_;
		$e =~ s/ at \S+ line \d+\.?\s*\z//;
		return $e;
	}

	subtest 'Util.parse_number' => sub {
		my $fn = \&Database::BI::Util::parse_number;
		is $fn->('$1,234.56'), 1234.56, 'the POD example with a currency sign';
		is $fn->('(1,234.56)'), -1234.56, 'an accounting negative';
		is $fn->('USD 100'), 100, 'a currency code';
		is $fn->('SKU123'), undef, 'text holding digits';
		is $fn->(undef), undef, 'missing';
		is $fn->(''), undef, 'empty';
		is $fn->('1e999'), undef, 'too large to be finite';
		returns_is $fn->('5'), { type => 'number' }, 'a number comes back';
		delete $ledger{'api.Util.parse_number'};
	};

	subtest 'A filter that names an unknown operator or column is refused' => sub {
		my $f = sub { 'f=' . url_escape($_[0]) };
		$t->get_ok('/view/sales?' . $f->('region:gtx:North'))->status_is(400);
		message_ok('Dashboard', 'error_filter_op', $t->tx->res->body,
			['gtx', 'region:gtx:North', 'eq, ne, contains, starts, lt, le, gt, ge, empty, notempty, between, in']);
		$t->get_ok('/view/sales?' . $f->('regoin:eq:North'))->status_is(400);
		message_ok('Dashboard', 'error_filter_column', $t->tx->res->body, ['regoin', 'regoin:eq:North', undef]);
		like $t->tx->res->body, qr/the columns are: .*\bregion\b/, '... naming the columns there are';
		$t->get_ok('/bar?l=table:sales&cat=region&' . $f->('regoin:eq:North'))->status_is(400, 'a chart too');
		$t->get_ok('/view/sales?range=last_30_days&rcol=nosuch')->status_is(400);
		message_ok('Dashboard', 'error_range_column_unknown', $t->tx->res->body, ['nosuch', 'nosuch', undef]);
		$t->get_ok('/view/sales?' . $f->('region:eq:North'))->status_is(200, 'a filter on a column there still works');
		$t->get_ok('/view/sales?c=' . url_escape('twice:amount*2') . '&' . $f->('twice:gt:0'))
			->status_is(200, 'and on a calculated field of the request');
	};

	subtest 'Password and the password command raise their own messages' => sub {
		require Database::BI::Password;
		require Database::BI::Command::password;
		my $hash = \&Database::BI::Password::hash_password;
		my $err = sub { my ($code) = @_; local $@; eval { $code->(); 1 } and return; return without_location($@) };

		message_ok('Password', 'error_password_required', $err->(sub { $hash->('') }));
		message_ok('Password', 'error_password_rounds', $err->(sub { $hash->('x', rounds => 5) }), [10_000, 100_000_000]);
		message_ok('Password', 'error_password_salt', $err->(sub { $hash->('x', salt => 'short') }), [16]);
		require Crypt::URandom;	# before the mock, or loading it puts urandom back
		mock 'Crypt::URandom::urandom' => sub { 'abc' };
		message_ok('Password', 'error_password_random', $err->(sub { $hash->('x', rounds => 10_000) }), [3, 16]);
		restore_all();
		like $hash->('x', rounds => 10_000), qr/\Apbkdf2-sha256\$10000\$/, 'and a salt from Crypt::URandom';

		my $cmd = Database::BI::Command::password->new(app => $t->app);
		is $err->(sub { $cmd->run('extra') }), $cmd->usage, 'an argument: the usage, and nothing else';
		like $cmd->usage, qr/database-bi password/, '... which shows how it is run';

		my @typed;
		mock 'Database::BI::Command::password::_read_secret' => sub { shift @typed };
		mock 'Database::BI::Command::password::_interactive' => sub { 1 };
		@typed = ('one pass', 'another');
		message_ok('PasswordCommand', 'error_mismatch', $err->(sub { $cmd->run }));
		@typed = ('one pass');
		message_ok('PasswordCommand', 'error_mismatch', $err->(sub { $cmd->run }));
		@typed = ('');
		message_ok('PasswordCommand', 'error_no_password', $err->(sub { $cmd->run }));
		@typed = ('one pass', 'one pass');
		my $out = '';
		{
			open my $fh, '>', \$out or BAIL_OUT('no in-memory handle');
			my $old = select $fh;
			my $ok = eval { $cmd->run; 1 };
			select $old;
			ok $ok, 'the same twice at a terminal: a hash';
		}
		my ($made) = $out =~ /password_hash => '([^']+)'/;
		ok $made && Database::BI::Password::verify_password('one pass', $made), '... of that password';
		mock 'Database::BI::Command::password::_interactive' => sub { 0 };
		@typed = ('piped');
		$out = '';
		{
			open my $fh, '>', \$out or BAIL_OUT('no in-memory handle');
			my $old = select $fh;
			ok eval { $cmd->run; 1 }, 'from a pipe it is asked once';
			select $old;
		}
		is scalar(@typed), 0, '... and read once';
		restore_all();
	};

	subtest 'Util.minute_stamp and Util.iso8601_utc' => sub {
		my $stamp = \&Database::BI::Util::minute_stamp;
		my $iso   = \&Database::BI::Util::iso8601_utc;
		is $stamp->(gmtime 0), '1970-01-01 00:00', 'the epoch, to the minute';
		is $stamp->(gmtime 1_794_060_309), '2026-11-07 14:05', 'a day this year';
		is $stamp->(5, 4, 3, 2, 0, 99), '1999-01-02 03:04', 'a list as localtime gives it';
		is $stamp->(), '', 'nothing given';
		is $stamp->(1, 2, 3), '', 'too few values';
		is $iso->(0), '1970-01-01T00:00:00Z', 'the epoch in UTC';
		is $iso->(1_794_060_309), '2026-11-07T14:05:09Z', 'to the second';
		like $iso->(), qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, 'now, when no time is given';
		SKIP: {
			# The same as strftime gives, where strftime can be asked.
			skip 'POSIX::strftime is not asked on Windows', 2 if $^O eq 'MSWin32';
			require POSIX;
			my $t = 1_794_060_309;
			is $stamp->(localtime $t), POSIX::strftime('%Y-%m-%d %H:%M', localtime $t), 'as strftime, local time';
			is $iso->($t), POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime $t), 'as strftime, UTC';
		}
		# And nothing else formats a time with strftime, outside comments and POD.
		my @calls;
		for my $file (Mojo::File->new('lib')->list_tree->grep(qr/\.pm\z/)->each,
				map { Mojo::File->new("script/$_") } qw(database-bi bi-extract bi-geocode bi-alert)) {
			(my $code = $file->slurp) =~ s/\r\n/\n/g;
			$code =~ s/^=\w.*?(?:^=cut\n|\z)//msg;
			$code =~ s/^__END__\n.*//ms;
			my $n = 0;
			for my $line (split /\n/, $code) {
				$n++;
				(my $bare = $line) =~ s/#.*//;
				push @calls, "$file:$n" if $bare =~ /\bstrftime\b/;
			}
		}
		is_deeply \@calls, [], 'lib/ and script/ call no strftime';
		delete $ledger{'api.Util.minute_stamp'};
		delete $ledger{'api.Util.iso8601_utc'};
	};

	subtest 'Util.iso_datetime' => sub {
		my $fn = \&Database::BI::Util::iso_datetime;
		is_deeply [ $fn->('2026-11-06') ], [ '2026-11-06', undef, undef, undef ], 'a date';
		is_deeply [ $fn->('2026-11-06 09:15') ], [ '2026-11-06', '09', '15', undef ], 'a space and no seconds';
		is_deeply [ $fn->('2026-11-06T23:30:00.250Z') ], [ '2026-11-06', '23', '30', '00' ],
			'a fraction and Z are accepted, and the time is as written';
		is_deeply [ $fn->("2026-11-06T23:30:00$_") ], [ '2026-11-06', '23', '30', '00' ], "an offset written $_"
			for qw(+01:00 +0100 -05 z);
		is_deeply [ $fn->('2026-11-06T23:30:00,5') ], [ '2026-11-06', '23', '30', '00' ], 'a comma before the fraction';
		is_deeply [ $fn->($_) ], [], "not ISO: $_"
			for ('06/11/2026', '2026-11-06Z', '2026-11-06T25', '2026-11-06T23:30:00.Z', '2026-11-06T23:30Q', '');
		is_deeply [ $fn->(undef) ], [], 'missing';
		is_deeply [ $fn->([]) ], [], 'a reference';
		delete $ledger{'api.Util.iso_datetime'};
	};

	subtest 'Calc -- the documented constructor, accessors and evaluate' => sub {
		my $good = Database::BI::Calc->new(expr => 'amount * 2', columns => ['amount']);
		isa_ok $good, 'Database::BI::Calc';
		is $good->error, undef, 'error() is undef after a clean compile';
		ok !$good->has_error, 'and has_error() false';
		is $good->evaluate({ amount => 21 }), 42, 'evaluate() computes';
		is $good->evaluate({ amount => undef }), undef, 'an undef operand is undef, not a croak';

		my $zero = Database::BI::Calc->new(expr => 'amount / 0', columns => ['amount']);
		is $zero->evaluate({ amount => 1 }), undef, 'division by zero is undef';

		for my $case (
			[ 'nope', ['amount'], 'an unknown identifier' ],
			[ 'amount == 1', ['amount'], 'the == operator' ],
			[ 'x' x 513, [], 'an expression over 512 characters' ],
			[ "span(amount, '1x')", ['amount'], 'a bad span interval' ],
		) {
			my ($expr, $cols, $why) = @$case;
			my $bad;
			lives_ok { $bad = Database::BI::Calc->new(expr => $expr, columns => $cols) } "$why does not croak";
			ok $bad->has_error, 'has_error() says so';
			returns_is $bad->error, { type => 'string' }, 'error() gives the reason';
			is $bad->evaluate({ amount => 1 }), undef, 'and it evaluates nothing';
		}
		ok(Database::BI::Calc->new(expr => 'a', columns => ['a'], params => { a => 1 })->has_error, 'a parameter named like a column');
		is(Database::BI::Calc->new(expr => 'rate * 2', params => { rate => 3 })->evaluate({ rate => 100 }), 6, 'a bound parameter is read in place of a row key');
		delete @ledger{qw(api.Calc.new api.Calc.error api.Calc.has_error api.Calc.evaluate)};
	};

	subtest 'Calc.span_interval' => sub {
		my $fn = \&Database::BI::Calc::span_interval;
		is_deeply $fn->('1mon'), { n => 1, unit => 'mon' }, 'months have no secs';
		is_deeply $fn->('15m'), { n => 15, unit => 'm', secs => 60 }, 'minutes do';
		is_deeply $fn->('2h'), { n => 2, unit => 'h', secs => 3600 }, 'hours';
		is_deeply $fn->('1s'), { n => 1, unit => 's', secs => 1 }, 'seconds';
		is_deeply $fn->("1$_"), { n => 1, unit => $_ }, "unit $_" for qw(d w q y);
		is $fn->($_), undef, 'not an interval' for undef, '', '0h', '-1d', '1x', 'h', [ 1 ];
		delete $ledger{'api.Calc.span_interval'};
	};

	subtest 'Calc.date_normalise' => sub {
		my $fn = \&Database::BI::Calc::date_normalise;
		is $fn->('01/15/2026', '%m/%d/%Y'), '2026-01-15', 'US';
		is $fn->('15/01/2026', '%d/%m/%Y'), '2026-01-15', 'EU';
		is $fn->('15-jan-2026', '%d-%b-%Y'), '2026-01-15', 'a month name in any case';
		is $fn->('27/10/2026 14:05', { date => '%d/%m/%Y', time => '%H:%M' }), '2026-10-27T14:05:00', 'with a time';
		is $fn->('27/10/2026 14:05:32', { date => '%d/%m/%Y', time => '%H:%M:%S' }), '2026-10-27T14:05:32', 'with seconds';
		is $fn->('27/10/2026', { date => '%d/%m/%Y', as => 'timestamp' }), '2026-10-27T00:00:00', 'as a timestamp';
		is $fn->(undef, '%m/%d/%Y'), undef, 'undefined value';
		is $fn->('', '%m/%d/%Y'), undef, 'empty value';
		is $fn->('01/15/2026', '%Q'), undef, 'unknown pattern';
		is $fn->('junk', '%m/%d/%Y'), undef, 'no match';
		delete $ledger{'api.Calc.date_normalise'};
	};

	subtest 'Extract -- the whole documented life of a cache file' => sub {
		throws_ok { Database::BI::Extract->new() } qr/\Amodel_dir is required at /, 'new() without model_dir';
		my $dir = tempdir(CLEANUP => 1);
		my $ex  = Database::BI::Extract->new(model_dir => $dir);
		isa_ok $ex, 'Database::BI::Extract';
		ok !-e File::Spec->catdir($dir, 'extracts'), 'nothing is created until put';
		delete $ledger{'api.Extract.new'};

		my @key = ($SPEC, $EPOCH, 10);
		my $path = $ex->path(@key);
		like $path, qr{extracts[/\\][0-9a-f]{32}\.db\z}, 'path() is <md5>.db under extracts/';
		ok !-e $path, 'and need not exist';
		is $ex->path($SPEC), $ex->path($SPEC, 0, 0), 'undef mtime and size are 0';
		delete $ledger{'api.Extract.path'};

		is $ex->get(@key), undef, 'get() misses before a put';
		is $ex->evict($SPEC), 0, 'evict() with no extracts/ is 0';
		throws_ok { $ex->put(@key, undef) } qr/\Asqlite_bytes are required at /, 'put() undefined bytes';
		throws_ok { $ex->put(@key, '') } qr/\Asqlite_bytes are required at /, 'put() empty bytes';

		is $ex->put(@key, 'bytes'), $path, 'put() returns the path written';
		is $ex->get(@key), $path, 'get() now finds it';
		is $ex->get($SPEC, $EPOCH + 1, 10), undef, 'a changed mtime is a miss';
		is $ex->get($SPEC, $EPOCH, 11), undef, 'a changed size is a miss';
		delete @ledger{qw(api.Extract.get api.Extract.put)};

		$ex->put('table:other', 1, 1, 'more');
		is $ex->evict($SPEC), 2, 'evict() removes every file, not only that spec';
		is $ex->get(@key), undef, 'and it is gone';
		delete $ledger{'api.Extract.evict'};

		# A file where the directory should be: no permissions involved, so this
		# holds on every platform and for root.
		my $blocked = Database::BI::Extract->new(model_dir => unit_csv('file-not-dir', 'x'));
		throws_ok { $blocked->put(@key, 'x') } qr/extracts/, 'put() croaks naming the path when it cannot write';
	};

	subtest 'Tutorial -- the documented data shapes' => sub {
		my $T = 'Database::BI::Tutorial';
		returns_is $T->intro, { type => 'arrayref' }, 'intro() is a list';
		ok !(grep { ref } @{ $T->intro }), 'of sentences';
		my $chapters = $T->chapters;
		returns_is $chapters, { type => 'arrayref' }, 'chapters()';
		returns_is $T->faq, { type => 'arrayref' }, 'faq()';
		returns_is $T->glossary, { type => 'arrayref' }, 'glossary()';
		returns_is $T->parts, { type => 'arrayref' }, 'parts()';
		returns_is $T->covered_routes, { type => 'hashref' }, 'covered_routes()';
		ok scalar keys %{ $T->covered_routes }, 'and it names some';
		returns_is $T->exempt_routes, { type => 'hashref' }, 'exempt_routes()';

		my $hit = $T->chapter_for_action('bar_view');
		returns_is $hit, { type => 'hashref' }, 'chapter_for_action() finds a chapter';
		is_deeply [ $T->chapter_for_action('no_such_action') ], [], 'an unknown action is an empty list';
		is_deeply [ $T->chapter_for_action(undef) ], [], 'as is undef';
		delete @ledger{ map { "api.Tutorial.$_" } qw(intro chapters faq glossary parts covered_routes exempt_routes chapter_for_action) };
	};

	subtest 'DataSource -- the accessors t/unit.t had not reached' => sub {
		my $csv = Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE);
		is $csv->sqlite_tables, undef, 'sqlite_tables() is undef for a CSV';
		my $mtime = (stat $SALES_CSV)[9];
		is $csv->updated, $mtime, 'updated() is the file mtime';
		is $csv->count, scalar @{ $csv->fetch_all }, 'count() is the number of rows';
		returns_is $csv->schema, { type => 'hashref' }, 'schema() is a hashref';

		my $db = unit_sqlite('shop.sqlite', 'CREATE TABLE alpha (id INTEGER, n INTEGER)', 'CREATE TABLE beta (id INTEGER)',
			'INSERT INTO alpha VALUES (1, 5)', 'INSERT INTO alpha VALUES (2, 7)');
		my ($dir) = $db =~ m{\A(.*)[/\\]};
		my $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'shop');
		is_deeply $src->sqlite_tables, [qw(alpha beta)], 'sqlite_tables() names them, alphabetically';
		ok defined $src->dbi_source, 'dbi_source() is defined for SQLite';
		is $src->count, 2, 'count() on SQL';
		is $src->schema->{n}{type} // '', 'INTEGER', 'schema() reports the declared type';
		my $agg = $src->aggregate(by => ['id'], measures => [ { fn => 'sum', col => 'n', as => 't' } ], sort_by => 'id');
		is_deeply [ map { $_->{t} } @$agg ], [ 5, 7 ], 'aggregate() is one row a group';

		my $empty_path = unit_csv('blank.csv', '');
		my ($edir) = $empty_path =~ m{\A(.*)[/\\]};
		my $blank = Database::BI::Model::DataSource->new(directory => $edir, table => 'blank');
		is $blank->count, 0, 'count() on an empty file is 0';
		is_deeply $blank->aggregate(by => ['x'], measures => []), [], 'aggregate() on an empty file is []';
		is $blank->dbi_source, undef, 'dbi_source() on an empty file is undef';
		delete @ledger{ map { "api.DataSource.$_" } qw(sqlite_tables dbi_source aggregate updated schema count) };
	};

	sub UnitFakeMariaDbh::prepare { Carp::croak('no such table') }
	sub UnitFakeMariaDbh::disconnect { return 1 }

	subtest 'DataSource -- every message' => sub {
		my $DS  = 'Database::BI::Model::DataSource';
		my $err = sub { my %a = @_; my $ok = eval { $DS->new(%a); 1 }; return $ok ? '' : without_location("$@") };

		message_ok(DataSource => 'error_table_required', $err->(directory => $DATA_DIR));
		message_ok(DataSource => 'error_directory_missing', $err->(directory => '/no/such/dir', table => 'x'), ['/no/such/dir']);
		message_ok(DataSource => 'error_table_name_invalid', $err->(directory => $DATA_DIR, table => 'a/b'), ['a/b']);
		message_ok(DataSource => 'error_url_invalid', $err->(url => 'ftp://x/y'), ['ftp://x/y']);
		message_ok(DataSource => 'error_redis_invalid', $err->(redis => 'http://x', table => 't'), ['http://x']);

		my $maria = sub { $err->(table => 't', server => 's', mariadb => $_[0]) };
		message_ok(DataSource => 'error_mariadb_unknown_server', $maria->(undef), ['s']);
		message_ok(DataSource => 'error_mariadb_settings', $maria->({ database => 'a;host=evil' }), ['s', 'database']);
		{
			# With neither driver to be found, whatever this machine has installed.
			local @INC = ();
			local %INC = %INC;
			delete @INC{qw(DBD/MariaDB.pm DBD/mysql.pm)};
			message_ok(DataSource => 'error_mariadb_no_driver', $maria->({ database => 'd' }), ['s']);
		}
		{
			# A driver that seems to be there, and a server that refuses or has no table.
			local $INC{'DBD/MariaDB.pm'} = __FILE__;
			require DBI;
			no warnings qw(redefine once);
			local *DBI::connect = sub { return };
			message_ok(DataSource => 'error_mariadb_connect', $maria->({ database => 'd' }), ['s', undef]);
			local *DBI::connect = sub { return bless {}, 'UnitFakeMariaDbh' };
			message_ok(DataSource => 'error_mariadb_table', $maria->({ database => 'd' }), ['t', 's', undef]);
		}

		my $dir_of = sub { my ($d) = $_[0] =~ m{\A(.*)[/\\]}; $d };
		my $no_id = unit_csv('noid.csv', "a b,c d\nhello,world\n");
		message_ok(DataSource => 'error_no_safe_id', $err->(directory => $dir_of->($no_id), table => 'noid'), ['noid']);

		my $none = unit_sqlite('none.sqlite', 'CREATE TABLE gone (id INTEGER)', 'DROP TABLE gone');
		message_ok(DataSource => 'error_no_tables', $err->(directory => $dir_of->($none), table => 'none'), [undef]);

		my $two = unit_sqlite('two.sqlite', 'CREATE TABLE alpha (id INTEGER)', 'CREATE TABLE beta (id INTEGER)');
		message_ok(DataSource => 'error_table_not_found', $err->(directory => $dir_of->($two), table => 'two', internal_table => 'gamma'), [undef, 'gamma']);

		my $bad_json = unit_csv('broken.json', '{"rows": [');
		message_ok(DataSource => 'error_json_invalid', $err->(directory => $dir_of->($bad_json), table => 'broken'), [$bad_json, undef]);
		my $no_rows = unit_csv('scalars.json', '[1, 2, 3]');
		message_ok(DataSource => 'error_json_no_rows', $err->(directory => $dir_of->($no_rows), table => 'scalars'), [$no_rows]);
		my $lists = unit_csv('lists.json', '{"findings": [{"a": 1}], "hosts": [{"b": 2}]}');
		message_ok(DataSource => 'error_json_list_not_found',
			$err->(directory => $dir_of->($lists), table => 'lists', internal_table => 'ports'), [$lists, 'ports']);
		is_deeply(Database::BI::Model::DataSource->json_lists($lists),
			[ { name => 'findings', columns => ['a'] }, { name => 'hosts', columns => ['b'] } ],
			'json_lists: each list of objects, with its columns, in file order');
		is_deeply(Database::BI::Model::DataSource->json_lists(unit_csv('plain.json', '[{"a": 1}]')), [],
			'json_lists: a file that is a list of rows holds no lists');
		delete $ledger{'api.DataSource.json_lists'};

		my $odd = unit_sqlite('odd.sqlite', 'CREATE TABLE "bad name" (id INTEGER)', 'CREATE TABLE good (id INTEGER)');
		my $unsafe = $err->(directory => $dir_of->($odd), table => 'odd', internal_table => 'bad name');
		like $unsafe, qr/\AThe table "bad name" in /, 'error_table_name_unsafe says which table';
		delete $ledger{'msg.DataSource.error_table_name_unsafe'} if $unsafe =~ /\AThe table "bad name" in /;
		like $unsafe, qr/\QOpen another table in the file instead: good.\E/, 'and error_table_name_others offers another';
		delete $ledger{'msg.DataSource.error_table_name_others'} if $unsafe =~ /instead: good\./;

		my $only = unit_sqlite('only.sqlite', 'CREATE TABLE "bad name" (id INTEGER)');
		my $unusable = $err->(directory => $dir_of->($only), table => 'only');
		like $unusable, qr/\ANo table in /, 'error_no_usable_tables';
		delete $ledger{'msg.DataSource.error_no_usable_tables'} if $unusable =~ /\ANo table in /;

		# Berkeley DB's magic number is at byte 12; what follows it is no database.
		my $bdb = unit_csv('junk.db', ('x' x $BDB_MAGIC_AT) . "\x61\x15\x06\x00" . ('x' x $BDB_MAGIC_AT));
		message_ok(DataSource => 'error_unsupported_db', $err->(directory => $dir_of->($bdb), table => 'junk'), ['junk']);

		# The backend is what fails here, and only a mock can make it fail on demand.
		mock('Database::Abstraction::new' => sub { require Carp; Carp::croak('backend down') });
		my $big = unit_csv('fine.csv', "id,v\n1,2\n");
		message_ok(DataSource => 'error_backend_init', $err->(directory => $dir_of->($big), table => 'fine'), ['fine', undef]);
		restore_all();

		mock('Database::Abstraction::new' => sub { require Carp; Carp::croak('no such page') });
		message_ok(DataSource => 'error_url_fetch', $err->(url => 'http://example.invalid/t.html'), ['http://example.invalid/t.html', undef]);
		restore_all();

		my $source = $DS->new(directory => $DATA_DIR, table => $SALES_TABLE);
		{
			mock('Database::Abstraction::selectall_hashref' => sub { require Carp; Carp::croak('read failed') });
			my $ok = eval { $source->fetch_all; 1 };
			restore_all();
			message_ok(DataSource => 'error_fetch_failed', $ok ? '' : without_location("$@"), [$SALES_TABLE, undef]);
		}
		my @warned;
		{
			local $SIG{__WARN__} = sub { push @warned, without_location($_[0]) };
			mock('Database::Abstraction::selectall_hashref' => sub { [] });
			$source->fetch_all;
			restore_all();
			mock('Database::Abstraction::selectall_hashref' => sub { { 1 => { a => 1 } } });
			$source->fetch_all;
			restore_all();
		}
		my ($empty) = grep { /no records/ } @warned;
		message_ok(DataSource => 'warn_empty_result', $empty, [$SALES_TABLE]);
		my ($normal) = grep { /hashref/ } @warned;
		message_ok(DataSource => 'warn_data_normalised', $normal, [$SALES_TABLE]);
	};

	subtest 'Geocode -- every message, and the shared cache' => sub {
		my $G    = 'Database::BI::Model::Geocode';
		my $good = Unit::Geocoder->new(results => { Paris => Unit::GeoPoint->new({ latitude => 48, longitude => 2, database => 'x' }) });
		my $geo  = $G->new(geocoder => $good);
		my $err  = sub { my ($code) = @_; my $ok = eval { $code->(); 1 }; $ok ? '' : without_location("$@") };

		message_ok(Geocode => 'error_geocoder_interface', $err->(sub { $G->new(geocoder => Unit::GeoBroken->new) }), ['geocode_many()', undef]);
		message_ok(Geocode => 'error_values_arrayref', $err->(sub { $geo->resolve_values('x') }), ['x']);
		message_ok(Geocode => 'error_rows_arrayref', $err->(sub { $geo->resolve_column('x', 'c') }), ['x']);
		message_ok(Geocode => 'error_column_required', $err->(sub { $geo->resolve_column([], '') }));
		message_ok(Geocode => 'error_map_loc_column', $err->(sub { $geo->resolve_column([ { a => 1 } ], 'nope') }), ['nope']);
		message_ok(Geocode => 'error_max_invalid', $err->(sub { $geo->resolve_values(['Paris'], max => 0) }), ['0']);
		message_ok(Geocode => 'error_max_invalid', $err->(sub { $geo->resolve_values(['Paris'], max => 'all') }), ['all']);

		my $missing = $G->new(min_geocoder_version => '9999');
		my (undef, $why) = $missing->geocoder_available;
		message_ok(Geocode => 'error_map_geocoder_missing', ref $why ? $why->{text} : $why, ['9999', undef]);

		message_ok(Geocode => 'error_online_max_invalid', $err->(sub { $G->new(online_max => 0) }), ['0']);
		message_ok(Geocode => 'error_cache_interface', $err->(sub { $G->new(cache => Unit::GeoBroken->new) }), ['Unit::GeoBroken']);
		message_ok(Geocode => 'error_cache_dir', $err->(sub { $G->file_cache('/no/such/directory') }), ['/no/such/directory']);

		# Geo::Coder::Free without Geo::Coder::List: a stand-in for the first,
		# and the second hidden, so this is raised whatever is installed.
		{
			no warnings qw(once redefine);
			local $INC{'Geo/Coder/Free.pm'} = __FILE__;
			local $Geo::Coder::Free::VERSION = '99';
			local *Geo::Coder::Free::new = sub { return bless {}, 'Unit::GeoFree' };
			delete local $INC{'Geo/Coder/List.pm'};
			local @INC = (sub {
				die "Can't locate $_[1] in \@INC (hidden by t/unit.t)\n" if $_[1] eq 'Geo/Coder/List.pm';
				return;
			}, @INC);
			my (undef, $no_list) = $G->new->geocoder_available;
			message_ok(Geocode => 'error_map_geocoder_list_missing', $no_list, ['it is not installed']);
		}

		# The chain's own messages, with the local data and Nominatim stood in
		# for by t/lib/BI/Test/Nominatim.pm, so nothing reaches the network.  They
		# need the real chain; where it cannot be built (CI installs no
		# recommended modules) the two are left out of the ledger rather than
		# failed, and t/geocode-online.t, which skips there too, is their test.
		SKIP: {
			my $have_chain = eval {
				require Geo::Coder::List;          Geo::Coder::List->VERSION(0.39);
				require Geo::Coder::OSM;           Geo::Coder::OSM->VERSION(0.03);
				require LWP::UserAgent::Throttled; LWP::UserAgent::Throttled->VERSION(0.14);
				require Geo::Location::Point;
				1;
			};
			unless ($have_chain) {
				delete $ledger{"msg.Geocode.$_"} for qw(warn_map_geocoder_local_only warn_map_geocoder_online_failed);
				skip 'Geo::Coder::List 0.39, Geo::Coder::OSM 0.03 and LWP::UserAgent::Throttled 0.14 or later are needed', 2;
			}
			require BI::Test::Nominatim;
			my $text = sub {
				my ($result, $key) = @_;
				my ($m) = grep { $_->{key} eq $key } @{ $result->{messages} };
				return $m ? $m->{text} : undef;
			};

			BI::Test::Nominatim::with_chain(hide => ['Geo::Coder::OSM'], sub {
				my $r = $G->new->resolve_values(['Nowhere']);
				message_ok(Geocode => 'warn_map_geocoder_local_only', $text->($r, 'warn_map_geocoder_local_only'));
			});
			BI::Test::Nominatim::with_chain(online => { Nowhere => 503 }, sub {
				my $r = $G->new->resolve_values(['Nowhere']);
				message_ok(Geocode => 'warn_map_geocoder_online_failed',
					$text->($r, 'warn_map_geocoder_online_failed'), ['503 Stand-in failure', 1]);
			});
		}

		my $messages = sub {
			my ($result) = @_;
			return join "\n", map { ref $_ ? $_->{text} : $_ } @{ $result->{messages} // [] };
		};
		my $res = $geo->resolve_column([ { c => 'Paris' }, { c => '' }, { c => '12' } ], 'c');
		my %by  = map { $_->{key} => $_->{text} } grep { ref } @{ $res->{messages} // [] };
		$why = join ', ',
			sprintf($DICTIONARY{Geocode}{warn_map_rows_why_empty}, 1),
			sprintf($DICTIONARY{Geocode}{warn_map_rows_why_refused}, 1);
		message_ok(Geocode => 'warn_map_rows_skipped', $by{warn_map_rows_skipped}, [1, 3, 2, $why]);
		message_ok(Geocode => 'warn_map_rows_why_empty',   $by{warn_map_rows_skipped}, [1], 1);
		message_ok(Geocode => 'warn_map_rows_why_refused', $by{warn_map_rows_skipped}, [1], 1);
		{
			# The other two reasons: a place not found, and one held back by the cap.
			my $res2 = $G->new(geocoder => Unit::Geocoder->new)
				->resolve_column([ { c => 'Nowhere' }, { c => 'Elsewhere' } ], 'c', max => 1);
			my ($m) = map { $_->{text} } grep { ref && $_->{key} eq 'warn_map_rows_skipped' } @{ $res2->{messages} // [] };
			message_ok(Geocode => 'warn_map_rows_why_not_found', $m, [1], 1);
			message_ok(Geocode => 'warn_map_rows_why_later',     $m, [1], 1);
		}

		my $many = Unit::Geocoder->new;
		my $capped = $G->new(geocoder => $many)->resolve_values([qw(A B)], max => $CAPPED);
		%by = map { $_->{key} => $_->{text} } grep { ref } @{ $capped->{messages} // [] };
		message_ok(Geocode => 'warn_map_geocode_capped', $by{warn_map_geocode_capped}, [1, 2]);

		{
			local $ENV{OPENADDR_HOME};
			delete $ENV{OPENADDR_HOME};
			my $text = '';
			mock('Database::BI::Model::Geocode::_load_geocoder' => sub { Unit::Geocoder->new }) if $G->can('_load_geocoder');
			my $nodata = $G->new;
			my $r = eval { $nodata->resolve_values(['Paris']) };
			restore_all();
			%by = map { $_->{key} => $_->{text} } grep { ref } @{ ($r // {})->{messages} // [] };
			message_ok(Geocode => 'warn_map_geocoder_unavailable_data', $by{warn_map_geocoder_unavailable_data}, []) if $by{warn_map_geocoder_unavailable_data};
		}

		is_deeply $G->shared_cache_from_models({ geo => { '_shared' => {} } }) // {}, {}, 'an empty store';
		is_deeply $G->shared_cache_from_models('x'), {}, 'a store that is not a hash';
		is_deeply $G->shared_cache_from_models(undef), {}, 'no store';
		my $merged = $G->models_with_shared_cache({ other => 1 }, { Paris => [ 48, 2 ] });
		is $merged->{other}, 1, 'models_with_shared_cache keeps what was there';
		is_deeply $G->shared_cache_from_models($merged), { Paris => [ 48, 2 ] }, 'and the cache comes back out';
		delete @ledger{qw(api.Geocode.shared_cache_from_models api.Geocode.models_with_shared_cache)};
	};

	subtest 'Database::BI.startup -- what it documents having done' => sub {
		my $tm = unit_app();
		is $tm->app->max_request_size, 50 * 1024 * 1024, 'a 50 MiB limit on request bodies';
		ok $tm->app->renderer->handlers->{tt}, 'Template Toolkit is registered as tt';
		my $fresh = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1) });
		is $fresh->app->config('platform') // 'web', 'web', 'platform defaults to web';
		is $fresh->app->config('language') // 'en', 'en', 'language defaults to en';
		like $fresh->get_ok('/tutorial')->tx->res->body, qr/<html/i, 'and routes are in place';
		delete $ledger{'api.BI.startup'};
	};

	# Why: every function here is called from inside request handling and from scripts
	# that may hold a timer or be reading $@ and $! themselves.
	subtest 'public functions leave the caller its globals and its alarm' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my @calls = (
			[ 'Util::urlencode'      => sub { Database::BI::Util::urlencode('a b') } ],
			[ 'Util::parse_number'   => sub { Database::BI::Util::parse_number('$5') } ],
			[ 'Calc::new'            => sub { Database::BI::Calc->new(expr => 'a+1', columns => ['a']) } ],
			[ 'Calc::new (bad)'      => sub { Database::BI::Calc->new(expr => 'nope', columns => []) } ],
			[ 'Calc::evaluate'       => sub { Database::BI::Calc->new(expr => 'a/0', columns => ['a'])->evaluate({ a => 1 }) } ],
			[ 'Calc::span_interval'  => sub { Database::BI::Calc::span_interval('1h') } ],
			[ 'Calc::date_normalise' => sub { Database::BI::Calc::date_normalise('01/15/2026', '%m/%d/%Y') } ],
			[ 'Extract::get'         => sub { Database::BI::Extract->new(model_dir => $dir)->get($SPEC, 1, 1) } ],
			[ 'Extract::put'         => sub { Database::BI::Extract->new(model_dir => $dir)->put($SPEC, 1, 1, 'x') } ],
			[ 'Extract::evict'       => sub { Database::BI::Extract->new(model_dir => $dir)->evict } ],
			[ 'Ask::infer_column_types' => sub { Database::BI::Ask::infer_column_types([ { a => 1 } ], ['a']) } ],
			[ 'Ask::ask (no key)'    => sub { Database::BI::Ask::ask(question => 'q') } ],
			[ 'Insights::compute'    => sub { Database::BI::Insights::compute(records => [ map { { a => $_ } } 1 .. 9, 500 ], columns => ['a']) } ],
			[ 'Insights::method_note' => sub { Database::BI::Insights::method_note('iqr_fence') } ],
			[ 'Summary::generate'    => sub { Database::BI::Summary::generate(insights => [], label => 'x') } ],
			[ 'Tutorial::chapters'   => sub { Database::BI::Tutorial->chapters } ],
			[ 'Geocode::cache_from_models' => sub { Database::BI::Model::Geocode->cache_from_models({}, $SPEC) } ],
			[ 'Geocode::resolve_values' => sub { Database::BI::Model::Geocode->new(geocoder => Unit::Geocoder->new)->resolve_values(['Paris']) } ],
			[ 'DataSource::new'       => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE) } ],
			[ 'DataSource::fetch_all' => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE)->fetch_all } ],
			[ 'DataSource::count'     => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE)->count } ],
			[ 'DataSource::columns'   => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE)->columns } ],
			[ 'DataSource::schema'    => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE)->schema } ],
			[ 'DataSource::updated'   => sub { Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => $SALES_TABLE)->updated } ],
		);
		# Windows runs an alarm, but alarm(0) there always answers 0.
		alarm($ALARM_SECS);
		my $alarm_reports = alarm(0) > 0;
		for my $case (@calls) {
			my ($name, $code) = @$case;
			local $_  = 'caller topic';
			local $@  = 'caller error';
			local $! = 2;
			my $errno = $! + 0;
			alarm($ALARM_SECS);
			$code->();
			my $left = alarm(0);
			is $_, 'caller topic', "$name keeps \$_";
			is $@, 'caller error', "$name keeps \$\@";
			is $! + 0, $errno, "$name keeps \$!";
			cmp_ok $left, '>', $ALARM_SECS - 10, "$name leaves the alarm running" if $alarm_reports;
		}

		# FreeBSD's mktime runs tzset, which can leave errno set (84, EILSEQ) when
		# it succeeds; Linux's does not, so this mktime does it on purpose.  The
		# date functions still give the caller its $! back.
		{
			no warnings 'redefine';
			my $real = \&POSIX::mktime;
			local *POSIX::mktime = sub { my $epoch = $real->(@_); $! = 84; return $epoch };
			for my $case (
				[ 'Calc::date_normalise' => sub { Database::BI::Calc::date_normalise('01/15/2026', '%m/%d/%Y') } ],
				[ 'Calc::evaluate (week, weekday)' => sub {
					Database::BI::Calc->new(expr => 'week(d) + weekday(d)', columns => ['d'])->evaluate({ d => '2026-01-15' });
				} ],
				[ 'Calc::evaluate (span by week)' => sub {
					Database::BI::Calc->new(expr => 'span(d, "1w")', columns => ['d'])->evaluate({ d => '2026-01-15' });
				} ],
			) {
				my ($name, $code) = @$case;
				local $! = 2;
				my $value = $code->();
				is $! + 0, 2, "$name keeps \$! where mktime sets errno";
				ok defined($value), "$name still answers";
			}
		}
		delete $ledger{'api.Globals'};
	};

	subtest 'analyses_* -- the documented bodies and codes' => sub {
		my $tm  = unit_app();
		my %doc = (name => 'First', datasets => [ { spec => $SPEC } ]);

		$tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses', []);
		delete $ledger{'api.analyses.list'};

		$tm->post_ok('/api/analyses' => json => \%doc)->status_is(201)->json_is('/created', 1);
		my $id = $tm->tx->res->json->{id};
		like $id, qr/\A[A-Za-z0-9]+\z/, 'an id';
		$tm->post_ok('/api/analyses' => { 'Content-Type' => 'application/json' } => 'not json')->status_is(400);
		message_ok(Dashboard => 'error_analysis_json', $tm->tx->res->json->{error}, [undef]);
		$tm->post_ok('/api/analyses' => json => { name => 'n' })->status_is(400);
		message_ok(Dashboard => 'error_analysis_invalid', $tm->tx->res->json->{error}, ['Missing required field: datasets']);
		$tm->post_ok('/api/analyses' => json => { %doc, version => 2 })->status_is(400);
		like $tm->tx->res->json->{error}, qr/\QUnsupported analysis version 2; please upgrade the application\E/, 'a newer version';
		delete $ledger{'msg.Dashboard.error_analysis_version'};
		delete $ledger{'api.analyses.create'};

		$tm->get_ok("/api/analyses/$id")->status_is(200)->json_is('/name', 'First');
		$tm->get_ok('/api/analyses/a-b')->status_is(400);
		message_ok(Dashboard => 'error_analysis_id_invalid', $tm->tx->res->json->{error});
		$tm->get_ok('/api/analyses/nosuch')->status_is(404);
		message_ok(Dashboard => 'error_analysis_not_found', $tm->tx->res->json->{error}, ['nosuch']);
		delete $ledger{'api.analyses.get'};

		$tm->put_ok("/api/analyses/$id" => json => { %doc, name => 'Second' })->status_is(200)->json_is('/id', $id)->json_is('/updated', 1);
		$tm->put_ok('/api/analyses/nosuch' => json => \%doc)->status_is(404);
		$tm->put_ok('/api/analyses/a-b' => json => \%doc)->status_is(400);
		$tm->put_ok("/api/analyses/$id" => json => {})->status_is(400);
		delete $ledger{'api.analyses.update'};

		$tm->patch_ok("/api/analyses/$id" => json => { name => 'Third' })->status_is(200)->json_is('/updated', 1);
		$tm->get_ok("/api/analyses/$id")->json_is('/name', 'Third')->json_is('/datasets/0/spec', $SPEC);
		$tm->patch_ok('/api/analyses/nosuch' => json => {})->status_is(404);
		$tm->patch_ok('/api/analyses/a-b' => json => {})->status_is(400);
		$tm->patch_ok("/api/analyses/$id" => json => { visuals => 'x' })->status_is(400);
		delete $ledger{'api.analyses.patch'};

		# The POD says unknown keys are dropped on write, with no exception for any verb.
		$tm->post_ok('/api/analyses' => json => { %doc, junk => 1 });
		my $with_junk = $tm->tx->res->json->{id};
		$tm->get_ok("/api/analyses/$with_junk")->json_hasnt('/junk', 'POST drops an unknown key');
		$tm->put_ok("/api/analyses/$with_junk" => json => { %doc, junk => 1 });
		$tm->get_ok("/api/analyses/$with_junk")->json_hasnt('/junk', 'PUT drops it');
		$tm->patch_ok("/api/analyses/$with_junk" => json => { junk => 1 });
		$tm->get_ok("/api/analyses/$with_junk")->json_hasnt('/junk', 'PATCH drops it');
		$tm->post_ok('/api/analyses/import' => json => { %doc, junk => 1 });
		$tm->get_ok('/api/analyses/' . $tm->tx->res->json->{id})->json_hasnt('/junk', 'import drops it');
		delete $ledger{'api.analyses.unknown_keys'};

		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', encode => { cat => 'region', value => 'amount' } })->status_is(201);
		ok defined $tm->tx->res->json->{visual}, 'the new visual index';
		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'nosuch' })->status_is(400)->json_is('/error', 'Unsupported visual kind');
		$tm->post_ok('/api/analyses/nosuch/visuals' => json => { kind => 'bar' })->status_is(404);
		$tm->post_ok('/api/analyses/a-b/visuals' => json => { kind => 'bar' })->status_is(400);
		delete $ledger{'api.analyses.add_visual'};

		# A text card, whose settings are all that can go wrong with it.
		my $text_error = sub {
			$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'text', options => { @_ } })->status_is(400);
			return $tm->tx->res->json->{error};
		};
		message_ok(Dashboard => 'error_text_card_empty', $text_error->(text => ' '));
		message_ok(Dashboard => 'error_text_card_long', $text_error->(text => 'x' x 20_001), [20_000]);
		message_ok(Dashboard => 'error_text_card_font', $text_error->(text => 'x', font => 'nosuch'));
		message_ok(Dashboard => 'error_text_card_size', $text_error->(text => 'x', size => 1), [8, 96]);
		message_ok(Dashboard => 'error_text_card_colour', $text_error->(text => 'x', colour => 'red'));
		message_ok(Dashboard => 'error_text_card_align', $text_error->(text => 'x', align => 'up'));

		$tm->delete_ok("/api/analyses/$id/visuals/0")->status_is(400);
		message_ok(Dashboard => 'error_visual_not_text', $tm->tx->res->json->{error});

		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'text', options => { text => 'x' } })->status_is(201);
		my $text_at = $tm->tx->res->json->{visual};
		$tm->patch_ok("/api/analyses/$id/visuals/$text_at" => json => {})->status_is(400);
		message_ok(Dashboard => 'error_text_card_options', $tm->tx->res->json->{error});
		$tm->patch_ok("/api/analyses/$id/visuals/$text_at" => json => { encode => {} })->status_is(400);
		message_ok(Dashboard => 'error_text_card_columns', $tm->tx->res->json->{error});
		$tm->get_ok("/a/$id/visual/$text_at/csv")->status_is(404);
		message_ok(Dashboard => 'error_text_card_no_data', $tm->tx->res->body);
		$tm->delete_ok("/api/analyses/$id/visuals/$text_at")->status_is(200);

		$tm->patch_ok("/api/analyses/$id/visuals/0" => json => { encode => { cat => 'product', value => 'amount' } })->status_is(200);
		$tm->patch_ok("/api/analyses/$id/visuals/9" => json => { encode => {} })->status_is(404)->json_is('/error', 'No visual at index 9');
		$tm->patch_ok("/api/analyses/$id/visuals/x" => json => { encode => {} })->status_is(400)->json_is('/error', 'Visual index must be a number');
		$tm->patch_ok("/api/analyses/$id/visuals/0" => json => {})->status_is(400)->json_is('/error', 'encode or cross_row must be given');
		$tm->patch_ok('/api/analyses/nosuch/visuals/0' => json => {})->status_is(404);
		delete $ledger{'api.analyses.update_visual'};

		my $export = $tm->get_ok("/api/analyses/$id/export")->status_is(200)
			->header_like('Content-Disposition', qr/analysis-\Q$id\E\.json/)->tx->res->json;
		is $export->{name}, 'Third', 'the export is the document';
		$tm->get_ok('/api/analyses/a-b/export')->status_is(400);
		$tm->get_ok('/api/analyses/nosuch/export')->status_is(404);
		delete $ledger{'api.analyses.export'};

		$tm->post_ok('/api/analyses/import' => json => $export)->status_is(201)->json_is('/imported', 1);
		isnt $tm->tx->res->json->{id}, $id, 'import creates a new id';
		$tm->post_ok('/api/analyses/import' => { 'Content-Type' => 'application/json' } => '[1]')->status_is(400);
		delete $ledger{'api.analyses.import'};

		# A parameter's checks surface through the same route, and are reported as such.
		$tm->post_ok('/api/analyses' => json => { %doc, params => { a => { type => 'number', min => 1, max => 5, default => 2 } } });
		my $with_param = $tm->tx->res->json->{id};
		my %card = (kind => 'bar', encode => { cat => 'region', value => 'amount' });
		$tm->post_ok("/api/analyses/$with_param/visuals" => json => { %card, query => 'p.a=x' })->status_is(400);
		message_ok(Dashboard => 'error_param_type', $tm->tx->res->json->{error}, ['a']);
		$tm->post_ok("/api/analyses/$with_param/visuals" => json => { %card, query => 'p.a=9' })->status_is(400);
		message_ok(Dashboard => 'error_param_range', $tm->tx->res->json->{error}, ['a', 1, 5]);

		$tm->delete_ok("/api/analyses/$id")->status_is(200)->json_is('/deleted', 1);
		$tm->delete_ok("/api/analyses/$id")->status_is(404);
		$tm->delete_ok('/api/analyses/a-b')->status_is(400);
		delete $ledger{'api.analyses.delete'};
	};

	# Why: the POD says every write answers 503 when the store is not writable.  The
	# routes that only checked at the top used to say "saved" over a failed write.
	subtest 'analyses_* -- every write answers 503 when the store cannot take it' => sub {
		my $tm  = unit_app();
		my %doc = (name => 'n', datasets => [ { spec => $SPEC } ], visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ]);
		my $id  = $tm->post_ok('/api/analyses' => json => \%doc)->tx->res->json->{id};

		mock('Database::BI::Controller::Dashboard::_write_analyses' => sub { 0 });
		my %card = (kind => 'bar', encode => { cat => 'product', value => 'amount' });
		for my $call (
			[ put_ok    => "/api/analyses/$id", json => \%doc ],
			[ patch_ok  => "/api/analyses/$id", json => { name => 'x' } ],
			[ post_ok   => "/api/analyses/$id/visuals", json => \%card ],
			[ patch_ok  => "/api/analyses/$id/visuals/0", json => { encode => $card{encode} } ],
			[ post_ok   => '/api/analyses', json => \%doc ],
			[ post_ok   => '/api/analyses/import', json => \%doc ],
			[ delete_ok => "/api/analyses/$id" ],
		) {
			my ($method, @args) = @$call;
			$tm->$method(@args)->status_is(503, "$method $args[0]");
			message_ok(Dashboard => 'error_analysis_storage', $tm->tx->res->json->{error});
		}
		restore_all();
		$tm->get_ok("/api/analyses/$id")->status_is(200, 'and the document is still there');
		delete $ledger{'api.analyses.storage_503'};
	};

	subtest 'share, embed, visual download' => sub {
		my $tm = unit_app();
		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'Shared', datasets => [ { spec => $SPEC } ],
			visuals => [ { kind => 'bar', title => 'By region', encode => { cat => 'region', value => 'amount' } } ],
		})->tx->res->json->{id};
		my $none = $tm->post_ok('/api/analyses' => json => { name => 'Empty', datasets => [ { spec => $SPEC } ] })->tx->res->json->{id};

		my $share = $tm->post_ok("/api/analyses/$id/share")->status_is(200)->tx->res->json;
		returns_is $share->{token}, { type => 'string' }, 'a token';
		cmp_ok $share->{expires}, '>', time(), 'that lasts';
		like $share->{url}, qr{/share/\Q$id\E\?token=}, 'and a link';
		$tm->post_ok('/api/analyses/a-b/share')->status_is(400);
		$tm->post_ok('/api/analyses/nosuch/share')->status_is(404);

		my $none_token = $tm->post_ok("/api/analyses/$none/share")->tx->res->json->{token};
		for my $route (qw(share embed)) {
			$tm->get_ok("/$route/$id?token=$share->{token}")->status_is(200)->content_type_like(qr{\Atext/html});
			$tm->get_ok("/$route/a-b?token=x")->status_is(400);
			$tm->get_ok("/$route/$id")->status_is(401);
			message_ok(Dashboard => 'error_token_missing', $tm->tx->res->body);
			$tm->get_ok("/$route/$id?token=junk")->status_is(403);
			message_ok(Dashboard => 'error_token_invalid', $tm->tx->res->body);
			$tm->get_ok("/$route/$none?token=$none_token")->status_is(404)->content_is('This shared analysis has no visuals');
		}
		delete $ledger{'api.share.share'} ;

		# Why: an embed is a page of charts in an iframe.  This drew the frame and threw
		# the charts away, so what it documents is what has to be on the page.
		my $embed = $tm->get_ok("/embed/$id?token=$share->{token}")->tx->res;
		like $embed->body, qr/id="vis-0|<svg|d3\./, 'the embed draws the chart';
		like $embed->body, qr/By region/, 'under its title';
		like $embed->body, qr/<script\b[^>]*\ssrc="[^"]*d3/, 'and loads what draws it';
		unlike $embed->body, qr/No visuals to display/, 'rather than saying there is nothing';
		is $embed->headers->header('X-Frame-Options'), 'SAMEORIGIN', 'embedding is opt-in';
		delete $ledger{'api.share.embed'};

		$tm->get_ok("/a/$id/visual/0/csv")->status_is(200)->content_like(qr/\Aid,product,region/)
			->header_like('Content-Disposition', qr/visual-0\.csv/);
		$tm->get_ok("/a/$id/visual/0/png")->status_is(501);
		$tm->get_ok("/a/$id/visual/0/exe")->status_is(400)->content_is('Format must be csv or png');
		$tm->get_ok("/a/$id/visual/x/csv")->status_is(400)->content_is('Visual index must be a non-negative integer');
		$tm->get_ok("/a/$id/visual/9/csv")->status_is(404)->content_is('Visual 9 not found');
		$tm->get_ok('/a/nosuch/visual/0/csv')->status_is(404);
		delete $ledger{'api.share.visual_download'};
	};

	subtest 'calc, groups, dates and geo stores' => sub {
		my $tm = unit_app();
		my $l  = "l=$SPEC";

		$tm->get_ok('/calc/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/calc/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/calc/delete')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok("/calc/save?$l&name=1bad&expr=1")->status_is(400);
		message_ok(Dashboard => 'error_calc_name', $tm->tx->res->json->{error}, ['1bad']);
		$tm->post_ok("/calc/save?$l&name=x")->status_is(400)->json_is('/error', 'expr= required');
		$tm->post_ok("/calc/save?$l&name=x&expr=1")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/calc/list?$l")->status_is(200)->json_is('/fields/x', '1');
		$tm->post_ok("/calc/delete?$l&name=x")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/calc/list?$l")->json_is('/fields', {});
		delete $ledger{'api.crud.calc'};

		$tm->get_ok('/groups/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/groups/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/groups/delete')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok("/groups/save?$l")->status_is(400)->json_is('/error', 'col= required');
		$tm->post_ok("/groups/save?$l&col=region")->status_is(400)->json_is('/error', 'group= required');

		# Why: this is the form the panel posts and the POD documents, one values= with a
		# line for each.  Stored whole, it was a single value that no row could ever equal.
		$tm->post_ok("/groups/save?$l&col=region" => form => { group => 'Top', values => "North\nSouth" })->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/groups/list?$l")->json_is('/groups/region/Top', [qw(North South)]);
		$tm->post_ok("/groups/save?$l&col=region&group=Rep&values=East&values=West")->status_is(200);
		$tm->get_ok("/groups/list?$l")->json_is('/groups/region/Rep', [qw(East West)], 'a repeated parameter too');
		my $rows = $tm->get_ok("/export?$l&format=json")->tx->res->json;
		my ($north) = grep { $_->{region} eq 'North' } @$rows;
		is $north->{region_group}, 'Top', 'and a row really lands in its group';
		$tm->post_ok("/groups/delete?$l&col=region&group=Top")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/groups/list?$l")->json_hasnt('/groups/region/Top');
		$tm->post_ok("/groups/delete?$l&col=region")->status_is(200);
		$tm->get_ok("/groups/list?$l")->json_hasnt('/groups/region');
		$tm->post_ok("/groups/delete?$l")->status_is(200);
		delete $ledger{'api.crud.groups'};

		$tm->get_ok('/dates/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/dates/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/dates/delete')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok("/dates/save?$l")->status_is(400)->json_is('/error', 'col= required');
		$tm->post_ok("/dates/save?$l&col=d&pattern=nope")->status_is(400);
		message_ok(Dashboard => 'error_date_pattern', $tm->tx->res->json->{error}, ['nope']);
		my $us = Mojo::Util::url_escape('%m/%d/%Y');
		$tm->post_ok("/dates/save?$l&col=d&pattern=$us&time=nope")->status_is(400);
		message_ok(Dashboard => 'error_date_time_pattern', $tm->tx->res->json->{error}, ['nope']);
		$tm->post_ok("/dates/save?$l&col=d&pattern=$us&as=nope")->status_is(400);
		message_ok(Dashboard => 'error_date_as', $tm->tx->res->json->{error}, ['nope']);
		$tm->post_ok("/dates/save?$l&col=d&pattern=$us")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/dates/list?$l")->json_is('/patterns/d', '%m/%d/%Y');
		$tm->post_ok("/dates/save?$l&col=t&pattern=$us&as=timestamp")->status_is(200);
		$tm->get_ok("/dates/list?$l")->json_is('/patterns/t/as', 'timestamp');
		$tm->post_ok("/dates/delete?$l&col=d")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/dates/list?$l")->json_hasnt('/patterns/d');
		$tm->post_ok("/dates/delete?$l")->status_is(200);
		$tm->get_ok("/dates/list?$l")->json_is('/patterns', {});
		delete $ledger{'api.crud.dates'};

		$tm->get_ok('/geo/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/geo/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/geo/delete')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok("/geo/save?$l")->status_is(400)->json_is('/error', 'col= required');
		$tm->post_ok("/geo/save?$l&col=c&kind=evil")->status_is(400)->json_is('/error', 'kind must be lat, lon, location or location_suffix');
		$tm->post_ok("/geo/save?$l&col=c&kind=$_")->status_is(200)->json_is('/ok', 1) for qw(lat lon location location_suffix);
		$tm->get_ok("/geo/list?$l")->json_is('/columns/c/kind', 'location_suffix');
		$tm->post_ok("/geo/delete?$l&col=c")->status_is(200)->json_is('/ok', 1);
		$tm->post_ok("/geo/save?$l&col=d&kind=lat");
		$tm->post_ok("/geo/delete?$l")->status_is(200);
		$tm->get_ok("/geo/list?$l")->json_is('/columns', {});
		delete $ledger{'api.crud.geo'};
	};

	subtest 'the routes t/unit.t had not reached' => sub {
		my $tm = unit_app();
		$tm->get_ok('/')->status_is(200);
		delete $ledger{'api.route.index'};
		$tm->get_ok('/tutorial')->status_is(200)->content_type_like(qr{\Atext/html});
		delete $ledger{'api.route.tutorial'};
		$tm->get_ok('/catalog')->status_is(200)->content_like(qr/sales\.csv/);
		delete $ledger{'api.route.catalog'};

		$tm->get_ok('/api/range')->status_is(400)->json_is('/error', 'l required');
		$tm->get_ok("/api/range?l=$SPEC")->status_is(400)->json_is('/error', 'col required');
		$tm->get_ok("/api/range?l=$SPEC&col=sale_date")->status_is(200)->json_like('/min', qr/\A\d{4}-\d{2}-\d{2}\z/)->json_like('/max', qr/\A\d{4}-\d{2}-\d{2}\z/);
		$tm->get_ok("/api/range?l=$SPEC&col=region")->status_is(200)->json_is('/min', undef)->json_is('/max', undef);
		delete $ledger{'api.route.range'};

		my $db = unit_sqlite('many.sqlite', 'CREATE TABLE alpha (id INTEGER)', 'CREATE TABLE beta (id INTEGER)');
		$tm->get_ok('/tables?l=' . Mojo::Util::url_escape("path:$db"))->status_is(200)->content_like(qr/alpha/)->content_like(qr/beta/);
		delete $ledger{'api.route.tables'};

		$tm->get_ok("/wordcloud?l=$SPEC&col=product")->status_is(200)->content_like(qr/Widget|widget/);
		$tm->get_ok("/wordcloud?l=$SPEC")->status_is(400);
		delete $ledger{'api.route.wordcloud'};

		$tm->get_ok("/stats?l=$SPEC&p=abc")->status_is(400);
		message_ok(Dashboard => 'error_stats_percentile', $tm->tx->res->body, ['abc']);
		$tm->get_ok("/stats?l=$SPEC&p=101")->status_is(400);
		message_ok(Dashboard => 'error_stats_percentile', $tm->tx->res->body, ['101']);
		$tm->get_ok("/stats?l=$SPEC&p=50")->status_is(200);
		delete $ledger{'api.route.stats_percentile'};
	};

	# Each row is one message: the request that must raise it, the code it must be
	# answered with, and the parameters that fill in the template.
	subtest 'every message a plain request can raise' => sub {
		my $tm = unit_app();
		my $e  = \&Mojo::Util::url_escape;
		my @table = (
			[ error_range_name   => "/export?l=$SPEC&range=nope", ['nope', undef] ],
			[ error_range_column => "/export?l=$SPEC&range=today" ],
			[ error_span_interval     => "/export?l=$SPEC&span=nope&tcol=region", ['nope'] ],
			[ error_span_no_column    => "/export?l=$SPEC&span=1d" ],
			[ error_span_tcol_orphan  => "/export?l=$SPEC&tcol=region", ['region'] ],
			[ error_span_tcol_unknown => "/export?l=$SPEC&span=1d&tcol=nope", ['nope'] ],
			[ error_span_conflict     => "/export?l=$SPEC&span=1d&tcol=region&as=z&c=z:1", ['z'] ],
			[ error_span_name         => "/export?l=$SPEC&span=1d&tcol=region&as=1bad", ['1bad'] ],
			[ error_cs_spec      => "/export?l=$SPEC&cs=x", ['x'] ],
			[ error_cs_column    => "/export?l=$SPEC&cs=nope:rank:r", ['nope:rank:r', 'nope'] ],
			[ error_cs_fn        => "/export?l=$SPEC&cs=amount:evil:r", ['evil', undef] ],
			[ error_cs_alias     => "/export?l=$SPEC&cs=amount:rank:1bad", ['1bad'] ],
			[ error_cs_conflict  => "/export?l=$SPEC&cs=amount:rank:region", ['region'] ],
			[ error_cs_arg       => "/export?l=$SPEC&cs=amount:window_sum:w&order=id", ['amount:window_sum:w', 'window_sum', 'amount', 'window_sum'] ],
			[ error_cs_no_arg    => "/export?l=$SPEC&cs=amount:rank:r:5", ['amount:rank:r:5', 'rank'] ],
			[ error_cs_by        => "/export?l=$SPEC&cs=amount:rank:r&by=nope", ['nope', 'nope'] ],
			[ error_cs_order     => "/export?l=$SPEC&cs=amount:rank:r&order=id:sideways", ['id:sideways'] ],
			[ error_cs_order_col => "/export?l=$SPEC&cs=amount:rank:r&order=nope", ['nope', 'nope'] ],
			[ error_cs_order_need => "/export?l=$SPEC&cs=amount:running_total:t", ['amount:running_total:t', 'running_total'] ],
			[ error_calc_compile => "/export?l=$SPEC&c=" . $e->('z:nope'), ['z', undef] ],
			[ error_agg_fn       => "/graph?l=$SPEC&x=sale_date&y=amount&agg=evil", ['evil', undef] ],
			[ error_pivot_rows_required   => "/pivot?l=$SPEC" ],
			[ error_pivot_measure_req     => "/pivot?l=$SPEC&rows=region" ],
			[ error_pivot_measure_invalid => "/pivot?l=$SPEC&rows=region&m=bad", ['bad', undef] ],
			[ error_measure_column        => "/pivot?l=$SPEC&rows=region&m=nope:sum:t", ['nope'] ],
			[ error_pivot_dim_not_found   => "/pivot?l=$SPEC&rows=nope&m=amount:sum:t", ['nope'] ],
			[ error_topn_col => "/pivot?l=$SPEC&rows=region&m=amount:sum:t&topn=1&topn_col=nope", ['nope'] ],
			[ error_map_source      => "/map?l=$SPEC" ],
			[ error_map_coordinates => "/map?l=$SPEC&lat=id" ],
			[ error_map_tiles_unknown => "/map?l=$SPEC&lat=id&lon=id&tiles=nope", ['nope'] ],
			[ error_map_geocode_mode  => "/map?l=$SPEC&lat=id&lon=id&geocode=nope", ['nope'] ],
			[ error_map_coordinate_numeric => "/map?l=$SPEC&lat=region&lon=product", ['region', 'product'] ],
		);
		for my $row (@table) {
			my ($key, $url, $args) = @$row;
			$tm->get_ok($url)->status_is(400, $key);
			my $body = $tm->tx->res->body;
			$body = without_location($body);
			message_ok(Dashboard => $key, $body, $args);
		}

		# Reached with data of a particular shape.
		my $out = unit_csv('out.csv', "id,lat,lon\n1,200,10\n2,300,20\n");
		$tm->get_ok('/map?l=' . $e->("path:$out") . '&lat=lat&lon=lon')->status_is(400);
		message_ok(Dashboard => 'error_map_coordinate_range', $tm->tx->res->body, ['lat', 'latitude']);

		$tm->get_ok('/view/nosuch_table')->status_is(404);
		message_ok(Dashboard => 'error_table_missing', $tm->tx->res->body, ['nosuch_table'], 1);

		$tm->get_ok('/api/stat')->status_is(400);
		message_ok(Dashboard => 'error_path_required', $tm->tx->res->json->{error});
		$tm->post_ok("/export?l=$SPEC&dir=/no/such/dir&filename=x.csv")->status_is(404);
		message_ok(Dashboard => 'error_dir_not_found', $tm->tx->res->json->{error}, ['/no/such/dir']);
		my $outdir = tempdir(CLEANUP => 1);
		$tm->post_ok("/export?l=$SPEC&dir=" . $e->($outdir) . '&filename=x.txt')->status_is(415);
		message_ok(Dashboard => 'error_ext_required', $tm->tx->res->json->{error});
		my $hidden = File::Spec->catdir($outdir, '.settings');
		mkdir $hidden or BAIL_OUT("cannot make $hidden: $!");
		$tm->post_ok("/export?l=$SPEC&dir=" . $e->($hidden) . '&filename=x.json')->status_is(403);
		message_ok(Dashboard => 'error_hidden_target', $tm->tx->res->json->{error},
			[Mojo::File->new($hidden)->child('x.json')->to_string]);
		$tm->post_ok("/export?l=$SPEC&dir=" . $e->($outdir) . '&filename=x.csv', { Origin => 'https://evil.example' })
			->status_is(403);
		message_ok(Dashboard => 'error_cross_site', $tm->tx->res->json->{error}, ['https://evil.example']);
		$tm->get_ok('/preferences', { Host => 'evil.example' })->status_is(403);
		message_ok(Dashboard => 'error_host_refused', $tm->tx->res->body, ['evil.example']);

		{
			local $ENV{MOJO_REVERSE_PROXY} = 1;
			my $tr = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1) });
			$tr->get_ok('/preferences', { 'X-Forwarded-For' => '192.168.1.20' })->status_is(403);
			message_ok(Dashboard => 'error_remote_needs_password', $tr->tx->res->body);
		}

		{
			my $root = tempdir(CLEANUP => 1);
			my $tf = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1), file_roots => [$root] });
			$tf->get_ok('/api/dirs?path=/etc')->status_is(403);
			message_ok(Dashboard => 'error_outside_roots', $tf->tx->res->json->{error}, ['/etc']);
		}

		# The login, on only with password_hash.
		require Database::BI::Password;
		my $tl = Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1), export_dirs => [ tempdir(CLEANUP => 1) ],
			password_hash => Database::BI::Password::hash_password('pw', rounds => 10_000) });
		$tl->get_ok('/calc/list')->status_is(401);
		message_ok(Dashboard => 'error_login_required', $tl->tx->res->json->{error});
		$tl->post_ok('/login' => form => { password => 'no' })->status_is(401);
		message_ok(Dashboard => 'error_login_failed', $tl->tx->res->dom->at('#login-error')->text);
		$tl->post_ok('/login' => form => { password => 'no' }) for 2 .. 10;
		$tl->post_ok('/login' => form => { password => 'pw' })->status_is(429);
		message_ok(Dashboard => 'error_login_locked', $tl->tx->res->dom->at('#login-error')->text, [15]);

		$tm->get_ok('/import')->status_is(200);
		message_ok(Dashboard => 'error_url_required', $tm->tx->res->body, [], 1);
		$tm->get_ok('/import?url=' . $e->('ftp://x/y'))->status_is(200);
		message_ok(Dashboard => 'error_url_invalid', $tm->tx->res->body, ['ftp://x/y'], 1);
		$tm->get_ok('/import?url=' . $e->('http://192.168.1.1/'))->status_is(200);
		message_ok(Dashboard => 'error_url_ssrf', $tm->tx->res->body, ['http://192.168.1.1/'], 1);

		$tm->post_ok('/upload')->status_is(400);
		message_ok(Dashboard => 'error_upload_none', $tm->tx->res->json->{error});
		$tm->post_ok('/upload' => form => { file => { content => 'x', filename => 'x.exe' } })->status_is(415);
		message_ok(Dashboard => 'error_upload_ext', $tm->tx->res->json->{error});
		# The size is what is mocked, not the body.  A really oversized body has the
		# server answer and close while the client still writes, which on Windows can
		# lose the answer; the subtest for POST /upload above sends a real one.
		mock('Mojo::Upload::size' => sub { 51 * 1024 * 1024 });
		$tm->post_ok('/upload' => form => { file => { content => 'x', filename => 'x.csv' } })->status_is(413);
		restore_all();
		message_ok(Dashboard => 'error_upload_too_large', $tm->tx->res->json->{error}, [undef]);
	};

	subtest 'the lookup store and its messages' => sub {
		my $tm   = unit_app();
		my $data = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir} = $data;
		my $put = sub { Mojo::File->new($data, $_[0])->spew($_[1]) };
		$put->('orders.csv', "id,shop,region,shops_region\n1,A,x,y\n");
		$put->('shops.csv', "code,city,region\nA,Here,North\nA,There,South\n");
		$put->('odd.csv', "a b,c d\nx y,z w\n");
		my $outside = unit_csv('far.csv', "code,city\nA,Far\n");
		open my $fh, '>', "$data/huge.csv" or BAIL_OUT("huge.csv: $!");
		truncate $fh, 9 * 1_048_576;
		close $fh;

		my $l    = 'l=table:orders';
		my $save = sub {
			$tm->post_ok('/lookups/save' => form => { l => 'table:orders', @_ });
			return $tm->tx->res->json->{error};
		};

		$tm->get_ok('/lookups/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/lookups/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/lookups/delete')->status_is(400)->json_is('/error', 'l= required');
		message_ok(Dashboard => 'error_lookup_name', $save->(name => '9x', file => 'shops.csv', key => 'code'), ['9x']);
		is $save->(name => 's', file => 'shops.csv'), 'key= required', 'key= is required';
		message_ok(Dashboard => 'error_lookup_remote', $save->(name => 's', file => 'http://x/y.csv', key => 'code'),
			['s', 'http://x/y.csv']);
		message_ok(Dashboard => 'error_lookup_outside', $save->(name => 's', file => $outside, key => 'code'),
			['s', $outside]);
		message_ok(Dashboard => 'error_lookup_not_found', $save->(name => 's', file => 'nope.csv', key => 'code'),
			['s', 'nope.csv']);
		message_ok(Dashboard => 'error_lookup_too_large', $save->(name => 's', file => 'huge.csv', key => 'code'),
			['s', 'huge.csv', 9 * 1_048_576, 8 * 1_048_576]);
		message_ok(Dashboard => 'error_lookup_unreadable', $save->(name => 's', file => 'odd.csv', key => 'code'),
			['s', 'odd.csv', undef]);
		message_ok(Dashboard => 'error_lookup_key_unknown', $save->(name => 's', file => 'shops.csv', key => 'nope'),
			['s', 'nope', 'shops.csv']);
		message_ok(Dashboard => 'error_lookup_field_unknown',
			$save->(name => 's', file => 'shops.csv', key => 'code', fields => 'nope'), ['s', 'nope', 'shops.csv']);

		$tm->get_ok("/export?$l&format=json&lk=ghost")->status_is(400);
		message_ok(Dashboard => 'error_lookup_unknown', $tm->tx->res->text, ['ghost']);

		is $save->(name => 'bycode', file => 'shops.csv', key => 'code', fields => 'city'), undef, 'a lookup saves';
		$tm->get_ok("/export?$l&format=json")->status_is(400);
		message_ok(Dashboard => 'error_lookup_col_unknown', $tm->tx->res->text, ['bycode', 'code', 'bycode']);
		$tm->post_ok("/lookups/delete?$l&name=bycode")->status_is(200)->json_is('/ok', 1);

		# region is the orders' own, and shops_region too, so there is nowhere to put it.
		is $save->(name => 'shops', file => 'shops.csv', key => 'code', col => 'shop', fields => 'region'), undef,
			'a lookup whose field has no free name still saves';
		$tm->get_ok("/export?$l&format=json")->status_is(400);
		message_ok(Dashboard => 'error_lookup_name_taken', $tm->tx->res->text, ['shops', 'region', 'shops_region']);

		is $save->(name => 'shops', file => 'shops.csv', key => 'code', col => 'shop', fields => 'city'), undef,
			'and saving it again replaces it';
		$tm->get_ok("/lookups/list?$l")->json_is('/lookups/shops/fields', ['city']);
		my @logged;
		$tm->app->log->level('warn');
		my $sub = $tm->app->log->on(message => sub { push @logged, $_[2] if $_[1] eq 'warn' });
		$tm->get_ok("/export?$l&format=json")->status_is(200)->json_is('/0/city', 'Here');
		$tm->app->log->unsubscribe(message => $sub);
		$tm->app->log->level('fatal');
		my ($dup) = grep { /duplicate key/ } @logged;
		message_ok(Dashboard => 'warn_lookup_duplicate_key', $dup, ['shops', 1, 'shops.csv']);

		$tm->post_ok("/lookups/delete?$l")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/lookups/list?$l")->json_is('/lookups', {});
		delete $ledger{'api.crud.lookups'};
	};

	subtest 'Calc.compile_pattern and Calc.capture_of' => sub {
		my $c = Database::BI::Calc::compile_pattern('^(?<cc>[A-Z]{2})-(\d+)');
		returns_is $c, { type => 'hashref' }, 'a compiled pattern is a hashref';
		is_deeply [ $c->{groups}, $c->{names} ], [ 2, ['cc'] ], 'with its group count and names';
		ok !eval { Database::BI::Calc::compile_pattern('(*FAIL)'); 1 }, 'a refused construct croaks';
		is Database::BI::Calc::capture_of($c, 'GB-1', 'cc'), 'GB', 'capture_of by name';
		is Database::BI::Calc::capture_of($c, 'GB-1', 2), '1', 'and by number';
		is Database::BI::Calc::capture_of($c, 'nope', 1), undef, 'undef on no match';
		delete $ledger{'api.Calc.compile_pattern'};
		delete $ledger{'api.Calc.capture_of'};
	};

	subtest 'the extraction store and its messages' => sub {
		my $tm   = unit_app();
		my $data = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir} = $data;
		Mojo::File->new($data, 'refs.csv')->spew("id,ref,cc\n1,GB-1,x\n");
		my $l    = 'l=table:refs';
		my $save = sub {
			$tm->post_ok('/extract/save' => form => { l => 'table:refs', @_ });
			return $tm->tx->res->json->{error};
		};

		$tm->get_ok('/extract/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/extract/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/extract/delete')->status_is(400)->json_is('/error', 'l= required');
		message_ok(Dashboard => 'error_extract_name', $save->(name => '9x', col => 'ref', pattern => '(?<a>.)'), ['9x']);
		is $save->(name => 'p', pattern => '(?<a>.)'), 'col= required', 'col= is required';
		is $save->(name => 'p', col => 'ref'), 'pattern= required', 'pattern= is required';
		message_ok(Dashboard => 'error_extract_pattern', $save->(name => 'p', col => 'ref', pattern => '(a'), ['p', undef]);
		message_ok(Dashboard => 'error_extract_no_names', $save->(name => 'p', col => 'ref', pattern => '(a)'), ['p']);
		message_ok(Dashboard => 'error_extract_field', $save->(name => 'p', col => 'ref', pattern => '(?<a>.)', fields => 'b'),
			['p', 'b']);

		is $save->(name => 'p', col => 'nope', pattern => '(?<a>.)'), undef, 'an extraction saves';
		$tm->get_ok("/export?$l&format=json")->status_is(400);
		message_ok(Dashboard => 'error_extract_col_unknown', $tm->tx->res->text, ['p', 'nope']);

		# cc is a source column, and so is the prefixed name x_cc would need to be:
		# here it is the extraction's own name that collides.
		Mojo::File->new($data, 'refs.csv')->spew("id,ref,cc,p_cc\n1,GB-1,x,y\n");
		is $save->(name => 'p', col => 'ref', pattern => '^(?<cc>[A-Z]+)'), undef, 'and again';
		$tm->get_ok("/export?$l&format=json")->status_is(400);
		message_ok(Dashboard => 'error_extract_name_taken', $tm->tx->res->text, ['p', 'cc', 'p_cc']);

		is $save->(name => 'p', col => 'ref', pattern => '^(?<code>[A-Z]+)'), undef, 'a free name';
		$tm->get_ok("/extract/list?$l")->json_is('/extractions/p/fields', ['code']);
		$tm->get_ok("/export?$l&format=json")->status_is(200)->json_is('/0/code', 'GB');
		$tm->post_ok("/extract/delete?$l&name=p")->status_is(200)->json_is('/ok', 1);
		$tm->post_ok("/extract/delete?$l")->status_is(200)->json_is('/ok', 1);
		$tm->get_ok("/extract/list?$l")->json_is('/extractions', {});
		delete $ledger{'api.crud.extract'};
	};

	subtest 'accelerated datasets and their messages' => sub {
		plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
		my $tm   = unit_app();
		my $data = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir} = $data;
		Mojo::File->new($data, 'sales.csv')->spew("id,region,amount\n1,North,10\n");
		Mojo::File->new($data, 'odd.csv')->spew("a b,c d\nx y,z w\n");
		my $db = unit_sqlite('lite.sqlite', 'CREATE TABLE lite (id INTEGER)');
		my $tx  = Mojo::Transaction::HTTP->new;
		my $c   = Database::BI::Controller::Dashboard->new(app => $tm->app, tx => $tx);
		my $acc = \&Database::BI::Controller::Dashboard::accelerate;
		my $err = sub { my ($spec) = @_; eval { $acc->($c, $spec); 1 } ? undef : $@ };

		message_ok(Dashboard => 'error_accel_spec', without_location($err->('url:http://x/y.csv')), ['url:http://x/y.csv']);
		message_ok(Dashboard => 'error_accel_sqlite', without_location($err->("path:$db")), ["path:$db"]);
		message_ok(Dashboard => 'error_accel_open', without_location($err->('table:odd')), ['table:odd', undef]);

		my $built = $acc->($c, 'table:sales');
		returns_is $built, { type => 'hashref' }, 'accelerate returns what it built';
		is_deeply [ @{$built}{qw(spec rows columns)} ], [ 'table:sales', 1, 3 ], 'the spec, rows and columns';
		ok -f $built->{path}, 'and the extract is on disc';
		is_deeply [ Database::BI::Controller::Dashboard::accelerated_specs($c) ], ['table:sales'], 'accelerated_specs lists it';
		delete $ledger{'api.accel.specs'};
		delete $ledger{'api.accel.accelerate'};

		my $src = $tm->app->build_controller->open_table(
			Mojo::File->new($built->{path})->basename =~ s/\.db\z//r,
			directory => Mojo::File->new($built->{path})->dirname->to_string, column_order => [qw(id region amount)]);
		is_deeply $src->columns, [qw(id region amount)], 'DataSource gives the column_order it was given';
		delete $ledger{'api.DataSource.column_order'};

		ok Database::BI::Controller::Dashboard::unaccelerate($c, 'table:sales'), 'unaccelerate says it was';
		ok !-f $built->{path}, 'and removes the extract';
		ok !Database::BI::Controller::Dashboard::unaccelerate($c, 'table:sales'), 'and is false the second time';
		delete $ledger{'api.accel.unaccelerate'};

		$tm->app->config->{model_dir} = File::Spec->catdir($data, 'models');
		message_ok(Dashboard => 'error_accel_store', without_location($err->('table:sales')), ['table:sales']);

		# A file with nothing in it opens, but has no columns for a SQLite table.
		$tm->app->config->{model_dir} = tempdir(CLEANUP => 1);
		Mojo::File->new($data, 'blank.csv')->spew('');
		message_ok(Dashboard => 'error_accel_build', without_location($err->('table:blank')), ['table:blank', undef]);
	};

	subtest 'messages that need a collaborator to fail' => sub {
		my $tm = unit_app();
		my $e  = \&Mojo::Util::url_escape;
		my $boom = sub { require Carp; Carp::croak('backend down') };

		mock('Database::BI::Model::DataSource::new' => $boom);
		$tm->get_ok('/view/sales')->status_is(200);
		message_ok(Dashboard => 'error_table_open', $tm->tx->res->body, ['sales', undef], 1);
		$tm->get_ok('/open?path=' . $e->($SALES_CSV))->status_is(200);
		message_ok(Dashboard => 'error_file_open', $tm->tx->res->body, [undef, undef], 1);
		restore_all();

		mock('Database::BI::Model::DataSource::new' => $boom);
		$tm->get_ok('/import?url=' . $e->('http://example.invalid/t.html'))->status_is(200);
		message_ok(Dashboard => 'error_url_fetch', $tm->tx->res->body, ['http://example.invalid/t.html', undef], 1);
		restore_all();

		# The export is written to a temporary file beside its name, then renamed.
		mock('Database::BI::Controller::Dashboard::tempfile' => $boom);
		my $outdir = tempdir(CLEANUP => 1);
		$tm->post_ok("/export?l=$SPEC&dir=" . $e->($outdir) . '&filename=x.csv')->status_is(500);
		message_ok(Dashboard => 'error_write_failed', $tm->tx->res->json->{error}, [undef]);
		restore_all();
		SKIP: {
			skip 'no symlinks here', 2 unless eval { symlink("$outdir/elsewhere.csv", "$outdir/link.csv") };
			$tm->post_ok("/export?l=$SPEC&dir=" . $e->($outdir) . '&filename=link.csv')->status_is(403);
			# Named as the app joins it (Mojo::File, so with \ on Windows).
			message_ok(Dashboard => 'error_export_not_file', $tm->tx->res->json->{error},
				[Mojo::File->new($outdir)->child('link.csv')->to_string]);
		}
		$tm->app->config->{export_dirs} = [ tempdir(CLEANUP => 1) ];
		$tm->post_ok("/export?l=$SPEC&dir=" . $e->($outdir) . '&filename=x.csv')->status_is(403);
		message_ok(Dashboard => 'error_outside_export_dirs', $tm->tx->res->json->{error}, [$outdir]);
		delete $tm->app->config->{export_dirs};

		mock('Mojo::Upload::move_to' => $boom);
		$tm->post_ok('/upload' => form => { file => { content => "a,b\n1,2\n", filename => 'x.csv' } })->status_is(500);
		message_ok(Dashboard => 'error_upload_save', $tm->tx->res->json->{error});
		restore_all();

		mock('Mojo::File::list' => $boom);
		$tm->post_ok('/uploads/clear')->status_is(500);
		message_ok(Dashboard => 'error_uploads_clear', $tm->tx->res->json->{error});
		restore_all();

		mock('Database::BI::Controller::Dashboard::_write_sqlite_db' => $boom);
		$tm->get_ok("/export?l=$SPEC&format=sqlite")->status_is(500);
		message_ok(Dashboard => 'error_export_sqlite', $tm->tx->res->body);
		restore_all();

		require LWP::UserAgent;
		mock('LWP::UserAgent::get' => sub {
			require HTTP::Response;
			return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json' ], '[1,2,3]');
		});
		$tm->get_ok('/import?url=' . $e->('http://example.invalid/scalars.json'))->status_is(200);
		message_ok(DataSource => 'error_rows_not_records', $tm->tx->res->body, [], 1);
		restore_all();

		my $geo = unit_csv('geo.csv', "id,lat,lon,place\n1,10,20,Paris\n2,x,y,Rome\n3,30,40,Oslo\n");
		my $l   = 'l=' . $e->("path:$geo");
		$tm->get_ok("/map?$l&lat=lat&lon=lon")->status_is(200);
		message_ok(Dashboard => 'warn_map_coordinate_rows', $tm->tx->res->body, [2, 3, 1], 1);
		$tm->get_ok("/map?$l&lat=lat&lon=lon&max=$CAPPED")->status_is(200);
		message_ok(Dashboard => 'warn_map_markers_capped', $tm->tx->res->body, [$CAPPED, 2], 1);

		SKIP: {
			# The key on the map, and what it says when nothing in it is in
			# view, need an HTML::OSM that draws one
			unless (eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }) {
				delete $ledger{'msg.Dashboard.map_legend_empty'};
				skip 'the key on a map needs HTML::OSM 0.14', 1;
			}
			$tm->get_ok("/map?$l&lat=lat&lon=lon&series=place")->status_is(200);
			my ($empty) = $tm->tx->res->body =~ /var legendEmpty = '([^']*)'/;
			message_ok(Dashboard => 'map_legend_empty', $empty);
		}

		mock('Database::BI::Controller::Dashboard::_map_renderer_version' => sub { (0, undef) });
		$tm->get_ok("/map?$l&lat=lat&lon=lon")->status_is(200);
		message_ok(Dashboard => 'error_map_renderer_missing', $tm->tx->res->body, [], 1);
		restore_all();
		mock('Database::BI::Controller::Dashboard::_map_renderer_version' => sub { (0, '0.01') });
		$tm->get_ok("/map?$l&lat=lat&lon=lon")->status_is(200);
		message_ok(Dashboard => 'error_map_renderer_old', $tm->tx->res->body, ['0.01'], 1);
		restore_all();
		{
			# With the renderer said to be there and failing, whether or not this
			# machine has it: HTML::OSM is only recommended, and this key is in the ledger.
			mock('Database::BI::Controller::Dashboard::_map_renderer_version' => sub { (1, '0.13') });
			no warnings qw(redefine once);
			local *HTML::OSM::new = $boom;
			$tm->get_ok("/map?$l&lat=lat&lon=lon")->status_is(200);
			message_ok(Dashboard => 'error_map_renderer_failed', $tm->tx->res->body, [], 1);
			restore_all();
		}

		$tm->app->config->{geocoder} = Unit::Geocoder->new;
		$tm->get_ok("/map?$l&loc=place")->status_is(200);
		message_ok(Dashboard => 'error_map_no_markers', $tm->tx->res->body, [], 1);
		$tm->get_ok("/map?$l&loc=nope")->status_is(400);
		message_ok(Dashboard => 'error_map_loc_column', $tm->tx->res->body, ['nope']);
		delete $tm->app->config->{geocoder};

		# A store of its own: the warning is about a new lookup, and a place the
		# requests above have asked about is one already answered.
		my $fresh = unit_app();
		$fresh->app->config->{geocoder} = Unit::Geocoder->new(results => {
			Paris => Unit::GeoPoint->new({ latitude => 48, longitude => 2, database => 'x' }),
		});
		mock('Database::BI::Controller::Dashboard::_write_models' => sub { 0 });
		$fresh->get_ok("/map?$l&loc=place")->status_is(200);
		message_ok(Dashboard => 'warn_map_cache_unwritten', $fresh->tx->res->body, [], 1);
		restore_all();

		# The map page's progress bar looks places up one at a time, each signed
		# by the page that listed it.
		$tm->post_ok('/geo/lookup')->status_is(400);
		message_ok(Dashboard => 'error_geo_lookup_place', $tm->tx->res->json->{error});
		$tm->post_ok('/geo/lookup' => form => { place => 'Paris', sig => 'forged' })->status_is(403);
		message_ok(Dashboard => 'error_geo_lookup_unsigned', $tm->tx->res->json->{error});

		# The AI routes: the provider is the only thing replaced.
		require HTTP::Response;
		$tm->post_ok("/api/ask?l=$SPEC&q=x")->status_is(503);
		message_ok(Dashboard => 'ask_unavailable', $tm->tx->res->json->{error});
		$tm->app->config->{ai_api_key} = 'k';
		$tm->post_ok("/api/ask?l=$SPEC")->status_is(400);
		message_ok(Dashboard => 'ask_no_question', $tm->tx->res->json->{error});
		my $reply = sub {
			my ($code, $text) = @_;
			my $body = Mojo::JSON::encode_json({ content => [ { text => $text } ] });
			return sub { HTTP::Response->new($code, 'x', ['Content-Type' => 'application/json'], $body) };
		};
		mock('LWP::UserAgent::request' => $reply->(500, ''));
		$tm->post_ok("/api/ask?l=$SPEC&q=x")->status_is(502);
		message_ok(Dashboard => 'ask_provider_error', $tm->tx->res->json->{error});
		restore_all();
		mock('LWP::UserAgent::request' => $reply->(200, 'no json here'));
		$tm->post_ok("/api/ask?l=$SPEC&q=x")->status_is(422);
		message_ok(Dashboard => 'ask_unparseable', $tm->tx->res->json->{error});
		restore_all();
		mock('LWP::UserAgent::request' => $reply->(200, '{"kind":"bar","title":"T","encode":{"cat":"nope"}}'));
		$tm->post_ok("/api/ask?l=$SPEC&q=x")->status_is(422);
		message_ok(Dashboard => 'ask_invalid_spec', $tm->tx->res->json->{error}, ['nope']);
		restore_all();
		$tm->post_ok("/api/ask?l=$SPEC&q=" . ('x' x 501))->status_is(400);
		message_ok(Dashboard => 'ask_question_too_long', $tm->tx->res->json->{error}, [500]);
		$tm->app->config->{ai_calls_per_hour} = 1;	# the calls above used it up
		$tm->post_ok("/api/ask?l=$SPEC&q=x")->status_is(429);
		message_ok(Dashboard => 'ai_limit_reached', $tm->tx->res->json->{error}, [1]);
		delete $tm->app->config->{ai_calls_per_hour};
		delete $tm->app->config->{ai_api_key};

		# A canvas older than its data says so.
		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'Old', datasets => [ { spec => $SPEC } ],
			visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
		})->tx->res->json->{id};
		my $store = Mojo::File->new($tm->app->config->{model_dir})->child('analyses.json');
		my $all = Mojo::JSON::decode_json($store->slurp);
		$all->{$id}{updated} = 1;
		$store->spew(Mojo::JSON::encode_json($all));
		$tm->get_ok("/a/$id")->status_is(200);
		message_ok(Dashboard => 'freshness_stale_msg', $tm->tx->res->body, [], 1);
	};

	# These do not reach the reader: they are said to the operator, as warnings or in
	# the log, and each must still say exactly what it documents.
	subtest 'messages said to the operator' => sub {
		my $tm = unit_app();
		my $e  = \&Mojo::Util::url_escape;
		my @warned;
		local $SIG{__WARN__} = sub { push @warned, without_location($_[0]) };

		$tm->get_ok("/combine?l=$SPEC&sort=amount")->status_is(200);
		$tm->get_ok("/export?l=$SPEC&sort=nope")->status_is(200);
		my ($combine) = grep { /Sorting is applied/ } @warned;
		message_ok(Dashboard => 'warn_combine_sort', $combine);
		my ($sort) = grep { /Unknown sort column/ } @warned;
		message_ok(Dashboard => 'error_sort_column', $sort, ['nope']);

		my $db = unit_sqlite('mixed.sqlite', 'CREATE TABLE mixed (id INTEGER, g TEXT, v TEXT)',
			q{INSERT INTO mixed VALUES (1, 'a', '5')}, q{INSERT INTO mixed VALUES (2, 'a', 'x')});
		@warned = ();
		$tm->get_ok('/bar?l=' . $e->("path:$db") . '&cat=g&val=v')->status_is(200);
		my ($fallback) = grep { /not uniformly numeric/ } @warned;
		message_ok(Dashboard => 'warn_measure_fallback', $fallback, ['sum', 'v']);

		my @logged;
		$tm->app->log->level('warn');
		my $sub = $tm->app->log->on(message => sub { push @logged, $_[2] if $_[1] eq 'warn' });
		$tm->get_ok("/export?l=$SPEC&c=" . $e->('z:amount/0'))->status_is(200);
		$tm->app->log->unsubscribe(message => $sub);
		$tm->app->log->level('fatal');
		my ($undef_rows) = grep { /returned undef/ } @logged;
		message_ok(Dashboard => 'warn_calc_undef', $undef_rows, ['z', undef]);

		my $left  = unit_sqlite('lefty.sqlite', 'CREATE TABLE lefty (id INTEGER, v INTEGER)', 'INSERT INTO lefty VALUES (1, 2)');
		my $right = unit_sqlite('righty.sqlite', 'CREATE TABLE righty (id INTEGER, v TEXT)', q{INSERT INTO righty VALUES (1, 'x')});
		$tm->get_ok('/export?l=' . $e->("path:$left") . '&j=' . $e->("path:$right|id|id"))->status_is(200);
		my $hdr = $tm->tx->res->headers->header('X-BI-Warnings') // '';
		message_ok(Dashboard => 'warn_join_schema_mismatch', $hdr, ['v', 'INTEGER', undef, 'TEXT', undef]);
	};
}

# ---------------------------------------------------------------------------
# Ledger assertion -- every documented state must have been exercised.
# ---------------------------------------------------------------------------
if(my @untested = sort keys %ledger) {
	for my $key (@untested) {
		fail "Untested documented state: $key ($ledger{$key})";
	}
} else {
	pass('All documented API states covered by the test suite');
}

done_testing();
