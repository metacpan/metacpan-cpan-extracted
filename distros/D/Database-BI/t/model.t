#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::JSON qw(decode_json encode_json);

# Minimal valid analysis spec used throughout the test file.
my %BASE_SPEC = (
	name     => 'Test Analysis',
	datasets => [ { spec => 'table:sales', alias => 'left' } ],
);

my $t = Test::Mojo->new('Database::BI');

# Redirect model storage to a per-run temp directory so tests are isolated.
my $model_dir = tempdir(CLEANUP => 1);
$t->app->config->{model_dir} = $model_dir;

# ---------------------------------------------------------------------------
# Phase 3.1 -- /api/analyses CRUD
# ---------------------------------------------------------------------------

subtest 'list returns empty array on fresh store' => sub {
	$t->get_ok('/api/analyses')
	  ->status_is(200)
	  ->json_is('/analyses' => []);
};

subtest 'create returns 201 with id' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json(\%BASE_SPEC)
	)->status_is(201)
	 ->json_has('/id')
	 ->json_is('/created' => 1);
};

subtest 'get retrieves created analysis' => sub {
	# Create one
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'GetTest' })
	)->status_is(201);
	my $id = $t->tx->res->json->{id};
	ok $id, 'got an id';

	$t->get_ok("/api/analyses/$id")
	  ->status_is(200)
	  ->json_is('/name' => 'GetTest')
	  ->json_is('/id'   => $id);
};

subtest 'list shows created analyses' => sub {
	$t->get_ok('/api/analyses')
	  ->status_is(200);
	my $list = $t->tx->res->json->{analyses};
	ok ref $list eq 'ARRAY' && @$list >= 2, 'at least two analyses in list';
	ok defined $_->{id} && defined $_->{name}, 'each entry has id and name'
		for @$list;
};

subtest 'full replace via PUT' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'BeforeReplace' })
	)->status_is(201);
	my $id = $t->tx->res->json->{id};

	$t->put_ok("/api/analyses/$id",
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'AfterReplace' })
	)->status_is(200)
	 ->json_is('/updated' => 1);

	$t->get_ok("/api/analyses/$id")
	  ->status_is(200)
	  ->json_is('/name' => 'AfterReplace');
};

subtest 'partial update via PATCH preserves untouched fields' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'PatchBase' })
	)->status_is(201);
	my $id = $t->tx->res->json->{id};

	$t->patch_ok("/api/analyses/$id",
		{ 'Content-Type' => 'application/json' },
		encode_json({ name => 'PatchedName' })
	)->status_is(200)
	 ->json_is('/updated' => 1);

	$t->get_ok("/api/analyses/$id")
	  ->status_is(200)
	  ->json_is('/name' => 'PatchedName');

	# datasets were not in the PATCH body -- they must still be present
	my $ds = $t->tx->res->json->{datasets};
	ok ref $ds eq 'ARRAY' && @$ds, 'datasets preserved after PATCH';
};

subtest 'delete removes analysis' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'ToDelete' })
	)->status_is(201);
	my $id = $t->tx->res->json->{id};

	$t->delete_ok("/api/analyses/$id")
	  ->status_is(200)
	  ->json_is('/deleted' => 1);

	$t->get_ok("/api/analyses/$id")
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
# Export / import round-trip
# ---------------------------------------------------------------------------

subtest 'export downloads JSON document' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'ExportTest' })
	)->status_is(201);
	my $id = $t->tx->res->json->{id};

	$t->get_ok("/api/analyses/$id/export")
	  ->status_is(200);

	my $body = $t->tx->res->body;
	my $doc  = eval { decode_json($body) };
	ok !$@,               'exported body is valid JSON';
	is $doc->{name}, 'ExportTest', 'exported name matches';
	is $doc->{id},   $id,          'exported id matches';
};

subtest 'import creates a new analysis from raw JSON body' => sub {
	my $doc = { %BASE_SPEC, name => 'ImportedAnalysis', id => 'should-be-stripped' };
	$t->post_ok('/api/analyses/import',
		{ 'Content-Type' => 'application/json' },
		encode_json($doc)
	)->status_is(201)
	 ->json_is('/imported' => 1)
	 ->json_has('/id');

	my $new_id = $t->tx->res->json->{id};
	isnt $new_id, 'should-be-stripped', 'server assigns a fresh id';

	$t->get_ok("/api/analyses/$new_id")
	  ->status_is(200)
	  ->json_is('/name' => 'ImportedAnalysis');
};

