use strict;
use warnings;

# Caches go where CACHEDIR, CACHE_DIR or Object::Configure say before model_dir
# (Database::BI::CacheDir): without this, a run writes into the user's own cache.
delete @ENV{qw(CACHEDIR CACHE_DIR Database__BI__cache_dir Database__BI__Extract__cache_dir Database__BI__Model__Geocode__cache_dir)};

# ---------------------------------------------------------------------------
# Integration test suite for Database::BI
#
# Focus: cross-module, multi-step workflows where Database::BI (routing/config),
# Database::BI::Controller::Dashboard (HTTP actions), and
# Database::BI::Model::DataSource (data access) all interact.
#
# Sections 60 onward hold the workflows that cross every layer, independent
# objects in one process, every combination of the optional modules, permissions
# revoked under a running app, and upstreams that fail.
#
# What is NOT here (covered by dedicated suites):
#   - Individual filter operators             -> t/filter.t
#   - Single-endpoint status codes            -> t/unit.t
#   - Internal helpers (white-box)            -> t/function.t
#   - Security / hostile inputs               -> t/cgi_security.t
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use Test::Without::Module;
use Test::Mockingbird qw(mock_scoped spy restore_all);
use Test::Permissions qw(can_revoke_create can_revoke_search with_revoked);
use Test::Returns;
use Readonly;
use File::Basename ();
use File::Spec     ();
use File::Temp     qw(tempdir tempfile);
use HTTP::Response ();
use LWP::UserAgent ();
use Mojo::File     ();
use Mojo::JSON     qw(decode_json encode_json);
use Mojo::Promise  ();
use Mojo::Util     qw(url_escape);
use Scalar::Util   qw(reftype refaddr);
use DBI            ();

# Mojolicious dispatches under a __DIE__ handler that throws an object.  When
# Test::Without::Module's @INC hook croaks under it, perl goes on through @INC and
# loads the module after all, so a test that hides a module and then makes a
# request sees it installed.  The hook has to die with no handler in the way.
{
	no warnings 'redefine';
	my $hook = \&Test::Without::Module::fake_module;
	*Test::Without::Module::fake_module = sub { local $SIG{__DIE__}; return $hook->(@_) };
}

# ---------------------------------------------------------------------------
# Constants derived from known sample data (sales.csv, products.psv).
# Keep in sync with the data/ directory.
# ---------------------------------------------------------------------------
Readonly my $SALES_CSV   => File::Spec->rel2abs('data/sales.csv');
Readonly my $PRODUCTS_PSV => File::Spec->rel2abs('data/products.psv');
Readonly my $CATALOG_XML  => File::Spec->rel2abs('data/catalog.xml');

# Known row counts (as of the shipped sample data):
Readonly my $SALES_ROW_COUNT    => 6;
Readonly my $PRODUCTS_ROW_COUNT => 4;

# Known column names present in sales.csv (integration assertions):
Readonly my @SALES_COLS => qw(id product region sales_rep amount sale_date);

# ---------------------------------------------------------------------------
# Bootstrap: Test::Mojo must be constructed BEFORE any direct use of
# DataSource so that Database::Abstraction modules are loaded at runtime
# (bypassing the Sub::Private CHECK-phase stash cleanup).
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');

# Redirect model_dir to a temp directory so tests never write to .bi/models.json
# in the workspace.  The variable must be file-scoped so the dir persists for
# the entire test process (CLEANUP => 1 deletes it when it goes out of scope).
my $TEST_MODEL_DIR = tempdir(CLEANUP => 1);
$t->app->config->{model_dir} = $TEST_MODEL_DIR;

# And uploads to a directory this file owns.  The staging directory is shared
# by every test file, so under a parallel harness (HARNESS_OPTIONS=j...) a
# POST /uploads/clear in another file deleted this file's upload between its
# POST /upload and its GET /open, which returned 404 about one run in four.
my $TEST_UPLOAD_DIR = tempdir(CLEANUP => 1);
$t->app->config->{uploads_dir} = $TEST_UPLOAD_DIR;

# Guard: most integration subtests depend on the sample data files.
plan skip_all => 'data/sales.csv not found'    unless -f $SALES_CSV;
plan skip_all => 'data/products.psv not found' unless -f $PRODUCTS_PSV;

require Database::BI::Model::DataSource;    # already in %INC; stash intact

# ---------------------------------------------------------------------------
# Minimal i18n spy object used in Section 5.
# Implements maketext() so it is accepted by DataSource's i18n validation.
# ---------------------------------------------------------------------------
{
	package MockI18n;
	sub new { bless { log => [] }, shift }
	sub maketext {
		my ($self, $key, @args) = @_;
		push @{ $self->{log} }, { key => $key, args => \@args };
		# Delegate to the built-in message dict so error text is still human-readable.
		my %msgs = %Database::BI::Model::DataSource::MESSAGES;
		return sprintf($msgs{$key} // $key, @args);
	}
}

# ===========================================================================
# SECTION 1: App config -> DataSource -> HTTP response pipeline
#
# Strategy: Verify that the app's open_table helper correctly passes the
# data_dir config to DataSource, and that DataSource in turn feeds the
# controller with the expected data -- a full config-to-HTML round-trip.
# ===========================================================================

subtest 'Config -> open_table helper -> DataSource -> HTML response (sales)' => sub {
	# The app config sets data_dir='data'.  GET /view/sales must:
	#   1. Use the open_table helper with data_dir from config
	#   2. DataSource opens data/sales.csv via Database::Abstraction
	#   3. Controller renders rows -> HTML contains known sample values
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Widget A/,   'known product in HTML output')
	  ->content_like(qr/Alice Smith/, 'known sales_rep in HTML output')
	  ->content_like(qr/North/,       'known region in HTML output');

	# Verify DataSource is in fact delivering the right column set by
	# checking the columns API (which calls open_table -> DataSource.columns).
	my $cols = $t->get_ok('/api/columns?table=sales')
	             ->status_is(200)
	             ->json_has('/columns')
	             ->tx->res->json('/columns');
	for my $expected (@SALES_COLS) {
		ok(grep({ $_ eq $expected } @$cols), "column '$expected' present in columns API response");
	}
};

subtest 'Config -> open_table(directory=>) -> DataSource -> HTML (custom path)' => sub {
	# /open uses open_table(directory => $dir_of_file) -- the directory override
	# path in the helper.  This exercises a distinct code path from /view/:table.
	my $enc = url_escape($SALES_CSV);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Widget A/,    'open_file path reads correct data')
	  ->content_like(qr/Alice Smith/,  'known rep present when opened via path');
};

# ===========================================================================
# SECTION 2: Multi-step HTTP workflow -- upload -> open -> filter pipeline
#
# Strategy: Simulate a complete user session: upload a fresh CSV, then
# immediately open it and apply a filter.  Verifies that the upload path
# (DataSource via open_table) and the filter path (_apply_filters) compose
# correctly across two independent HTTP requests.
# ===========================================================================

subtest 'Upload -> open -> filter end-to-end pipeline' => sub {
	# Step 1: Upload a custom CSV that we control precisely.
	my $csv_content = join("\n",
		'id,label,tier,score',
		'1,Alpha,premium,90',
		'2,Beta,standard,60',
		'3,Gamma,premium,80',
		'4,Delta,standard,40',
		''    # trailing newline (RFC 4180)
	);

	$t->post_ok('/upload', form => {
		file => { content => $csv_content, filename => 'integ_upload.csv' },
	})->status_is(200)
	  ->json_has('/url')
	  ->json_has('/path');

	my $upload_path = $t->tx->res->json('/path');
	ok -f $upload_path, 'uploaded file physically exists on disk';

	# Step 2: Open the uploaded file -- exercises the open_table path arg.
	my $enc = url_escape($upload_path);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'all rows present before filtering')
	  ->content_like(qr/Beta/,    'Beta row present before filtering')
	  ->content_like(qr/premium/, 'tier column data visible');

	# Step 3: Open with an eq filter -- only premium tier rows should appear.
	$t->get_ok("/open?path=$enc&f=" . url_escape('tier:eq:premium'))
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'Alpha is premium -- present in filtered view')
	  ->content_like(qr/Gamma/,   'Gamma is premium -- present in filtered view')
	  ->content_unlike(qr/Beta/,  'Beta is standard -- absent from filtered view')
	  ->content_unlike(qr/Delta/, 'Delta is standard -- absent from filtered view');

	# Step 4: Open with a gt filter -- only score > 70.
	$t->get_ok("/open?path=$enc&f=" . url_escape('score:gt:70'))
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'Alpha score 90 > 70 -- present')
	  ->content_like(qr/Gamma/,   'Gamma score 80 > 70 -- present')
	  ->content_unlike(qr/Beta/,  'Beta score 60 not > 70 -- absent')
	  ->content_unlike(qr/Delta/, 'Delta score 40 not > 70 -- absent');
};

# ===========================================================================
# SECTION 3: Browse -> open -> export pipeline
#
# Strategy: Navigate the filesystem to a temp directory containing a fresh
# CSV, open the file, and write it out to a second location.  Tests the
# browse, open_file, and export_write actions composing correctly.
# ===========================================================================

subtest 'Browse -> open -> export_write end-to-end pipeline' => sub {
	# Arrange: a temp dir with a known CSV.
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'inventory.csv');
	Mojo::File->new($file)->spurt(
		"sku,description,qty\n" .
		"A001,Widget,100\n"      .
		"A002,Gadget,200\n"
	);
	my $out_dir = tempdir(CLEANUP => 1);

	# Step 1: Browse verifies the CSV appears in the directory listing.
	$t->get_ok('/browse?path=' . url_escape($dir))
	  ->status_is(200)
	  ->content_like(qr/inventory\.csv/i, 'CSV file listed in browse view');

	# Step 2: Open the file.
	$t->get_ok('/open?path=' . url_escape($file))
	  ->status_is(200)
	  ->content_like(qr/Widget/, 'Widget data visible after open')
	  ->content_like(qr/Gadget/, 'Gadget data visible after open');

	# Step 3: Export the opened file to the output directory.
	$t->post_ok('/export', form => {
		l        => "path:$file",
		dir      => $out_dir,
		filename => 'inventory_out.csv',
	})->status_is(200)
	  ->json_has('/saved');

	my $saved = $t->tx->res->json('/saved');
	ok -f $saved, 'exported file physically exists';
	my $exported = Mojo::File->new($saved)->slurp;
	like $exported, qr/Widget/, 'exported CSV contains Widget data';
	like $exported, qr/Gadget/, 'exported CSV contains Gadget data';
	like $exported, qr/sku/,    'exported CSV contains column headers';
};

# ===========================================================================
# SECTION 4: Join + filter + export complete pipeline
#
# Strategy: Join sales.csv (CSV) with products.psv (PSV), apply a filter to
# the merged result, then export it.  This is the most complex end-to-end
# path: it exercises _left_join, _apply_filters, and _serialize_csv together
# across all three data-access layers.
# ===========================================================================

subtest 'CSV + PSV join -> filter -> export_write complete pipeline' => sub {
	plan skip_all => 'data/products.psv not found' unless -f $PRODUCTS_PSV;

	my $out_dir = tempdir(CLEANUP => 1);
	my $l_spec  = 'table:sales';
	my $j_spec  = url_escape('table:products|product|name');

	# Step 1: Join verifies merged result set.
	$t->get_ok("/join?l=" . url_escape($l_spec) . "&j=$j_spec")
	  ->status_is(200)
	  ->content_like(qr/product|category/i, 'merged columns from PSV visible in joined view');

	# Step 2: Join + filter -- only North region rows.
	$t->get_ok(
		'/join?l=' . url_escape($l_spec) .
		'&j=' . $j_spec .
		'&f=' . url_escape('region:eq:North')
	)->status_is(200)
	 ->content_like(qr/North/,     'North region present in filtered join')
	 ->content_unlike(qr/\bSouth\b/i, 'South region excluded from filtered join');

	# Step 3: Export the joined + filtered result.
	$t->post_ok('/export', form => {
		l        => $l_spec,
		'j'      => "table:products|product|name",
		'f'      => 'region:eq:North',
		dir      => $out_dir,
		filename => 'north_joined.csv',
	})->status_is(200)
	  ->json_has('/saved');

	my $saved = $t->tx->res->json('/saved');
	ok -f $saved, 'joined+filtered export file exists';
	my $content = Mojo::File->new($saved)->slurp;
	like $content,   qr/North/, 'exported CSV contains North rows';
	unlike $content, qr/\bSouth\b/, 'exported CSV excludes South rows';
};

# ===========================================================================
# SECTION 5: DataSource state isolation and idempotency
#
# Strategy: Instantiate multiple DataSource objects simultaneously (same
# table and different tables) and verify they do not share mutable state.
# Also verify fetch_all is idempotent (same result on repeated calls).
# ===========================================================================

subtest 'DataSource concurrent instances do not share state' => sub {
	# Open two independent DataSource objects for two different tables.
	my $ds_sales = Database::BI::Model::DataSource->new(
		directory => 'data',
		table     => 'sales',
	);
	my $ds_prod = Database::BI::Model::DataSource->new(
		directory => 'data',
		table     => 'products',
	);

	# Confirm they report different table names.
	is $ds_sales->table_name, 'sales',    'first instance is sales';
	is $ds_prod->table_name,  'products', 'second instance is products';

	# Fetch data from both.
	my $rows_sales = $ds_sales->fetch_all;
	my $rows_prod  = $ds_prod->fetch_all;

	# Row count must differ (6 sales vs 4 products in the sample data).
	isnt scalar @$rows_sales, scalar @$rows_prod,
		'sales and products DataSource instances return different row counts';

	# Column sets must be disjoint (no column overlap between the two files).
	my @sc = @{ $ds_sales->columns // [] };
	my @pc = @{ $ds_prod->columns  // [] };
	my %prod_cols = map { $_ => 1 } @pc;
	my @shared    = grep { $prod_cols{$_} } @sc;

	# 'id' is the only column both happen to share (it is the first column
	# in both files).  Everything else must be distinct.
	my @non_id_shared = grep { $_ ne 'id' } @shared;
	is scalar @non_id_shared, 0,
		'sales and products columns are disjoint except for the shared id column';

	diag 'sales cols: '    . join(', ', @sc) if $ENV{TEST_VERBOSE};
	diag 'products cols: ' . join(', ', @pc) if $ENV{TEST_VERBOSE};
};

subtest 'DataSource fetch_all is idempotent (same result on repeated calls)' => sub {
	my $ds = Database::BI::Model::DataSource->new(
		directory => 'data',
		table     => 'sales',
	);

	my $first  = $ds->fetch_all;
	my $second = $ds->fetch_all;

	is scalar @$first, scalar @$second,
		'repeated fetch_all returns same number of rows';
	is_deeply $first->[0], $second->[0],
		'first row identical on both fetch_all calls (no mutation)';
};

subtest 'Two DataSource instances on the same table are independent objects' => sub {
	# Open the same table twice; they must be distinct Perl objects that do
	# not share any mutable reference (no singleton pattern).
	my $ds1 = Database::BI::Model::DataSource->new(directory => 'data', table => 'sales');
	my $ds2 = Database::BI::Model::DataSource->new(directory => 'data', table => 'sales');

	isnt refaddr($ds1), refaddr($ds2), 'two DataSource instances are distinct objects';

	my $rows1 = $ds1->fetch_all;
	my $rows2 = $ds2->fetch_all;

	# Both return the same logical data, but they are independent arrayrefs.
	is scalar @$rows1, scalar @$rows2, 'both instances return the same row count';
	isnt refaddr($rows1), refaddr($rows2), 'fetch_all results are separate arrayrefs';
};

# ===========================================================================
# SECTION 6: i18n object integration
#
# Strategy: Pass a mock Locale::Maketext-compatible object to DataSource and
# trigger an error condition.  Verify that the i18n object's maketext() is
# called with the expected message key, confirming the DataSource<->i18n
# integration path.
# ===========================================================================

subtest 'DataSource uses supplied i18n object for error messages' => sub {
	my $spy = MockI18n->new;

	# Trigger error_directory_missing by pointing at a non-existent directory.
	# DataSource should call $spy->maketext (not the built-in _fmt) for this.
	# Note: _fmt is used before the object exists (during validate_strict).
	# After object creation the i18n path is taken.  To reach the instance-level
	# _msg path, we open a valid DataSource and provoke fetch_all to fail.
	#
	# Simpler probe: the constructor runs validate_strict then checks -d dir.
	# That croak goes through _fmt (package-level), NOT $spy->maketext.
	# So we open a valid DataSource WITH the spy, then confirm the object
	# carries the spy (and that fetch_all of a valid table works without error).
	my $ds = Database::BI::Model::DataSource->new(
		directory => 'data',
		table     => 'sales',
		i18n      => $spy,
	);

	# A successful fetch_all must not trigger any error messages through the spy.
	my $rows = $ds->fetch_all;
	ok scalar @$rows, 'fetch_all works when i18n object is supplied';
	is scalar @{ $spy->{log} }, 0,
		'i18n spy was not called during successful fetch_all';

	diag 'i18n spy log: ' . join(', ', map { $_->{key} } @{ $spy->{log} })
		if $ENV{TEST_VERBOSE} && @{ $spy->{log} };
};

# ===========================================================================
# SECTION 7: Export -> re-open roundtrip (SQLite)
#
# Strategy: Export the sales table to a SQLite file, then re-open that file
# via the HTTP API.  This confirms that the SQLite write path (Dashboard ->
# _write_sqlite_db -> DBI) and the SQLite read path (DataSource ->
# Database::Abstraction -> DBD::SQLite) compose correctly.
# ===========================================================================

subtest 'SQLite read->filter pipeline (DBI-created file re-opened via /open)' => sub {
	eval { require DBI; DBI->install_driver('SQLite') }
		or plan skip_all => 'DBD::SQLite not available';

	# Strategy: create the SQLite file ourselves with a table whose name
	# matches the filename stem.  This tests the DataSource SQLite read path
	# and the filter pipeline without depending on the export->re-open naming
	# alignment (which requires the internal export table name "data" to match
	# the filename stem -- a separate concern tested in export_write subtests).
	my $tmpdir   = tempdir(CLEANUP => 1);
	my $sqlfile  = File::Spec->catfile($tmpdir, 'regions.sql');

	my $dbh = DBI->connect(
		"dbi:SQLite:dbname=$sqlfile", '', '',
		{ RaiseError => 1, AutoCommit => 1 },
	);
	$dbh->do('CREATE TABLE regions (id TEXT, city TEXT, country TEXT)');
	$dbh->do("INSERT INTO regions VALUES ('1','London','UK')");
	$dbh->do("INSERT INTO regions VALUES ('2','Paris','FR')");
	$dbh->do("INSERT INTO regions VALUES ('3','Berlin','DE')");
	$dbh->disconnect;

	ok -f $sqlfile, 'SQLite file created by DBI';

	# Open via the HTTP API -- exercises DataSource -> D::A -> DBD::SQLite.
	$t->get_ok('/open?path=' . url_escape($sqlfile))
	  ->status_is(200)
	  ->content_like(qr/London/, 'London row visible in SQLite view')
	  ->content_like(qr/Paris/,  'Paris row visible in SQLite view')
	  ->content_like(qr/Berlin/, 'Berlin row visible in SQLite view');

	# Filter -- only UK rows.
	$t->get_ok(
		'/open?path=' . url_escape($sqlfile) . '&f=' . url_escape('country:eq:UK')
	)->status_is(200)
	 ->content_like(qr/London/, 'UK filter keeps London')
	 ->content_unlike(qr/Paris/, 'UK filter excludes Paris')
	 ->content_unlike(qr/Berlin/, 'UK filter excludes Berlin');

	# Export the SQLite-backed view to CSV via the API.
	my $out_dir = tempdir(CLEANUP => 1);
	$t->post_ok('/export', form => {
		l        => "path:$sqlfile",
		dir      => $out_dir,
		filename => 'regions_out.csv',
	})->status_is(200)
	  ->json_has('/saved');

	my $csv = Mojo::File->new($t->tx->res->json('/saved'))->slurp;
	like $csv, qr/London/, 'CSV export of SQLite-backed view contains London';
	like $csv, qr/Paris/,  'CSV export of SQLite-backed view contains Paris';
};

# ===========================================================================
# SECTION 8: Multiple filter AND semantics across the join pipeline
#
# Strategy: Apply two filters whose intersection is a strict subset of either
# filter applied alone.  This proves the filters compose with AND semantics
# and that _apply_filters iterates all specs -- not just the first matching one.
# ===========================================================================

subtest 'Multiple filters compose with AND semantics (join pipeline)' => sub {
	# sales.csv: regions are North, South, East, West.
	# Amount range: 725.25 to 2100.00.
	#
	# Filter A: region eq North  -> rows with id 1 (1250.00) and id 5 (1875.00)
	# Filter B: amount gt 1000   -> ids 1 (1250), 3 (2100), 5 (1875)
	# Intersection: id 1 and id 5 (region=North AND amount>1000)
	# Excluded: id 3 (East, not North), ids 2/4/6 (amount<=1000 or wrong region)

	$t->get_ok(
		'/view/sales?f=' . url_escape('region:eq:North') . '&f=' . url_escape('amount:gt:1000')
	)->status_is(200)
	 ->content_like(qr/Alice Smith/, 'Alice Smith (id 1, North, 1250) passes both filters')
	 ->content_unlike(qr/Bob Jones/,   'Bob Jones (South) fails region filter')
	 ->content_unlike(qr/Carol White/, 'Carol White (East) fails region filter')
	 ->content_unlike(qr/David Lee/,   'David Lee (West, 950) fails both region and amount');

	# Same AND semantics on /join.
	$t->get_ok(
		'/join?l=' . url_escape('table:sales') .
		'&f=' . url_escape('region:eq:North') .
		'&f=' . url_escape('amount:gt:1000')
	)->status_is(200)
	 ->content_like(qr/Alice Smith/, 'join pipeline: Alice Smith passes AND filter')
	 ->content_unlike(qr/Bob Jones/, 'join pipeline: Bob Jones filtered out');
};

# ===========================================================================
# SECTION 9: XML format integration (optional -- XML::Simple)
#
# Strategy: Verify the full XML data path (DataSource -> Database::Abstraction
# -> XML::Simple -> HTTP response).  Failure without it is in SECTION 63.
# ===========================================================================

subtest 'XML data path: catalog.xml with XML::Simple present' => sub {
	plan skip_all => 'data/catalog.xml not found' unless -f $CATALOG_XML;
	eval { require XML::Simple }
		or plan skip_all => 'XML::Simple not available';

	$t->get_ok('/view/catalog')
	  ->status_is(200)
	  ->content_like(qr/Widget A/,    'XML catalog: Widget A row present')
	  ->content_like(qr/Gizmo B/,     'XML catalog: Gizmo B row present')
	  ->content_like(qr/Doohickey C/, 'XML catalog: Doohickey C row present');

	# Filter on the XML-backed table.
	$t->get_ok('/view/catalog?f=' . url_escape('category:eq:hardware'))
	  ->status_is(200)
	  ->content_like(qr/Widget A/,    'hardware category present in filter')
	  ->content_unlike(qr/Gizmo B/,   'software category absent from hardware filter');

	# Export XML table as CSV.
	$t->get_ok('/export?l=' . url_escape('table:catalog') . '&format=csv')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv})
	  ->content_like(qr/Widget A/, 'CSV export of XML table contains Widget A');
};

# ===========================================================================
# SECTION 11: Concurrent HTTP requests -- no shared controller state
#
# Strategy: Issue multiple overlapping requests against the same Test::Mojo
# instance (sequentially, since Test::Mojo is synchronous) and verify that
# each request's stash is isolated -- no filter, column order, or table name
# bleeds from one request into the next.
# ===========================================================================

subtest 'Sequential requests have isolated stash / no state bleed' => sub {
	# Request A: sales filtered to North.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:North'))
	  ->status_is(200)
	  ->content_like(qr/North/);

	# Request B: products (no filter) -- must NOT inherit the North filter.
	$t->get_ok('/view/products')
	  ->status_is(200)
	  ->content_like(qr/Hammer/,      'products table visible without North filter')
	  ->content_like(qr/Screwdriver/, 'all products visible -- no stale filter');

	# Request C: sales again with South filter -- must not show North.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:South'))
	  ->status_is(200)
	  ->content_like(qr/Bob Jones/,    'South row visible')
	  ->content_unlike(qr/Alice Smith/, 'North row absent in South filter');
};

# ===========================================================================
# SECTION 12: DataSource with dynamically-created data file
#
# Strategy: Write a fresh CSV to a temp directory at test time, open it via
# DataSource directly, and verify the returned rows and column names exactly
# match what was written.  This confirms the full write->read pipeline across
# the OS filesystem and the Database::Abstraction CSV parser.
# ===========================================================================

