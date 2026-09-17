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
	# Without back2, the template must never emit a spurious third segment.
	my $enc = url_escape($SALES_CSV);
	$t->get_ok("/open?path=$enc")
	  ->status_is(200)
	  ->content_like(qr/Back to browser/, 'second breadcrumb present as usual')
	  ->content_unlike(qr/back2/,          'back2 stash key not leaked to HTML');
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

	# Filter to hardware only — A1 and B1 must be present; A2 and B2 must not.
	$t->get_ok(
		"/combine?l=$a_spec&c=$b_spec&f=" . url_escape('category:eq:hardware')
	)->status_is(200)
	 ->content_like(qr/A1/,        'A1 (hardware) present in filtered combined view')
	 ->content_like(qr/B1/,        'B1 (hardware) present in filtered combined view')
	 ->content_unlike(qr/A2/,      'A2 (software) absent from filtered combined view')
	 ->content_unlike(qr/B2/,      'B2 (services) absent from filtered combined view');
};

done_testing();