subtest 'export then import round-trip preserves name and datasets' => sub {
	# Create
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'RoundTrip' })
	)->status_is(201);
	my $orig_id = $t->tx->res->json->{id};

	# Export
	$t->get_ok("/api/analyses/$orig_id/export")->status_is(200);
	my $exported_json = $t->tx->res->body;

	# Import
	$t->post_ok('/api/analyses/import',
		{ 'Content-Type' => 'application/json' },
		$exported_json
	)->status_is(201);
	my $new_id = $t->tx->res->json->{id};
	isnt $new_id, $orig_id, 'import creates a distinct id';

	# Verify
	$t->get_ok("/api/analyses/$new_id")->status_is(200);
	is $t->tx->res->json->{name}, 'RoundTrip', 'name survives round-trip';
	my $ds_orig = decode_json($exported_json)->{datasets};
	my $ds_new  = $t->tx->res->json->{datasets};
	is_deeply $ds_new, $ds_orig, 'datasets survive round-trip';
};

# ---------------------------------------------------------------------------
# Validation rejection table
# ---------------------------------------------------------------------------

subtest 'create rejects missing name' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ datasets => [{ spec => 'table:sales' }] })
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'create rejects missing datasets' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ name => 'NoDatasets' })
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'create rejects empty datasets array' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ name => 'EmptyDS', datasets => [] })
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'create rejects dataset spec with forbidden prefix' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ name => 'BadSpec', datasets => [{ spec => 'file:///etc/passwd' }] })
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'create rejects unsupported analysis version' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, version => 99 })
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'create rejects invalid JSON body' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		'not json at all'
	)->status_is(400)
	 ->json_has('/error');
};

subtest 'get returns 404 for unknown id' => sub {
	$t->get_ok('/api/analyses/doesnotexist99')
	  ->status_is(404)
	  ->json_has('/error');
};

subtest 'put returns 404 for unknown id' => sub {
	$t->put_ok('/api/analyses/doesnotexist99',
		{ 'Content-Type' => 'application/json' },
		encode_json(\%BASE_SPEC)
	)->status_is(404);
};

subtest 'patch returns 404 for unknown id' => sub {
	$t->patch_ok('/api/analyses/doesnotexist99',
		{ 'Content-Type' => 'application/json' },
		encode_json({ name => 'x' })
	)->status_is(404);
};

subtest 'delete returns 404 for unknown id' => sub {
	$t->delete_ok('/api/analyses/doesnotexist99')
	  ->status_is(404);
};

subtest 'id with non-alphanumeric chars returns 400' => sub {
	# Use an id that passes Mojo routing (single path segment) but fails the
	# /\A[A-Za-z0-9]+\z/ guard inside the controller.
	$t->get_ok('/api/analyses/abc!def')
	  ->status_is(400);
};

# ---------------------------------------------------------------------------
# /a/:id -- render redirect (Phase 3.1)
# ---------------------------------------------------------------------------

subtest '/a/:id redirects to reconstructed URL' => sub {
	my $spec = {
		name     => 'RedirectTest',
		datasets => [
			{ spec => 'table:sales', alias => 'left', filters => [] },
		],
		joins => [],
	};
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201);
	my $id = $t->tx->res->json->{id};

	$t->get_ok("/a/$id")
	  ->status_is(302);

	my $loc = $t->tx->res->headers->location;
	like $loc, qr{/join\?l=}, 'redirect points to /join with l= param';
	like $loc, qr{table%3Asales|table:sales}, 'left spec is in the redirect URL';
};

subtest '/a/:id returns 404 for unknown id' => sub {
	$t->get_ok('/a/nosuchanalysis')
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
# Atomic write: verify no partial JSON on disk
# ---------------------------------------------------------------------------

subtest 'analyses.json is valid JSON after write' => sub {
	$t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({ %BASE_SPEC, name => 'AtomicWrite' })
	)->status_is(201);

	my $file = Mojo::File->new($model_dir)->child('analyses.json');
	ok -f $file, 'analyses.json file exists';
	my $content = $file->slurp;
	my $parsed  = eval { decode_json($content) };
	ok !$@,                 'analyses.json contains valid JSON';
	ok ref $parsed eq 'HASH', 'analyses.json decoded to a hash';
};

