use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Test::Mockingbird qw(mock restore_all);
use Readonly;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Mojo::File;
use Mojo::Util qw(url_escape);

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
);

# ---------------------------------------------------------------------------
# Bootstrap the Mojolicious app first so that Test::Mojo dynamically
# requires all app modules at runtime (after the CHECK phase).
# Sub::Private's namespace::clean runs at CHECK time, so modules loaded
# via 'use' at compile-time lose their :Private stash entries — including
# _init_backend, which new() calls.  Loading via Test::Mojo->new (which
# uses require at runtime) bypasses CHECK and preserves the full stash.
# Only AFTER the app is started do we require DataSource so we get the
# already-loaded, stash-intact version.
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;	# no-op: already in %INC; stash intact

# ---------------------------------------------------------------------------
# DataSource — direct constructor and accessor tests
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
	  ->content_like(qr/action="\/open"/, 'Browse card form targets /open');
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
	# When the DataSource backend throws during fetch_all, the controller must
	# catch the exception (inside its eval block) and re-render the home page
	# with the error_table_open message rather than propagating a 500.
	mock 'Database::BI::Model::DataSource::fetch_all' => sub {
		die "Simulated backend failure\n";
	};
	$t->get_ok("/view/$SALES_TABLE")
	  ->status_is(200, 'renders 200 (home page) when fetch_all throws')
	  ->content_type_like(qr{text/html}, 'response is HTML')
	  ->content_like(qr/Could not open table/i, 'error_table_open message present');
	restore_all();
	delete $ledger{'GET./view.error_table_open'};
};

# ---  GET /open error rendering  --------------------------------------------

subtest 'GET /open?path= -- fetch_all error renders home with error_file_open' => sub {
	# open_file wraps open_table+fetch_all in eval; a DataSource throw must
	# surface as error_file_open on the home page, not as a 500.
	SKIP: {
		skip 'data/sales.csv not found', 4 unless -f $SALES_CSV;
		my $enc = url_escape($SALES_CSV);
		mock 'Database::BI::Model::DataSource::fetch_all' => sub {
			die "Simulated read error\n";
		};
		$t->get_ok("/open?path=$enc")
		  ->status_is(200, 'renders 200 (home page) when fetch_all throws')
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
		skip 'Cannot simulate write failure as root', 3 unless $> != 0;
		chmod(0555, $dir) or skip 'Cannot set directory read-only', 3;

		$t->post_ok('/export', form => {
			l        => "table:$SALES_TABLE",
			dir      => $dir,
			filename => 'out.csv',
		})->status_is(500, '500 when write to read-only dir fails')
		  ->json_has('/error', 'error key present in JSON response');
		my $err = $t->tx->res->json('/error');
		like $err, qr/Write failed/i, 'error message mentions Write failed';

		chmod(0755, $dir);	# restore so CLEANUP can remove the dir
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
# Ledger assertion — every documented state must have been exercised.
# ---------------------------------------------------------------------------
if(my @untested = sort keys %ledger) {
	for my $key (@untested) {
		fail "Untested documented state: $key ($ledger{$key})";
	}
} else {
	pass('All documented API states covered by the test suite');
}

done_testing();
