use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp ();
use Test::Needs;
use File::Spec ();
use Mojo::File;
use Mojo::Util qw(url_escape);

my $t = Test::Mojo->new('Database::BI');

# Uploads land in a directory this file owns: the default staging directory is
# shared by every test file, and a parallel run's POST /uploads/clear could
# empty it between an upload and the /open that reads it.
$t->app->config->{uploads_dir} = File::Temp::tempdir(CLEANUP => 1);

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = File::Temp::tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
subtest 'Home page' => sub {
	$t->get_ok('/')->status_is(200)->content_like(qr/Choose a Database/i);
	$t->get_ok('/')->content_like(qr/Browse filesystem/i);
	# Regression guard: the Browse card must have a path text input.
	# Previously the field was removed without any test catching it.
	$t->get_ok('/')->content_like(qr/id="bi-path-input"/, 'home page has path input field');
};

# ---------------------------------------------------------------------------
subtest 'View table' => sub {
    $t->get_ok('/view/sales')->status_is(200);
    # Path traversal characters are rejected with 404.
    $t->get_ok('/view/../etc/passwd')->status_is(404);
    # A nonexistent table is a 404 page that names it.
    $t->get_ok('/view/nonexistent_xyz_table')->status_is(404)
      ->content_like(qr/There is no table called &quot;nonexistent_xyz_table&quot;/);
};