# ---------------------------------------------------------------------------
# Degraded mode: read-only model_dir
# ---------------------------------------------------------------------------

SKIP: {
	# Only run this test when we can actually chmod (root can always write)
	skip 'Cannot test read-only dir as root', 2 if $> == 0;

	my $ro_dir = tempdir(CLEANUP => 1);
	# Create the analyses.json first so the app can read but not write
	Mojo::File->new($ro_dir)->child('analyses.json')
		->spurt(encode_json({}));
	chmod 0555, $ro_dir;

	my $ro_t = Test::Mojo->new('Database::BI');
	$ro_t->app->config->{model_dir} = $ro_dir;

	$ro_t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json(\%BASE_SPEC)
	)->status_is(503, 'write to read-only dir returns 503');

	$ro_t->get_ok('/api/analyses')
	  ->status_is(200, 'read still works on read-only dir');

	chmod 0755, $ro_dir;  # restore for CLEANUP
}

# ---------------------------------------------------------------------------
# Phase 3.3 -- cross-filter on the canvas (/a/:id?cf=col:op:val&cv=N)
# ---------------------------------------------------------------------------

subtest '3.3: cross-filter filters non-source visuals and highlights source' => sub {
	# Use table visuals (kind=>'table') so we can inspect rendered cell data
	# without needing HTML::D3 to be installed.  sales.csv has columns:
	#   id, product, region, sales_rep, amount, sale_date
	# We create two visuals, both showing the full table.
	# With ?cf=region:eq:North, visual 1 should show only North rows;
	# visual 0 (the source, cv=0) should still show all regions.

	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'CF test canvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'table', encode => { columns => ['region', 'amount'] }, title => 'All regions' },
			{ kind => 'table', encode => { columns => ['region', 'amount'] }, title => 'Filtered' },
		],
	};

	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};
	ok $cid, 'canvas id returned';

	# -- Phase 1: no cross-filter -- both visuals show all rows
	$t->get_ok("/a/$cid")
	  ->status_is(200, 'canvas renders without cross-filter');
	my $body = $t->tx->res->body;
	is scalar(() = $body =~ /North/g) >= 2, 1,
		'North appears in both visuals (no cross-filter)';
	unlike $body, qr/id="cf-chip"/, 'no cross-filter chip element when cf= absent';

	# -- Phase 2: cross-filter with cv=0 (source) --
	# visual 0 is source: unfiltered, gets cf-source class
	# visual 1 is filtered: shows only North rows
	use Mojo::Util qw(url_escape);
	$t->get_ok("/a/$cid?cf=" . url_escape('region:eq:North') . "&cv=0")
	  ->status_is(200, 'canvas renders with cross-filter');
	my $cf_body = $t->tx->res->body;

	like   $cf_body, qr/id="cf-chip"/,      'cross-filter chip rendered';
	like   $cf_body, qr/region = North/,    'chip shows filter description';
	like   $cf_body, qr/class="[^"]*\bcf-source\b/, 'source visual gets cf-source class on element';
	like   $cf_body, qr/Clear/,             'clear link present';
	like   $cf_body, qr/\?cf=/,             'clear link URL contains cf param (before stripping)';

	# The cross-filter chip's clear href must NOT contain cf= or cv=
	if ($cf_body =~ /href="([^"]+)"[^>]*>\s*[&\#x2F;\w]*\s*Clear/) {
		my $clear_href = $1;
		unlike $clear_href, qr/[?&]cf=/,  'clear href has no cf= param';
		unlike $clear_href, qr/[?&]cv=/,  'clear href has no cv= param';
	}

	# visual 0 (source, cv=0): both North and South should still appear
	# visual 1 (filtered): only North rows, South absent from that visual's section
	# We check by counting visual card sections -- source card has cf-source class;
	# the text "South" should appear in the source section but not in the filtered one.
	# Simplified: verify South appears at all (source) and North appears at all (both).
	like   $cf_body, qr/North/,   'North visible (in source and/or filtered visual)';
	like   $cf_body, qr/South/,   'South visible in source (unfiltered) visual';

	# -- Phase 3: cross-filter without cv (no source) -- both visuals filtered
	$t->get_ok("/a/$cid?cf=" . url_escape('region:eq:North'))
	  ->status_is(200, 'cross-filter without cv= still renders');
	my $nocv_body = $t->tx->res->body;
	like   $nocv_body, qr/id="cf-chip"/, 'chip shown when cv absent';
	unlike $nocv_body, qr/class="[^"]*\bcf-source\b/, 'no cf-source class on any element when cv absent';

	# -- Phase 4: clear URL round-trip -- canvas renders normally after clearing
	$t->get_ok("/a/$cid")
	  ->status_is(200, 'canvas renders cleanly after cross-filter cleared');
};