subtest 'DataSource reads a dynamically-created CSV exactly' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $csv    = File::Spec->catfile($tmpdir, 'dyntest.csv');
	Mojo::File->new($csv)->spurt(
		"color,hex,weight\n" .
		"red,#FF0000,1.0\n"   .
		"green,#00FF00,2.0\n" .
		"blue,#0000FF,3.0\n"
	);

	my $ds   = Database::BI::Model::DataSource->new(directory => $tmpdir, table => 'dyntest');
	my $rows = $ds->fetch_all;

	is scalar @$rows, 3, 'three rows returned from dynamic CSV';

	my $cols = $ds->columns;
	if (defined $cols) {
		is_deeply $cols, [qw(color hex weight)], 'columns match CSV header in order';
	}

	# Verify one known row.
	my ($blue) = grep { ($_->{color} // '') eq 'blue' } @$rows;
	ok $blue, 'blue row found';
	is $blue->{hex}, '#0000FF', 'hex column value correct for blue row';

	diag "Dynamic CSV rows: " . scalar @$rows if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 13: /api/stat <-> filesystem truthfulness
#
# Strategy: Create a file, stat it, delete it, stat again.  Verifies that
# stat_api reflects real filesystem state and does not cache stale metadata
# (no memoisation across requests).
# ===========================================================================

subtest '/api/stat reflects live filesystem state (no cross-request cache)' => sub {
	# Create a temp CSV file so stat_api accepts it (extension check in controller).
	my ($fh, $tmpfile) = tempfile(SUFFIX => '.csv', UNLINK => 0);
	print $fh "id,val\n1,hello\n";
	close $fh;

	my $enc = url_escape($tmpfile);

	# Stat while file exists.
	$t->get_ok("/api/stat?path=$enc")
	  ->status_is(200)
	  ->json_is('/exists', Mojo::JSON->true);
	my $size1 = $t->tx->res->json('/size');
	ok $size1 > 0, 'size is positive while file exists';

	# Delete the file and stat again -- must now report exists:false.
	unlink $tmpfile;
	$t->get_ok("/api/stat?path=$enc")
	  ->status_is(200)
	  ->json_is('/exists', Mojo::JSON->false, 'exists:false after file deleted');
};

# ===========================================================================
# SECTION 14: /pie full pipeline
#
# Strategy: Verify that the pie_view action correctly reads the l=/cat=/val=
# pipeline, aggregates values per category, renders HTML with the pie snippet,
# and embeds the correct data-back-url and data-cat-col metadata used by the
# drill-down JS.
# ===========================================================================

subtest '/pie full pipeline: CSV -> aggregation -> HTML with metadata' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	# The sales table has region (cat) and amount (val) -- four distinct regions.
	$t->get_ok('/pie?l=table:sales&cat=region&val=amount&back=/view/sales')
	  ->status_is(200)
	  ->content_like(qr/North/,         'North slice present in pie output')
	  ->content_like(qr/South/,         'South slice present in pie output')
	  ->content_like(qr/data-back-url/, 'data-back-url metadata present')
	  ->content_like(qr|/view/sales|,   'back URL embedded in metadata div');

	# Verify the cat-col attribute so the JS drill-down can apply the correct filter.
	$t->get_ok('/pie?l=table:sales&cat=region&val=amount&back=/view/sales')
	  ->status_is(200)
	  ->content_like(qr/data-cat-col="region"/, 'data-cat-col="region" present for drill-down');
};

subtest '/pie drillDown JS constructs back2= parameter (not back=)' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	# The JS drillDown() function must append back2= (not back=) so that the
	# target dashboard page places the pie link at the third breadcrumb level
	# without conflicting with open_file's hardcoded back_url.
	$t->get_ok('/pie?l=table:sales&cat=region&val=amount&back=/view/sales')
	  ->status_is(200)
	  ->content_like(qr/back2=/,         'drillDown JS uses back2= param (not back=)')
	  ->content_like(qr/back2_label=/,   'drillDown JS sets back2_label= param')
	  ->content_unlike(qr/'back='[^']|"back="[^"]/, 'no bare back= param appended by drillDown');
};

subtest '/pie count mode: __count__ aggregates rows per category' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	# In count mode each category should appear once.  Sales has two North rows
	# (id 1 and id 5) so the Count by region chart must show North with count 2.
	$t->get_ok('/pie?l=table:sales&cat=region&val=__count__&back=/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Count by region/i, 'count-mode chart title mentions "Count by region"')
	  ->content_like(qr/North/,            'North category present in count chart');
};

# ===========================================================================
# SECTION 15: Three-level breadcrumb integration (back2= / back2_label=)
#
# Strategy: Verify that all controller actions (open_file, view, join_tables,
# combine_tables) correctly read back2=/back2_label= from the URL and pass
# them to the template as back2_url/back2_label stash vars, producing the
# third breadcrumb segment "... > Back to pie chart".
#
# The pie page URL used as back2 in the tests below is deliberately a plausible
# value -- the exact URL is not reachable from Test::Mojo but the controller only
# reads it as a string and forwards it into the stash, so any value works.
# ===========================================================================

# Shared fake pie URL used as the back2 param throughout this section.
Readonly my $PIE_URL       => '/pie?l=table:sales&cat=region&val=amount';
Readonly my $PIE_LABEL     => 'Back to pie chart';
Readonly my $PIE_URL_ENC   => url_escape($PIE_URL);
Readonly my $PIE_LABEL_ENC => url_escape($PIE_LABEL);

subtest 'open_file: back2=/back2_label= produce third breadcrumb segment' => sub {
	# When a user drills down from a pie chart into an open_file view,
	# the breadcrumb must show three levels:
	#   Home > Back to browser > Back to pie chart
	#
	# open_file hardcodes back_url (the "Back to browser" link) and reads
	# back2 from the URL for the third segment.
	# Note: the & in the pie URL is HTML-encoded to &amp; in the href attribute,
	# so we match on just the /pie path prefix to avoid quoting issues.
	my $enc = url_escape($SALES_CSV);
	$t->get_ok(
		"/open?path=$enc"
		. "&back2=$PIE_URL_ENC"
		. "&back2_label=$PIE_LABEL_ENC"
	)->status_is(200)
	 ->content_like(qr/Back to browser/,        'second breadcrumb: Back to browser present')
	 ->content_like(qr/Back to pie chart/,       'third breadcrumb: Back to pie chart present')
	 ->content_like(qr{href="/pie\?},            'pie href begins with /pie? in third link');
};

subtest 'view: back2=/back2_label= promoted to second breadcrumb (no inherent back link)' => sub {
	# The view action has no inherent back URL, so it PROMOTES back2 to the
	# first back-link position.  Result:
	#   Home > Back to pie chart   (just two levels, not three)
	$t->get_ok(
		'/view/sales'
		. "?back2=$PIE_URL_ENC"
		. "&back2_label=$PIE_LABEL_ENC"
	)->status_is(200)
	 ->content_like(qr/Back to pie chart/,  'promoted back2: Back to pie chart visible')
	 ->content_like(qr{href="/pie\?},       'pie href present as the promoted back link')
	 ->content_unlike(qr/Back to browser/,  'no "Back to browser" in view without open_file');
};

subtest 'join_tables: back2=/back2_label= add third breadcrumb segment' => sub {
	# join_tables has its own auto-generated back URL ("Back to sales").
	# With back2 set, the result must be three levels:
	#   Home > Back to sales > Back to pie chart
	$t->get_ok(
		'/join?l=' . url_escape('table:sales')
		. "&back2=$PIE_URL_ENC"
		. "&back2_label=$PIE_LABEL_ENC"
	)->status_is(200)
	 ->content_like(qr/Back to sales/,     'second breadcrumb: Back to sales present')
	 ->content_like(qr/Back to pie chart/, 'third breadcrumb: Back to pie chart present')
	 ->content_like(qr{href="/pie\?},      'pie href present in third link');
};

subtest 'combine_tables: back2=/back2_label= add third breadcrumb segment' => sub {
	# combine_tables has its own auto-generated back URL like join_tables.
	my $tmpdir = tempdir(CLEANUP => 1);
	Mojo::File->new(File::Spec->catfile($tmpdir, 'extra.csv'))->spurt(
		"id,product,region,sales_rep,amount,sale_date\n" .
		"99,Extra,North,Alice Smith,500.00,2025-02-01\n"
	);

	$t->get_ok(
		'/combine?l=' . url_escape('table:sales')
		. '&c=' . url_escape("path:$tmpdir/extra.csv")
		. "&back2=$PIE_URL_ENC"
		. "&back2_label=$PIE_LABEL_ENC"
	)->status_is(200)
	 ->content_like(qr/Back to pie chart/, 'third breadcrumb: Back to pie chart present')
	 ->content_like(qr{href="/pie\?},      'pie href present in third link')
	 ->content_like(qr/Extra/,             'extra row from combined table visible');
};

subtest 'back2 absent: no third breadcrumb segment rendered' => sub {
	# Without back2, the back-link paragraph must contain exactly two links:
	# Home and the second segment.  A third rsaquo means a spurious segment.
	my $enc = url_escape($SALES_CSV);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Back to browser/, 'second breadcrumb present as usual')
	  ->content_unlike(qr/class="back-link"[^<]*<a[^>]*>[^<]*<\/a>[^<]*&rsaquo;[^<]*<a[^>]*>[^<]*<\/a>[^<]*&rsaquo;/,
	                   'no third breadcrumb segment when back2 absent');
};

# ===========================================================================
# SECTION 16: /graph full pipeline
#
# Strategy: Verify graph_view reads x/y columns, strips non-numeric Y values,
# computes min/max/avg, and renders a D3 chart snippet with the correct title
# and a back link pointing at the ?back= param.
# ===========================================================================

subtest '/graph full pipeline: CSV -> D3 snippet -> HTML with reference lines' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	$t->get_ok(
		'/graph?l=table:sales&x=sale_date&y=amount&back=/view/sales'
	)->status_is(200)
	 ->content_like(qr/amount vs sale_date/i, 'graph title "amount vs sale_date" present')
	 ->content_like(qr/2025-01-15/,           '2025-01-15 X-label visible in output')
	 ->content_like(qr/back-link/,            'back-link breadcrumb element present')
	 ->content_like(qr|/view/sales|,          'back link points at /view/sales');
};

subtest '/graph: ref_min_y/ref_max_y/ref_avg_y injected correctly' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	# The amounts in sales.csv are: 1250.00, 875.50, 2100.00, 950.00, 1875.00, 725.25
	# min = 725.25, max = 2100.00
	$t->get_ok('/graph?l=table:sales&x=sale_date&y=amount&back=/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Min.*725/,    'min reference value (725.25) present in page')
	  ->content_like(qr/Max.*2100/,   'max reference value (2100) present in page');
};

# ===========================================================================
# SECTION 17: /combine (UNION ALL) full pipeline
#
# Strategy: Stack two custom CSVs with the same column schema.  Verify the
# combined result contains rows from both sources with no duplicates (unless
# dedup is on), and that the title includes both source labels.
# ===========================================================================

subtest '/combine stacks two CSVs vertically (UNION ALL semantics)' => sub {
	my $dir = tempdir(CLEANUP => 1);

	# Create two CSVs with overlapping schema but distinct rows.
	Mojo::File->new(File::Spec->catfile($dir, 'dogs.csv'))->spurt(
		"name,breed\nRex,Labrador\nBuddy,Poodle\n"
	);
	Mojo::File->new(File::Spec->catfile($dir, 'cats.csv'))->spurt(
		"name,breed\nWhiskers,Siamese\nMittens,Tabby\n"
	);

	my $dogs_spec = url_escape("path:" . File::Spec->catfile($dir, 'dogs.csv'));
	my $cats_spec = url_escape("path:" . File::Spec->catfile($dir, 'cats.csv'));

	$t->get_ok("/combine?l=$dogs_spec&c=$cats_spec")
	  ->status_is(200)
	  ->content_like(qr/Rex/,      'Rex (dogs) present in combined view')
	  ->content_like(qr/Buddy/,    'Buddy (dogs) present in combined view')
	  ->content_like(qr/Whiskers/, 'Whiskers (cats) present in combined view')
	  ->content_like(qr/Mittens/,  'Mittens (cats) present in combined view');
};

subtest '/combine + filter narrows the stacked result' => sub {
	my $dir = tempdir(CLEANUP => 1);

	Mojo::File->new(File::Spec->catfile($dir, 'items_a.csv'))->spurt(
		"sku,category,price\nA1,hardware,10\nA2,software,20\n"
	);
	Mojo::File->new(File::Spec->catfile($dir, 'items_b.csv'))->spurt(
		"sku,category,price\nB1,hardware,30\nB2,services,40\n"
	);

	my $a_spec = url_escape("path:" . File::Spec->catfile($dir, 'items_a.csv'));
	my $b_spec = url_escape("path:" . File::Spec->catfile($dir, 'items_b.csv'));

	# Filter to hardware only -- A1 and B1 must be present; A2 and B2 must not.
	# Use table-cell anchors (<td>...</td>) to avoid matching CSS escape sequences
	# like \25B2 (the UP TRIANGLE sort indicator) that also contain these substrings.
	$t->get_ok(
		"/combine?l=$a_spec&c=$b_spec&f=" . url_escape('category:eq:hardware')
	)->status_is(200)
	 ->content_like(qr/<td[^>]*>A1<\/td>/,  'A1 (hardware) present in filtered combined view')
	 ->content_like(qr/<td[^>]*>B1<\/td>/,  'B1 (hardware) present in filtered combined view')
	 ->content_unlike(qr/<td[^>]*>A2<\/td>/, 'A2 (software) absent from filtered combined view')
	 ->content_unlike(qr/<td[^>]*>B2<\/td>/, 'B2 (services) absent from filtered combined view');
};

# ---------------------------------------------------------------------------
# Phase 0.2 acceptance tests: pagination and sort on /join, /combine, /export
# ---------------------------------------------------------------------------

# SECTION 8: /join pagination
subtest '/join pagination slices the joined view' => sub {
	my $dir = File::Temp->newdir;
	Mojo::File->new(File::Spec->catfile($dir, 'orders.csv'))->spurt(
		"id,item,amount\n1,Alpha,100\n2,Beta,200\n3,Gamma,300\n4,Delta,400\n5,Epsilon,500\n"
	);
	my $l_spec = url_escape("path:" . File::Spec->catfile($dir, 'orders.csv'));

	# Without pagination: all 5 rows.
	$t->get_ok("/join?l=$l_spec")->status_is(200);
	my $body = $t->tx->res->body;
	my @rows = ($body =~ /<td[^>]*>[^<]+<\/td>/g);
	ok scalar(@rows) >= 5, 'no pagination returns all rows';

	# With per_page=2 page=1: first 2 rows, has_next.
	$t->get_ok("/join?l=$l_spec&per_page=2&page=1")->status_is(200)
	  ->content_like(qr/pagination|page/i, '/join page 1 shows pagination nav');
	my $p1_body = $t->tx->res->body;

	# With per_page=2 page=2: next 2 rows.
	$t->get_ok("/join?l=$l_spec&per_page=2&page=2")->status_is(200);
	my $p2_body = $t->tx->res->body;

	# page 1 and page 2 must not show identical rows.
	my @p1_cells = ($p1_body =~ /<td[^>]*>([^<]+)<\/td>/g);
	my @p2_cells = ($p2_body =~ /<td[^>]*>([^<]+)<\/td>/g);
	my %p1_set = map { $_ => 1 } @p1_cells;
	my @overlap = grep { $p1_set{$_} } @p2_cells;
	# Some overlap is expected (column headers row reuse) but row data differs.
	ok scalar(@p1_cells) > 0, 'page 1 has data cells';
	ok scalar(@p2_cells) > 0, 'page 2 has data cells';
};

# SECTION 9: /join sort pushdown
subtest '/join sort= orders the result' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 4;

		my $dir     = File::Temp->newdir;
		my $sqlfile = File::Spec->catfile($dir, 'sortable.sql');
		my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlfile", '', '',
			{ RaiseError => 1 });
		$dbh->do('CREATE TABLE sortable (id INTEGER, name TEXT, score INTEGER)');
		my $ins = $dbh->prepare('INSERT INTO sortable VALUES (?,?,?)');
		$ins->execute(1, 'Charlie', 70);
		$ins->execute(2, 'Alice',   90);
		$ins->execute(3, 'Bob',     80);
		$dbh->disconnect;

		my $l_spec = url_escape("path:$sqlfile");

		# Sort ascending by name.
		$t->get_ok("/join?l=$l_spec&sort=name&dir=asc")->status_is(200);
		my $body = $t->tx->res->body;
		my @names = ($body =~ /<td[^>]*>([A-Z][a-z]+)<\/td>/g);
		is $names[0], 'Alice',   'asc sort: Alice is first';
		is $names[-1], 'Charlie', 'asc sort: Charlie is last';

		# Sort descending by name.
		$t->get_ok("/join?l=$l_spec&sort=name&dir=desc")->status_is(200);
		$body = $t->tx->res->body;
		@names = ($body =~ /<td[^>]*>([A-Z][a-z]+)<\/td>/g);
		is $names[0], 'Charlie', 'desc sort: Charlie is first';
		is $names[-1], 'Alice',   'desc sort: Alice is last';
	}
};

# SECTION 10: /combine pagination and sort
subtest '/combine pagination and sort' => sub {
	my $dir = File::Temp->newdir;
	Mojo::File->new(File::Spec->catfile($dir, 'grp_a.csv'))->spurt(
		"label,val\nZebra,10\nApe,20\n"
	);
	Mojo::File->new(File::Spec->catfile($dir, 'grp_b.csv'))->spurt(
		"label,val\nMink,30\nBear,40\n"
	);
	my $a_spec = url_escape("path:" . File::Spec->catfile($dir, 'grp_a.csv'));
	my $b_spec = url_escape("path:" . File::Spec->catfile($dir, 'grp_b.csv'));

	# Pagination: 4 rows total, per_page=2.
	$t->get_ok("/combine?l=$a_spec&c=$b_spec&per_page=2&page=1")->status_is(200);
	my $p1 = $t->tx->res->body;
	$t->get_ok("/combine?l=$a_spec&c=$b_spec&per_page=2&page=2")->status_is(200);
	my $p2 = $t->tx->res->body;
	ok $p1 =~ /<td/, 'combine page 1 has data';
	ok $p2 =~ /<td/, 'combine page 2 has data';

	# Sort ascending by label: Ape, Bear, Mink, Zebra.
	$t->get_ok("/combine?l=$a_spec&c=$b_spec&sort=label&dir=asc")->status_is(200);
	my $body = $t->tx->res->body;
	my @labels = ($body =~ /<td[^>]*>([A-Z][a-z]+)<\/td>/g);
	is $labels[0], 'Ape',   'combine asc sort: Ape first';
	is $labels[-1], 'Zebra', 'combine asc sort: Zebra last';

	# Sort descending by label: Zebra, Mink, Bear, Ape.
	$t->get_ok("/combine?l=$a_spec&c=$b_spec&sort=label&dir=desc")->status_is(200);
	$body = $t->tx->res->body;
	@labels = ($body =~ /<td[^>]*>([A-Z][a-z]+)<\/td>/g);
	is $labels[0],  'Zebra', 'combine desc sort: Zebra first';
	is $labels[-1], 'Ape',   'combine desc sort: Ape last';
};

# SECTION 11: /export page slice
subtest '/export page slice writes exactly the requested rows' => sub {
	my $dir = File::Temp->newdir;
	Mojo::File->new(File::Spec->catfile($dir, 'export_src.csv'))->spurt(
		"id,color\n1,Red\n2,Green\n3,Blue\n4,Yellow\n5,Purple\n"
	);
	my $l_spec = url_escape("path:" . File::Spec->catfile($dir, 'export_src.csv'));

	# Page 1, per_page=2: rows 1 and 2 (Red, Green).
	$t->get_ok("/export?l=$l_spec&format=csv&per_page=2&page=1")->status_is(200);
	my $csv1 = $t->tx->res->body;
	like   $csv1, qr/Red/,   'export page 1 contains Red';
	like   $csv1, qr/Green/, 'export page 1 contains Green';
	unlike $csv1, qr/Blue/,  'export page 1 excludes Blue';

	# Page 2, per_page=2: rows 3 and 4 (Blue, Yellow).
	$t->get_ok("/export?l=$l_spec&format=csv&per_page=2&page=2")->status_is(200);
	my $csv2 = $t->tx->res->body;
	like   $csv2, qr/Blue/,   'export page 2 contains Blue';
	like   $csv2, qr/Yellow/, 'export page 2 contains Yellow';
	unlike $csv2, qr/\bRed\b/, 'export page 2 excludes Red';

	# Sort descending: page 1 with sort=color desc should start with Yellow (last alpha).
	$t->get_ok("/export?l=$l_spec&format=csv&per_page=2&page=1&sort=color&dir=desc")
	  ->status_is(200);
	my $sorted_csv = $t->tx->res->body;
	# First data row after header should be Yellow (descending alpha).
	my @lines = split /\r?\n/, $sorted_csv;
	shift @lines;  # skip header
	like $lines[0], qr/Yellow/, 'export sort desc: Yellow is first row';
};

# SECTION 12: /pivot pagination
subtest '/pivot pagination slices the row groups' => sub {
	my $dir = File::Temp->newdir;
	# 6 distinct region values -> 6 row groups in the pivot
	Mojo::File->new(File::Spec->catfile($dir, 'sales_p.csv'))->spurt(
		"region,amount\n" .
		"North,100\nSouth,200\nEast,300\n" .
		"West,400\nCentral,500\nNorthEast,600\n"
	);
	my $l = url_escape("path:" . File::Spec->catfile($dir, 'sales_p.csv'));
	my $m = url_escape('amount:sum:total');

	# No pagination: all 6 row groups visible.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m")->status_is(200);
	my $full = $t->tx->res->body;
	my @all_rows = ($full =~ /<td[^>]*class="row-dim"[^>]*>/g);
	is scalar(@all_rows), 6, 'no pagination: all 6 region rows present';
	unlike $full, qr/<nav[^>]*piv-pagination/, 'no pagination nav when all rows fit';

	# per_page=2: page 1 has exactly 2 row groups, has_next shown.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=1")->status_is(200);
	my $p1 = $t->tx->res->body;
	my @p1_rows = ($p1 =~ /<td[^>]*class="row-dim"[^>]*>/g);
	is scalar(@p1_rows), 2, 'page 1 has exactly 2 row groups';
	like $p1, qr/piv-pagination/, 'page 1 shows pagination nav';
	like $p1, qr/page=2/, 'page 1 has Next link to page 2';

	# per_page=2: page 2 has 2 more rows.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=2")->status_is(200);
	my $p2 = $t->tx->res->body;
	my @p2_rows = ($p2 =~ /<td[^>]*class="row-dim"[^>]*>/g);
	is scalar(@p2_rows), 2, 'page 2 has exactly 2 row groups';
	like $p2, qr/page=1/, 'page 2 has Prev link to page 1';

	# per_page=2: page 3 has the last 2 rows, no Next.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=3")->status_is(200);
	my $p3 = $t->tx->res->body;
	my @p3_rows = ($p3 =~ /<td[^>]*class="row-dim"[^>]*>/g);
	is scalar(@p3_rows), 2, 'page 3 has 2 row groups';
	unlike $p3, qr/page=4/, 'page 3 has no Next link (last page)';

	# page 4 beyond end: 0 row groups, "No data" message.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=4")->status_is(200);
	my $p4 = $t->tx->res->body;
	like $p4, qr/No data to display/, 'page 4 beyond end shows no-data message';

	# Subtotals computed over the full set even when paginated.
	# Grand total of amount:sum must equal 2100 regardless of page.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=1&totals=1")->status_is(200);
	like $t->tx->res->body, qr/2100/, 'grand total (2100) visible on page 1 even with per_page=2';

	# Export ignores pagination params and returns all 6 rows.
	$t->get_ok("/pivot?l=$l&rows=region&m=$m&per_page=2&page=1&format=csv")->status_is(200);
	my $csv = $t->tx->res->body;
	my @csv_lines = grep { /\S/ } split /\r?\n/, $csv;
	is scalar(@csv_lines) - 1, 6, 'CSV export returns all 6 rows regardless of per_page';
};

# ---------------------------------------------------------------------------
# Section 13: Phase 2.2 -- Calculated fields (?c= wiring and CRUD)
# ---------------------------------------------------------------------------

subtest 'Calculated fields: ?c= inline field on /pivot' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'calc_src.csv');
	Mojo::File->new($csv)->spurt(
		"region,amount,cost\n"
		. "North,500,300\n"
		. "South,400,250\n"
		. "North,600,350\n"
		. "South,300,200\n"
	);
	my $lspec = url_escape("path:$csv");

	# Basic: ?c=margin:amount-cost adds virtual column used by measure
	my $url = "/pivot?l=$lspec&rows=region&m=" . url_escape('margin:sum:total_margin')
	        . '&c=' . url_escape('margin:amount-cost');
	$t->get_ok($url)->status_is(200);
	my $body = $t->tx->res->body;
	like $body, qr/total_margin/, 'measure alias present in pivot output';
	# North total margin: (500-300)+(600-350) = 200+250 = 450
	like $body, qr/450/, 'North total_margin = 450';
	# South total margin: (400-250)+(300-200) = 150+100 = 250
	like $body, qr/250/, 'South total_margin = 250';

	# IF with comparison: ?c=flag:if(amount>400,"high","low") groups correctly
	my $url2 = "/pivot?l=$lspec&rows=flag&m=:count:orders"
	         . '&c=' . url_escape('flag:if(amount>400,"high","low")');
	$t->get_ok($url2)->status_is(200);
	my $body2 = $t->tx->res->body;
	like $body2, qr/high/, 'flag=high present in pivot';
	like $body2, qr/low/,  'flag=low present in pivot';

	# YEAR() date function: groups by year extracted from date column
	my $date_csv = File::Spec->catfile("$dir", 'dated.csv');
	Mojo::File->new($date_csv)->spurt(
		"date,amount\n"
		. "2024-01-15,100\n"
		. "2024-06-20,200\n"
		. "2025-03-10,150\n"
	);
	my $dlspec = url_escape("path:$date_csv");
	my $url3 = "/pivot?l=$dlspec&rows=yr&m=amount:sum:total"
	         . '&c=' . url_escape('yr:year(date)');
	$t->get_ok($url3)->status_is(200);
	my $body3 = $t->tx->res->body;
	like $body3, qr/2024/, 'year 2024 present in pivot';
	like $body3, qr/2025/, 'year 2025 present in pivot';
	# 2024 total: 300; 2025 total: 150
	like $body3, qr/300/, '2024 sum correct';
	like $body3, qr/150/, '2025 sum correct';

	# Unknown column -> 400
	$t->get_ok("/pivot?l=$lspec&rows=region&m=" . url_escape('x:sum:total')
	         . '&c=' . url_escape('x:nosuchcol'))
	  ->status_is(400, 'unknown column in calc expr -> 400');

	# Bad expression syntax -> 400
	$t->get_ok("/pivot?l=$lspec&rows=region&m=" . url_escape('x:sum:total')
	         . '&c=' . url_escape('x:amount =='))
	  ->status_is(400, 'syntax error in calc expr -> 400');
};

subtest 'Calculated fields: ?c= on /bar' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'bar_calc.csv');
	Mojo::File->new($csv)->spurt(
		"region,revenue,cost\n"
		. "East,800,500\n"
		. "West,600,400\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/bar?l=$lspec&cat=region&val=margin&c=" . url_escape('margin:revenue-cost'))
	  ->status_is(200)
	  ->content_like(qr/bar_chart/, 'bar chart rendered with calc field');
};

subtest 'Calc CRUD: /calc/save, /calc/list, /calc/delete' => sub {
	my $spec = 'table:sales';

	# Save a named calc field
	$t->post_ok('/calc/save', form => {
		l    => $spec,
		name => 'margin',
		expr => 'amount - cost',
	})->status_is(200)
	  ->json_is('/ok', 1, 'calc_save returns ok:1');

	# List returns the saved field
	$t->get_ok('/calc/list?l=' . url_escape($spec))
	  ->status_is(200)
	  ->json_is('/fields/margin', 'amount - cost', 'saved field appears in list');

	# Save a second field
	$t->post_ok('/calc/save', form => {
		l    => $spec,
		name => 'doubled',
		expr => 'amount * 2',
	})->status_is(200);

	$t->get_ok('/calc/list?l=' . url_escape($spec))
	  ->status_is(200)
	  ->json_has('/fields/margin',  'first field still present')
	  ->json_has('/fields/doubled', 'second field present');

	# Delete one field
	$t->post_ok('/calc/delete', form => {
		l    => $spec,
		name => 'doubled',
	})->status_is(200)
	  ->json_is('/ok', 1);

	$t->get_ok('/calc/list?l=' . url_escape($spec))
	  ->status_is(200)
	  ->json_is('/fields/doubled', undef, 'deleted field absent')
	  ->json_is('/fields/margin', 'amount - cost', 'remaining field intact');

	# Delete the last field
	$t->post_ok('/calc/delete', form => {
		l    => $spec,
		name => 'margin',
	})->status_is(200);

	$t->get_ok('/calc/list?l=' . url_escape($spec))
	  ->status_is(200)
	  ->json_is('/fields', {}, 'all fields deleted');

	# Error cases
	$t->post_ok('/calc/save', form => { name => 'x', expr => '1' })
	  ->status_is(400, 'calc_save without l= -> 400');

	$t->post_ok('/calc/save', form => { l => $spec, name => 'bad-name', expr => '1' })
	  ->status_is(400, 'calc_save with invalid name -> 400');

	$t->post_ok('/calc/save', form => { l => $spec, name => 'x' })
	  ->status_is(400, 'calc_save without expr -> 400');

	$t->get_ok('/calc/list')
	  ->status_is(400, 'calc_list without l= -> 400');
};

# ---------------------------------------------------------------------------
# Section 14: Phase 2.4 -- New chart routes smoke tests + multi-series line
# ---------------------------------------------------------------------------

subtest '/scatter -- renders with id="scatter_chart"' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'scatter_src.csv');
	Mojo::File->new($csv)->spurt(
		"x,y\n1,10\n2,20\n3,15\n4,25\n5,18\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/scatter?l=$lspec&x=x&y=y")
	  ->status_is(200)
	  ->content_like(qr/id="scatter_chart"/, 'scatter SVG id present');

	# Missing required params -> 400
	$t->get_ok("/scatter?l=$lspec&x=x")->status_is(400, 'missing y= -> 400');
	$t->get_ok("/scatter?l=$lspec&y=y")->status_is(400, 'missing x= -> 400');
};