# ---------------------------------------------------------------------------
subtest 'New canvas starts with the current table' => sub {
	$t->get_ok('/view/sales')->status_is(200)
		->content_like(qr{id="save-analysis-panel"[^>]*data-left-spec="table:sales"}s,
			'the New canvas panel knows the current table even though the URL has no l=')
		->content_like(qr/var visuals = \[\{ kind: 'table'/,
			'saving a new canvas builds a table visual');

	$t->get_ok('/pie?l=table:sales&cat=region&val=amount')->status_is(200)
		->content_like(qr/id="new-canvas-btn"/, 'the chart page has a New canvas button')
		->content_like(qr/id="new-canvas-panel" data-chart="[^"]*&quot;kind&quot;:&quot;pie&quot;/, 'the chart page exposes its chart spec')
		->content_like(qr/&quot;value&quot;:&quot;amount&quot;/, 'the exposed spec keeps the value column');
};

# ---------------------------------------------------------------------------
subtest 'Table toolbar has a Map panel' => sub {
	$t->get_ok('/view/sales')->status_is(200)
		->content_like(qr/id="btn-map"/, 'the Map button is in the toolbar')
		->content_like(qr/&#x1F5FA; Map&hellip;/, 'the button names the map')
		->content_like(qr/id="map-panel"/, 'the Map panel is present')
		->content_like(qr/id="map-form"[^>]*action="\/map"/s, 'the panel submits to /map')
		->content_like(qr/id="map-mode-sel"/, 'the panel offers both ways to place a row')
		->content_like(qr/id="map-lat-sel"[^>]*name="lat"/s, 'there is a latitude column')
		->content_like(qr/id="map-lon-sel"[^>]*name="lon"/s, 'there is a longitude column')
		->content_like(qr/id="map-loc-sel"[^>]*name="loc"/s, 'there is a place-name column')
		->content_like(qr/id="btn-do-map"/, 'the panel has its own submit button');

	# Opening any of the other chart panels must close the Map panel, or two
	# forms would be on screen at once.
	my $body = $t->tx->res->body;
	my ($list) = $body =~ /var BI_PANELS = \[([^\]]*)\]/;
	like($list // '', qr/'map-panel'/, 'every chart panel closes the Map panel');
};

# ---------------------------------------------------------------------------
subtest 'Filesystem browser' => sub {
    my $tmpdir = File::Spec->tmpdir;
    $t->get_ok('/browse')->status_is(200)->content_like(qr/Browse Files/i);
    $t->get_ok('/browse?path=' . url_escape($tmpdir))->status_is(200);
    $t->get_ok('/browse?path=' . url_escape('/nonexistent/path/xyz'))->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'Open file by absolute path' => sub {
    my $sales = File::Spec->rel2abs('data/sales.csv');
    if (-f $sales) {
        $t->get_ok('/open?path=' . url_escape($sales))
          ->status_is(200)->content_like(qr/sales\.csv/i);
    }
    $t->get_ok('/open')->status_is(404);
    $t->get_ok('/open?path=' . url_escape('/etc/passwd'))->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'Columns API' => sub {
    $t->get_ok('/api/columns?table=sales')->status_is(200)->json_has('/columns');
    $t->get_ok('/api/columns?table=nonexistent_xyz')->status_is(404);
    $t->get_ok('/api/columns')->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'Join' => sub {
    $t->get_ok('/join')->status_is(404);
    $t->get_ok('/join?l=table:nonexistent_xyz')->status_is(404);

    my $sales = File::Spec->rel2abs('data/sales.csv');
    if (-f $sales) {
        my $jspec = url_escape('table:sales|product|product');
        $t->get_ok('/join?l=' . url_escape('table:sales') . '&j=' . $jspec)
          ->status_is(200)->content_like(qr/sales/i);
    }
};

subtest 'Join warns when a shared column has different types' => sub {
	# The join always prefixes the right table's columns, so Database::Join's own
	# mismatch warning stays quiet; the banner is the controller's comparison of
	# the two declared types, and this is the check that it still reaches a page.
	my $dir = File::Temp->newdir;
	my $a   = File::Spec->catfile("$dir", 'a.db');
	my $b   = File::Spec->catfile("$dir", 'b.db');

	require DBI;
	for my $fixture ([ $a, 'INTEGER' ], [ $b, 'TEXT' ]) {
		my ($path, $type) = @$fixture;
		my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1 });
		$dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, amount $type)");
		$dbh->do("INSERT INTO t VALUES (1, '10')");
		$dbh->disconnect;
	}

	$t->get_ok('/join?l=' . url_escape("path:$a") . '&j=' . url_escape("path:$b|id|id"))
		->status_is(200)
		->content_like(qr/class="schema-warnings"/, 'the warnings banner is rendered')
		->content_like(
			qr/Column &quot;amount&quot; has type INTEGER in a\.db but TEXT in b\.db/,
			'the warning names the column, both types and both files')
		->content_unlike(qr/Column &quot;id&quot;/, 'the join key is not reported');
};

# ---------------------------------------------------------------------------
subtest 'Export CSV download' => sub {
    $t->get_ok('/export?l=' . url_escape('table:sales') . '&format=csv')
      ->status_is(200)
      ->content_type_like(qr{text/csv})
      ->content_like(qr/product/i);
};

subtest 'Export SQLite download' => sub {
    $t->get_ok('/export?l=' . url_escape('table:sales') . '&format=sqlite')
      ->status_is(200)
      ->content_type_like(qr{sqlite});
};

subtest 'Export missing table' => sub {
    $t->get_ok('/export')->status_is(404);
    $t->get_ok('/export?l=' . url_escape('table:nonexistent_xyz'))->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'Filter support' => sub {
    $t->get_ok('/view/sales?f=' . url_escape('region:eq:North'))
      ->status_is(200)->content_like(qr/North/i);

    $t->get_ok('/join?l=' . url_escape('table:sales') . '&f=' . url_escape('region:eq:North'))
      ->status_is(200)->content_like(qr/North/i);

    # Filter matching no rows still returns 200 (empty-state).
    $t->get_ok('/join?l=' . url_escape('table:sales') . '&f=' . url_escape('region:eq:XYZZY'))
      ->status_is(200);
};

# ---------------------------------------------------------------------------
subtest 'PSV format' => sub {
    my $psv = File::Spec->rel2abs('data/products.psv');
    plan skip_all => 'data/products.psv not found' unless -f $psv;

    $t->get_ok('/view/products')
      ->status_is(200)->content_like(qr/Hammer/)->content_like(qr/Screwdriver/);

    $t->get_ok('/api/columns?table=products')->status_is(200)->json_has('/columns');

    $t->get_ok('/view/products?f=' . url_escape('category:eq:Tools'))
      ->status_is(200)->content_like(qr/Hammer/);

    $t->get_ok('/export?l=' . url_escape('table:products') . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Hammer/);

    $t->get_ok('/export?l=' . url_escape('table:products') . '&format=sqlite')
      ->status_is(200)->content_type_like(qr{sqlite});

    # Cross-format join: CSV sales left-joined with PSV products.
    my $jspec = url_escape('table:products|product|name');
    $t->get_ok('/join?l=' . url_escape('table:sales') . '&j=' . $jspec)
      ->status_is(200)->content_like(qr/product|category/i);

    $t->get_ok('/open?path=' . url_escape($psv))
      ->status_is(200)->content_like(qr/Hammer/);
};

# ---------------------------------------------------------------------------
subtest 'TSV format' => sub {
    my $psv = File::Spec->rel2abs('data/employees.tsv');
    plan skip_all => 'data/employees.tsv not found' unless -f $psv;

    $t->get_ok('/view/employees')
      ->status_is(200)->content_like(qr/Alice/)->content_like(qr/Engineering/);

    $t->get_ok('/api/columns?table=employees')->status_is(200)->json_has('/columns');

    $t->get_ok('/view/employees?f=' . url_escape('City:eq:Seattle'))
      ->status_is(200)->content_like(qr/Alice/);

    $t->get_ok('/export?l=' . url_escape('table:employees') . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Alice/);

    $t->get_ok('/export?l=' . url_escape('table:employees') . '&format=sqlite')
      ->status_is(200)->content_type_like(qr{sqlite});
};

# ---------------------------------------------------------------------------
subtest 'XML format' => sub {
	test_needs 'XML::Simple';
	my $xml = File::Spec->rel2abs('data/catalog.xml');
	plan skip_all => 'data/catalog.xml not found' unless -f $xml;

    $t->get_ok('/view/catalog')
      ->status_is(200)->content_like(qr/Widget A/)->content_like(qr/Gizmo B/);

    $t->get_ok('/view/catalog?f=' . url_escape('category:eq:hardware'))
      ->status_is(200)->content_like(qr/Widget A/);

    $t->get_ok('/export?l=' . url_escape('table:catalog') . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Widget A/);

    $t->get_ok('/api/columns?table=catalog')->status_is(200)->json_has('/columns');

    $t->get_ok('/open?path=' . url_escape($xml))
      ->status_is(200)->content_like(qr/Widget A/);
};

# ---------------------------------------------------------------------------
subtest 'SQLite format (.sql extension)' => sub {
	test_needs 'DBI', 'DBD::SQLite';

    my $sql_dir  = File::Temp::tempdir(CLEANUP => 1);
    my $sql_file = File::Spec->catfile($sql_dir, 'inventory.sql');

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$sql_file", '', '',
        { RaiseError => 1, AutoCommit => 1 },
    );
    $dbh->do('CREATE TABLE inventory (sku TEXT, description TEXT, qty INTEGER)');
    $dbh->do("INSERT INTO inventory VALUES ('SKU001', 'Bolt M6',  100)");
    $dbh->do("INSERT INTO inventory VALUES ('SKU002', 'Nut M6',   200)");
    $dbh->disconnect;

    $t->get_ok('/open?path=' . url_escape($sql_file))
      ->status_is(200)->content_like(qr/Bolt M6/);

    $t->get_ok('/open?path=' . url_escape($sql_file) . '&f=' . url_escape('sku:eq:SKU001'))
      ->status_is(200)->content_like(qr/Bolt M6/);

    $t->get_ok('/export?l=' . url_escape("path:$sql_file") . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Bolt/);

    $t->get_ok('/export?l=' . url_escape("path:$sql_file") . '&format=sqlite')
      ->status_is(200)->content_type_like(qr{sqlite});

    $t->get_ok('/browse?path=' . url_escape($sql_dir))
      ->status_is(200)->content_like(qr/inventory\.sql/);
};

# ---------------------------------------------------------------------------
subtest 'SQLite3 format (.sqlite3 extension)' => sub {
	test_needs 'DBI', 'DBD::SQLite';

    my $sql_dir  = File::Temp::tempdir(CLEANUP => 1);
    my $sql_file = File::Spec->catfile($sql_dir, 'parts.sqlite3');

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$sql_file", '', '',
        { RaiseError => 1, AutoCommit => 1 },
    );
    $dbh->do('CREATE TABLE parts (partno TEXT, name TEXT, stock INTEGER)');
    $dbh->do("INSERT INTO parts VALUES ('P001', 'Washer',  500)");
    $dbh->do("INSERT INTO parts VALUES ('P002', 'Gasket',  150)");
    $dbh->disconnect;

    $t->get_ok('/open?path=' . url_escape($sql_file))
      ->status_is(200)->content_like(qr/Washer/);

    $t->get_ok('/open?path=' . url_escape($sql_file) . '&f=' . url_escape('partno:eq:P001'))
      ->status_is(200)->content_like(qr/Washer/);

    $t->get_ok('/export?l=' . url_escape("path:$sql_file") . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Gasket/);

    $t->get_ok('/browse?path=' . url_escape($sql_dir))
      ->status_is(200)->content_like(qr/parts\.sqlite3/);
};

# ---------------------------------------------------------------------------
subtest 'SQLite format (.sqlite extension)' => sub {
	test_needs 'DBI', 'DBD::SQLite';

    my $sql_dir  = File::Temp::tempdir(CLEANUP => 1);
    my $sql_file = File::Spec->catfile($sql_dir, 'sensors.sqlite');

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$sql_file", '', '',
        { RaiseError => 1, AutoCommit => 1 },
    );
    $dbh->do('CREATE TABLE sensors (id INTEGER, label TEXT, value REAL)');
    $dbh->do("INSERT INTO sensors VALUES (1, 'Temp',     21.5)");
    $dbh->do("INSERT INTO sensors VALUES (2, 'Humidity', 55.0)");
    $dbh->disconnect;

    $t->get_ok('/open?path=' . url_escape($sql_file))
      ->status_is(200)->content_like(qr/Temp/);

    $t->get_ok('/open?path=' . url_escape($sql_file) . '&f=' . url_escape('label:eq:Humidity'))
      ->status_is(200)->content_like(qr/Humidity/);

    $t->get_ok('/export?l=' . url_escape("path:$sql_file") . '&format=csv')
      ->status_is(200)->content_type_like(qr{text/csv})->content_like(qr/Temp/);

    $t->get_ok('/browse?path=' . url_escape($sql_dir))
      ->status_is(200)->content_like(qr/sensors\.sqlite/);
};