subtest '3.4: drill-through link in cross-filter chip' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'DT Canvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'table', encode => {}, title => 'Table' },
		],
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};

	# Without cross-filter: no drill-through link element (CSS class name
	# appears in the <style> block, so match the HTML attribute form instead).
	$t->get_ok("/a/$cid")->status_is(200);
	unlike $t->tx->res->body, qr/class="cf-drillthrough"/,
		'no drill-through link when no cf= active';

	# With cross-filter: drill-through link appears in the chip pointing to /open.
	# The URL contains ?path=<encoded> followed by &f= (HTML-encoded as &amp;f=).
	require Mojo::Util;
	my $cf_url = "/a/$cid?cf=" . Mojo::Util::url_escape('region:eq:North');
	$t->get_ok($cf_url)->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/class="cf-drillthrough"/,
		'drill-through link present when cf= is active';
	like $b, qr{/open\?path=.*f=region},
		'drill-through URL contains /open with f= param';
};

subtest '3.4: drill-down breadcrumb from ?dd=/?dl= params' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name        => 'Drill Canvas',
		datasets    => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals     => [
			{ kind => 'bar', encode => { cat => 'region' },  title => 'By Region' },
			{ kind => 'bar', encode => { cat => 'product' }, title => 'By Product' },
		],
		hierarchies => [ { name => 'Geo', levels => [ 'region', 'product' ] } ],
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201, 'canvas with hierarchies created')->tx->res->json;
	my $cid = $res->{id};

	# Level 0: "All" is current (no link)
	$t->get_ok("/a/$cid?dd=Geo&dl=0")->status_is(200);
	my $b0 = $t->tx->res->body;
	like   $b0, qr/class="drill-cur"[^>]*>All</,
		'All is current at dl=0';
	unlike $b0, qr/<a [^>]*>All</,
		'All has no link at dl=0 (already at top)';
	unlike $b0, qr/id="cf-chip"/,
		'no cf chip when drill mode is active';

	# Level 1 after drilling into North: All is a link, North is current
	require Mojo::Util;
	my $dl1_url = "/a/$cid?dd=Geo&dl=1&cf=" . Mojo::Util::url_escape('region:eq:North');
	$t->get_ok($dl1_url)->status_is(200);
	my $b1 = $t->tx->res->body;
	like   $b1, qr/<a [^>]*href=[^>]*>All</,
		'All is a link at dl=1';
	like   $b1, qr/class="drill-cur"[^>]*>North</,
		'North is current at dl=1';
	like   $b1, qr/drill-through-link/,
		'drill-through link present when drill path is non-empty';

	# Level 2 (max): breadcrumb = All > North > product_val (current)
	my $dl2_url = "/a/$cid?dd=Geo&dl=2"
		. '&cf=' . Mojo::Util::url_escape('region:eq:North')
		. '&cf=' . Mojo::Util::url_escape('product:eq:Widget A');
	$t->get_ok($dl2_url)->status_is(200);
	my $b2 = $t->tx->res->body;
	like   $b2, qr/<a [^>]*href=[^>]*>All</,     'All linked at dl=2';
	like   $b2, qr/<a [^>]*href=[^>]*>North</,   'North linked at dl=2';
	like   $b2, qr/class="drill-cur"[^>]*>Widget A</, 'Widget A is current at dl=2';
};

subtest '3.3: _vis_cf_col selects correct dimension per kind' => sub {
	# White-box check via canvas_render stash (inspect rendered HTML for data-cf-col).
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'CF col test',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'table',   encode => { cat => 'region' },                      title => 'T1' },
			{ kind => 'table',   encode => { x   => 'sale_date' },                   title => 'T2' },
			{ kind => 'table',   encode => {},                                        title => 'T3' },
		],
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid2 = $res->{id};

	$t->get_ok("/a/$cid2")->status_is(200);
	my $b = $t->tx->res->body;
	like   $b, qr/data-cf-col="region"/,    'cat column exposed as data-cf-col';
	like   $b, qr/data-cf-col="sale_date"/, 'x column exposed as data-cf-col';
	unlike $b, qr/data-cf-col=""/, 'empty cf_col produces no data-cf-col attribute';
};

