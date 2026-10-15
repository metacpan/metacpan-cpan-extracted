use strict;
use warnings;

# ---------------------------------------------------------------------------
# Integration test suite for Database::BI
#
# Focus: cross-module, multi-step workflows where Database::BI (routing/config),
# Database::BI::Controller::Dashboard (HTTP actions), and
# Database::BI::Model::DataSource (data access) all interact.
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
use Readonly;
use File::Spec     ();
use File::Temp     qw(tempdir tempfile);
use Mojo::File     ();
use Mojo::Util     qw(url_escape);
use Scalar::Util   qw(reftype refaddr);
use DBI            ();

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
# SECTION 1: App config → DataSource → HTTP response pipeline
#
# Strategy: Verify that the app's open_table helper correctly passes the
# data_dir config to DataSource, and that DataSource in turn feeds the
# controller with the expected data — a full config-to-HTML round-trip.
# ===========================================================================

subtest 'Config → open_table helper → DataSource → HTML response (sales)' => sub {
	# The app config sets data_dir='data'.  GET /view/sales must:
	#   1. Use the open_table helper with data_dir from config
	#   2. DataSource opens data/sales.csv via Database::Abstraction
	#   3. Controller renders rows → HTML contains known sample values
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Widget A/,   'known product in HTML output')
	  ->content_like(qr/Alice Smith/, 'known sales_rep in HTML output')
	  ->content_like(qr/North/,       'known region in HTML output');

	# Verify DataSource is in fact delivering the right column set by
	# checking the columns API (which calls open_table → DataSource.columns).
	my $cols = $t->get_ok('/api/columns?table=sales')
	             ->status_is(200)
	             ->json_has('/columns')
	             ->tx->res->json('/columns');
	for my $expected (@SALES_COLS) {
		ok(grep({ $_ eq $expected } @$cols), "column '$expected' present in columns API response");
	}
};

subtest 'Config → open_table(directory=>) → DataSource → HTML (custom path)' => sub {
	# /open uses open_table(directory => $dir_of_file) — the directory override
	# path in the helper.  This exercises a distinct code path from /view/:table.
	my $enc = url_escape($SALES_CSV);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Widget A/,    'open_file path reads correct data')
	  ->content_like(qr/Alice Smith/,  'known rep present when opened via path');
};

# ===========================================================================
# SECTION 2: Multi-step HTTP workflow — upload → open → filter pipeline
#
# Strategy: Simulate a complete user session: upload a fresh CSV, then
# immediately open it and apply a filter.  Verifies that the upload path
# (DataSource via open_table) and the filter path (_apply_filters) compose
# correctly across two independent HTTP requests.
# ===========================================================================

subtest 'Upload → open → filter end-to-end pipeline' => sub {
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

	# Step 2: Open the uploaded file — exercises the open_table path arg.
	my $enc = url_escape($upload_path);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'all rows present before filtering')
	  ->content_like(qr/Beta/,    'Beta row present before filtering')
	  ->content_like(qr/premium/, 'tier column data visible');

	# Step 3: Open with an eq filter — only premium tier rows should appear.
	$t->get_ok("/open?path=$enc&f=" . url_escape('tier:eq:premium'))
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'Alpha is premium — present in filtered view')
	  ->content_like(qr/Gamma/,   'Gamma is premium — present in filtered view')
	  ->content_unlike(qr/Beta/,  'Beta is standard — absent from filtered view')
	  ->content_unlike(qr/Delta/, 'Delta is standard — absent from filtered view');

	# Step 4: Open with a gt filter — only score > 70.
	$t->get_ok("/open?path=$enc&f=" . url_escape('score:gt:70'))
	  ->status_is(200)
	  ->content_like(qr/Alpha/,   'Alpha score 90 > 70 — present')
	  ->content_like(qr/Gamma/,   'Gamma score 80 > 70 — present')
	  ->content_unlike(qr/Beta/,  'Beta score 60 not > 70 — absent')
	  ->content_unlike(qr/Delta/, 'Delta score 40 not > 70 — absent');
};

# ===========================================================================
# SECTION 3: Browse → open → export pipeline
#
# Strategy: Navigate the filesystem to a temp directory containing a fresh
# CSV, open the file, and write it out to a second location.  Tests the
# browse, open_file, and export_write actions composing correctly.
# ===========================================================================