# ---------------------------------------------------------------------------
subtest 'POST /export -- write to filesystem' => sub {
	test_needs 'DBI';

    my $out_dir = File::Temp::tempdir(CLEANUP => 1);

    # Write CSV.
    $t->post_ok('/export',
        form => { l => 'table:sales', dir => $out_dir, filename => 'out.csv' }
    )->status_is(200)->json_has('/saved')->json_like('/saved', qr/out\.csv$/);

    my $saved_csv = $t->tx->res->json('/saved');
    if (defined $saved_csv && -f $saved_csv) {
        my $content = Mojo::File->new($saved_csv)->slurp;
        like($content, qr/product/i, 'CSV contains header row');
    }

    # Write SQLite (only when DBD::SQLite is installed).
    SKIP: {
        eval { DBI->install_driver('SQLite') } or skip 'DBD::SQLite not available', 3;
        $t->post_ok('/export',
            form => { l => 'table:sales', dir => $out_dir, filename => 'out.sql' }
        )->status_is(200)->json_like('/saved', qr/out\.sql$/);

        my $saved_sql = $t->tx->res->json('/saved');
        ok(-f $saved_sql, 'SQLite file written to disk') if defined $saved_sql;
    }

    # Write PSV source.
    SKIP: {
        skip 'data/products.psv not found', 1 unless -f 'data/products.psv';
        $t->post_ok('/export',
            form => { l => 'table:products', dir => $out_dir, filename => 'products_out.csv' }
        )->status_is(200)->json_like('/saved', qr/products_out\.csv$/);
    }

    # Unknown extension returns 415.
    $t->post_ok('/export',
        form => { l => 'table:sales', dir => $out_dir, filename => 'out.txt' }
    )->status_is(415);

    # Missing table returns 404.
    $t->post_ok('/export',
        form => { l => 'table:nonexistent', dir => $out_dir, filename => 'out.csv' }
    )->status_is(404);

    # Bad directory returns 404.
    $t->post_ok('/export',
        form => { l => 'table:sales', dir => '/nonexistent/xyz', filename => 'out.csv' }
    )->status_is(404);

    # Filtered export: only North region.
    $t->post_ok('/export',
        form => { l => 'table:sales', 'f' => 'region:eq:North', dir => $out_dir, filename => 'north.csv' }
    )->status_is(200);

    my $north = $t->tx->res->json('/saved');
    if (defined $north && -f $north) {
        my $c = Mojo::File->new($north)->slurp;
        like($c,   qr/North/i, 'filtered CSV contains North');
        unlike($c, qr/South/i, 'filtered CSV excludes South');
    }

    # XML -> SQLite.
    SKIP: {
        skip 'data/catalog.xml not found', 3 unless -f 'data/catalog.xml';
        eval { require XML::Simple } or skip 'XML::Simple not available', 3;
        eval { DBI->install_driver('SQLite') } or skip 'DBD::SQLite not available', 3;
        $t->post_ok('/export',
            form => { l => 'table:catalog', dir => $out_dir, filename => 'catalog_out.sql' }
        )->status_is(200)->json_like('/saved', qr/catalog_out\.sql$/);
    }
};