# ---------------------------------------------------------------------------
# Phase 3.5 -- parameters and what-if
# ---------------------------------------------------------------------------

subtest '3.5: parameter bar renders with defaults and URL values' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'Param Canvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
		params   => {
			target   => { type => 'number', default => 100, min => 0, max => 1000 },
			label    => { type => 'string', default => 'All' },
		},
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};

	# Default values: no ?p.* in URL.
	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/id="param-bar"/,              'param-bar rendered';
	like $b, qr/data-param="p\.target"/,      'target input present';
	like $b, qr/data-param="p\.label"/,       'label input present';
	like $b, qr/value="100"/,                 'target default value 100';
	like $b, qr/value="All"/,                 'label default value All';
	like $b, qr/type="number"/,               'target rendered as number input';
	like $b, qr/min="0"/,                     'min attribute present';
	like $b, qr/max="1000"/,                  'max attribute present';

	# URL-supplied value overrides default.
	require Mojo::Util;
	$t->get_ok("/a/$cid?p.target=50")->status_is(200);
	$b = $t->tx->res->body;
	like $b, qr/value="50"/, 'URL-supplied param value shown in input';
};

subtest '3.5: out-of-range parameter returns 400' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'Range Check',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
		params   => {
			rate => { type => 'number', default => 5, min => 0, max => 100 },
		},
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};

	$t->get_ok("/a/$cid?p.rate=200")->status_is(400, '200 > max 100 returns 400');
	$t->get_ok("/a/$cid?p.rate=-5")->status_is(400, '-5 < min 0 returns 400');
	$t->get_ok("/a/$cid?p.rate=abc")->status_is(400, 'non-numeric for number param returns 400');
	$t->get_ok("/a/$cid?p.rate=50")->status_is(200, 'in-range value renders normally');
};

subtest '3.5: parameter flows into calc expression' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'Calc Param',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
		params   => {
			factor => { type => 'number', default => 1 },
		},
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};

	require Mojo::Util;
	# ?c= inline calc that references the parameter by name.
	my $c_spec = Mojo::Util::url_escape('scaled:amount * factor');
	$t->get_ok("/a/$cid?c=$c_spec&p.factor=2")->status_is(200,
		'canvas with calc referencing param renders');
	my $b = $t->tx->res->body;
	like $b, qr/scaled/, 'calc column name appears in rendered output';
};

subtest '3.5: param-column clash returns 400' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	# A parameter named the same as an existing column ('amount') is rejected
	# at compile time when a calc field references it.
	my $spec = {
		name     => 'Clash Test',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
		params   => {
			amount => { type => 'number', default => 0 },
		},
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json;
	my $cid = $res->{id};

	require Mojo::Util;
	my $c_spec = Mojo::Util::url_escape('doubled:amount * 2');
	$t->get_ok("/a/$cid?c=$c_spec")->status_is(400,
		'param-column clash in calc expression returns 400');
	like $t->tx->res->body, qr/amount/, 'error names the clashing identifier';
};

# ---------------------------------------------------------------------------
# Phase 3.6 -- Bookmarks and Undo/Redo
# ---------------------------------------------------------------------------

subtest '3.6: canvas renders undo/redo buttons' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'UndoRedo',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/id="btn-undo"/, 'undo button present';
	like $b, qr/id="btn-redo"/, 'redo button present';
	like $b, qr/btn-undo.*disabled/s, 'undo button initially disabled';
	like $b, qr/btn-redo.*disabled/s, 'redo button initially disabled';
	like $b, qr/pushUndo/, 'pushUndo function defined in JS';
	like $b, qr/initUndoRedo/, 'initUndoRedo called in JS';
};

subtest '3.6: bookmark panel present in canvas' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'BmCanvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/id="btn-bm"/, 'bookmark toggle button present';
	like $b, qr/id="bm-panel"/, 'bookmark panel present';
	like $b, qr/bm-empty/, 'empty bookmark message shown (no bookmarks yet)';
	like $b, qr/canvasBookmarks/, 'canvasBookmarks JS variable present';
	unlike $b, qr/class="bm-item"/, 'no bookmark items shown before any are saved';
};