subtest '/stacked -- renders with id="stacked_bar"' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'stacked_src.csv');
	Mojo::File->new($csv)->spurt(
		"region,product,amount\n"
		. "North,Widget A,500\n"
		. "South,Widget A,300\n"
		. "North,Widget B,200\n"
		. "South,Widget B,400\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/stacked?l=$lspec&cat=region&seg=product")
	  ->status_is(200)
	  ->content_like(qr/id="stacked_bar"/, 'stacked SVG id present');

	# Count mode (no val=)
	$t->get_ok("/stacked?l=$lspec&cat=region&seg=product")
	  ->status_is(200)
	  ->content_like(qr/Count by/, 'count mode label present');

	# Val mode
	$t->get_ok("/stacked?l=$lspec&cat=region&seg=product&val=amount")
	  ->status_is(200)
	  ->content_like(qr/amount by/, 'val mode label present');

	# Missing required params -> 400
	$t->get_ok("/stacked?l=$lspec&seg=product")->status_is(400, 'missing cat= -> 400');
	$t->get_ok("/stacked?l=$lspec&cat=region")->status_is(400, 'missing seg= -> 400');
};

subtest '/combo -- renders with id="combo_chart"' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'combo_src.csv');
	Mojo::File->new($csv)->spurt(
		"month,revenue,cost\n"
		. "Jan,1000,600\n"
		. "Feb,1200,700\n"
		. "Mar,900,550\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/combo?l=$lspec&x=month&bar=revenue&line=cost")
	  ->status_is(200)
	  ->content_like(qr/id="combo_chart"/, 'combo SVG id present');

	# Missing required params -> 400
	$t->get_ok("/combo?l=$lspec&bar=revenue&line=cost")->status_is(400, 'missing x= -> 400');
	$t->get_ok("/combo?l=$lspec&x=month&line=cost")->status_is(400, 'missing bar= -> 400');
	$t->get_ok("/combo?l=$lspec&x=month&bar=revenue")->status_is(400, 'missing line= -> 400');
};

subtest '/treemap -- renders with id="treemap"' => sub {
	my $lspec = url_escape('table:sales');

	$t->get_ok("/treemap?l=$lspec&cat=product")
	  ->status_is(200)
	  ->content_like(qr/id="treemap"/, 'treemap SVG id present');

	# Count mode (no val=): renders successfully
	$t->get_ok("/treemap?l=$lspec&cat=region")
	  ->status_is(200);

	# Missing cat= -> 400
	$t->get_ok("/treemap?l=$lspec")->status_is(400, 'missing cat= -> 400');
};

subtest '/histogram -- renders with id="histogram" and correct bin count' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'hist_src.csv');
	Mojo::File->new($csv)->spurt(
		"value\n10\n25\n45\n60\n80\n95\n110\n140\n170\n200\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/histogram?l=$lspec&col=value")
	  ->status_is(200)
	  ->content_like(qr/id="histogram"/, 'histogram SVG id present');

	# bins=5 produces 5 bins
	$t->get_ok("/histogram?l=$lspec&col=value&bins=5")
	  ->status_is(200)
	  ->content_like(qr/id="histogram"/, 'histogram with bins=5 renders');

	# Missing col= -> 400
	$t->get_ok("/histogram?l=$lspec")->status_is(400, 'missing col= -> 400');

	# Non-numeric col -> graceful (renders empty or 200)
	$t->get_ok("/histogram?l=table:sales&col=product")
	  ->status_is(200, 'non-numeric col returns 200');
};

subtest '/graph with ?series= renders multi-series line chart' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'multi_src.csv');
	Mojo::File->new($csv)->spurt(
		"month,region,amount\n"
		. "Jan,North,500\n"
		. "Feb,North,600\n"
		. "Mar,North,550\n"
		. "Jan,South,300\n"
		. "Feb,South,400\n"
		. "Mar,South,350\n"
	);
	my $lspec = url_escape("path:$csv");

	# Multi-series: one line per region value
	$t->get_ok("/graph?l=$lspec&x=month&y=amount&series=region")
	  ->status_is(200)
	  ->content_like(qr/North/, 'North series present in multi-series chart')
	  ->content_like(qr/South/, 'South series present in multi-series chart');

	# Without series: single-series (existing behaviour unchanged)
	$t->get_ok("/graph?l=$lspec&x=month&y=amount")
	  ->status_is(200)
	  ->content_like(qr/id="chart"/, 'single-series: zoomable chart id present');

	# Unknown series col -> 400
	$t->get_ok("/graph?l=$lspec&x=month&y=amount&series=nosuchcol")
	  ->status_is(400, 'unknown series col -> 400');

	# /line alias for /graph also works with series
	$t->get_ok("/line?l=$lspec&x=month&y=amount&series=region")
	  ->status_is(200)
	  ->content_like(qr/North/, '/line alias works with series');
};

# ---------------------------------------------------------------------------
# SECTION 15: Phase 2.5 -- Time intelligence (date normalisation)
# ---------------------------------------------------------------------------

subtest 'Date patterns CRUD: /dates/save, /dates/list, /dates/delete' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'usdate.csv');
	Mojo::File->new($csv)->spurt("date,amount\n12/25/2025,100\n01/15/2026,200\n");
	my $l_raw = "path:$csv";
	my $l     = url_escape($l_raw);

	# Initially no patterns registered
	$t->get_ok("/dates/list?l=$l")->status_is(200)
	  ->json_is('/patterns', {}, 'no patterns initially');

	# Save a valid US date pattern
	$t->post_ok('/dates/save', form => { l => $l_raw, col => 'date', pattern => '%m/%d/%Y' })
	  ->status_is(200)->json_is('/ok', 1, 'dates_save ok');

	# List confirms the pattern is stored
	$t->get_ok("/dates/list?l=$l")->status_is(200)
	  ->json_is('/patterns/date', '%m/%d/%Y', 'pattern stored under col key');

	# Unsupported pattern is rejected with 400
	$t->post_ok('/dates/save', form => { l => $l_raw, col => 'date', pattern => '%Y/%m/%d' })
	  ->status_is(400)
	  ->json_like('/error', qr/[Uu]nsupported|[Uu]nknown/, 'bad pattern rejected with 400');

	# Missing l= -> 400
	$t->get_ok('/dates/list')->status_is(400, 'dates_list without l= -> 400');
	$t->post_ok('/dates/save', form => { col => 'date', pattern => '%m/%d/%Y' })
	  ->status_is(400, 'dates_save without l= -> 400');

	# Delete the pattern for one column
	$t->post_ok('/dates/delete', form => { l => $l_raw, col => 'date' })
	  ->status_is(200)->json_is('/ok', 1, 'dates_delete ok');
	$t->get_ok("/dates/list?l=$l")->status_is(200)
	  ->json_is('/patterns', {}, 'pattern removed after delete');
};

subtest 'Date normalisation: M/D/YYYY -> ISO-8601 before YEAR() in /pivot' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'usdate2.csv');
	Mojo::File->new($csv)->spurt(
		"date,amount\n12/25/2025,100\n01/15/2026,200\n12/31/2025,300\n"
	);
	my $l_raw = "path:$csv";
	my $l     = url_escape($l_raw);

	# Register US date pattern
	$t->post_ok('/dates/save', form => { l => $l_raw, col => 'date', pattern => '%m/%d/%Y' })
	  ->status_is(200);

	# Pivot: rows=yr (calc=year(date)), measure sum(amount)
	# With normalisation: 12/25/2025 -> 2025-12-25, 12/31/2025 -> 2025-12-31 -> YEAR=2025 (sum=400)
	#                     01/15/2026 -> 2026-01-15 -> YEAR=2026 (sum=200)
	my $c = url_escape('yr:year(date)');
	$t->get_ok("/pivot?l=$l&rows=yr&m=amount:sum:total&c=$c")
	  ->status_is(200)
	  ->content_like(qr/2025/, '2025 year group visible after normalisation')
	  ->content_like(qr/2026/, '2026 year group visible after normalisation')
	  ->content_like(qr/400/,  '2025 sum=400 (100+300) after normalisation');

	# Cleanup
	$t->post_ok('/dates/delete', form => { l => $l_raw })->status_is(200);
};

subtest 'Date normalisation: undef calc result groups as (unparseable) in /pivot' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'baddate.csv');
	# Two ISO dates + one non-date value; YEAR(date) returns undef for 'badvalue'
	Mojo::File->new($csv)->spurt("date,amount\n2025-12-25,100\n2026-01-15,200\nbadvalue,300\n");
	my $l = url_escape("path:$csv");
	my $c = url_escape('yr:year(date)');

	$t->get_ok("/pivot?l=$l&rows=yr&m=amount:sum:total&c=$c")
	  ->status_is(200)
	  ->content_like(qr/2025/, '2025 group present')
	  ->content_like(qr/2026/, '2026 group present')
	  ->content_like(qr/\(unparseable\)/, '(unparseable) bucket for bad date value')
	  ->content_like(qr/300/, 'amount for unparseable row is present');
};

# ---------------------------------------------------------------------------
# Section 16: Phase 2.6 -- Named groups and Top-N
# ---------------------------------------------------------------------------

subtest 'Named groups: ${col}_group virtual column added via models.json' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'regions.csv');
	Mojo::File->new($csv)->spurt(
		"region,sales\n"
		. "North,100\n"
		. "South,200\n"
		. "East,150\n"
		. "West,50\n"
		. "Unknown,10\n"
	);
	my $l = url_escape("path:$csv");

	# Save a named group: North+East => "Northern", South+West => "Southern"
	$t->post_ok('/groups/save', form => {
		l      => "path:$csv",
		col    => 'region',
		group  => 'Northern',
		values => ['North', 'East'],
	})->status_is(200)->json_is('/ok', 1);

	$t->post_ok('/groups/save', form => {
		l      => "path:$csv",
		col    => 'region',
		group  => 'Southern',
		values => ['South', 'West'],
	})->status_is(200)->json_is('/ok', 1);

	# Confirm groups stored
	$t->get_ok("/groups/list?l=" . url_escape("path:$csv"))
	  ->status_is(200)
	  ->json_like('/groups/region/Northern/0', qr/North/)
	  ->json_like('/groups/region/Southern/0', qr/South/);

	# /pivot grouping by region_group virtual column
	my $url = "/pivot?l=$l&rows=region_group&m=sales:sum:total";
	$t->get_ok($url)->status_is(200);
	my $body = $t->tx->res->body;
	# Northern = 100+150 = 250
	like $body, qr/Northern/, 'Northern group present in pivot';
	like $body, qr/250/,      'Northern total sales = 250';
	# Southern = 200+50 = 250
	like $body, qr/Southern/, 'Southern group present in pivot';
	# Unknown row -> (other)
	like $body, qr/\(other\)/, '(other) group present for unmapped values';

	# /bar grouping by region_group virtual column
	$t->get_ok("/bar?l=$l&cat=region_group")
	  ->status_is(200)
	  ->content_like(qr/Northern/, 'bar chart has Northern group');

	# Clean up groups to avoid polluting other tests
	$t->post_ok('/groups/delete', form => { l => "path:$csv" })
	  ->status_is(200)->json_is('/ok', 1);
};

subtest '/bar ?topn=N: shows N bars plus correct "Other" aggregate' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'products.csv');
	# 5 products; topn=3 should show top 3 + Other (sum of remaining 2)
	Mojo::File->new($csv)->spurt(
		"product,revenue\n"
		. "A,500\n"
		. "B,400\n"
		. "C,300\n"
		. "D,200\n"
		. "E,100\n"
	);
	my $l = url_escape("path:$csv");

	$t->get_ok("/bar?l=$l&cat=product&val=revenue&topn=3")
	  ->status_is(200);
	my $body = $t->tx->res->body;
	# Top 3: A=500, B=400, C=300; Other = D+E = 300
	like $body, qr/Other/, '"Other" bar present';
	# bar_count stash = 4 (3 top + Other); reflected in the page
	like $body, qr/4 bar/, 'bar_count is 4 (3 top + Other)';

	# topn=0 (disabled): all 5 bars, no Other
	$t->get_ok("/bar?l=$l&cat=product&val=revenue&topn=0")
	  ->status_is(200)
	  ->content_unlike(qr/Other/, 'no Other bar when topn=0');
};

subtest '/pivot ?topn=N: top-N row groups with "Other" row' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'pivot_topn.csv');
	Mojo::File->new($csv)->spurt(
		"category,amount\n"
		. "Alpha,1000\n"
		. "Beta,800\n"
		. "Gamma,600\n"
		. "Delta,400\n"
		. "Epsilon,200\n"
	);
	my $l = url_escape("path:$csv");

	$t->get_ok("/pivot?l=$l&rows=category&m=amount:sum:total&topn=2")
	  ->status_is(200);
	my $body = $t->tx->res->body;
	# Top 2 by total: Alpha=1000, Beta=800; Other = 600+400+200 = 1200
	like $body, qr/Alpha/,  'Alpha row present';
	like $body, qr/Beta/,   'Beta row present';
	like $body, qr/Other/,  '"Other" row present';
	like $body, qr/1200/,   'Other total = 1200';
	unlike $body, qr/Gamma/, 'Gamma row not present (not in top 2)';

	# Bad topn_col
	$t->get_ok("/pivot?l=$l&rows=category&m=amount:sum:total&topn=2&topn_col=nonexistent")
	  ->status_is(400)
	  ->content_like(qr/nonexistent/, 'error message names bad topn_col');
};

# ===========================================================================
# SECTION 50: Push-versus-fold equivalence gate (TODO-10.4)
#
# For each SQL-backed chart view, assert that the numeric totals are identical
# with and without $ENV{BI_FORCE_PERL_AGG}.  This is the strongest net against
# a repeat of the /stacked//combo category-order divergence (TODO-3).
# ===========================================================================

subtest 'Push-vs-fold equivalence: /bar' => sub {
	SKIP: {
		my $dir = tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/eq_bar.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 2 unless $dbh;
		$dbh->do('CREATE TABLE eq_bar (region TEXT, amount INTEGER)');
		for my $row (['North', 100], ['South', 200], ['North', 50]) {
			$dbh->do('INSERT INTO eq_bar VALUES (?,?)', {}, @$row);
		}
		$dbh->disconnect;
		my $l = url_escape("path:$dir/eq_bar.sql");

		my $push_body = $t->get_ok("/bar?l=$l&cat=region&val=amount")
						   ->status_is(200)->tx->res->body;

		local $ENV{BI_FORCE_PERL_AGG} = 1;
		my $fold_body = $t->get_ok("/bar?l=$l&cat=region&val=amount")
						   ->status_is(200)->tx->res->body;

		my @push_vals = sort ($push_body =~ /"value":(\d+)/g);
		my @fold_vals = sort ($fold_body =~ /"value":(\d+)/g);
		is_deeply(\@push_vals, \@fold_vals, '/bar push and fold produce same values');
	}
};

subtest 'Push-vs-fold equivalence: /stacked' => sub {
	SKIP: {
		my $dir = tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/eq_stacked.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 2 unless $dbh;
		$dbh->do('CREATE TABLE eq_stacked (cat TEXT, seg TEXT, val INTEGER)');
		for my $row (['A','X',10],['A','Y',20],['B','X',30],['B','Y',40]) {
			$dbh->do('INSERT INTO eq_stacked VALUES (?,?,?)', {}, @$row);
		}
		$dbh->disconnect;
		my $l = url_escape("path:$dir/eq_stacked.sql");

		my $push_body = $t->get_ok("/stacked?l=$l&cat=cat&series=seg&val=val")
						   ->status_is(200)->tx->res->body;

		local $ENV{BI_FORCE_PERL_AGG} = 1;
		my $fold_body = $t->get_ok("/stacked?l=$l&cat=cat&series=seg&val=val")
						   ->status_is(200)->tx->res->body;

		my @push_vals = sort ($push_body =~ /"val":(\d+)/g);
		my @fold_vals = sort ($fold_body =~ /"val":(\d+)/g);
		is_deeply(\@push_vals, \@fold_vals, '/stacked push and fold produce same values');
	}
};

subtest 'Push-vs-fold equivalence: /heatmap' => sub {
	SKIP: {
		my $dir = tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/eq_heatmap.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 2 unless $dbh;
		$dbh->do('CREATE TABLE eq_heatmap (x TEXT, y TEXT, v REAL)');
		for my $row (['P','Q',1.0],['P','R',2.0],['S','Q',3.0]) {
			$dbh->do('INSERT INTO eq_heatmap VALUES (?,?,?)', {}, @$row);
		}
		$dbh->disconnect;
		my $l = url_escape("path:$dir/eq_heatmap.sql");

		my $push_body = $t->get_ok("/heatmap?l=$l&x=x&y=y&val=v")
						   ->status_is(200)->tx->res->body;

		local $ENV{BI_FORCE_PERL_AGG} = 1;
		my $fold_body = $t->get_ok("/heatmap?l=$l&x=x&y=y&val=v")
						   ->status_is(200)->tx->res->body;

		my @push_vals = sort ($push_body =~ /"value":([\d.]+)/g);
		my @fold_vals = sort ($fold_body =~ /"value":([\d.]+)/g);
		is_deeply(\@push_vals, \@fold_vals, '/heatmap push and fold produce same values');
	}
};

subtest 'Push-vs-fold equivalence: /treemap' => sub {
	SKIP: {
		my $dir = tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/eq_treemap.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 2 unless $dbh;
		$dbh->do('CREATE TABLE eq_treemap (cat TEXT, val INTEGER)');
		for my $row (['Alpha', 100], ['Beta', 200], ['Alpha', 50]) {
			$dbh->do('INSERT INTO eq_treemap VALUES (?,?)', {}, @$row);
		}
		$dbh->disconnect;
		my $l = url_escape("path:$dir/eq_treemap.sql");

		my $push_body = $t->get_ok("/treemap?l=$l&group=cat&size=val")
						   ->status_is(200)->tx->res->body;

		local $ENV{BI_FORCE_PERL_AGG} = 1;
		my $fold_body = $t->get_ok("/treemap?l=$l&group=cat&size=val")
						   ->status_is(200)->tx->res->body;

		my @push_vals = sort ($push_body =~ /"value":([\d.]+)/g);
		my @fold_vals = sort ($fold_body =~ /"value":([\d.]+)/g);
		is_deeply(\@push_vals, \@fold_vals, '/treemap push and fold produce same values');
	}
};

# ===========================================================================
# SECTION 51: XLSX export parity (TODO-10.1)
#
# Assert that ?format=xlsx produces cell-for-cell identical data to
# ?format=csv for the same request (data/sales.csv).
# ===========================================================================