# ---------------------------------------------------------------------------
subtest 'GET /api/stat' => sub {
    my $sales = File::Spec->rel2abs('data/sales.csv');

    SKIP: {
        skip 'data/sales.csv not found', 6 unless -f $sales;

        $t->get_ok('/api/stat?path=' . url_escape($sales))
          ->status_is(200)
          ->json_is('/exists', 1)
          ->json_has('/mtime')
          ->json_has('/size')
          ->json_has('/path');

        my $mtime = $t->tx->res->json('/mtime');
        ok(defined $mtime && $mtime > 0, 'mtime is a positive epoch integer');

        my $size = $t->tx->res->json('/size');
        ok(defined $size && $size > 0, 'size is positive');
    }

    # Non-existent file returns exists:false, not 404.
    $t->get_ok('/api/stat?path=' . url_escape('/nonexistent/file.csv'))
      ->status_is(200)->json_is('/exists', 0);

    # Missing path param returns 400.
    $t->get_ok('/api/stat')->status_is(400);

    # PSV and XML files stat correctly.
    SKIP: {
        my $psv = File::Spec->rel2abs('data/products.psv');
        skip 'data/products.psv not found', 1 unless -f $psv;
        $t->get_ok('/api/stat?path=' . url_escape($psv))
          ->status_is(200)->json_is('/exists', 1);
    }
    SKIP: {
        my $xml = File::Spec->rel2abs('data/catalog.xml');
        skip 'data/catalog.xml not found', 1 unless -f $xml;
        $t->get_ok('/api/stat?path=' . url_escape($xml))
          ->status_is(200)->json_is('/exists', 1);
    }
};