subtest '3.6: save bookmark via PATCH then verify on canvas' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'BmSave',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	# Save a bookmark by PATCHing the analyses endpoint directly
	# (mirrors what the JS patchBookmarks() function does).
	my $bm = { name => 'My view', state => '?f=region:eq:North', created => 1234567890 };
	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ bookmarks => [$bm] })
	)->status_is(200);

	# Verify the bookmark is persisted in the stored analysis.
	$t->get_ok("/api/analyses/$cid")->status_is(200);
	my $stored = $t->tx->res->json;
	is ref($stored->{bookmarks}), 'ARRAY', 'bookmarks key is array';
	is scalar @{ $stored->{bookmarks} }, 1, 'one bookmark stored';
	is $stored->{bookmarks}[0]{name},    'My view', 'bookmark name correct';
	is $stored->{bookmarks}[0]{state},   '?f=region:eq:North', 'bookmark state correct';
	is $stored->{bookmarks}[0]{created}, 1234567890, 'bookmark created timestamp preserved';

	# Verify the canvas renders the bookmark link.
	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/class="bm-item"/, 'saved bookmark item rendered';
	like $b, qr/My view/, 'bookmark name visible';
	like $b, qr{/a/[^"]+\?f=region}, 'bookmark href contains state';
	like $b, qr/class="bm-del-btn"/, 'delete button rendered on bookmark';
	unlike $b, qr/id="bm-empty"/, 'empty-state message absent when bookmarks exist';
};

subtest '3.6: undo/redo JS stack key scoped to canvas id' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'StackKey',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;

	# The localStorage key must contain the canvas id so stacks from
	# different analyses do not collide.
	like $b, qr/bi:undo:/, 'localStorage key prefix present';
	# The key includes the canvas id (either literal in JS or via anaId var).
	like $b, qr/UNDO_KEY\s*=\s*'bi:undo:'\s*\+\s*anaId/, 'stack key uses anaId';
	like $b, qr/MAX_STACK\s*=\s*50/, 'max stack size is 50';
};

# ---------------------------------------------------------------------------
# Phase 3.7 -- Print / PDF / PNG
# ---------------------------------------------------------------------------

subtest '3.7: print button and PNG download infrastructure present' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'PrintExport',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'product', val => 'amount' }, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;

	# Print button
	like $b, qr/id="btn-print"/, 'Print button present in toolbar';
	like $b, qr/window\.print\(\)/, 'Print button calls window.print()';

	# Per-visual download button injected in card header
	like $b, qr/class="visual-dl-btn"/, 'PNG download button rendered on visual card';
	like $b, qr/downloadCardPng/, 'downloadCardPng JS function defined';
	like $b, qr/initDownloadButtons/, 'initDownloadButtons called';
	like $b, qr/XMLSerializer/, 'SVG serialiser used for PNG export';

	# Print CSS
	like $b, qr/\@media print/, '@media print block present';
	like $b, qr/\@page/, '@page rule present in print CSS';
	like $b, qr/break-inside\s*:\s*avoid/, 'break-inside:avoid on visual cards';
};