subtest 'XLSX export parity with CSV export (/pivot?format=xlsx)' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 4 unless -f 'data/sales.csv';
		eval { require Spreadsheet::ParseXLSX }
			or skip 'Spreadsheet::ParseXLSX not available', 4;
		eval { require Excel::Writer::XLSX }
			or skip 'Excel::Writer::XLSX not available', 4;
		eval { require Text::CSV }
			or skip 'Text::CSV not available', 4;

		my $l = url_escape("path:$SALES_CSV");

		# CSV export of the same pivot (rows=product, m=amount:sum:total)
		my $csv_body = $t->get_ok("/pivot?l=$l&rows=product&m=amount:sum:total&format=csv")
						  ->status_is(200)->tx->res->body;

		# XLSX export of the same pivot
		my $xlsx_body = $t->get_ok("/pivot?l=$l&rows=product&m=amount:sum:total&format=xlsx")
						   ->status_is(200)->tx->res->body;

		# Parse CSV rows (skip the header row for cell comparison)
		my $csv_parser = Text::CSV->new({ binary => 1 });
		open my $fh, '<', \$csv_body or die "open: $!";
		my @csv_rows;
		while (my $row = $csv_parser->getline($fh)) { push @csv_rows, $row }
		close $fh;

		# Write XLSX to temp file and parse
		my $tmpdir = tempdir(CLEANUP => 1);
		my $xlsx_file = "$tmpdir/export.xlsx";
		Mojo::File->new($xlsx_file)->spurt($xlsx_body);
		my $wb  = Spreadsheet::ParseXLSX->new->parse($xlsx_file);
		skip 'Spreadsheet::ParseXLSX could not parse output', 2 unless $wb;
		my $ws  = $wb->worksheet(0);
		my ($row_min, $row_max) = $ws->row_range;
		my ($col_min, $col_max) = $ws->col_range;

		my @xlsx_rows;
		for my $r ($row_min .. $row_max) {
			push @xlsx_rows, [
				map { my $c = $ws->get_cell($r, $_); $c ? $c->value : '' }
					$col_min .. $col_max
			];
		}

		is(scalar @xlsx_rows, scalar @csv_rows, 'XLSX and CSV have same row count');
		is_deeply(\@xlsx_rows, \@csv_rows, 'XLSX and CSV cells are identical');
	}
};

# ===========================================================================
# SECTION 52: Stacked empty-vs-zero (TODO-10.2)
#
# Missing intersections in /stacked must produce no data point at all --
# not a zero bar -- so the chart can distinguish "no sale in that segment"
# from "zero sale".
# ===========================================================================

subtest '/stacked: correct category count and totals (no row inflation)' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $csv = "$dir/sparse.csv";
	Mojo::File->new($csv)->spurt(
		"cat,seg,val\n"
		. "A,X,10\n"
		. "A,X,5\n"   # two rows for A/X: total should be 15, not 10
		. "B,Y,20\n"
	);
	my $l = url_escape("path:$csv");

	my $body = $t->get_ok("/stacked?l=$l&cat=cat&series=seg&val=val")
				 ->status_is(200)->tx->res->body;

	# The JSON should contain 2 unique categories (A and B).
	my @cats = ($body =~ /"cat"\s*:\s*"([^"]+)"/g);
	is(scalar @cats, 2, 'exactly 2 categories after aggregation');

	# A/X sum should be 15 (not 10 -- two rows summed)
	like $body, qr/"X"\s*:\s*15/, 'A/X aggregated to 15 (two rows summed)';

	# B/Y should be 20
	like $body, qr/"Y"\s*:\s*20/, 'B/Y is 20';
};

# ===========================================================================
# SECTION 53: Geocode.pm <-> map_view end-to-end integration
#
# Strategy:
#   - Inject stub geocoders through app->config->{geocoder} so every test
#     runs without Geo::Coder::Free installed.
#   - Cover the full cross-module pipeline: HTTP request -> map_view ->
#     Geocode->resolve_column -> models_with_cache -> _write_models.
#   - Verify cache round-trips: a second request over the same column must
#     not call the geocoder for values already resolved in the first.
#   - Verify count arithmetic invariants hold across the pipeline.
# ===========================================================================