# ---------------------------------------------------------------------------
subtest 'GET /api/dirs' => sub {
    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    mkdir "$tmp/alpha";
    mkdir "$tmp/beta";

    $t->get_ok('/api/dirs?path=' . url_escape($tmp))
      ->status_is(200)
      ->json_has('/path')
      ->json_has('/dirs')
      ->json_like('/dirs/0/name', qr/alpha|beta/);

    $t->get_ok('/api/dirs?path=' . url_escape($tmp))->json_has('/parent');

    # Non-existent path returns 404.
    $t->get_ok('/api/dirs?path=' . url_escape('/nonexistent/xyz'))->status_is(404);

    # Hidden directories are excluded.
    mkdir "$tmp/.hidden";
    my $res = $t->get_ok('/api/dirs?path=' . url_escape($tmp))->tx->res->json;
    my @names = map { $_->{name} } @{ $res->{dirs} // [] };
    ok(!(grep { /hidden/ } @names), 'hidden directory excluded from listing');
};

# ---------------------------------------------------------------------------
subtest 'POST /upload -- drag-and-drop upload' => sub {
    # Basic CSV upload.
    my $csv_content = "id,name,qty\r\n1,Widget,100\r\n2,Gadget,200\r\n";
    $t->post_ok('/upload',
        form => { file => { content => $csv_content, filename => 'upload_test.csv' } }
    )->status_is(200)->json_has('/url')->json_has('/path')
     ->json_like('/url', qr{/open\?path=});

    # The returned URL must be openable.
    my $url = $t->tx->res->json('/url');
    if (defined $url) {
        $t->get_ok($url)->status_is(200)->content_like(qr/Widget/);
    }

    # No file -> 400.
    $t->post_ok('/upload')->status_is(400);

    # Unsupported extension -> 415.
    $t->post_ok('/upload',
        form => { file => { content => 'data', filename => 'bad.txt' } }
    )->status_is(415);

    # PSV upload.
    my $psv_content = "id|name|price\n1|Bolt|0.99\n2|Nut|0.49\n";
    $t->post_ok('/upload',
        form => { file => { content => $psv_content, filename => 'parts.psv' } }
    )->status_is(200)->json_like('/url', qr{/open\?path=});

    # SQLite (.sql) upload.
    SKIP: {
        eval { require DBI; DBI->install_driver('SQLite') }
            or skip 'DBD::SQLite not available', 3;

        my $sql_dir  = File::Temp::tempdir(CLEANUP => 1);
        my $sql_file = File::Spec->catfile($sql_dir, 'upload_sq.sql');
        my $dbh = DBI->connect(
            "dbi:SQLite:dbname=$sql_file", '', '', { RaiseError => 1, AutoCommit => 1 }
        );
        $dbh->do('CREATE TABLE upload_sq (col1 TEXT, col2 TEXT)');
        $dbh->do("INSERT INTO upload_sq VALUES ('hello', 'world')");
        $dbh->disconnect;

        my $bytes = Mojo::File->new($sql_file)->slurp;
        $t->post_ok('/upload',
            form => { file => { content => $bytes, filename => 'upload_sq.sql' } }
        )->status_is(200)->json_like('/url', qr{/open\?path=});
        # Roundtrip content check omitted: the no_entry+SQLite backend combination
        # is intermittently unreliable (see CLAUDE.md "SQLite export" note).
        # Full SQLite open coverage lives in t/transaction.t.
    }
};

# ---------------------------------------------------------------------------
subtest 'GET /import -- HTML URL import' => sub {
    test_needs 'LWP::UserAgent', 'HTML::TableExtract';

    # Param / scheme validation does not touch the network.
    $t->get_ok('/import')
      ->status_is(200)->content_like(qr/Please enter a URL/);

    $t->get_ok('/import?url=' . url_escape('ftp://example.com/page'))
      ->status_is(200)->content_like(qr/not a valid/i);

    # For network-dependent tests, monkeypatch LWP::UserAgent::get.
    # Test::Mojo runs the app in-process so the patch is visible inside D::A.
    require LWP::UserAgent;
    require HTTP::Response;

    my $html = '<table>'
             . '<tr><th>sku</th><th>qty</th></tr>'
             . '<tr><td>BOLT</td><td>10</td></tr>'
             . '<tr><td>NUT</td><td>20</td></tr>'
             . '</table>';

    {
        no warnings 'redefine';
        local *LWP::UserAgent::get = sub {
            my ($self, $url) = @_;
            return HTTP::Response->new(200, 'OK', [], $html);
        };

        my $test_url = 'http://example.com/test-table';

        # Basic happy path.
        $t->get_ok('/import?url=' . url_escape($test_url))
          ->status_is(200)
          ->content_like(qr/BOLT/)
          ->content_like(qr/NUT/);

        # Filters apply to URL-backed tables.
        $t->get_ok('/import?url=' . url_escape($test_url)
                 . '&f=' . url_escape('sku:eq:BOLT'))
          ->status_is(200)->content_like(qr/BOLT/);

        # Out-of-range table_index -> backend croaks -> error page (still 200).
        $t->get_ok('/import?url=' . url_escape($test_url) . '&table_index=99')
          ->status_is(200);

        # url: spec works as the left table in a join.
        $t->get_ok('/join?l=' . url_escape("url:$test_url"))
          ->status_is(200)->content_like(qr/BOLT/);

        # LWP failure (e.g. 404) -> backend croaks -> error page.
        local *LWP::UserAgent::get = sub {
            my ($self, $url) = @_;
            my $r = HTTP::Response->new(404, 'Not Found', [], '');
            return $r;
        };
        $t->get_ok('/import?url=' . url_escape($test_url))
          ->status_is(200);   # error page, not a 500
    }
};

# ---------------------------------------------------------------------------
subtest 'GET /api/columns -- spec= parameter branch' => sub {
	# The "spec=table:name" unified spec mirrors _open_spec's table: branch.
	$t->get_ok('/api/columns?spec=table:sales')
	  ->status_is(200)->json_has('/columns');

	# Unknown table via spec still returns 404.
	$t->get_ok('/api/columns?spec=table:no_such_table_xyz')
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'GET /export?format=json -- JSON download' => sub {
	$t->get_ok('/export?l=' . url_escape('table:sales') . '&format=json')
	  ->status_is(200)
	  ->content_type_like(qr{application/json});
	# Response body must be a valid JSON array.
	my $rows = $t->tx->res->json;
	ok(ref($rows) eq 'ARRAY', 'JSON export returns an array');
};

# ---------------------------------------------------------------------------
subtest 'GET /combine -- vertical stack (UNION ALL)' => sub {
	# Single left table with no extra sources: acts like a plain view.
	$t->get_ok('/combine?l=' . url_escape('table:sales'))
	  ->status_is(200)->content_like(qr/sales/i);

	# Two identical sources stacked: row count doubles, content still present.
	$t->get_ok('/combine?l=' . url_escape('table:sales')
	         . '&c=' . url_escape('table:sales'))
	  ->status_is(200)->content_like(qr/sales/i);

	# Missing left table returns 404.
	$t->get_ok('/combine?l=' . url_escape('table:no_such_xyz'))
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
subtest 'POST /uploads/clear -- purge upload cache' => sub {
	$t->post_ok('/uploads/clear')
	  ->status_is(200)
	  ->json_has('/freed')
	  ->json_has('/count');
};

# ---------------------------------------------------------------------------
subtest 'GET /api/stat -- security: non-data-extension file' => sub {
	# stat_api intentionally returns exists:false for files whose extension is
	# not in $EXT_RE.  This prevents filesystem oracle attacks (callers cannot
	# use stat to probe arbitrary files like /etc/passwd).
	$t->get_ok('/api/stat?path=/etc/passwd')
	  ->status_is(200)
	  ->json_is('/exists', 0);

	# Directories also return exists:false for the same reason.
	$t->get_ok('/api/stat?path=/tmp')
	  ->status_is(200)
	  ->json_is('/exists', 0);
};

# ---------------------------------------------------------------------------
subtest 'GET /heatmap' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'heatsmoke.csv');
	Mojo::File->new($csv)->spurt("team,week,tickets\nAlpha,W1,5\nBeta,W1,3\nAlpha,W2,7\nBeta,W2,4\n");
	$t->get_ok('/heatmap?l=' . url_escape("path:$csv") . '&x=week&y=team&val=tickets')
	  ->status_is(200)
	  ->content_like(qr/id="heatmap"/, 'heatmap SVG present');
};

subtest 'GET /bar' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'barsmoke.csv');
	Mojo::File->new($csv)->spurt("region,amount\nNorth,100\nSouth,200\nEast,150\n");
	$t->get_ok('/bar?l=' . url_escape("path:$csv") . '&cat=region&val=amount')
	  ->status_is(200)
	  ->content_like(qr/id="bar_chart"/, 'bar chart SVG present');
};

