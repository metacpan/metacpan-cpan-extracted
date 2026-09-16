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
    # A nonexistent table renders the home page with an error message (still 200).
    $t->get_ok('/view/nonexistent_xyz_table')->status_is(200);
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

done_testing();