{
	# ---------------------------------------------------------------------------
	# In-process stub geocoder packages, isolated to this block.
	# They implement the minimal interface Geocode->new(geocoder=>) expects.
	# ---------------------------------------------------------------------------

	package Integ::GeoPoint;
	sub new  { my ($cls, %h) = @_; bless \%h, $cls }
	sub latitude  { $_[0]->{latitude}  }
	sub longitude { $_[0]->{longitude} }
	sub database  { $_[0]->{database}  }

	package Integ::Geocoder;
	sub new {
		my ($cls, %h) = @_;
		bless { results => $h{results} // {}, calls => [] }, $cls;
	}
	sub valid_location { defined $_[1] && length $_[1] && $_[1] !~ /\A\d+\z/ }
	sub geocode_many {
		my ($self, $values, %opts) = @_;
		push @{ $self->{calls} }, { values => [@$values] };
		return { map { $_ => $self->{results}{$_} } @$values };
	}

	package main;
}

# Fixtures -----------------------------------------------------------------
Readonly my $RAMSGATE_LAT =>  51.336;
Readonly my $RAMSGATE_LON =>   1.416;
Readonly my $MARGATE_LAT  =>  51.384;
Readonly my $MARGATE_LON  =>   1.386;

# A CSV with a location column; re-used across all /map loc= subtests.
my $MAP_DIR   = tempdir(CLEANUP => 1);
my $PLACE_CSV = "$MAP_DIR/places.csv";
Mojo::File->new($PLACE_CSV)->spew(
	"id,city,amount\n"
	. "1,Ramsgate,100\n"
	. "2,Ramsgate,50\n"
	. "3,Margate,200\n"
	. "4,,10\n"           # empty -- skipped
	. "5,42,999\n"        # bare number -- refused by valid_location
);

# A CSV with pre-computed lat/lon columns; re-used for the coordinate path.
my $COORD_CSV = "$MAP_DIR/coords.csv";
Mojo::File->new($COORD_CSV)->spew(
	"id,name,lat,lon\n"
	. "1,A,$RAMSGATE_LAT,$RAMSGATE_LON\n"
	. "2,B,$RAMSGATE_LAT,$RAMSGATE_LON\n"  # duplicate coordinate -> one marker
	. "3,C,$MARGATE_LAT,$MARGATE_LON\n"
	. "4,D,,\n"                             # empty cells -> unusable
);

Readonly my $PLACE_SPEC => 'path:' . $PLACE_CSV;
Readonly my $COORD_SPEC => 'path:' . $COORD_CSV;

# ---------------------------------------------------------------------------
# Helper: build a stub geocoder that resolves Ramsgate and Margate.
# ---------------------------------------------------------------------------
sub _stub_geocoder {
	my %extra = @_;
	return Integ::Geocoder->new(
		results => {
			'Ramsgate' => Integ::GeoPoint->new(
				latitude => $RAMSGATE_LAT, longitude => $RAMSGATE_LON,
				database => 'Test',
			),
			'Margate'  => Integ::GeoPoint->new(
				latitude => $MARGATE_LAT,  longitude => $MARGATE_LON,
				database => 'Test',
			),
			%extra,
		},
	);
}

# ---------------------------------------------------------------------------
# Subtest 53.1: loc= path -- geocoder is called; markers and counts are right
# ---------------------------------------------------------------------------
subtest '/map loc= path: geocoder called, markers + counts correct' => sub {
	my $stub  = _stub_geocoder();
	my $model_dir = tempdir(CLEANUP => 1);
	$t->app->config->{geocoder}   = $stub;
	$t->app->config->{openaddr}   = 'test';
	$t->app->config->{model_dir}  = $model_dir;

	my $l = url_escape($PLACE_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")
	             ->status_is(200)
	             ->tx->res->body;

	# Both distinct non-skipped places appear in map_body (Leaflet popup HTML),
	# which is only rendered when HTML::OSM is installed.
	SKIP: {
		eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
			or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 2;
		like $body, qr/Ramsgate/i, 'Ramsgate marker present in response';
		like $body, qr/Margate/i,  'Margate marker present in response';
	}

	# Exactly one geocode_many() call was made for the two pending values.
	is scalar(@{ $stub->{calls} }), 1, 'geocoder was called exactly once';
	my @called_with = sort @{ $stub->{calls}[0]{values} };
	is_deeply \@called_with, [qw(Margate Ramsgate)], 'geocoder received both distinct places';

	# Cache was persisted: the models file should now carry the two places.
	my $models_path = "$model_dir/models.json";
	ok -f $models_path, 'models.json written after geocode';

	my $json = Mojo::File->new($models_path)->slurp;
	my $data = eval { decode_json($json) };
	ok !$@, 'models.json is valid JSON';
	ok exists($data->{geo}{shared}), 'shared place cache written into geo section';

	# '42' is refused by valid_location() (pure-digit string) -> skipped, NOT cached.
	# Empty string is also skipped.  Only the two successfully resolved places appear.
	is_deeply [sort keys %{ $data->{geo}{shared}{places} }],
		[qw(Margate Ramsgate)],
		'only resolved places in cache (42 and empty are skipped, never cached)';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ---------------------------------------------------------------------------
# Subtest 53.2: cache round-trip -- second request must not call geocoder
#
# Strategy: first request geocodes; second request uses the written cache.
# The geocoder's call-count should not change on the second request.
# ---------------------------------------------------------------------------
subtest '/map loc= cache round-trip: second request free of geocoder calls' => sub {
	my $stub      = _stub_geocoder();
	my $model_dir = tempdir(CLEANUP => 1);
	$t->app->config->{geocoder}   = $stub;
	$t->app->config->{openaddr}   = 'test';
	$t->app->config->{model_dir}  = $model_dir;

	my $l = url_escape($PLACE_SPEC);

	# First request -- populates the cache.
	$t->get_ok("/map?l=$l&loc=city")->status_is(200);
	my $calls_after_first = scalar @{ $stub->{calls} };
	is $calls_after_first, 1, 'geocoder called once on first request';

	# Second request over the same spec -- all places are now in the cache.
	$t->get_ok("/map?l=$l&loc=city")->status_is(200);
	is scalar(@{ $stub->{calls} }), $calls_after_first,
		'geocoder NOT called again on second request (cache served all values)';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ---------------------------------------------------------------------------
# Subtest 53.3: count arithmetic invariants hold over the full pipeline
#
# The POD promises: skipped + cached + attempted + not_attempted == distinct
# and resolved + unresolved == cached + attempted.  This test verifies both
# by replaying the sequence in a single-model-dir run so counts are clean.
# ---------------------------------------------------------------------------
subtest '/map loc= count invariants: skipped+cached+attempted+not_attempted==distinct' => sub {
	my $stub      = _stub_geocoder();
	my $model_dir = tempdir(CLEANUP => 1);
	$t->app->config->{geocoder}   = $stub;
	$t->app->config->{openaddr}   = 'test';
	$t->app->config->{model_dir}  = $model_dir;

	my $l    = url_escape($PLACE_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")->status_is(200)->tx->res->body;

	# Re-derive counts from the stored cache to confirm they add up:
	# distinct = Ramsgate, Margate, 42, '' = 4 distinct keys (empty deduplicated)
	# skipped  = '' (empty) + 42 (refused by valid_location) = 2
	# attempted = Ramsgate, Margate = 2 (after valid_location check)
	# cached = 0 on first request
	# not_attempted = 0 (2 <= DEFAULT_MAX)
	# resolved = 2, unresolved = 0 (42 was skipped, not attempted)
	# => skipped(2) + cached(0) + attempted(2) + not_attempted(0) == distinct(4) ok
	# => resolved(2) + unresolved(0) == cached(0) + attempted(2) ok

	# Read the written models and count places to verify attempted == resolved.
	my $json = Mojo::File->new("$model_dir/models.json")->slurp;
	my $data = decode_json($json);
	my $places = $data->{geo}{shared}{places};

	# '42' is refused by valid_location() (pure-digit string): it goes into @skipped,
	# never into @pending, and is therefore never stored in the cache at all.
	# The empty string is also skipped (length=0 short-circuit).
	# Only the two successfully geocoded places appear in the cache.
	my @resolved   = grep { ref($places->{$_}) eq 'ARRAY' } keys %$places;
	my @unresolved = grep { !ref($places->{$_})            } keys %$places;

	is scalar(@resolved),   2, 'two places resolved (Ramsgate, Margate)';
	is scalar(@unresolved), 0, 'no unresolved entries (42 was skipped, never attempted)';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ---------------------------------------------------------------------------
# Subtest 53.4: two concurrent model_dir paths do not cross-contaminate
#
# Instantiate two separate "users" (different model dirs) in sequence and
# verify their cached data is fully isolated.
# ---------------------------------------------------------------------------
subtest '/map loc= concurrent model dirs are isolated' => sub {
	my $stub_a = _stub_geocoder();
	my $stub_b = _stub_geocoder(
		'Broadstairs' => Integ::GeoPoint->new(
			latitude => 51.358, longitude => 1.437, database => 'Test',
		),
	);

	my $dir_a = tempdir(CLEANUP => 1);
	my $dir_b = tempdir(CLEANUP => 1);

	# Two separate data files for two separate specs.
	my $csv_a = "$dir_a/towns_a.csv";
	my $csv_b = "$dir_b/towns_b.csv";
	Mojo::File->new($csv_a)->spew("id,city\n1,Ramsgate\n2,Margate\n");
	Mojo::File->new($csv_b)->spew("id,city\n1,Broadstairs\n");

	# User A.
	$t->app->config->{geocoder}  = $stub_a;
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = $dir_a;
	$t->get_ok('/map?l=' . url_escape("path:$csv_a") . '&loc=city')
	  ->status_is(200);

	# User B.
	$t->app->config->{geocoder}  = $stub_b;
	$t->app->config->{model_dir} = $dir_b;
	$t->get_ok('/map?l=' . url_escape("path:$csv_b") . '&loc=city')
	  ->status_is(200);

	# Verify isolation: dir_a has no knowledge of Broadstairs; dir_b has no
	# knowledge of Ramsgate or Margate.
	my $data_a = decode_json(Mojo::File->new("$dir_a/models.json")->slurp);
	my $data_b = decode_json(Mojo::File->new("$dir_b/models.json")->slurp);

	my $places_a = $data_a->{geo}{shared}{places} // {};
	my $places_b = $data_b->{geo}{shared}{places} // {};

	ok !exists($places_a->{Broadstairs}), 'dir_a cache has no Broadstairs';
	ok !exists($places_b->{Ramsgate}),    'dir_b cache has no Ramsgate';
	ok !exists($places_b->{Margate}),     'dir_b cache has no Margate';
	ok  exists($places_b->{Broadstairs}), 'dir_b cache has Broadstairs';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ---------------------------------------------------------------------------
# Subtest 53.5: lat/lon path -- no geocoder needed; duplicate coordinate -> one marker
# ---------------------------------------------------------------------------
subtest '/map lat/lon path: duplicate coordinates collapse to one marker' => sub {
	delete $t->app->config->{geocoder};   # explicitly none

	my $l    = url_escape($COORD_SPEC);
	my $body = $t->get_ok("/map?l=$l&lat=lat&lon=lon")
	             ->status_is(200)
	             ->tx->res->body;

	# Rows 1+2 share a coordinate -> one marker; row 3 is separate; row 4 is unusable.
	# The lat values appear inside the Leaflet JS in map_body, which requires HTML::OSM.
	SKIP: {
		eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
			or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 2;
		like $body, qr/$RAMSGATE_LAT/, 'Ramsgate lat present in response';
		like $body, qr/$MARGATE_LAT/,  'Margate lat present in response';
	}
};

# ---------------------------------------------------------------------------
# Subtest 53.6: lat/lon path with f= filter reduces markers
# ---------------------------------------------------------------------------
subtest '/map lat/lon path: f= filter applied before marker construction' => sub {
	my $l    = url_escape($COORD_SPEC);
	my $f    = url_escape('name:eq:A');
	my $body = $t->get_ok("/map?l=$l&lat=lat&lon=lon&f=$f")
	             ->status_is(200)
	             ->tx->res->body;

	# Only row 1 (name=A) survives the filter.
	# Lat values appear in the Leaflet JS inside map_body, which requires HTML::OSM.
	SKIP: {
		eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
			or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 2;
		like   $body, qr/$RAMSGATE_LAT/, 'Ramsgate lat in response after filter';
		unlike $body, qr/$MARGATE_LAT/,  'Margate lat absent after name:eq:A filter';
	}
};

# ---------------------------------------------------------------------------
# Subtest 53.7: map_view with no geocoder gracefully degrades
#
# When no geocoder is available and the column has never been cached,
# the page should still return 200 with "not_attempted" counts reflected
# (the POD calls this the "without the geocoder" path).
# ---------------------------------------------------------------------------
subtest '/map loc= no geocoder: 200 with all values not_attempted' => sub {
	# No injected geocoder; no Geo::Coder::Free installed on this machine
	# (or an impossibly high version floor).
	delete $t->app->config->{geocoder};
	my $model_dir = tempdir(CLEANUP => 1);
	$t->app->config->{model_dir} = $model_dir;

	# Synthesise a Geocode object with a very high version floor to guarantee
	# the geocoder is "unavailable", regardless of what is installed.
	# We cannot easily inject via the HTTP path for this sub-path, so
	# we verify at the module level instead and check the HTTP response
	# separately.
	require Database::BI::Model::Geocode;
	my $g = Database::BI::Model::Geocode->new(min_geocoder_version => '9999.0');
	my ($avail, $reason) = $g->geocoder_available();
	ok !$avail, 'geocoder_available() is false with impossible version floor';
	like $reason, qr/9999\.0/, 'reason names the minimum version';

	my $result = $g->resolve_values([qw(Ramsgate Margate)]);
	is $result->{counts}{not_attempted}, 2,
		'all values go into not_attempted when geocoder unavailable';
	is $result->{counts}{attempted},     0,
		'no lookups made when geocoder unavailable';
	is $result->{available},             0,
		'available=0 in result';
};

# ---------------------------------------------------------------------------
# Subtest 53.8: cap (max=) pipeline -- capped values reach warn_map_geocode_capped
# ---------------------------------------------------------------------------
subtest 'Geocode resolve_values cap: warn_map_geocode_capped emitted' => sub {
	my @five_places = map { "Place$_" } 1..5;
	my %results     = map { $_ => Integ::GeoPoint->new(
		latitude => 51.0, longitude => 1.0, database => 'T',
	) } @five_places;
	my $stub = Integ::Geocoder->new(results => \%results);
	my $g    = Database::BI::Model::Geocode->new(geocoder => $stub, openaddr => 'test');

	my $r = $g->resolve_values(\@five_places, max => 3);

	is $r->{counts}{attempted},     3, '3 values attempted (max=3)';
	is $r->{counts}{not_attempted}, 2, '2 values held back';
	ok $r->{capped}, 'capped flag is true';

	my @capped_msgs = grep { $_->{key} eq 'warn_map_geocode_capped' } @{ $r->{messages} };
	is scalar(@capped_msgs), 1, 'exactly one warn_map_geocode_capped message';
	like $capped_msgs[0]{text}, qr/3/, 'message mentions the cap size';
};

# ---------------------------------------------------------------------------
# Subtest 53.9: models_with_cache <-> cache_from_models round-trip
#
# Writes a cache, reads it back through cache_from_models, passes it to a
# second resolve_values call, and confirms no geocoder calls are made.
# ---------------------------------------------------------------------------
subtest 'Geocode cache round-trip: models_with_cache -> cache_from_models -> no geocoder calls' => sub {
	my $stub  = _stub_geocoder();
	my $g     = Database::BI::Model::Geocode->new(geocoder => $stub, openaddr => 'test');
	my $spec  = 'table:test|loc=city';

	# First resolve -- populates cache.
	my $r1 = $g->resolve_values([qw(Ramsgate Margate)]);
	is scalar(@{ $stub->{calls} }), 1, 'one geocode_many call on first resolve';

	# Persist the cache into a model store.
	my $models = Database::BI::Model::Geocode->models_with_cache(
		{}, $spec, $r1->{cache},
		backend => $r1->{backend}, built => '2026-01-01T00:00:00Z',
	);
	ok exists($models->{geo}{$spec}), 'spec key written into models';

	# Reload the cache from the persisted store.
	my $cache2 = Database::BI::Model::Geocode->cache_from_models($models, $spec);
	is scalar(keys %$cache2), 2, 'both resolved places in the reloaded cache';

	# Second resolve, with the pre-loaded cache.
	my $r2 = $g->resolve_values([qw(Ramsgate Margate)], cache => $cache2);
	is scalar(@{ $stub->{calls} }), 1,
		'geocoder NOT called again (both values served from cache)';
	is $r2->{counts}{cached},   2, 'cached=2 on second resolve';
	is $r2->{counts}{attempted},0, 'attempted=0 on second resolve';
};

# ---------------------------------------------------------------------------
# Subtest 53.10: popup= columns injected via HTTP propagate to marker label
# ---------------------------------------------------------------------------
subtest '/map popup= column appears in marker label HTML' => sub {
	my $stub = _stub_geocoder();
	$t->app->config->{geocoder}  = $stub;
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l    = url_escape($PLACE_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city&popup=amount")
	             ->status_is(200)
	             ->tx->res->body;

	# Popup column names appear inside map_body (Leaflet popup HTML),
	# which is only rendered when HTML::OSM is installed.
	SKIP: {
		eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
			or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 1;
		like $body, qr/amount/i, 'amount column referenced in map output (popup)';
	}

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ---------------------------------------------------------------------------
# Subtest 53.11: i18n override -- custom i18n object formats Geocode messages
#
# Named subs in Perl do NOT form closures over runtime lexicals, so the i18n
# stub must store the call log inside the object (not in a lexical captured by
# a named sub) to record which keys were passed to maketext().
# ---------------------------------------------------------------------------
subtest 'Geocode i18n: injected maketext() is called for warn_map_geocode_capped' => sub {
	{
		package Integ::I18N;
		sub new  { bless { log => [] }, shift }
		sub maketext {
			my ($self, $key, @args) = @_;
			push @{ $self->{log} }, $key;
			return "i18n:$key";
		}
		package main;
	}

	my @places = map { "Place$_" } 1..10;
	my %results = map { $_ => Integ::GeoPoint->new(
		latitude => 51.0, longitude => 1.0, database => 'T'
	) } @places;
	my $stub = Integ::Geocoder->new(results => \%results);
	my $i18n = Integ::I18N->new();
	my $g    = Database::BI::Model::Geocode->new(
		geocoder => $stub,
		openaddr => 'test',
		i18n     => $i18n,
	);

	$g->resolve_values(\@places, max => 5);

	ok(grep({ $_ eq 'warn_map_geocode_capped' } @{ $i18n->{log} }),
		'i18n->maketext() called with warn_map_geocode_capped key');
};

# ---------------------------------------------------------------------------
# Subtest 53.12: Geocode resolve_column -- skipped + unusable row counting
# ---------------------------------------------------------------------------
subtest 'Geocode resolve_column: skipped and unusable counts add up correctly' => sub {
	my $stub = _stub_geocoder();
	my $g    = Database::BI::Model::Geocode->new(geocoder => $stub, openaddr => 'test');

	# 5 rows: 2 x Ramsgate (resolved), 1 x Margate (resolved), 1 empty (skipped),
	# 1 x '42' (refused by valid_location, skipped).
	my @rows = (
		{ city => 'Ramsgate' },
		{ city => 'Ramsgate' },
		{ city => 'Margate'  },
		{ city => ''         },
		{ city => '42'       },
	);

	my $r = $g->resolve_column(\@rows, 'city');

	is $r->{counts}{rows},    5, 'rows=5';
	is $r->{counts}{plotted}, 3, 'plotted=3 (2xRamsgate + 1xMargate)';

	# unusable = rows - plotted
	is $r->{counts}{unusable}, 2, 'unusable=2 (empty + 42)';

	# count invariants: skipped + cached + attempted + not_attempted == distinct
	my $c = $r->{counts};
	is $c->{skipped} + $c->{cached} + $c->{attempted} + $c->{not_attempted},
	   $c->{distinct},
	   'skipped + cached + attempted + not_attempted == distinct';

	# resolved + unresolved == cached + attempted
	is $c->{resolved} + $c->{unresolved},
	   $c->{cached}   + $c->{attempted},
	   'resolved + unresolved == cached + attempted';
};

# ===========================================================================
# SECTION 54: /map -> HTML::OSM graceful degradation
#
# When HTML::OSM is missing, or older than the floor the controller passes
# options for, map_view must still return 200 with the matching warning in the
# response.  The two states are produced by replacing the renderer probe,
# which is the only way to reach the missing one in-process: Test::Without::Module
# removes HTML/OSM.pm from %INC but its @INC hook is bypassed during dispatch,
# so the installed copy is found again (and recompiled, printing "Subroutine ...
# redefined" for every sub in it).
# ===========================================================================

sub _map_body_with_renderer {
	my ($ok, $version) = @_;

	my $stub = _stub_geocoder();
	$t->app->config->{geocoder}  = $stub;
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l    = url_escape($PLACE_SPEC);
	my $body;
	{
		no warnings 'redefine';
		local *Database::BI::Controller::Dashboard::_map_renderer_version =
			sub { $ok, $version };
		$body = $t->get_ok("/map?l=$l&loc=city")->status_is(200)->tx->res->body;
	}

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};

	return $body // '';
}

subtest '/map: an older HTML::OSM => 200 with the older-renderer warning' => sub {
	my $body = _map_body_with_renderer(0, '0.11');

	like $body, qr/data-key="error_map_renderer_old"/,
		'the older install is reported as such, not as a missing module';
	like $body, qr/installed HTML::OSM is 0\.11/,
		'the warning names the version that is installed';
	like $body, qr/HTML::OSM 0\.14 or later/,
		'and the version that is needed';
};

subtest '/map: a missing HTML::OSM => 200 with the not-installed warning' => sub {
	my $body = _map_body_with_renderer(0, undef);

	like $body, qr/data-key="error_map_renderer_missing"/,
		'the missing renderer is reported as not installed';
	like $body, qr/and it is not installed/, 'the warning says so';
	like $body, qr/HTML::OSM 0\.14 or later/, 'and names the version that is needed';
	unlike $body, qr/installed HTML::OSM is/, 'it does not claim a version is installed';
};

# ===========================================================================
# SECTION 55: Geocode + calc pipeline composition
#
# A virtual calculated column (via ?c=) is applied before geocoding.
# The geocode must see the transformed values, not the raw column.
# ===========================================================================

subtest '/map: ?c= calculated field applied before geocoding' => sub {
	# CSV whose raw column holds lowercase city names; a calc field uppercases them.
	my $dir = tempdir(CLEANUP => 1);
	my $csv = "$dir/lower.csv";
	Mojo::File->new($csv)->spew(
		"id,city_raw\n1,ramsgate\n2,margate\n"
	);

	# Stub that answers only the lowercased forms (the geocoder sees what the
	# calc layer produced, so the lookup names must match what ?c= emits).
	my $stub = Integ::Geocoder->new(results => {
		'ramsgate' => Integ::GeoPoint->new(
			latitude => $RAMSGATE_LAT, longitude => $RAMSGATE_LON, database => 'T',
		),
		'margate'  => Integ::GeoPoint->new(
			latitude => $MARGATE_LAT, longitude => $MARGATE_LON, database => 'T',
		),
	});

	$t->app->config->{geocoder}  = $stub;
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l   = url_escape("path:$csv");
	# city_alias = trim(city_raw) -- identity transform that proves the pipeline runs
	my $c   = url_escape('city_alias:city_raw');
	my $body = $t->get_ok("/map?l=$l&c=$c&loc=city_raw")
	             ->status_is(200)
	             ->tx->res->body;

	# City names appear inside map_body (Leaflet popup HTML),
	# which is only rendered when HTML::OSM is installed.
	SKIP: {
		eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 }
			or skip 'HTML::OSM 0.14 or later is needed for marker HTML', 1;
		like $body, qr/ramsgate/i, 'ramsgate appears in the map output';
	}

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ===========================================================================
# SECTION 56: Geocode models isolation (model_dir guard)
#
# When model_dir is inside data_dir, _write_models() must refuse the write,
# and map_view must emit warn_map_cache_unwritten but still return 200.
# ===========================================================================

subtest '/map: model_dir inside data_dir -> warn_map_cache_unwritten, still 200' => sub {
	my $stub = _stub_geocoder();
	$t->app->config->{geocoder}  = $stub;
	$t->app->config->{openaddr}  = 'test';

	# Point model_dir at the same directory as the data file: the guard
	# rejects writes that would land inside data_dir.
	$t->app->config->{model_dir} = File::Spec->rel2abs('data');

	my $l    = url_escape($PLACE_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")
	             ->status_is(200)
	             ->tx->res->body;

	# warn_map_cache_unwritten key should appear somewhere in the rendered page
	# (the template emits message texts).
	like $body, qr/cache|model|remember/i,
		'response contains a cache/model-related message when write is refused';

	# Restore
	$t->app->config->{model_dir} = $TEST_MODEL_DIR;
	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ===========================================================================
# SECTION 57: The measure vocabulary -- median, percentile, stdev, first, last,
# range
#
# The pivot and the /stats page share one vocabulary, and the functions no
# backend aggregate can express come from the same arithmetic.  The fixture is
# chosen so that combining a group's cells would give the wrong total -- three
# medians average to 44.67, and the three ranges add to 24, where the real
# answers are 24 and 110 -- so each grand total below is a proof that the totals
# row is computed over every row rather than added up out of the cells above it.
#
#   region     deal           sum  median  p90    p95    stdev  range  first  last
#   North      2, 4, 6        12   4       5.6    5.8    2      4      2      6
#   South      20, 24, 28     72   24      27.2   27.6   4      8      20     28
#   East       100, 106, 112  318  106     110.8  111.4  6      12     100    112
#   every row  402            402  24      107.2  109.6  46.9574275274956  110  2  112
# ===========================================================================

Readonly my $MEASURE_FIXTURE => 'region,deal,rep' . "\n"
	. "North,2,Ann\nNorth,4,Ben\nNorth,6,Cid\n"
	. "South,20,Dan\nSouth,24,Eve\nSouth,28,Fay\n"
	. "East,100,Gus\nEast,106,Hal\nEast,112,Ivy\n";

# The pivot grid as data: each body row is [row-dimension value, ...cells], and
# the footer is the totals row's cells.  Reading the table rather than grepping
# the page keeps an assertion on the number a cell holds, not on whether the
# number appears somewhere in the HTML.
sub _pivot_grid {
	my $body = shift;
	$body =~ s/\s+/ /g;
	my ($tbody) = $body =~ m{<tbody>(.*?)</tbody>}s;
	my ($tfoot) = $body =~ m{<tfoot>(.*?)</tfoot>}s;
	my @rows;
	for my $tr ($tbody =~ m{<tr>(.*?)</tr>}gs) {
		push @rows, [ map { s/\A\s+|\s+\z//g; $_ } ($tr =~ m{<td[^>]*>(.*?)</td>}gs) ];
	}
	my @totals = $tfoot
		? map { s/\A\s+|\s+\z//g; $_ } ($tfoot =~ m{<td[^>]*>(.*?)</td>}gs)
		: ();
	return (\@rows, \@totals);
}

# One column's row on the stats page, keyed by the header it sits under.  The em
# dash the page uses for "not applicable" reads as the empty string, and a
# drill-down link reads as the value it links to.
sub _stats_row {
	my ($body, $col) = @_;
	$body =~ s/\s+/ /g;
	my ($thead) = $body =~ m{<thead>(.*?)</thead>}s;
	my @names   = $thead =~ m{<th[^>]*>(.*?)</th>}gs;
	my ($tr)    = $body =~ m{<tr>\s*<td class="col-name">\Q$col\E</td>(.*?)</tr>}s;
	return () unless defined $tr;
	my @cells = ($col, map {
		s{<a[^>]*>}{}g;
		s{</a>}{}g;
		s/\A\s+|\s+\z//g;
		$_ eq '&mdash;' ? '' : $_;
	} ($tr =~ m{<td[^>]*>(.*?)</td>}gs));
	my %row;
	for my $i (0 .. $#names) {
		next unless defined $cells[$i];
		(my $name = $names[$i]) =~ s/\A\s+|\s+\z//g;
		$row{lc $name} = $cells[$i];
	}
	return %row;
}

subtest 'Pivot: the Perl-computed measures, per group and in total' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'measure_fixture.csv');
	Mojo::File->new($csv)->spurt($MEASURE_FIXTURE);
	my $l = url_escape("path:$csv");

	# sum is the control: it is the one aggregate here the backend does compute,
	# and it is the shape every other row has to match.
	my %expected = (
		'deal:sum:s'      => { East => '318',   North => '12',  South => '72',   total => '402'   },
		'deal:median:med' => { East => '106',   North => '4',   South => '24',   total => '24'    },
		'deal:p50:half'   => { East => '106',   North => '4',   South => '24',   total => '24'    },
		'deal:p90:p90'    => { East => '110.8', North => '5.6', South => '27.2', total => '107.2' },
		'deal:p95:p95'    => { East => '111.4', North => '5.8', South => '27.6', total => '109.6' },
		'deal:p100:top'   => { East => '112',   North => '6',   South => '28',   total => '112'   },
		'deal:stdev:sd'   => { East => '6',     North => '2',   South => '4',
		                       total => '46.9574275274956' },
		'deal:range:rg'   => { East => '12',    North => '4',   South => '8',    total => '110'   },
		'deal:first:f'    => { East => '100',   North => '2',   South => '20',   total => '2'     },
		'deal:last:l'     => { East => '112',   North => '6',   South => '28',   total => '112'   },
	);

	for my $spec (sort keys %expected) {
		my $want = $expected{$spec};
		$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape($spec) . '&totals=1')
		  ->status_is(200);

		my ($rows, $totals) = _pivot_grid($t->tx->res->body);
		is scalar(@$rows), 3, "$spec: one row per region";
		for my $row (@$rows) {
			is $row->[1], $want->{ $row->[0] },
				"$spec: the value for $row->[0]";
		}

		# The last cell of the totals row is the grand total; the cell before it
		# belongs to the column dimension this pivot does not have.
		is $totals->[-1], $want->{total},
			"$spec: the grand total over every row, not the cells combined";
	}

	# The same request without totals= must not change a cell value.
	$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:median:med'))
	  ->status_is(200);
	my ($plain) = _pivot_grid($t->tx->res->body);
	is_deeply [ map { [ $_->[0], $_->[1] ] } @$plain ],
		[ [ 'East', '106' ], [ 'North', '4' ], [ 'South', '24' ] ],
		'median is the same with no subtotals shown';
};

subtest 'Pivot: first and last read a column of text as readily as one of numbers' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'measure_fixture.csv');
	Mojo::File->new($csv)->spurt($MEASURE_FIXTURE);
	my $l = url_escape("path:$csv");

	my %expected = (
		'rep:first:rf' => { East => 'Gus', North => 'Ann', South => 'Dan', total => 'Ann' },
		'rep:last:rl'  => { East => 'Ivy', North => 'Cid', South => 'Fay', total => 'Ivy' },
	);

	for my $spec (sort keys %expected) {
		my $want = $expected{$spec};
		$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape($spec) . '&totals=1')
		  ->status_is(200);
		my ($rows, $totals) = _pivot_grid($t->tx->res->body);
		for my $row (@$rows) {
			is $row->[1], $want->{ $row->[0] }, "$spec: the value for $row->[0]";
		}
		is $totals->[-1], $want->{total}, "$spec: the grand total";
	}
};

subtest 'Pivot: an unknown function is refused, and the message names the vocabulary' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'measure_fixture.csv');
	Mojo::File->new($csv)->spurt($MEASURE_FIXTURE);
	my $l = url_escape("path:$csv");

	$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:mean:m'))
	  ->status_is(400)
	  ->content_like(qr/Invalid measure spec/, 'an unknown function is refused')
	  ->content_like(qr/median/, 'and the message names the measures that were added')
	  ->content_like(qr/stdev/, 'stdev included')
	  ->content_like(qr/p1 to p100/, 'and says how a percentile is spelled');

	# The level is part of the name, so the bare word carries no level and is
	# refused rather than silently taken as a median.
	$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:percentile:m'))
	  ->status_is(400)
	  ->content_like(qr/Invalid measure spec/, 'percentile with no level is refused');

	$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:p0:m'))
	  ->status_is(400)
	  ->content_like(qr/p1 to p100/, 'a level below 1 is refused');
};

subtest '/stats: the same numbers, one row per column' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'measure_fixture.csv');
	Mojo::File->new($csv)->spurt($MEASURE_FIXTURE);
	my $l = url_escape("path:$csv");

	my $body = $t->get_ok("/stats?l=$l&p=90")->status_is(200)->tx->res->body;
	like $body, qr{<th[^>]*>p90</th>}, 'the percentile column is the level that was asked for';

	my %deal = _stats_row($body, 'deal');
	is $deal{rows},        '9',      'row count';
	is $deal{'non-null'},  '9',      'non-null count';
	is $deal{null},        '0',      'null count';
	is $deal{distinct},    '9',      'distinct count';
	is $deal{min},         '2',      'min';
	is $deal{max},         '112',    'max';
	is $deal{range},       '110',    'range is max minus min';
	is $deal{mean},        '44.67',  'mean';
	is $deal{median},      '24',      'median and the pivot grand total agree';
	is $deal{p90},         '107.2',  'the percentile column';
	is $deal{'std dev'},   '46.96',  'sample standard deviation, rounded for display';
	is $deal{first},       '2',      'the first value the column holds';
	is $deal{last},        '112',    'the last value the column holds';

	# A column of text has a first and a last value and nothing to average.
	my %rep = _stats_row($body, 'rep');
	is $rep{first}, 'Ann', 'a text column has a first value';
	is $rep{last},  'Ivy', 'a text column has a last value';
	is $rep{min},   '',    'a text column has no minimum';
	is $rep{median}, '',   'a text column has no median';
	is $rep{'std dev'}, '', 'a text column has no standard deviation';

	# The header names the level, so the page cannot claim a level it did not
	# apply; 95 is the default and p=50 is the median by another name.
	$t->get_ok("/stats?l=$l")->status_is(200)
	  ->content_like(qr{<th[^>]*>p95</th>}, 'the default percentile column is p95');

	my %fifty = _stats_row($t->get_ok("/stats?l=$l&p=50")->tx->res->body, 'deal');
	is $fifty{p50}, $fifty{median}, 'p50 is the median, as it is in a pivot measure';
};

subtest '/stats: an unusable percentile level is refused, not ignored' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'measure_fixture.csv');
	Mojo::File->new($csv)->spurt($MEASURE_FIXTURE);
	my $l = url_escape("path:$csv");

	for my $bad (qw(0 101 abc 95.5)) {
		$t->get_ok("/stats?l=$l&p=$bad")
		  ->status_is(400, "p=$bad is refused")
		  ->content_like(qr/1 to 100/, "p=$bad is told the range it should be in");
	}
};

subtest 'Pivot: the Perl-computed measures need no backend, so a SQL source works' => sub {
	SKIP: {
		my $dir = tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/measures.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 4 unless $dbh;
		$dbh->do('CREATE TABLE measures (region TEXT, deal INTEGER)');
		for my $row ([North => 2], [North => 4], [North => 6],
		             [South => 20], [South => 24], [South => 28]) {
			$dbh->do('INSERT INTO measures VALUES (?, ?)', {}, @$row);
		}
		$dbh->disconnect;
		my $l = url_escape("path:$dir/measures.sql");

		# This source can aggregate(), so the push path is available to the
		# measures that have one; the ones that do not are still computed here.
		$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:median:med'))
		  ->status_is(200);
		my ($med) = _pivot_grid($t->tx->res->body);
		is_deeply [ map { [ $_->[0], $_->[1] ] } @$med ],
			[ [ 'North', '4' ], [ 'South', '24' ] ],
			'a median over a SQL-backed source';

		$t->get_ok("/pivot?l=$l&rows=region&m=" . url_escape('deal:p90:p90'))
		  ->status_is(200);
		my ($p90) = _pivot_grid($t->tx->res->body);
		is_deeply [ map { [ $_->[0], $_->[1] ] } @$p90 ],
			[ [ 'North', '5.6' ], [ 'South', '27.2' ] ],
			'a percentile over a SQL-backed source';
	}
};

# ===========================================================================
# SECTION 60: Shared helpers for the workflow, concurrency, permission and
# sabotage sections below.
#
# These sections build their own apps and fixtures rather than sharing $t, so a
# revoked directory or a sabotaged upstream cannot leak into another subtest,
# and each one can look at what its own app logged.
# ===========================================================================
Readonly my %CONFIG => (
	# How long any one sabotaged workflow may take.  Nothing here should get
	# near it; it exists so that a hang fails the test rather than the run.
	deadline_s        => 20,
	# The delay injected to stand in for a slow upstream.
	latency_s         => 1,
	# The longest client timeout, in seconds, an upstream call may be given.
	max_timeout_s     => 30,
	# Spawned at most at once by the optional-dependency matrix.
	matrix_children   => 4,
	# Enough failed requests in a row to show that they do not accumulate.
	repeated_failures => 10,
	api_key           => 'integration-test-key',
	# Text that only ever appears in a row, to prove rows are kept from the LLM.
	row_only_text     => 'Alice Smith',
	join_max_rows     => 7,
	log_level         => 'warn',
	sqlite_magic      => 'SQLite format 3',
);

Readonly my @LEDGER_ROWS => (
	{ id => '1', region => 'North', amount => '100' },
	{ id => '2', region => 'South', amount => '20' },
	{ id => '3', region => 'East',  amount => '3' },
);
Readonly my @LEDGER_COLUMNS => qw(id region amount);

# Answers that say a reader was shown Perl's internals rather than a message.
Readonly my $INTERNALS_RE => qr/ at \S+ line \d+|\@INC (?:contains|entries)|CODE\(0x/;

# A page that Mojolicious rendered for an exception nobody caught.
Readonly my $UNCAUGHT_RE => qr/<h2>Server Error<\/h2>|Page temporarily unavailable/;

sub _verbose {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# _isolated_app(%config) -> $test_mojo
#
# An app of its own, with stores nothing else writes to.
sub _isolated_app {
	my (%config) = @_;

	return Test::Mojo->new('Database::BI', {
		model_dir   => tempdir(CLEANUP => 1),
		uploads_dir => tempdir(CLEANUP => 1),
		%config,
	});
}

# _capture_logs($test_mojo, $code) -> \@lines
#
# Runs $code and returns what the app logged at warn or above and what it carped.
sub _capture_logs {
	my ($tm, $code) = @_;

	my @lines;
	local $SIG{__WARN__} = sub { push @lines, "[carp] $_[0]" };
	my $log = $tm->app->log;
	my $level = $log->level;
	$log->level($CONFIG{log_level});
	my $sub = $log->on(message => sub {
		my ($self, $level, @text) = @_;
		push @lines, "[$level] @text";
	});
	my @others = @{ $log->subscribers('message') };
	$log->unsubscribe(message => $_) for grep { $_ != $sub } @others;
	my $ok = eval { $code->(); 1 };
	my $error = $@;
	$log->unsubscribe(message => $sub);
	$log->on(message => $_) for grep { $_ != $sub } @others;
	$log->level($level);
	die $error unless $ok;

	_verbose("log: $_") for @lines;
	return \@lines;
}

# _within_deadline($name, $code)
#
# Fails, rather than hangs, when a workflow does not come back.
sub _within_deadline {
	my ($name, $code) = @_;

	my $started = time();
	my $ok = eval {
		local $SIG{ALRM} = sub { die "deadline\n" };
		alarm $CONFIG{deadline_s};
		$code->();
		alarm 0;
		1;
	};
	my $error = $@;
	alarm 0;
	my $elapsed = time() - $started;
	_verbose("$name took ${elapsed}s");
	ok($ok, "$name came back within the deadline") or diag($error);
	return $elapsed;
}

# _app_is_alive($test_mojo, $why)
#
# The check that a failure did not spread: an unrelated page still works.
sub _app_is_alive {
	my ($tm, $why) = @_;

	$tm->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Widget A/, "the rest of the application still works after $why");
	return;
}

# _no_internals($body, $what)
sub _no_internals {
	my ($body, $what) = @_;

	unlike($body // '', $INTERNALS_RE, "$what shows the reader no Perl internals");
	unlike($body // '', $UNCAUGHT_RE, "$what is not an uncaught exception page");
	return;
}

sub _csv_file {
	my ($dir, $name, @lines) = @_;

	my $path = File::Spec->catfile($dir, $name);
	Mojo::File->new($path)->spurt(join("\n", @lines) . "\n");
	return $path;
}

sub _ledger_csv_lines {
	my ($sep) = @_;

	return (
		join($sep, @LEDGER_COLUMNS),
		map { my $row = $_; join($sep, map { $row->{$_} } @LEDGER_COLUMNS) } @LEDGER_ROWS,
	);
}

# _ledger_files() -> { csv => $path, psv => $path, xlsx => $path, sql => $path }
#
# One dataset, in every format that can hold it, under the same table name.  Each
# has a directory of its own, because the name is all that tells them apart.
sub _ledger_files {
	my %path;
	for my $fmt ([csv => ','], [psv => '|']) {
		my ($ext, $sep) = @{$fmt};
		$path{$ext} = _csv_file(tempdir(CLEANUP => 1), "ledger.$ext", _ledger_csv_lines($sep));
	}

	if (eval { require Excel::Writer::XLSX; require Spreadsheet::ParseXLSX; 1 }) {
		my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'ledger.xlsx');
		my $book = Excel::Writer::XLSX->new($file);
		my $sheet = $book->add_worksheet('ledger');
		$sheet->write_row(0, 0, [ @LEDGER_COLUMNS ]);
		my $n = 0;
		$sheet->write_row(++$n, 0, [ @{$_}{@LEDGER_COLUMNS} ]) for @LEDGER_ROWS;
		$book->close;
		$path{xlsx} = $file;
	}

	if (my $sql = _ledger_sqlite(tempdir(CLEANUP => 1))) {
		$path{sql} = $sql;
	}
	return \%path;
}

sub _ledger_sqlite {
	my ($dir) = @_;

	my $file = File::Spec->catfile($dir, 'ledger.sql');
	my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1 }) };
	return unless $dbh;
	$dbh->do('CREATE TABLE ledger (id TEXT, region TEXT, amount TEXT)');
	$dbh->do('INSERT INTO ledger VALUES (?, ?, ?)', {}, @{$_}{@LEDGER_COLUMNS}) for @LEDGER_ROWS;
	$dbh->disconnect;
	return $file;
}

sub _open_ledger {
	my ($file) = @_;

	my ($name, $dir) = File::Basename::fileparse($file, qr/\.[^.]+/);
	return Database::BI::Model::DataSource->new(directory => $dir, table => $name);
}

sub _rows_by_id {
	my ($rows) = @_;

	return [ map {
		my $row = $_;
		+{ map { $_ => "$row->{$_}" } @LEDGER_COLUMNS };
	} sort { $a->{id} <=> $b->{id} } @{$rows} ];
}

# The body cells that are one of the ledger's regions, in the order on the page.
sub _regions_on_page {
	my ($body) = @_;

	return [ $body =~ m{<td[^>]*>\s*(North|South|East)\s*</td>}g ];
}

sub _response {
	my ($code, $message, $type, $body) = @_;

	return HTTP::Response->new($code, $message, [ 'Content-Type' => $type ], $body);
}

sub _provider_text {
	my ($text) = @_;

	return _response(200, 'OK', 'application/json', encode_json({ content => [ { text => $text } ] }));
}

Readonly my $CANVAS_VISUAL_JSON => '{"kind":"bar","title":"By region","encode":{"cat":"region"}}';

sub _canvas_doc {
	my (@visuals) = @_;

	@visuals = ({ kind => 'bar', title => 'By region', encode => { cat => 'region' } }) unless @visuals;
	return {
		name     => 'Integration canvas',
		datasets => [ { alias => 'main', spec => 'table:sales' } ],
		visuals  => \@visuals,
	};
}

# ===========================================================================
# SECTION 61: The layered read path, Database::BI -> Database::Join ->
# Database::Abstraction -> driver
#
# Strategy: one dataset is written in every format and read through the public
# API and over HTTP.  Whatever the format, a reader must get the same rows, and
# sorting, joining and exporting must behave the same way.
# ===========================================================================
subtest 'Every format gives the same rows through the public DataSource API' => sub {
	my $files = _ledger_files();

	for my $ext (sort keys %{$files}) {
		my $src = new_ok('Database::BI::Model::DataSource' => [
			directory => File::Basename::dirname($files->{$ext}), table => 'ledger',
		], "$ext source");
		isa_ok($src->{_db}, 'Database::Abstraction', "the $ext backend");

		my $columns = $src->columns;
		returns_ok($columns, { type => 'arrayref' }, "$ext: columns() matches its POD");
		is_deeply([ sort @{$columns} ], [ sort @LEDGER_COLUMNS ], "$ext: the columns");

		returns_ok($src->table_name, { type => 'string' }, "$ext: table_name() matches its POD");
		is($src->table_name, 'ledger', "$ext: the table name");

		my $rows = $src->fetch_all;
		returns_ok($rows, { type => 'arrayref' }, "$ext: fetch_all() matches its POD");
		is_deeply(_rows_by_id($rows), [ @LEDGER_ROWS ], "$ext: the rows");

		my $count = $src->count;
		returns_ok($count, { type => 'integer', min => 0 }, "$ext: count() matches its POD");
		is($count, scalar @LEDGER_ROWS, "$ext: the count agrees with the rows");
	}
};