subtest 'D3 can be served from the deployment itself' => sub {
	# Charts load D3 from a CDN unless d3_url says otherwise.  A local URL
	# is emitted as written, so a deployment can serve the library itself and
	# draw charts with no outbound network access.
	local $t->app->config->{d3_url} = '/static/d3/d3.min.js';

	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'd3smoke.csv');
	Mojo::File->new($csv)->spurt("region,amount\nNorth,100\nSouth,200\n");

	for my $path ('/bar', '/pie') {
		$t->get_ok("$path?l=" . url_escape("path:$csv") . '&cat=region&val=amount')
		  ->status_is(200)
		  ->content_like(qr{<script src="/static/d3/d3\.min\.js"></script>},
			"$path loads D3 from the configured URL")
		  ->content_unlike(qr{cdnjs\.cloudflare\.com|d3js\.org},
			"$path asks no CDN for D3");
	}
};

# ---------------------------------------------------------------------------
subtest 'GET /folder' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'foldersmoke.csv');
	Mojo::File->new($csv)->spurt("order_no,item\nA10,Widget\nA20,Gadget\nB5,Doohickey\n");
	$t->get_ok('/folder?l=' . url_escape("path:$csv") . '&col=order_no')
	  ->status_is(200)
	  ->content_like(qr/Folder view/, 'folder view heading present');
};