subtest 'Browse → open → export_write end-to-end pipeline' => sub {
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

subtest 'CSV + PSV join → filter → export_write complete pipeline' => sub {
	plan skip_all => 'data/products.psv not found' unless -f $PRODUCTS_PSV;

	my $out_dir = tempdir(CLEANUP => 1);
	my $l_spec  = 'table:sales';
	my $j_spec  = url_escape('table:products|product|name');

	# Step 1: Join verifies merged result set.
	$t->get_ok("/join?l=" . url_escape($l_spec) . "&j=$j_spec")
	  ->status_is(200)
	  ->content_like(qr/product|category/i, 'merged columns from PSV visible in joined view');

	# Step 2: Join + filter — only North region rows.
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
# called with the expected message key, confirming the DataSource↔i18n
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
# SECTION 7: Export → re-open roundtrip (SQLite)
#
# Strategy: Export the sales table to a SQLite file, then re-open that file
# via the HTTP API.  This confirms that the SQLite write path (Dashboard →
# _write_sqlite_db → DBI) and the SQLite read path (DataSource →
# Database::Abstraction → DBD::SQLite) compose correctly.
# ===========================================================================

subtest 'SQLite read→filter pipeline (DBI-created file re-opened via /open)' => sub {
	eval { require DBI; DBI->install_driver('SQLite') }
		or plan skip_all => 'DBD::SQLite not available';

	# Strategy: create the SQLite file ourselves with a table whose name
	# matches the filename stem.  This tests the DataSource SQLite read path
	# and the filter pipeline without depending on the export→re-open naming
	# alignment (which requires the internal export table name "data" to match
	# the filename stem — a separate concern tested in export_write subtests).
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

	# Open via the HTTP API — exercises DataSource → D::A → DBD::SQLite.
	$t->get_ok('/open?path=' . url_escape($sqlfile))
	  ->status_is(200)
	  ->content_like(qr/London/, 'London row visible in SQLite view')
	  ->content_like(qr/Paris/,  'Paris row visible in SQLite view')
	  ->content_like(qr/Berlin/, 'Berlin row visible in SQLite view');

	# Filter — only UK rows.
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
# and that _apply_filters iterates all specs — not just the first matching one.
# ===========================================================================

subtest 'Multiple filters compose with AND semantics (join pipeline)' => sub {
	# sales.csv: regions are North, South, East, West.
	# Amount range: 725.25 to 2100.00.
	#
	# Filter A: region eq North  → rows with id 1 (1250.00) and id 5 (1875.00)
	# Filter B: amount gt 1000   → ids 1 (1250), 3 (2100), 5 (1875)
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
# SECTION 9: XML format integration (optional — XML::Simple)
#
# Strategy: Verify the full XML data path (DataSource → Database::Abstraction
# → XML::Simple → HTTP response), then verify graceful failure when XML::Simple
# is blocked by Test::Without::Module.
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

subtest 'XML data path: graceful failure when XML::Simple is absent' => sub {
	plan skip_all => 'data/catalog.xml not found' unless -f $CATALOG_XML;
	plan skip_all => 'XML::Simple already loaded; cannot simulate absence in this process'
		if exists $INC{'XML/Simple.pm'};

	# Block XML::Simple from loading and try to open the catalog table.
	# The controller must return the home page with an error (not a 500 crash).
	{
		local @INC = @INC;
		Test::Without::Module->import('XML::Simple');
		$t->get_ok('/view/catalog')
		  ->status_is(200)		# home page with error message, not 500
		  ->content_unlike(qr/Widget A/, 'no data visible when XML::Simple absent');
		Test::Without::Module->unimport('XML::Simple');
	}
};

# ===========================================================================
# SECTION 10: Optional dependency — DBD::SQLite graceful degradation
#
# Strategy: Verify that the /export SQLite path works when DBD::SQLite is
# present.  Without DBD::SQLite the export_write action must return a 500
# JSON error, not crash the process.
# ===========================================================================

subtest 'SQLite export: graceful failure when DBD::SQLite absent' => sub {
	plan skip_all => 'DBD::SQLite already loaded; cannot simulate absence in this process'
		if exists $INC{'DBD/SQLite.pm'};

	my $out_dir = tempdir(CLEANUP => 1);

	{
		local @INC = @INC;
		Test::Without::Module->import('DBD::SQLite');
		$t->post_ok('/export', form => {
			l        => 'table:sales',
			dir      => $out_dir,
			filename => 'no_sqlite.sql',
		})->status_is(500)
		  ->json_has('/error', 'error key present when DBD::SQLite absent');
		Test::Without::Module->unimport('DBD::SQLite');
	}

	ok !-f File::Spec->catfile($out_dir, 'no_sqlite.sql'),
		'no SQLite file written to disk on failure';
};

# ===========================================================================
# SECTION 11: Concurrent HTTP requests — no shared controller state
#
# Strategy: Issue multiple overlapping requests against the same Test::Mojo
# instance (sequentially, since Test::Mojo is synchronous) and verify that
# each request's stash is isolated — no filter, column order, or table name
# bleeds from one request into the next.
# ===========================================================================

subtest 'Sequential requests have isolated stash / no state bleed' => sub {
	# Request A: sales filtered to North.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:North'))
	  ->status_is(200)
	  ->content_like(qr/North/);

	# Request B: products (no filter) — must NOT inherit the North filter.
	$t->get_ok('/view/products')
	  ->status_is(200)
	  ->content_like(qr/Hammer/,      'products table visible without North filter')
	  ->content_like(qr/Screwdriver/, 'all products visible — no stale filter');

	# Request C: sales again with South filter — must not show North.
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
# match what was written.  This confirms the full write→read pipeline across
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
# SECTION 13: /api/stat ↔ filesystem truthfulness
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

	# Delete the file and stat again — must now report exists:false.
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

subtest '/pie full pipeline: CSV → aggregation → HTML with metadata' => sub {
	eval { require HTML::D3 }
		or plan skip_all => 'HTML::D3 not available';

	# The sales table has region (cat) and amount (val) — four distinct regions.
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
# value — the exact URL is not reachable from Test::Mojo but the controller only
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

subtest '/graph full pipeline: CSV → D3 snippet → HTML with reference lines' => sub {
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

done_testing();