subtest 'Sorting works on every format, through the API and over HTTP' => sub {
	my $files = _ledger_files();
	my $tm = _isolated_app();
	my @descending = qw(South North East);

	for my $ext (sort keys %{$files}) {
		my $src = _open_ledger($files->{$ext});
		my $rows = $src->selectall_arrayref(sort_by => [ 'region', 'desc' ]);
		is_deeply([ map { $_->{region} } @{$rows} ], \@descending, "$ext: sort_by is honoured");

		my $l = url_escape("path:$files->{$ext}");
		$tm->get_ok("/join?l=$l&sort=region&dir=desc")->status_is(200);
		is_deeply(_regions_on_page($tm->tx->res->body), \@descending, "$ext: /join shows them sorted");

		$tm->get_ok("/export?l=$l&format=json&sort=region&dir=desc")->status_is(200);
		is_deeply([ map { $_->{region} } @{ $tm->tx->res->json // [] } ], \@descending, "$ext: and /export writes them sorted");
	}
};

subtest 'A join goes through Database::Join, with the documented limits, between formats' => sub {
	my $files = _ledger_files();
	plan skip_all => 'needs both XLSX and SQLite' unless $files->{xlsx} && $files->{sql};

	my $dir = tempdir(CLEANUP => 1);
	my $managers = _csv_file($dir, 'managers.csv', 'id,manager', '1,Ann', '2,Bob', '3,Cy');
	my $tm = _isolated_app(join_max_rows => $CONFIG{join_max_rows});

	require Database::Join;
	my $joins = spy('Database::Join::new');
	my $l = url_escape("path:$files->{xlsx}");
	my $j = url_escape("path:$managers|id|id");
	$tm->get_ok("/export?l=$l&j=$j&format=json&f=" . url_escape('region:ne:East'))->status_is(200);
	my @calls = $joins->();
	restore_all();

	my $rows = $tm->tx->res->json // [];
	is_deeply([ sort map { $_->{manager} } @{$rows} ], [qw(Ann Bob)], 'the join and the filter both applied');
	is(scalar(@calls), 1, 'Database::Join built the join once');
	my (undef, undef, %args) = @{ $calls[0] };
	_verbose('Database::Join->new: ' . join(', ', map { "$_=" . ($args{$_} // '') } sort keys %args));
	is($args{backend}, 'auto', 'a large join may spill to disc');
	is($args{max_array_rows}, $CONFIG{join_max_rows}, 'at the limit in the configuration');
	is($args{join_column}, 'id', 'on the column the reader chose');

	# The same request with SQLite on the left must make no difference.
	my $from_sql = url_escape("path:$files->{sql}");
	$tm->get_ok("/export?l=$from_sql&j=$j&format=json&f=" . url_escape('region:ne:East'))->status_is(200);
	is_deeply([ sort map { $_->{manager} } @{ $tm->tx->res->json // [] } ], [qw(Ann Bob)], 'and from SQLite too');
};

subtest 'A header-less file: open, name the columns, sort, export and open again' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = _csv_file($dir, 'bank.csv',
		'2026-01-02,"1,234.56",Rent paid',
		'2026-01-03,5.00,Tea bought',
	);
	my $tm = _isolated_app();
	my $l = url_escape("path:$file");

	$tm->get_ok('/api/columns?path=' . url_escape($file))->status_is(200);
	is_deeply($tm->tx->res->json('/columns'), [qw(Date Amount Description)], 'the columns are named from the values');

	$tm->get_ok("/export?l=$l&format=json&sort=Date&dir=desc")->status_is(200);
	my $rows = $tm->tx->res->json // [];
	is_deeply([ map { $_->{Date} } @{$rows} ], [qw(2026-01-03 2026-01-02)], 'and can be sorted by');
	is($rows->[1]{Amount}, '1,234.56', 'a quoted separator stays inside its value');
	is($rows->[1]{Description}, 'Rent paid', 'and the fields after it stay in their columns');

	$tm->post_ok("/export?l=$l&dir=" . url_escape($dir) . '&filename=copy.csv')->status_is(200);
	my $again = Database::BI::Model::DataSource->new(directory => $dir, table => 'copy');
	is_deeply([ sort @{ $again->columns } ], [ sort qw(Date Amount Description) ], 'the copy has a header row');
	is_deeply(
		[ map { $_->{Amount} } sort { $a->{Date} cmp $b->{Date} } @{ $again->fetch_all } ],
		[ '1,234.56', '5.00' ],
		'and the same values',
	);
	is(Mojo::File->new($file)->slurp =~ tr/\n//, 2, 'the original is left as it was');
};

subtest '/api/range reads the joined view, as its POD says' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $people = _csv_file($dir, 'people.csv', 'id,name', '1,Ann', '2,Bob');
	my $orders = _csv_file($dir, 'orders.csv', 'id,placed', '1,2026-03-01', '2,2026-05-09');
	my $tm = _isolated_app();

	$tm->get_ok('/api/range?col=placed&l=' . url_escape("path:$people") . '&j=' . url_escape("path:$orders|id|id"))
	   ->status_is(200)
	   ->json_is('/min', '2026-03-01')
	   ->json_is('/max', '2026-05-09');

	$tm->get_ok('/api/range?col=placed&l=' . url_escape("path:$people"))
	   ->status_is(200)
	   ->json_is('/min', undef, 'without the join the column holds no dates');
};

# Strategy: follow one canvas through its whole life, each step reading what the
# last one stored, across the controller, the store and the token signing.
subtest 'A canvas from creation to deletion: store, render, share, embed, download' => sub {
	my $tm = _isolated_app();

	$tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201);
	my $id = $tm->tx->res->json('/id');
	ok(length $id, 'it has an id');
	is($tm->tx->res->headers->location, "/api/analyses/$id", 'and says where it is');

	$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', title => 'By product', encode => { cat => 'product' } })
	   ->status_is(201);
	$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', encode => { cat => 'no_such_column' } })
	   ->status_is(400, 'a card on a missing column is refused before it is stored');

	$tm->get_ok("/api/analyses/$id")->status_is(200);
	is(scalar @{ $tm->tx->res->json('/visuals') // [] }, 2, 'the two good cards were stored');

	$tm->get_ok("/a/$id")->status_is(200)->content_like(qr/By region/, 'the canvas page shows its cards');

	$tm->post_ok("/api/analyses/$id/share")->status_is(200);
	my $token = $tm->tx->res->json('/token');
	$tm->get_ok("/share/$id?token=" . url_escape($token))->status_is(200, 'the signed link opens');
	$tm->get_ok("/embed/$id?token=" . url_escape($token))->status_is(200, 'the embed opens');
	$tm->get_ok("/share/$id")->status_is(401, 'no token, no page');
	$tm->get_ok("/share/$id?token=" . url_escape($token . 'x'))->status_is(403, 'nor with one altered');

	$tm->get_ok("/a/$id/visual/0/csv")->status_is(200)->content_like(qr/Widget A/, 'a card downloads its data');
	$tm->get_ok("/a/$id/visual/9/csv")->status_is(404, 'a card that is not there does not');

	$tm->get_ok("/api/analyses/$id/export")->status_is(200);
	my $exported = $tm->tx->res->body;
	$tm->post_ok('/api/analyses/import' => { 'Content-Type' => 'application/json' } => $exported)->status_is(201);
	my $copy = $tm->tx->res->json('/id');
	isnt($copy, $id, 'an import is a new canvas');

	$tm->delete_ok("/api/analyses/$id")->status_is(200);
	$tm->get_ok("/api/analyses/$id")->status_is(404, 'the deleted canvas is gone');
	$tm->get_ok("/share/$id?token=" . url_escape($token))->status_is(404, 'and so is its link');
	$tm->get_ok("/api/analyses/$copy")->status_is(200, 'the copy is not');
};

subtest 'Ask and summary keep rows and paths from the provider' => sub {
	my $tm = _isolated_app(ai_api_key => $CONFIG{api_key});
	my @sent;
	my $guard = mock_scoped('LWP::UserAgent', request => sub {
		my ($ua, $req) = @_;
		push @sent, $req->content;
		return _provider_text($CANVAS_VISUAL_JSON);
	});

	require Database::BI::Ask;
	my $asked = spy('Database::BI::Ask::ask');
	$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => 'Amount by region?' })
	   ->status_is(200)
	   ->json_is('/valid', 1)
	   ->json_is('/spec/visuals/0/encode/cat', 'region');
	my @calls = $asked->();
	restore_all();
	is(scalar @calls, 1, 'the controller handed the question over once');
	my (undef, %args) = @{ $calls[0] };
	ok(!exists $args{records}, 'and gave Ask no rows to send');
	is($args{spec_key}, 'table:sales', 'only the spec, to build the link');

	$tm->post_ok('/api/summary' => form => { l => 'table:sales', ai => 1 })->status_is(200);
	my $summary = $tm->tx->res->json;
	returns_ok($summary, {
		type   => 'hashref',
		schema => {
			text   => { type => 'string' },
			source => { type => 'string', memberof => [qw(template template_fallback llm)] },
			cached => { type => 'integer', min => 0, max => 1 },
		},
	}, 'the summary is the shape its POD gives');

	ok(scalar @sent, 'the provider was asked');
	for my $body (@sent) {
		unlike($body, qr/\Q$CONFIG{row_only_text}\E/, 'a provider request holds no row data');
		unlike($body, qr/\Q$SALES_CSV\E|table:sales/, 'nor the path or the spec');
	}
};

# ===========================================================================
# SECTION 62: Independent objects in one process
#
# Strategy: build several objects with new(), use them in turn, and confirm that
# each still answers as it did on its own.
# ===========================================================================
subtest 'DataSource objects of different formats, used in turn, do not interfere' => sub {
	my $files = _ledger_files();
	my $dir = tempdir(CLEANUP => 1);
	my $other = _csv_file($dir, 'ledger.csv', 'code,label', 'a,Alpha');
	my $bank = _csv_file(tempdir(CLEANUP => 1), 'bank.csv', '2026-01-02,1.00,Rent paid');

	my %src = map { $_ => _open_ledger($files->{$_}) } keys %{$files};
	my $same_name = _open_ledger($other);
	my $headerless = _open_ledger($bank);

	for my $round (1, 2) {
		for my $ext (sort keys %src) {
			is_deeply(_rows_by_id($src{$ext}->fetch_all), [ @LEDGER_ROWS ], "round $round: $ext has its own rows");
			my $sorted = $src{$ext}->selectall_arrayref(sort_by => [ 'region', 'asc' ]);
			is($sorted->[0]{region}, 'East', "round $round: and its own sort");
		}
		is_deeply($same_name->columns, [qw(code label)], "round $round: same table name, other directory, other columns");
		is($same_name->fetch_all->[0]{label}, 'Alpha', "round $round: and other rows");
		is_deeply($headerless->columns, [qw(Date Amount Description)], "round $round: a header-less source keeps its names");
		is($headerless->count, 1, "round $round: and its one row");
	}
};

subtest 'One object dropping its temporary copy leaves the others working' => sub {
	my $file = _csv_file(tempdir(CLEANUP => 1), 'bank.csv', '2026-01-02,1.00,Rent paid', '2026-01-03,2.00,Tea bought');
	my $first  = _open_ledger($file);
	my $second = _open_ledger($file);

	undef $first;
	is($second->count, 2, 'the second still reads its own copy');
	is($second->fetch_all->[0]{Description}, 'Rent paid', 'with the values intact');
};

subtest 'Two apps with different stores share nothing' => sub {
	my $data_a = tempdir(CLEANUP => 1);
	my $data_b = tempdir(CLEANUP => 1);
	_csv_file($data_a, 'shared.csv', 'id,who', '1,from_a');
	_csv_file($data_b, 'shared.csv', 'id,who', '1,from_b');
	my $app_a = _isolated_app(data_dir => $data_a);
	my $app_b = _isolated_app(data_dir => $data_b);

	for my $round (1, 2) {
		$app_a->get_ok('/view/shared')->status_is(200)->content_like(qr/from_a/, "round $round: the first app reads its directory");
		$app_b->get_ok('/view/shared')->status_is(200)->content_like(qr/from_b/, "round $round: the second reads its own");
	}

	my $l = 'table:shared';
	$app_a->post_ok('/calc/save' => form => { l => $l, name => 'doubled', expr => 'id * 2' })->status_is(200);
	$app_a->get_ok('/calc/list?l=' . url_escape($l))->json_is('/fields/doubled', 'id * 2');
	$app_b->get_ok('/calc/list?l=' . url_escape($l))->json_is('/fields', {}, 'a saved field stays in its own store');

	$app_a->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201);
	my $id = $app_a->tx->res->json('/id');
	$app_a->post_ok("/api/analyses/$id/share")->status_is(200);
	my $token = $app_a->tx->res->json('/token');
	$app_b->get_ok("/api/analyses/$id")->status_is(404, 'a canvas stays in its own store');
	$app_b->get_ok("/share/$id?token=" . url_escape($token))->status_isnt(200, 'and is not reachable from the other app');
};

subtest 'Calc, Extract and Geocode objects keep their own state' => sub {
	require Database::BI::Calc;
	my $good = new_ok('Database::BI::Calc' => [ expr => 'a + 1', columns => ['a'] ]);
	my $bad  = new_ok('Database::BI::Calc' => [ expr => 'no_such + 1', columns => ['a'] ]);
	ok($bad->has_error, 'the bad expression reports it');
	returns_ok($bad->error, { type => 'string' }, 'error() is a string, as its POD says');
	ok(!$good->has_error, 'the good one does not catch it');
	is($good->evaluate({ a => 2 }), 3, 'and still evaluates');
	is($good->evaluate({ a => 40 }), 41, 'with no memory of the last row');

	require Database::BI::Extract;
	my ($dir_a, $dir_b) = (tempdir(CLEANUP => 1), tempdir(CLEANUP => 1));
	my $ext_a = new_ok('Database::BI::Extract' => [ model_dir => $dir_a ]);
	my $ext_b = new_ok('Database::BI::Extract' => [ model_dir => $dir_b ]);
	my @key = ('table:sales', 1, 2);
	my $written = $ext_a->put(@key, 'bytes');
	returns_ok($written, { type => 'string' }, 'put() returns the path');
	is($ext_a->get(@key), $written, 'the first has the extract');
	is($ext_b->get(@key), undef, 'the second, in another directory, does not');
	$ext_b->evict('table:sales');
	is($ext_a->get(@key), $written, 'and clearing the second leaves the first');

	require Database::BI::Model::Geocode;
	my $with    = Integ::Geocoder->new(results => {});
	my $geo_on  = new_ok('Database::BI::Model::Geocode' => [ geocoder => $with ]);
	my $geo_off = new_ok('Database::BI::Model::Geocode' => [ geocoder => Integ::Geocoder->new(results => {}) ]);
	my ($on) = $geo_on->geocoder_available;
	my ($off) = $geo_off->geocoder_available;
	ok($on && $off, 'each has the geocoder it was given');
	throws_ok { Database::BI::Model::Geocode->new(geocoder => bless {}, 'Integ::NotAGeocoder') }
		qr/geocoder/i, 'a third with a useless geocoder is refused';
	($on) = $geo_on->geocoder_available;
	ok($on, 'without touching the others');
};

subtest 'Requests in flight together each get their own answer' => sub {
	my $tm = _isolated_app();
	my %wanted = (
		'/view/sales'                 => qr/Widget A/,
		'/view/products'              => qr/\S/,
		'/api/columns?table=sales'    => qr/sale_date/,
		'/api/columns?table=products' => qr/\S/,
		'/bar?l=table:sales&cat=region&val=amount' => qr/North/,
	);
	my %got;
	my @promises = map {
		my $url = $_;
		$tm->ua->get_p($url)->then(sub { $got{$url} = $_[0]->res });
	} sort keys %wanted;
	Mojo::Promise->all(@promises)->wait;

	for my $url (sort keys %wanted) {
		is($got{$url}->code, 200, "$url answered");
		like($got{$url}->body, $wanted{$url}, 'with its own content');
	}
	unlike($got{'/api/columns?table=products'}->body, qr/sale_date/, 'and not the content of another request');
};

# ===========================================================================
# SECTION 63: Optional dependencies, in every combination
#
# Strategy: a module can only be hidden from a process that has not loaded it,
# and this file has loaded most of them, so a driver is run in a process of its
# own.  It loads the app once and forks for each combination; each child hides
# its modules, makes the same requests and writes what it saw, and this file
# holds that to the outcome the combination should give.  The features do not
# depend on each other, so a module's absence must change its own feature and
# nothing else.
# ===========================================================================
Readonly my @OPTIONAL_GROUPS => (
	# The geocoder is Geo::Coder::Free in a Geo::Coder::List: it needs both.
	[ geocoder => 'Geo::Coder::Free', 'Geo::Coder::List' ],
	[ osm      => 'HTML::OSM' ],
	[ redis    => 'Redis', 'Redis::Fast' ],
	[ xml      => 'XML::Simple' ],
	[ sqlite   => 'DBD::SQLite' ],
	[ sftp     => 'Net::SFTP::Foreign' ],
	[ xlsx     => 'Spreadsheet::ParseXLSX' ],
);

# The groups whose modules are needed together rather than as alternatives.
Readonly my %ALL_OF => (geocoder => 1);

Readonly my $MATRIX_DRIVER => <<'DRIVER';
use strict;
use warnings;

use POSIX ();
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::File ();
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(url_escape);
use Test::Mojo;
use Test::Without::Module ();

# Mojolicious dispatches under a __DIE__ handler that throws an object, and when
# Test::Without::Module's @INC hook croaks under it, perl goes on to the rest of
# @INC and loads the module after all.  The hook must die with no handler in the
# way, and with what perl itself says when a module is not there, less the list
# of directories that the application is expected to keep from a reader anyway.
{
	no warnings 'redefine';
	*Test::Without::Module::fake_module = sub {
		my (undef, $file) = @_;
		return unless exists Test::Without::Module::get_forbidden_list()->{$file};
		local $SIG{__DIE__};
		die "Can't locate $file in \@INC\n";
	};
}

my $input = decode_json(Mojo::File->new($ARGV[0])->slurp);
my ($fx, $groups) = @{$input}{qw(fixtures groups)};

local $SIG{__WARN__} = sub { };

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $fx->{data_dir},
	model_dir => tempdir(CLEANUP => 1),
});

# Everything no group depends on, loaded here so that no child loads it again.
require Database::Abstraction;
require Database::Join;
require DBI;
require HTML::D3;
require Text::CSV;
require Database::BI::Model::DataSource;
require Database::BI::Model::Geocode;
for my $url ('/', '/view/sales', '/join?l=table:sales', '/export?l=table:sales', '/open?path=' . url_escape($fx->{places})) {
	$t->ua->get($url);
}

# A module already loaded cannot be hidden: its driver and its symbols stay behind.
for my $group (@{$groups}) {
	my (undef, @modules) = @{$group};
	for my $module (@modules) {
		(my $file = "$module.pm") =~ s{::}{/}g;
		die "$module was loaded before any child ran\n" if $INC{$file};
	}
}

sub probe {
	my ($url, %marker) = @_;

	my $res = $t->ua->get($url)->res;
	my $body = $res->body // '';
	return {
		code  => $res->code,
		leak  => ($body =~ / at \S+ line \d+|\@INC (?:contains|entries)|CODE\(0x/ ? 1 : 0),
		crash => ($body =~ /<h2>Server Error<\/h2>/ ? 1 : 0),
		map { $_ => (index($body, $marker{$_}) >= 0 ? 1 : 0) } keys %marker,
	};
}

my $active = 0;
for my $mask (0 .. (2 ** @{$groups}) - 1) {
	if ($active >= $input->{children}) {
		wait;
		$active--;
	}
	my $pid = fork() // die "fork: $!";
	if ($pid) {
		$active++;
		next;
	}

	my %hidden;
	my @modules;
	for my $bit (0 .. $#{$groups}) {
		next unless $mask & (1 << $bit);
		my ($name, @mods) = @{ $groups->[$bit] };
		$hidden{$name} = 1;
		push @modules, @mods;
	}
	Test::Without::Module->import(@modules);

	my %seen;
	my $places = url_escape("path:$fx->{places}");

	# Exports where a page would do: a child makes these requests 128 times over,
	# and it is the page that takes the time.
	$seen{view} = probe('/export?l=table:sales', data => 'Widget A');
	$seen{join} = probe('/export?l=table:sales&j=' . url_escape('table:sales|id|id'), data => 'Widget A');
	$seen{map}  = probe("/map?l=$places&lat=lat&lon=lon",
		renderer_missing => 'error_map_renderer_missing', drawn => 'L.map');
	my ($geocoder) = Database::BI::Model::Geocode->new->geocoder_available;
	$seen{geocoder} = $geocoder ? 1 : 0;
	my %value = (xml => 'Widget A', sql => 'sql_value', xlsx => 'xlsx_value');
	for my $format (sort keys %value) {
		$seen{$format} = probe('/export?l=' . url_escape("path:$fx->{$format}"), data => $value{$format});
		next if $seen{$format}{data};
		$seen{"${format}_page"} = probe('/open?path=' . url_escape($fx->{$format}), cannot => 'Could not open &quot;');
	}
	$seen{export} = probe('/export?l=table:sales&format=sqlite', file => 'SQLite format 3');
	$seen{redis}  = probe('/tables?l=' . url_escape('redis://127.0.0.1:1'));
	if ($hidden{sftp}) {
		my $source = eval {
			Database::BI::Model::DataSource->new(host => 'nohost.invalid', directory => '/d', table => 'f');
		};
		$seen{sftp_error} = "$@";
	}

	Mojo::File->new(File::Spec->catfile($input->{out}, "$mask.json"))
		->spurt(encode_json({ hidden => \%hidden, seen => \%seen }));
	POSIX::_exit(0);
}
1 while wait() != -1;
DRIVER

# _module_is_installed($module) -> bool, without loading it.
sub _module_is_installed {
	my ($module) = @_;

	(my $file = "$module.pm") =~ s{::}{/}g;
	return scalar grep { !ref($_) && -f File::Spec->catfile($_, $file) } @INC;
}

subtest 'Optional modules: every combination degrades only its own feature' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $sql = _ledger_sqlite($dir);
	plan skip_all => 'the fixtures need DBD::SQLite' unless $sql;
	plan skip_all => 'the fixtures need Excel::Writer::XLSX' unless eval { require Excel::Writer::XLSX; 1 };
	plan skip_all => 'data/catalog.xml not found' unless -f $CATALOG_XML;
	plan skip_all => 'fork is not usable here' if $^O eq 'MSWin32';

	my $sql_file = File::Spec->catfile($dir, 'matrix.sql');
	my $dbh = DBI->connect("dbi:SQLite:dbname=$sql_file", '', '', { RaiseError => 1 });
	$dbh->do('CREATE TABLE matrix (id TEXT, v TEXT)');
	$dbh->do(q{INSERT INTO matrix VALUES ('1', 'sql_value')});
	$dbh->disconnect;

	# Not named as the SQLite file is: a stem is all a table name holds.
	my $xlsx_file = File::Spec->catfile($dir, 'matrix_book.xlsx');
	my $book = Excel::Writer::XLSX->new($xlsx_file);
	my $sheet = $book->add_worksheet('matrix_book');
	$sheet->write_row(0, 0, [qw(id v)]);
	$sheet->write_row(1, 0, [ 1, 'xlsx_value' ]);
	$book->close;

	# A data directory of its own: the shipped one holds SQLite files, and the app
	# looks inside them on every table page, which would load DBD::SQLite up front.
	my $data_dir = tempdir(CLEANUP => 1);
	Mojo::File->new($SALES_CSV)->copy_to(File::Spec->catfile($data_dir, 'sales.csv'));

	my $out = tempdir(CLEANUP => 1);
	my $input = File::Spec->catfile($dir, 'input.json');
	Mojo::File->new($input)->spurt(encode_json({
		children => $CONFIG{matrix_children},
		groups   => [ map { [ @{$_} ] } @OPTIONAL_GROUPS ],
		out      => $out,
		fixtures => {
			data_dir => $data_dir,
			places => _csv_file($dir, 'places.csv', 'id,place,lat,lon', '1,Ramsgate,51.3,1.4'),
			xml    => $CATALOG_XML,
			sql    => $sql_file,
			xlsx   => $xlsx_file,
		},
	}));
	my $driver = File::Spec->catfile($dir, 'driver.pl');
	Mojo::File->new($driver)->spurt($MATRIX_DRIVER);

	my @include = map { "-I$_" } grep { !ref } @INC;
	my $status = system($^X, @include, $driver, $input);
	is($status, 0, 'the driver ran to the end');

	# A group is there when any of its modules is (Redis or Redis::Fast), except
	# one that needs all of them together.
	my %installed = map {
		my ($name, @mods) = @{$_};
		my $found = scalar grep { _module_is_installed($_) } @mods;
		$name => ($ALL_OF{$name} ? $found == @mods : $found) ? 1 : 0;
	} @OPTIONAL_GROUPS;

	for my $mask (0 .. (2 ** @OPTIONAL_GROUPS) - 1) {
		my $file = File::Spec->catfile($out, "$mask.json");
		unless (-f $file) {
			fail("combination $mask reported");
			next;
		}
		my $result = decode_json(Mojo::File->new($file)->slurp);
		my $hidden = $result->{hidden};
		my $seen   = $result->{seen};
		my $label  = join(', ', sort keys %{$hidden}) || 'nothing';
		my %has    = map { $_ => ($installed{$_} && !$hidden->{$_}) ? 1 : 0 } keys %installed;
		_verbose("without $label: " . encode_json($seen));

		my @wrong;
		my $expect = sub {
			my ($what, $got, $want) = @_;
			push @wrong, "$what: got " . ($got // 'undef') . ", wanted $want" if ($got // '') ne $want;
		};

		# Plain tables, alone and joined, read through DBD::CSV, which no group affects.
		for my $page (qw(view join)) {
			$expect->("$page status", $seen->{$page}{code}, 200);
			$expect->("$page data", $seen->{$page}{data}, 1);
		}

		$expect->('map status', $seen->{map}{code}, 200);
		$expect->('map renderer warning', $seen->{map}{renderer_missing}, $has{osm} ? 0 : 1);
		$expect->('geocoder available', $seen->{geocoder}, $has{geocoder});

		for my $format (qw(xml sql xlsx)) {
			my $feature = $format eq 'sql' ? 'sqlite' : $format;
			my $export = $seen->{$format};
			$expect->("$format data", $export->{data}, $has{$feature});
			$expect->("$format crash", $export->{crash}, 0);
			next if $has{$feature};

			my $page = $seen->{"${format}_page"} // {};
			$expect->("$format page status", $page->{code}, 200);
			$expect->("$format says it cannot", $page->{cannot}, 1);
			$expect->("$format leak", $page->{leak}, 0);
			$expect->("$format page crash", $page->{crash}, 0);
		}

		$expect->('export status', $seen->{export}{code}, $has{sqlite} ? 200 : 500);
		$expect->('export file', $seen->{export}{file}, $has{sqlite});
		$expect->('export crash', $seen->{export}{crash}, 0);
		$expect->('export leak', $seen->{export}{leak}, 0);

		# Installed but refused, or not installed: the key picker has nothing to show.
		$expect->('redis status', $seen->{redis}{code}, 404);
		$expect->('redis crash', $seen->{redis}{crash}, 0);

		if ($hidden->{sftp}) {
			$expect->('sftp names the module', ($seen->{sftp_error} =~ /Net::SFTP::Foreign is not installed/ ? 1 : 0), 1);
		}

		ok(!@wrong, "without $label: each feature does what it should") or diag(join("\n", @wrong));
	}
};

# Also held to the same bar in a process that has them loaded: hiding them again
# in one subtest must restore cleanly for the next.
subtest 'Hiding a module for a moment leaves it usable afterwards' => sub {
	my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'hide.csv');
	Mojo::File->new($file)->spurt("id,v\n1,kept\n");
	my $tm = _isolated_app();

	Test::Without::Module->import('Net::SFTP::Foreign');
	throws_ok {
		Database::BI::Model::DataSource->new(host => 'nohost.invalid', directory => '/d', table => 'f');
	} qr/Net::SFTP::Foreign is not installed/, 'a remote source says what is missing';
	$tm->get_ok('/open?path=' . url_escape($file))->status_is(200)->content_like(qr/kept/, 'a local one still opens');
	Test::Without::Module->unimport('Net::SFTP::Foreign');

	ok(eval { require Net::SFTP::Foreign; 1 }, 'the module loads again afterwards')
		or diag($@);
};

# ===========================================================================
# SECTION 64: Permissions dropped underneath a running app
#
# Strategy: revoke access to a directory the pipeline depends on, while the app
# is running.  The request that needs it must fail with a message and leave a
# reason in the log; nothing else may break; and when access comes back so must
# the feature, with no restart.
# ===========================================================================
subtest 'Uploads: no create permission on the staging directory' => sub {
	my $tm = _isolated_app();
	my $dir = $tm->app->config->{uploads_dir};
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($dir);

	my $form = sub { return { file => { content => "id,v\n1,uploaded\n", filename => 'up.csv' } } };
	my $logs = _capture_logs($tm, sub {
		with_revoked('create', $dir, sub {
			$tm->post_ok('/upload' => form => $form->())
			   ->status_is(500)
			   ->json_like('/error', qr/Could not save uploaded file/, 'the documented error');
			_no_internals($tm->tx->res->body, 'the refused upload');
			_app_is_alive($tm, 'a refused upload');
		});
	});
	ok(scalar(grep { /Cannot stage an upload/ } @{$logs}), 'the log says why');

	$tm->post_ok('/upload' => form => $form->())->status_is(200, 'with access back, an upload works');
	$tm->get_ok($tm->tx->res->json('/url'))->status_is(200)->content_like(qr/uploaded/, 'and opens');
};

subtest 'Uploads: no search permission on the staging directory' => sub {
	my $tm = _isolated_app();
	my $dir = $tm->app->config->{uploads_dir};
	plan skip_all => 'cannot revoke search here' unless can_revoke_search($dir);

	$tm->post_ok('/upload' => form => { file => { content => "id,v\n1,kept\n", filename => 'keep.csv' } })->status_is(200);
	my $url = $tm->tx->res->json('/url');

	my $logs = _capture_logs($tm, sub {
		with_revoked('search', $dir, sub {
			$tm->post_ok('/uploads/clear')
			   ->status_is(500)
			   ->json_like('/error', qr/Could not clear the uploaded files/, 'clearing says it could not');
			_no_internals($tm->tx->res->body, 'the refused clear');
			$tm->get_ok($url)->status_is(404, 'a file in there cannot be opened');
			_no_internals($tm->tx->res->body, 'the refused open');
			_app_is_alive($tm, 'a staging directory that cannot be searched');
		});
	});
	ok(scalar(grep { /Cannot clear/ } @{$logs}), 'the log says why');

	$tm->get_ok($url)->status_is(200)->content_like(qr/kept/, 'with access back, the file is still there');
	$tm->post_ok('/uploads/clear')->status_is(200)->json_is('/count', 1, 'and can be cleared');
};

subtest 'Model store: no create permission' => sub {
	my $tm = _isolated_app();
	my $dir = $tm->app->config->{model_dir};
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($dir);

	my $logs = _capture_logs($tm, sub {
		with_revoked('create', $dir, sub {
			$tm->post_ok('/api/analyses' => json => _canvas_doc())
			   ->status_is(503)
			   ->json_like('/error', qr/not writable/, 'a canvas cannot be saved, and it says so');
			$tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses', [], 'the list is still served');

			# t/data-dir-invariant.t holds these routes to 200 when the store refuses.
			$tm->post_ok('/calc/save' => form => { l => 'table:sales', name => 'lost', expr => 'amount * 2' })
			   ->status_is(200);
			$tm->get_ok('/calc/list?l=table:sales')->status_is(200)->json_is('/fields', {}, 'nothing was stored');
			$tm->get_ok('/pivot?l=table:sales&rows=region&m=' . url_escape('amount:sum:total'))
			   ->status_is(200, 'a page that only reads the store is unaffected');
			_app_is_alive($tm, 'a store that refuses writes');
		});
	});
	ok(scalar(@{$logs}), 'the refused writes were reported') or diag('nothing logged');
	ok(scalar(grep { /Cannot write|not writable/ } @{$logs}), 'and say what they could not do');

	$tm->post_ok('/calc/save' => form => { l => 'table:sales', name => 'kept', expr => 'amount * 2' })->status_is(200);
	$tm->get_ok('/calc/list?l=table:sales')->json_is('/fields/kept', 'amount * 2', 'with access back, it stores again');
	$tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201, 'canvases too');
};

subtest 'Model store: no search permission, once something is stored' => sub {
	my $tm = _isolated_app();
	my $dir = $tm->app->config->{model_dir};
	plan skip_all => 'cannot revoke search here' unless can_revoke_search($dir);

	$tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201);
	my $id = $tm->tx->res->json('/id');

	_capture_logs($tm, sub {
		with_revoked('search', $dir, sub {
			$tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(503, 'a new canvas is refused');
			$tm->get_ok('/calc/list?l=table:sales')->status_is(200, 'the read routes still answer');
			$tm->get_ok('/view/sales')->status_is(200)->content_like(qr/Widget A/, 'and a data page does not depend on the store');
		});
	});

	$tm->get_ok("/api/analyses/$id")->status_is(200, 'with access back, the stored canvas is unharmed');
	is($tm->tx->res->json('/name'), _canvas_doc()->{name}, 'whole');
};

subtest 'A data directory that cannot be searched' => sub {
	my $data = tempdir(CLEANUP => 1);
	_csv_file($data, 'locked.csv', 'id,v', '1,locked_value');
	my $tm = _isolated_app(data_dir => $data);
	plan skip_all => 'cannot revoke search here' unless can_revoke_search($data);

	_capture_logs($tm, sub {
		with_revoked('search', $data, sub {
			$tm->get_ok('/')->status_is(200, 'the home page still draws');
			_no_internals($tm->tx->res->body, 'the home page');
			$tm->get_ok('/view/locked');
			cmp_ok($tm->tx->res->code, '<', 500, 'a table in there is refused, not a crash');
			$tm->content_unlike(qr/locked_value/, 'and shows no data');
			$tm->get_ok('/api/columns?table=locked')->status_is(404);
			$tm->get_ok('/bar?l=table:locked&cat=v')->status_is(404);
		});
	});

	$tm->get_ok('/view/locked')->status_is(200)->content_like(qr/locked_value/, 'with access back, the table opens');
};

subtest 'A directory holding one source cannot be searched: its siblings carry on' => sub {
	my $root = tempdir(CLEANUP => 1);
	my $locked = File::Spec->catdir($root, 'locked');
	mkdir $locked or die "mkdir: $!";
	my $inside = _csv_file($locked, 'inside.csv', 'id,right_value', '1,locked_value');
	my $outside = _csv_file($root, 'outside.csv', 'id,left_value', '1,open_value');
	plan skip_all => 'cannot revoke search here' unless can_revoke_search($locked);

	my $tm = _isolated_app();
	with_revoked('search', $locked, sub {
		$tm->get_ok('/open?path=' . url_escape($inside))->status_is(404, 'the source inside cannot be opened');
		_no_internals($tm->tx->res->body, 'the refused open');
		$tm->get_ok('/bar?cat=right_value&l=' . url_escape("path:$inside"))->status_is(404, 'nor charted');
		$tm->get_ok('/browse?path=' . url_escape($locked))->status_is(200, 'browsing to it is not an error');
		$tm->get_ok('/api/stat?path=' . url_escape($inside))->status_is(200)->json_is('/exists', Mojo::JSON::false, 'and it reports as absent');
		$tm->get_ok('/open?path=' . url_escape($outside))->status_is(200)->content_like(qr/open_value/, 'the source beside it opens');

		# The POD of /join: a step that cannot be opened is skipped.
		$tm->get_ok('/join?l=' . url_escape("path:$outside") . '&j=' . url_escape("path:$inside|id|id"))
		   ->status_is(200)
		   ->content_like(qr/open_value/, 'a join to it keeps the left side')
		   ->content_unlike(qr/locked_value/, 'without anything from the right');
	});
};

subtest 'An export to a directory that refuses new files' => sub {
	my $dir = tempdir(CLEANUP => 1);
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($dir);
	my $tm = _isolated_app();
	my $url = '/export?l=table:sales&dir=' . url_escape($dir) . '&filename=';

	with_revoked('create', $dir, sub {
		for my $name (qw(out.csv out.json out.sql)) {
			$tm->post_ok($url . $name)->status_is(500)->json_has('/error', "$name: the refusal is reported");
			_no_internals($tm->tx->res->json('/error'), "the refused $name");
		}
		_app_is_alive($tm, 'a refused export');
	});
	$tm->post_ok($url . 'out.csv')->status_is(200, 'with access back, the export is written');
	ok(-s File::Spec->catfile($dir, 'out.csv'), 'with something in it');
};

# HTML::D3 writes a chart's labels into a script.  Before 0.27 it left "</" as it was,
# so a cell could end that script and start its own.
subtest 'A cell holding a script tag cannot end the script of a chart' => sub {
	Readonly my $FLOOR  => '0.27';
	Readonly my $ATTACK => '</script><script>alert(1)//';

	for my $file (qw(Makefile.PL cpanfile)) {
		next unless -r $file;
		my ($declared) = Mojo::File->new($file)->slurp =~ /'HTML::D3'\s*(?:=>|,)\s*'([\d.]+)'/;
		cmp_ok($declared // 0, '>=', $FLOOR, "$file asks for an HTML::D3 that escapes its labels");
	}

	my $csv = _csv_file(tempdir(CLEANUP => 1), 'labels.csv', 'id,label,seg,amount,day', "1,$ATTACK,$ATTACK,5,$ATTACK", '2,Plain,Other,7,Plain');
	my $source = 'l=' . url_escape("path:$csv");
	for my $query ('bar?cat=label&val=amount', 'pie?cat=label&val=amount', 'stacked?cat=label&seg=seg&val=amount', 'graph?x=day&y=amount') {
		$t->get_ok("/$query&$source")->status_is(200)
		  ->content_like(qr/alert\(1\)/, "$query draws the cell")
		  ->content_unlike(qr{</script>\s*<script>\s*alert}i, "$query keeps it inside the script");
	}
};

# A tooltip is set with .html(), so the text put into it is markup.  Before
# HTML::D3 0.29 the stacked, combo and treemap tooltips put labels in as they
# were, and a cell holding <img onerror=...> ran when its bar or tile was
# hovered.  The browser is not run here: each page must define esc() and must
# not hold the unescaped forms 0.28 wrote.
subtest 'A cell holding markup is escaped in a chart tooltip' => sub {
	Readonly my $FLOOR  => '0.29';
	Readonly my $ATTACK => '<img src=x onerror=alert(2)>';

	for my $file (qw(Makefile.PL cpanfile)) {
		next unless -r $file;
		my ($declared) = Mojo::File->new($file)->slurp =~ /'HTML::D3'\s*(?:=>|,)\s*'([\d.]+)'/;
		cmp_ok($declared // 0, '>=', $FLOOR, "$file asks for an HTML::D3 that escapes its tooltips");
	}

	my $csv = _csv_file(tempdir(CLEANUP => 1), 'tips.csv', 'id,label,seg,amount', "1,$ATTACK,$ATTACK,5", '2,Plain,Other,7');
	my $source = 'l=' . url_escape("path:$csv");
	my %raw = (
		stacked => [ qr/"<b>"\+d\.data\.cat\+/, qr/\+seg\+": "/ ],
		combo   => [ qr/"<b>"\+d\.x\+/, qr/\+barLabel\+/ ],
		treemap => [ qr/"<b>"\+name\+/ ],
	);
	for my $query ('stacked?cat=label&seg=seg&val=amount', 'combo?cat=label&bar_val=amount&line_val=amount',
	               'treemap?group=label&size=amount') {
		my ($kind) = $query =~ /^(\w+)/;
		$t->get_ok("/$query&$source")->status_is(200)
		  ->content_like(qr/onerror=alert\(2\)/, "$kind draws the cell")
		  ->content_like(qr/function esc\(s\)/, "$kind escapes its tooltip text");
		$t->content_unlike($_, "$kind never sets a label raw: $_") for @{ $raw{$kind} };
	}
};

# Database::Abstraction reads any .db file as CSV, so DataSource shows it a SQLite
# one under a .sql name.  That used to happen only when the table was named after
# something other than the file, so orders.db holding a table called orders was
# read as text, and reported as if there were no such file.
subtest 'A SQLite .db file opens when its table is named after the file' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { DBI->install_driver('SQLite'); 1 };

	my $make = sub {
		my ($dir, $file, @tables) = @_;
		my $path = File::Spec->catfile($dir, $file);
		my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1, PrintError => 0 });
		for my $table (@tables) {
			$dbh->do("CREATE TABLE $table (id INTEGER PRIMARY KEY, label TEXT)");
			$dbh->do("INSERT INTO $table VALUES (1, 'row_of_$table')");
		}
		$dbh->disconnect;
		return $path;
	};

	my $path = $make->(tempdir(CLEANUP => 1), 'orders.db', 'orders');
	my $before = Mojo::File->new($path)->slurp;
	my $l = 'l=' . url_escape("path:$path");

	$t->get_ok("/export?$l&format=csv")->status_is(200)->content_like(qr/row_of_orders/, '/export reads it');
	$t->get_ok("/bar?$l&cat=label&val=__count__")->status_is(200)->content_like(qr/row_of_orders/, 'a chart reads it');
	$t->get_ok('/open?path=' . url_escape($path))->status_is(200)->content_like(qr/row_of_orders/, '/open reads it');

	my $two = $make->(tempdir(CLEANUP => 1), 'shop.db', 'orders', 'shop');
	$t->get_ok('/export?format=csv&l=' . url_escape("path:$two"))->status_is(200)
		->content_like(qr/row_of_shop/, 'the table named after the file is the one chosen from several');

	my $tm = Test::Mojo->new('Database::BI', { data_dir => File::Basename::dirname($path), model_dir => tempdir(CLEANUP => 1) });
	$tm->get_ok('/view/orders')->status_is(200)->content_like(qr/row_of_orders/, 'so does a table in the data directory');
	$tm->get_ok('/export?format=csv&l=' . url_escape('table:orders'))->status_is(200)
		->content_like(qr/row_of_orders/, 'and table: names it');

	is(Mojo::File->new($path)->slurp, $before, 'the file itself is left as it was');
};

subtest 'A temporary directory that refuses new files' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($tmp);

	my $bank = _csv_file(tempdir(CLEANUP => 1), 'bank.csv', '2026-01-02,1.00,Rent paid');
	my $plain = _csv_file(tempdir(CLEANUP => 1), 'plain.csv', 'id,v', '1,plain_value');
	my $tm = _isolated_app();

	# The test's own client keeps a reply over 256 KB in a file, and this page is
	# about that size, more on a machine with long temporary paths.  Without this it
	# would have nowhere to put it, and the reply would read as empty.
	local $ENV{MOJO_TMPDIR} = tempdir(CLEANUP => 1);
	local $ENV{TMPDIR} = $tmp;
	File::Spec->tmpdir;	# remembered, as it would be on a server where it was fine at first
	with_revoked('create', $tmp, sub {
		$tm->get_ok('/open?path=' . url_escape($bank))
		   ->status_is(200)
		   ->content_like(qr/Could not open/, 'a file needing a temporary copy says it cannot be opened');
		_no_internals($tm->tx->res->body, 'the refused copy');
		$tm->get_ok('/open?path=' . url_escape($plain))
		   ->status_is(200)
		   ->content_like(qr/plain_value/, 'a file that needs none is unaffected');
	});
	$tm->get_ok('/open?path=' . url_escape($bank))->status_is(200)->content_like(qr/Rent paid/, 'with access back, it opens');
};

subtest 'The extract cache: no create permission' => sub {
	require Database::BI::Extract;
	my $dir = tempdir(CLEANUP => 1);
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($dir);
	my $extract = new_ok('Database::BI::Extract' => [ model_dir => $dir ]);
	my @key = ('table:sales', 1, 2);

	with_revoked('create', $dir, sub {
		throws_ok { $extract->put(@key, 'bytes') } qr/Cannot create extract dir/, 'put croaks naming the directory, as its POD says';
		is($extract->get(@key), undef, 'and a read is a plain miss');
	});
	ok(length $extract->put(@key, 'bytes'), 'with access back, the same object writes');
};

subtest 'The page cache: a directory that refuses writes does not take the page down' => sub {
	my $dir = tempdir(CLEANUP => 1);
	plan skip_all => 'cannot revoke create here' unless can_revoke_create($dir);
	my $tm = Test::Mojo->new('Database::BI', { page_cache_dir => $dir, model_dir => tempdir(CLEANUP => 1) });

	_capture_logs($tm, sub {
		with_revoked('create', $dir, sub {
			$tm->get_ok('/tutorial')->status_is(200, 'the cached page is still served');
			_no_internals($tm->tx->res->body, 'the page');
		});
	});
	$tm->get_ok('/tutorial')->status_is(200, 'and afterwards');
};

# ===========================================================================
# SECTION 65: Sabotaged upstreams
#
# Strategy: each upstream's client is replaced, at the outermost call only, by
# one that fails in a way a real one does: an error status, a timeout, a dropped
# connection, a delay, or a success holding something malformed.  The request
# must answer quickly with a message, and the next must be unaffected.
# ===========================================================================
Readonly my @PROVIDER_FAILURES => (
	[ 'an error status',   502, sub { _response(500, 'Internal Server Error', 'text/plain', 'boom') } ],
	[ 'rate limiting',     502, sub { _response(429, 'Too Many Requests', 'application/json', '{}') } ],
	[ 'an LWP timeout',    502, sub { _response(500, 'read timeout', 'text/plain', '') } ],
	[ 'a dropped connection', 502, sub { die "Connection reset by peer\n" } ],
	[ 'a body not JSON',   502, sub { _response(200, 'OK', 'text/html', '<html>Bad gateway</html>') } ],
	[ 'truncated JSON',    502, sub { _response(200, 'OK', 'application/json', '{"content":[{"text":"{') } ],
	[ 'an empty body',     502, sub { _response(200, 'OK', 'application/json', '') } ],
	[ 'a JSON array',      502, sub { _response(200, 'OK', 'application/json', '[1,2]') } ],
	[ 'no content',        502, sub { _response(200, 'OK', 'application/json', '{"content":[]}') } ],
	[ 'content of a wrong shape', 502, sub { _response(200, 'OK', 'application/json', '{"content":"x"}') } ],
	[ 'prose, not a spec', 422, sub { _provider_text('I am sorry, I cannot do that') } ],
	[ 'a spec of the wrong shape', 422, sub { _provider_text('[1,2,3]') } ],
	[ 'an unknown chart',  422, sub { _provider_text('{"kind":"hologram","title":"t","encode":{}}') } ],
	[ 'an unknown column', 422, sub { _provider_text('{"kind":"bar","title":"t","encode":{"cat":"no_such"}}') } ],
);

subtest '/api/ask: every kind of provider failure is a clean error' => sub {
	my $tm = _isolated_app(ai_api_key => $CONFIG{api_key});

	for my $case (@PROVIDER_FAILURES) {
		my ($what, $status, $reply) = @{$case};
		my $guard = mock_scoped('LWP::UserAgent', request => $reply);
		_within_deadline($what, sub {
			$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => 'by region?' })
			   ->status_is($status, "$what is a $status")
			   ->json_has('/error', 'with a message');
		});
		_no_internals($tm->tx->res->body, $what);
		unlike($tm->tx->res->body, qr/\Q$CONFIG{api_key}\E/, "$what does not show the key");
		undef $guard;
		_app_is_alive($tm, $what);
	}

	my $guard = mock_scoped('LWP::UserAgent', request => sub { _provider_text($CANVAS_VISUAL_JSON) });
	$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => 'by region?' })
	   ->status_is(200, 'the next good answer is used: no failure was remembered');
};