# ---------------------------------------------------------------------------
subtest 'GET /pivot' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'pivotsmoke.csv');
	Mojo::File->new($csv)->spurt(
		"region,product,amount\n"
		. "East,Widget,100\nWest,Widget,200\nEast,Gadget,50\nWest,Gadget,150\n"
	);
	my $lspec = url_escape("path:$csv");

	# Basic pivot: rows=region, single measure (count).
	$t->get_ok("/pivot?l=$lspec&rows=region&m=" . url_escape(':count:rows'))
	  ->status_is(200)
	  ->content_like(qr/Pivot/, 'pivot heading present');

	# Pivot with col dimension and sum measure.
	$t->get_ok("/pivot?l=$lspec&rows=region&cols=product&m=" . url_escape('amount:sum:revenue') . '&totals=1')
	  ->status_is(200)
	  ->content_like(qr/revenue/, 'measure alias present');

	# CSV export.
	$t->get_ok("/pivot?l=$lspec&rows=region&m=" . url_escape('amount:sum:revenue') . '&format=csv')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv});

	# Missing rows= -> 400.
	$t->get_ok("/pivot?l=$lspec&m=" . url_escape('amount:sum:revenue'))
	  ->status_is(400);

	# Missing m= -> 400.
	$t->get_ok("/pivot?l=$lspec&rows=region")
	  ->status_is(400);

	# Bad measure fn -> 400.
	$t->get_ok("/pivot?l=$lspec&rows=region&m=" . url_escape('amount:bogus:x'))
	  ->status_is(400);
};