subtest '3.7: print CSS hides toolbar controls and keeps title' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'PrintCss',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'T' } ],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;

	# The print block must hide toolbar buttons but NOT the h2 title.
	# We check that the print block targets .canvas-toolbar button
	# (hides controls) without targeting h2 (which would hide the title).
	like $b, qr/canvas-toolbar button[^{]*\{[^}]*display\s*:\s*none/s,
		'print CSS hides toolbar buttons';

	# The canvas-grid should use a 2-column layout in print.
	like $b, qr/\@media print[^}]*\{[^@]*canvas-grid[^{]*\{[^}]*grid-template-columns\s*:\s*1fr 1fr/s,
		'print CSS sets canvas-grid to 2 columns';
};

# ---------------------------------------------------------------------------
# Phase 3.2 -- canvas grid spans: resize handles and layout persistence
# ---------------------------------------------------------------------------

subtest '3.2: resize handles render and layout spans are validated and persisted' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'ResizeCanvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'table', encode => {}, title => 'Left'  },
			{ kind => 'table', encode => {}, title => 'Right' },
		],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;

	# One handle per visual card, and the wiring that makes it resize.
	my $handles = () = $b =~ /class="visual-resize-handle"/g;
	is $handles, 2, 'one resize handle per visual';
	like $b, qr/initResizeHandles/,            'resize handles are wired up';
	like $b, qr/onResizeStart/,                'resize drag handler defined';
	like $b, qr/onResizeMove/,                 'resize drag moves the span';
	like $b, qr/nwse-resize/,                  'resize cursor affordance in CSS';
	like $b, qr/touch-action\s*:\s*none/,      'handle opts out of touch panning';
	# The grip has to be visible, not just present: a bare 18px corner is easy
	# to miss entirely, so the ridge triangle and its hover reveal matter.
	like $b, qr/\.visual-resize-handle::after/,              'the grip is drawn, not just the hit area';
	like $b, qr/\.visual-resize-handle::after\s*\{[^}]*repeating-linear-gradient/s,
		'the grip is marked with the conventional diagonal ridges';
	like $b, qr/\.visual-card:hover\s+\.visual-resize-handle/,
		'the grip comes up to full strength when the card is hovered';
	like $b, qr/grid-auto-rows\s*:\s*minmax/,  'row span is a real height, not just a number';
	like $b, qr/\@media print.*?visual-resize-handle[^{]*\{[^}]*display\s*:\s*none/s,
		'print CSS hides the resize handles';

	# Persist a layout: visual 0 full width, visual 1 half width and two rows.
	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => [
			{ visual => 0, x => 1, y => 1, w => 12, h => 1 },
			{ visual => 1, x => 1, y => 2, w => 6,  h => 2 },
		] })
	)->status_is(200, 'layout PATCH accepted');

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	my $stored = $t->tx->res->json->{layout};
	is scalar(@$stored), 2, 'both layout entries stored';
	is $stored->[0]{w}, 12, 'visual 0 stored full width';
	is $stored->[1]{h}, 2,  'visual 1 stored two rows tall';

	# ... and the canvas renders those spans server-side, with no JavaScript.
	$t->get_ok("/a/$cid")->status_is(200);
	$b = $t->tx->res->body;
	like $b, qr/id="visual-0"[^>]*style="[^"]*grid-column:1\/span 12/,
		'visual 0 rendered full width';
	like $b, qr/id="visual-1"[^>]*style="[^"]*grid-column:1\/span 6/,
		'visual 1 rendered half width';
	like $b, qr/id="visual-1"[^>]*style="[^"]*grid-row:2\/span 2/,
		'visual 1 rendered two rows tall';

	# Spans outside the grid are rejected rather than stored: a drag can only
	# produce whole columns and rows inside 12 columns, so anything else means
	# the document (not the drag) is wrong.
	my @bad = (
		[ { visual => 0, x => 1,  y => 1, w => 13,   h => 1 }, 'w wider than the grid' ],
		[ { visual => 0, x => 8,  y => 1, w => 6,    h => 1 }, 'x + w - 1 past column 12' ],
		[ { visual => 0, x => 1,  y => 1, w => 0,    h => 1 }, 'zero-width span' ],
		[ { visual => 0, x => 1,  y => 1, w => 6,    h => 0 }, 'zero-height span' ],
		[ { visual => 0, x => 1,  y => 1, w => 6,    h => 7 }, 'taller than the row cap' ],
		[ { visual => 0, x => 0,  y => 1, w => 6,    h => 1 }, 'x before column 1' ],
		[ { visual => 0, x => 13, y => 1, w => 1,    h => 1 }, 'x past the last column' ],
		[ { visual => 0, x => 1,  y => 0, w => 6,    h => 1 }, 'y before row 1' ],
		[ { visual => 0, x => 1,  y => 1, w => 'wide', h => 1 }, 'non-numeric span' ],
		[ { visual => 0, x => 1,  y => 1, w => 6.5,  h => 1 }, 'fractional span' ],
		[ { visual => 0, x => 1,  y => 1, w => 6 },            'entry missing h' ],
	);
	for my $case (@bad) {
		$t->patch_ok("/api/analyses/$cid",
			{ 'Content-Type' => 'application/json' },
			encode_json({ layout => [ $case->[0] ] })
		)->status_is(400, "rejected: $case->[1]");
	}

	# A rejected layout must not have reached the store.
	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is_deeply $t->tx->res->json->{layout}, $stored,
		'rejected layouts were not stored';
};

done_testing;