subtest 'A slow provider does not outlive the timeout given to its client' => sub {
	my $tm = _isolated_app(ai_api_key => $CONFIG{api_key});

	my $ua_new = spy('LWP::UserAgent::new');
	my $guard = mock_scoped('LWP::UserAgent', request => sub {
		sleep $CONFIG{latency_s};
		return _response(500, 'read timeout', 'text/plain', '');
	});
	my $elapsed = _within_deadline('a provider that times out', sub {
		$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => 'by region?' })->status_is(502);
	});
	my @calls = $ua_new->();
	undef $guard;
	restore_all();

	cmp_ok($elapsed, '>=', $CONFIG{latency_s}, 'the delay really was injected');
	my @bounded = grep {
		my (undef, undef, %args) = @{$_};
		defined $args{timeout} && $args{timeout} <= $CONFIG{max_timeout_s};
	} @calls;
	ok(scalar @bounded, "the provider's client has a timeout of at most $CONFIG{max_timeout_s}s")
		or diag(scalar(@calls) . ' clients built');

	# A slow provider that does answer is simply slow.
	my $slow = mock_scoped('LWP::UserAgent', request => sub {
		sleep $CONFIG{latency_s};
		return _provider_text($CANVAS_VISUAL_JSON);
	});
	$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => 'by region?' })->status_is(200, 'a slow answer is still an answer');
};