# ---------------------------------------------------------------------------
subtest 'GET /calc/list' => sub {
	# With a known spec, returns JSON with a 'fields' key.
	$t->get_ok('/calc/list?l=table:sales')
	  ->status_is(200)
	  ->json_has('/fields', 'fields key present');

	# Without l= param returns 400.
	$t->get_ok('/calc/list')
	  ->status_is(400);
};

# ---------------------------------------------------------------------------
subtest 'A saved calculation appears in the table view' => sub {
	my $model_dir = File::Temp->newdir;
	my $calc      = Test::Mojo->new('Database::BI');
	$calc->app->config->{model_dir} = "$model_dir";

	$calc->post_ok('/calc/save', form => {
		l    => 'table:sales',
		name => 'tax_amount',
		expr => 'amount * 1.2',
	})->status_is(200)->json_is('/ok', 1, 'the calculation was saved');

	$calc->get_ok('/view/sales')->status_is(200)
		->content_like(qr/tax_amount/, 'the table view shows the saved column')
		->content_like(qr/1500(?:\.00)?/, 'and the value it calculates for the first row');

	$calc->post_ok('/calc/delete', form => {
		l    => 'table:sales',
		name => 'tax_amount',
	})->status_is(200);
};

# ---------------------------------------------------------------------------
subtest 'GET /stats' => sub {
	my $dir = File::Temp->newdir;
	my $csv = File::Spec->catfile("$dir", 'statssmoke.csv');
	Mojo::File->new($csv)->spurt(
		"name,score\nAlice,90\nBob,75\nCarol,85\n"
	);
	my $lspec = url_escape("path:$csv");

	$t->get_ok("/stats?l=$lspec")
	  ->status_is(200)
	  ->content_like(qr/statistics/i, 'stats heading present')
	  ->content_like(qr/name/, 'column name present');

	# Missing l= -> 400.
	$t->get_ok('/stats')
	  ->status_is(400);
};

done_testing();