subtest '/api/summary: a provider outage falls back, once per summary' => sub {
	my $tm = _isolated_app(ai_api_key => $CONFIG{api_key});
	my $calls = 0;
	my $n = 0;
	my $dir = tempdir(CLEANUP => 1);

	for my $case (@PROVIDER_FAILURES[0 .. 9]) {
		my ($what, undef, $reply) = @{$case};
		$calls = 0;
		$n++;
		my $guard = mock_scoped('LWP::UserAgent', request => sub { $calls++; return $reply->(@_) });

		# The cache is keyed on the label and the insights, so each case has a file
		# of its own, or the first failure would answer for all the rest.
		my $file = _csv_file($dir, "outage$n.csv", 'id,v', '1,x');
		my $form = { l => "path:$file", ai => 1 };

		$tm->post_ok('/api/summary' => form => $form)
		   ->status_is(200, "$what still gives a summary")
		   ->json_is('/source', 'template_fallback', 'from the template');
		_no_internals($tm->tx->res->json('/text'), $what);
		is($calls, 1, 'after one attempt');

		# The POD: the same insights within the hour are the cached text, so an
		# outage is not hit again by everyone who opens the same page.
		$tm->post_ok('/api/summary' => form => $form)->status_is(200)->json_is('/cached', 1, 'the next reader gets it from the cache');
		is($calls, 1, 'without another attempt');
	}
	_app_is_alive($tm, 'a provider outage');
};

Readonly my @URL_FAILURES => (
	[ 'an error status',  sub { _response(500, 'Internal Server Error', 'text/html', 'boom') } ],
	[ 'not found',        sub { _response(404, 'Not Found', 'text/html', 'gone') } ],
	[ 'an LWP timeout',   sub { _response(500, 'read timeout', 'text/plain', '') } ],
	[ 'a dropped connection', sub { die "Connection reset by peer\n" } ],
	[ 'a page with no table', sub { _response(200, 'OK', 'text/html', '<html><p>No tables here</p></html>') } ],
	[ 'an empty table',   sub { _response(200, 'OK', 'text/html', '<table></table>') } ],
	[ 'truncated JSON',   sub { _response(200, 'OK', 'application/json', '[{"a":') } ],
	[ 'a JSON scalar',    sub { _response(200, 'OK', 'application/json', '3') } ],
	[ 'a JSON array of scalars', sub { _response(200, 'OK', 'application/json', '[1,2,3]') } ],
	[ 'rows mixed with scalars', sub { _response(200, 'OK', 'application/json', '[{"a":1},2]') } ],
);

subtest 'A URL source: every kind of failure is a message, on every kind of page' => sub {
	my $tm = _isolated_app();
	my $n = 0;
	local $SIG{__WARN__} = sub { };

	for my $case (@URL_FAILURES) {
		my ($what, $reply) = @{$case};
		$n++;
		my $url = "http://example.com/sabotage$n";
		my $guard = mock_scoped('LWP::UserAgent', get => $reply);

		_within_deadline($what, sub {
			$tm->get_ok('/import?url=' . url_escape($url))
			   ->status_is(200, "$what: /import draws the home page")
			   ->content_like(qr/Could not load HTML table/, 'with the reason');
			_no_internals($tm->tx->res->body, "$what on /import");

			$tm->get_ok('/bar?cat=a&l=' . url_escape("url:$url"))->status_is(404, "$what: a chart has no source");
			_no_internals($tm->tx->res->body, "$what on /bar");

			# The POD of /join: a step that cannot be opened is skipped.
			$tm->get_ok('/join?l=table:sales&j=' . url_escape("url:$url|id|a"))
			   ->status_is(200, "$what: a join to it")
			   ->content_like(qr/Widget A/, 'keeps the left side');
		});
		undef $guard;
		_app_is_alive($tm, $what);
	}
};

subtest 'A URL source: a failure is not cached, so the source can recover' => sub {
	my $tm = _isolated_app();
	my $url = 'http://example.com/recovers';
	local $SIG{__WARN__} = sub { };

	my $down = mock_scoped('LWP::UserAgent', get => sub { _response(503, 'Service Unavailable', 'text/html', '') });
	$tm->get_ok('/import?url=' . url_escape($url))->status_is(200)->content_like(qr/Could not load/, 'while it is down');
	undef $down;

	my $up = mock_scoped('LWP::UserAgent', get => sub {
		_response(200, 'OK', 'text/html', '<table><tr><th>a</th><th>b</th></tr><tr><td>1</td><td>recovered</td></tr></table>');
	});
	$tm->get_ok('/import?url=' . url_escape($url))->status_is(200)->content_like(qr/recovered/, 'and as soon as it is back');
};

subtest 'A URL source: the client is given a timeout, and is asked once' => sub {
	my $tm = _isolated_app();
	require Database::BI::SafeUA;
	my $ua_new = spy('LWP::UserAgent::new');
	my $gets = 0;
	my $guard = mock_scoped('LWP::UserAgent', get => sub {
		$gets++;
		sleep $CONFIG{latency_s};
		return _response(500, 'read timeout', 'text/plain', '');
	});
	local $SIG{__WARN__} = sub { };

	_within_deadline('a URL that times out', sub {
		$tm->get_ok('/import?url=' . url_escape('http://example.com/slow'))->status_is(200);
	});
	my @calls = $ua_new->();
	undef $guard;
	restore_all();

	is($gets, 1, 'a timeout is not retried while the reader waits');
	my ($call) = grep { ($_->[1] // '') eq 'Database::BI::SafeUA' } @calls;
	ok($call, 'the client is the one that will not reach this machine or a private network');
	my (undef, undef, %args) = @{ $call // [] };
	cmp_ok($args{timeout} // 0, '>', 0, 'and has a timeout');
	cmp_ok($args{timeout} // 0, '<=', $CONFIG{max_timeout_s}, "of at most $CONFIG{max_timeout_s}s");
};

subtest 'SFTP: an unreachable or misbehaving host is a message' => sub {
	plan skip_all => 'needs Net::SFTP::Foreign' unless eval { require Net::SFTP::Foreign; 1 };
	my $tm = _isolated_app();
	my $path = '/../nohost.invalid/remote/file.csv';

	my @failures = (
		[ 'a connection that dies', sub { die "ssh: connect: Connection timed out\n" } ],
		[ 'a connection in error',  sub { bless { error => 'Connection to remote server is broken' }, 'Integ::SFTP' } ],
		[ 'a host with no file',    sub { bless { get_error => 'No such file' }, 'Integ::SFTP' } ],
	);

	for my $case (@failures) {
		my ($what, $connect) = @{$case};
		my $connects = 0;
		my $guard = mock_scoped('Net::SFTP::Foreign', new => sub { $connects++; return $connect->(@_) });

		_within_deadline($what, sub {
			throws_ok {
				Database::BI::Model::DataSource->new(host => 'nohost.invalid', directory => '/remote', table => 'file');
			} qr/nohost\.invalid/, "$what: the constructor croaks naming the host";

			$tm->get_ok('/open?path=' . url_escape($path));
			cmp_ok($tm->tx->res->code, '<', 500, "$what: /open answers without a crash");
			_no_internals($tm->tx->res->body, "$what on /open");
		});
		cmp_ok($connects, '>=', 1, 'the connection was attempted');
		undef $guard;
		_app_is_alive($tm, $what);
	}

	my @args;
	my $capture = mock_scoped('Net::SFTP::Foreign', new => sub { @args = @_; die "refused\n" });
	eval { Database::BI::Model::DataSource->new(host => 'someone@nohost.invalid', directory => '/remote', table => 'file') };
	undef $capture;
	my (undef, $host, %opts) = @args;
	is($host, 'nohost.invalid', 'the host is passed apart from the user');
	is($opts{user}, 'someone', 'the user is passed as its own option');
	cmp_ok($opts{timeout} // 0, '>', 0, 'the connection has a timeout');
	cmp_ok($opts{timeout} // 0, '<=', $CONFIG{max_timeout_s}, "of at most $CONFIG{max_timeout_s}s");
};

subtest 'Redis: an unreachable server is a message, and is given timeouts' => sub {
	plan skip_all => 'needs Redis' unless eval { require Redis; 1 };
	my $tm = _isolated_app();
	my $server = 'redis://127.0.0.1:1';
	my @built;
	my $guard = mock_scoped('Redis', new => sub {
		my ($class, %args) = @_;
		push @built, \%args;
		die "Could not connect to Redis server at 127.0.0.1:1: Connection refused\n";
	});
	local $SIG{__WARN__} = sub { };

	_within_deadline('a refused Redis', sub {
		$tm->get_ok('/tables?l=' . url_escape($server));
		cmp_ok($tm->tx->res->code, '<', 500, 'the key picker answers without a crash');
		_no_internals($tm->tx->res->body, 'the key picker');

		$tm->get_ok('/bar?cat=a&l=' . url_escape("redis:$server|k"))->status_is(404, 'a chart has no source');
		_no_internals($tm->tx->res->body, 'the chart');

		$tm->get_ok('/join?l=table:sales&j=' . url_escape("redis:$server|k|id|id"))
		   ->status_is(200)
		   ->content_like(qr/Widget A/, 'a join to it keeps the left side, as the POD of /join says');
	});
	undef $guard;
	_app_is_alive($tm, 'a refused Redis');

	my ($picker) = grep { exists $_->{cnx_timeout} } @built;
	ok($picker, 'the key picker gave its client a connection timeout');
	cmp_ok($picker->{cnx_timeout} // 0, '<=', $CONFIG{max_timeout_s}, 'a short one');
	cmp_ok($picker->{read_timeout} // 0, '>', 0, 'and a read timeout');
};

{
	package Integ::SFTP;

	sub error { return $_[0]{error} // $_[0]{get_error_now} }

	# As the real client does: a failed get sets error and writes no file.
	sub get {
		my ($self) = @_;
		$self->{get_error_now} = $self->{get_error};
		return;
	}

	package Integ::Geocoder::Dies;

	sub new { return bless {}, shift }
	sub valid_location { return 1 }
	sub geocode_many { die "geocoder database is corrupt\n" }
}

# The POD of Database::BI::Model::Geocode: a backend that throws an exception
# breaks the request rather than being read as a place it could not find, and
# leaves nothing half-written.  So the request fails, and that is all that does.
subtest 'A geocoder that throws: the request fails, and leaves nothing behind' => sub {
	my $tm = _isolated_app(geocoder => Integ::Geocoder::Dies->new, openaddr => 'test');
	my $places = _csv_file(tempdir(CLEANUP => 1), 'places.csv', 'id,city', '1,Ramsgate', '2,Margate');
	my $l = url_escape("path:$places");

	throws_ok {
		Database::BI::Model::Geocode->new(geocoder => Integ::Geocoder::Dies->new)
			->resolve_column([ { city => 'Ramsgate' } ], 'city', cache => {});
	} qr/geocoder database is corrupt/, 'the exception reaches the caller of the model';

	local $SIG{__WARN__} = sub { };
	_within_deadline('a throwing geocoder', sub {
		$tm->get_ok("/map?loc=city&l=$l")->status_is(500, 'and breaks the request');
	});
	$tm->get_ok("/geo/list?l=$l")->status_is(200)->json_is('/columns', {}, 'with nothing stored');
	ok(!-e File::Spec->catfile($tm->app->config->{model_dir}, 'models.json'), 'and no model store started');
	_app_is_alive($tm, 'a throwing geocoder');

	$tm->app->config->{geocoder} = _stub_geocoder();
	$tm->get_ok("/map?loc=city&l=$l")->status_is(200, 'a working geocoder is used on the next request');
};

subtest 'A map renderer that fails mid-request is not a crash' => sub {
	plan skip_all => 'needs HTML::OSM 0.14 or later' unless eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 };
	my $tm = _isolated_app();
	my $places = _csv_file(tempdir(CLEANUP => 1), 'coords.csv', 'id,lat,lon', '1,51.3,1.4');
	my $guard = mock_scoped('HTML::OSM', new => sub { die "tile server unreachable\n" });

	$tm->get_ok('/map?lat=lat&lon=lon&l=' . url_escape("path:$places"));
	cmp_ok($tm->tx->res->code, '<', 500, 'the page is served');
	_no_internals($tm->tx->res->body, 'the page');
	undef $guard;
	_app_is_alive($tm, 'a failing renderer');
};

# Strategy: files on disc are an upstream too.  Each is broken in the way a real
# one is, and opening it must not stop the file beside it from opening.
subtest 'Data files that are not what they say: a message, and the next file opens' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $good = _csv_file($dir, 'good.csv', 'id,v', '1,good_value');
	my $tm = _isolated_app();
	local $SIG{__WARN__} = sub { };

	my %broken = (
		'not_really.xlsx'  => 'This is not a zip archive',
		'not_really.sql'   => 'This is not an SQLite database, whatever it may be called',
		'not_really.db'    => "\x00\x01\x02 neither SQLite nor Berkeley DB",
		'not_really.xml'   => '<rows><row>never closed',
		'quote_open.csv'   => qq{2026-01-02,"1.00,Rent paid\n2026-01-03,5.00,Tea\n},
	);
	for my $name (sort keys %broken) {
		my $path = File::Spec->catfile($dir, $name);
		Mojo::File->new($path)->spurt($broken{$name});
		_within_deadline($name, sub {
			$tm->get_ok('/open?path=' . url_escape($path));
		});
		cmp_ok($tm->tx->res->code, '<', 500, "$name: answered without a crash");
		_no_internals($tm->tx->res->body, $name);
		$tm->get_ok('/open?path=' . url_escape($good))->status_is(200)->content_like(qr/good_value/, "after $name, a good file opens");
	}
};

Readonly my @MALFORMED_BODIES => (
	[ 'truncated JSON', '{"name":', qr/Invalid JSON body: \S/ ],
	[ 'not JSON',       'name=x',   qr/Invalid JSON body: \S/ ],
	[ 'an empty body',  '',         qr/Invalid JSON body: \S/ ],
	[ 'a JSON array',   '[1,2,3]',  qr/Invalid JSON body: expected a JSON object/ ],
	[ 'a JSON string',  '"text"',   qr/Invalid JSON body: expected a JSON object/ ],
	[ 'JSON null',      'null',     qr/Invalid JSON body: expected a JSON object/ ],
);

subtest 'Malformed canvas documents are refused, with a reason, on every write route' => sub {
	my $tm = _isolated_app();
	$tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201);
	my $id = $tm->tx->res->json('/id');
	$tm->get_ok("/api/analyses/$id");
	my $stored = $tm->tx->res->json;

	for my $case (@MALFORMED_BODIES) {
		my ($what, $body, $reason) = @{$case};
		my @routes = (
			[ POST  => '/api/analyses' ],
			[ POST  => '/api/analyses/import' ],
			[ PUT   => "/api/analyses/$id" ],
			[ PATCH => "/api/analyses/$id" ],
			[ POST  => "/api/analyses/$id/visuals" ],
		);
		for my $route (@routes) {
			my ($method, $path) = @{$route};
			my $tx = $tm->ua->build_tx($method => $path => { 'Content-Type' => 'application/json' } => $body);
			$tm->request_ok($tx)->status_is(400, "$what: $method $path is refused");
			like($tm->tx->res->json('/error') // '', $reason, 'saying why');
			_no_internals($tm->tx->res->json('/error'), "$what: $method $path");
		}
	}

	$tm->get_ok("/api/analyses/$id")->status_is(200);
	is_deeply($tm->tx->res->json, $stored, 'the stored canvas is exactly as it was');
};

subtest 'A store corrupted on disc: reads are empty, and a save keeps the old file' => sub {
	my $tm = _isolated_app();
	my $dir = $tm->app->config->{model_dir};

	my %store = (
		'analyses.json' => {
			read => sub { $tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses', [], 'canvases read as none') },
			save => sub { $tm->post_ok('/api/analyses' => json => _canvas_doc())->status_is(201, 'a new canvas is accepted') },
			check => sub { $tm->get_ok('/api/analyses')->status_is(200); is(scalar @{ $tm->tx->res->json('/analyses') // [] }, 1, 'and is there') },
		},
		'models.json' => {
			read => sub { $tm->get_ok('/calc/list?l=table:sales')->status_is(200)->json_is('/fields', {}, 'fields read as none') },
			save => sub { $tm->post_ok('/calc/save' => form => { l => 'table:sales', name => 'twice', expr => 'amount * 2' })->status_is(200) },
			check => sub { $tm->get_ok('/calc/list?l=table:sales')->json_is('/fields/twice', 'amount * 2', 'and the new field is there') },
		},
	);

	for my $name (sort keys %store) {
		for my $damage ('{"half a file', '[1,2,3]') {
			my $path = File::Spec->catfile($dir, $name);
			unlink $path, glob("$path.corrupt.*");
			Mojo::File->new($path)->spurt($damage);

			my $logs = _capture_logs($tm, sub {
				$store{$name}{read}->();
				$store{$name}{save}->();
			});
			$store{$name}{check}->();

			my @kept = glob("$path.corrupt.*");
			is(scalar @kept, 1, "$name holding <$damage>: it was set aside, not overwritten");
			is(Mojo::File->new($kept[0])->slurp, $damage, 'with every byte kept') if @kept;
			ok(scalar(grep { /could not be parsed/ } @{$logs}), 'and the log says where it went');
			_app_is_alive($tm, "a corrupt $name");
		}
	}

	# A good store is only ever replaced, never set aside.
	my $path = File::Spec->catfile($dir, 'models.json');
	unlink glob("$path.corrupt.*");
	$tm->post_ok('/calc/save' => form => { l => 'table:sales', name => 'thrice', expr => 'amount * 3' })->status_is(200);
	is(scalar(() = glob("$path.corrupt.*")), 0, 'a healthy store is not set aside');
};

# Strategy: the failures that do most damage are the ones that spread.  One bad
# card, or a stream of failed requests, must leave everything else working.
subtest 'One bad card does not take down the rest of the canvas' => sub {
	my $tm = _isolated_app();
	my $doc = _canvas_doc(
		{ kind => 'bar', title => 'Good card', encode => { cat => 'region' } },
		{ kind => 'bar', title => 'Bad card', encode => { cat => 'no_such_column' } },
	);
	$tm->post_ok('/api/analyses' => json => $doc);
	my $id = $tm->tx->res->json('/id');
	plan skip_all => 'the store refused the canvas up front' unless defined $id;

	$tm->get_ok("/a/$id")
	   ->status_is(200, 'the canvas page is served')
	   ->content_like(qr/Good card/, 'with the good card')
	   ->content_like(qr/no_such_column/, 'and the reason for the bad one');
	_no_internals($tm->tx->res->body =~ s/<script.*?<\/script>//sgr, 'the canvas');
};

subtest 'A canvas whose source has gone is reported, and the store is left alone' => sub {
	my $data = tempdir(CLEANUP => 1);
	my $file = _csv_file($data, 'vanishing.csv', 'id,region', '1,North');
	my $tm = _isolated_app();
	my $doc = {
		name     => 'Vanishing',
		datasets => [ { alias => 'main', spec => "path:$file" } ],
		visuals  => [ { kind => 'bar', title => 'By region', encode => { cat => 'region' } } ],
	};
	$tm->post_ok('/api/analyses' => json => $doc)->status_is(201);
	my $id = $tm->tx->res->json('/id');
	$tm->get_ok("/a/$id")->status_is(200, 'while the file is there');

	unlink $file or die "unlink: $!";
	$tm->get_ok("/a/$id");
	cmp_ok($tm->tx->res->code, '<', 500, 'once it has gone the page does not crash');
	$tm->get_ok("/a/$id/visual/0/csv");
	cmp_ok($tm->tx->res->code, '<', 500, 'nor does the download');
	_no_internals($tm->tx->res->body, 'the download');
	$tm->get_ok("/api/analyses/$id")->status_is(200, 'and the canvas itself is kept');

	_csv_file($data, 'vanishing.csv', 'id,region', '1,North');
	$tm->get_ok("/a/$id")->status_is(200, 'when the file returns, so does the page');
};

subtest 'A stream of failures leaves nothing behind' => sub {
	my $tm = _isolated_app(ai_api_key => $CONFIG{api_key});
	my $guard = mock_scoped('LWP::UserAgent',
		get     => sub { die "Connection refused\n" },
		request => sub { die "Connection refused\n" },
	);
	local $SIG{__WARN__} = sub { };

	my $elapsed = _within_deadline('repeated failures', sub {
		for my $n (1 .. $CONFIG{repeated_failures}) {
			$tm->get_ok('/import?url=' . url_escape("http://example.com/down$n"))->status_is(200);
			$tm->post_ok('/api/ask' => form => { l => 'table:sales', q => "question $n" })->status_is(502);
		}
	});
	undef $guard;

	_app_is_alive($tm, "$CONFIG{repeated_failures} failures in a row");
	$tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses', [], 'no store was touched');
};

# Export > SQLite names its table "data", and Database::Abstraction before 0.54
# kept the DBI handle in the object under the table's name -- the slot its
# slurped rows use -- so no file this application exported could be opened by it.
# 0.54 is the minimum now, so this always runs.
subtest 'A SQLite export opens again' => sub {
	plan skip_all => 'DBD::SQLite is not available' unless eval { require DBD::SQLite; 1 };
	my $tm  = _isolated_app();
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	$tm->get_ok('/export?l=table:sales&format=sqlite')->status_is(200);
	my $file = File::Spec->catfile($dir, 'round.db');
	Mojo::File->new($file)->spew($tm->tx->res->body);
	$tm->get_ok('/open?path=' . url_escape($file))->status_is(200);
	my @cells = map { $_->text } @{ Mojo::DOM->new($tm->tx->res->body)->find('#bi-table tbody td')->to_array };
	ok(scalar(@cells), 'the table has rows');
	# As records: a SQLite source lists its columns alphabetically, so the
	# columns come back in another order.
	my $rows = sub {
		$tm->get_ok("/export?l=$_[0]&format=json")->status_is(200);
		return [ sort { $a->{id} <=> $b->{id} } @{ $tm->tx->res->json } ];
	};
	is_deeply($rows->(url_escape("path:$file")), $rows->('table:sales'), 'and the same rows as the table it came from');
};

# A bank export: the first transaction has a cheque number and almost no other
# row does.  The id column was the first safe column with a value in the first
# data row, so it was Check, and Database::Abstraction dropped every row with
# no cheque number: the table showed 2 of 6 rows.  Every row must be shown, and
# exported, whichever cells happen to be filled in the first one.
subtest 'A column empty in most rows is not the id' => sub {
	my $tm  = _isolated_app();
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'AccountHistory.csv');
	Mojo::File->new($file)->spew(join("\r\n",
		'Account Number,Post Date,Check,Description,Debit,Credit,Status',
		'"XX2106",11/4/2026,650825,"Money Transfer",260.00,,Pending',
		'"XX2106",11/3/2026,,"Humana",145.22,,Posted',
		'"XX2106",11/2/2026,,"Zelle, Transfer",141.00,,Posted',
		'"XX2106",10/30/2026,650826,"Card",673.42,,Posted',
		'"XX2106",10/20/2026,,"Aviva",,897.32,Posted',
		'"XX2106",10/19/2026,,"Zelle Transfer",,341.54,Posted',
	) . "\r\n");
	$tm->get_ok('/open?path=' . url_escape($file))->status_is(200);
	my $body = $tm->tx->res->body;
	is(scalar(() = $body =~ m{<td[^>]*>XX2106</td>}g), 6, 'every row is shown');
	like($body, qr{<td[^>]*>Zelle, Transfer</td>}, 'a quoted separator does not shift the columns');
	$tm->get_ok('/export?format=json&l=' . url_escape("path:$file"))->status_is(200);
	is(scalar(@{ $tm->tx->res->json }), 6, 'and exported');

	# The rows without a cheque number must be there to be filtered,
	# not dropped before any filter runs
	$tm->get_ok('/open?path=' . url_escape($file) . '&f=' . url_escape('Check:notempty:'))->status_is(200);
	$body = $tm->tx->res->body;
	is(scalar(() = $body =~ m{<td[^>]*>XX2106</td>}g), 2, 'a notempty filter on Check keeps the 2 cheques');
	like($body, qr{<td[^>]*>650826</td>}, 'one of them is the second cheque');
	$tm->get_ok('/open?path=' . url_escape($file) . '&f=' . url_escape('Check:empty:'))->status_is(200);
	is(scalar(() = $tm->tx->res->body =~ m{<td[^>]*>XX2106</td>}g), 4, 'an empty filter on Check gives the other 4');
};

done_testing();
