#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::JSON qw(decode_json encode_json);
use Test::Permissions qw(skip_unless_can_revoke with_revoked);

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

subtest 'POST /api/analyses/:id/visuals appends a rendered table or chart' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'Append visuals',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [ { kind => 'table', encode => {}, title => 'All rows' } ],
		layout   => [ { visual => 0, x => 1, y => 1, w => 6, h => 3 } ],
		params   => { factor => { type => 'number', default => 1 } },
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'table',
			encode => { columns => ['region', 'amount'] },
			title  => 'Regions',
		})
	)->status_is(201)
	 ->json_is('/id'     => $cid)
	 ->json_is('/visual' => 1)
	 ->json_is('/title'  => 'Regions');

	my $table_html = $t->tx->res->json->{html};
	like $table_html, qr/<table/, 'the response carries the rendered table';
	like $table_html, qr/North/,  'the new table renders the canvas rows';

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	my $stored = $t->tx->res->json;
	is scalar @{ $stored->{visuals} }, 2, 'the table was appended to the saved visuals';
	is $stored->{visuals}[1]{kind}, 'table', 'the appended visual keeps its kind';
	is_deeply $stored->{visuals}[1]{encode}{columns}, [qw(region amount)],
		'the appended table keeps its chosen columns';
	is scalar @{ $stored->{layout} }, 1,
		'the new card is auto-placed, leaving the saved layout alone';

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'bar',
			encode => { cat => 'region', value => 'amount' },
			title  => 'Amount by region',
		})
	)->status_is(201)
	 ->json_is('/visual' => 2)
	 ->json_is('/title'  => 'Amount by region')
	 ->json_is('/kind'   => 'bar')
	 ->json_is('/cf_col' => 'region');
	like $t->tx->res->json->{html}, qr/<svg/, 'the response carries a rendered chart';
	like $t->tx->res->json->{html}, qr/id="vis-2"/,
		'and the chart has an element id of its own, not a shared #bar_chart';

	# A card added in place is drawn against the canvas's own URL state, which
	# the page sends with the request: without that it would show every region
	# on a canvas the reader has filtered to one.
	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'bar',
			encode => { cat => 'region', value => 'amount' },
			title  => 'North only',
			query  => '?cf=region:eq:North',
		})
	)->status_is(201)->json_is('/visual' => 3);

	my $filtered = $t->tx->res->json->{html};
	like $filtered, qr/id="vis-3"/, 'the filtered chart has an element id of its own';
	like $filtered, qr/North/, 'the selected value is drawn';
	unlike $filtered, qr/South/, 'and the cross-filter the page was showing applied';

	# The same query can carry calculated columns and the parameter values they
	# reference, so a card using a column the canvas already shows is accepted.
	require Mojo::Util;
	my $calc_qs = '?c=' . Mojo::Util::url_escape('scaled:amount * factor') . '&p.factor=2';
	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'table',
			encode => { columns => ['scaled'] },
			title  => 'Scaled',
			query  => $calc_qs,
		})
	)->status_is(201)->json_is('/visual' => 4);
	like $t->tx->res->json->{html}, qr/<th>scaled<\/th>/,
		'the calculated column named in the query is on the card';
	like $t->tx->res->json->{html}, qr/>2500</,
		'and the parameter value in the query was bound';

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	my $after = $t->tx->res->json;
	is scalar @{ $after->{visuals} }, 5, 'the chart and the two filtered cards were appended too';
	is $after->{visuals}[2]{kind}, 'bar', 'the chart kind is stored';
	is_deeply $after->{visuals}[2]{encode}, { cat => 'region', value => 'amount' },
		'the chart encoding is stored';

	$t->get_ok("/a/$cid")->status_is(200);
	my $page = $t->tx->res->body;
	like $page, qr/id="btn-add-current"/, 'the canvas offers Add current view';
	like $page, qr/id="ac-panel"/,        'the add panel is on the canvas page';
	like $page, qr/var canvasColumns = \[/, 'the panel can list the canvas columns';
	like $page, qr/Amount by region/,      'the appended chart renders on the canvas';
	like $page, qr/id="vis-2"/, 'the first chart card keeps its element id';
	like $page, qr/id="vis-3"/, 'the appended chart card has a different one';
	like $page, qr/d3\.select\("#vis-3"\)/, 'so each card draws into its own element';
	like $page, qr/finished drawing/, 'and the page can say when the card has finished drawing';
	like $page, qr/function drawnIn/, 'which it knows from what the script drew, not from the script running';
	like $page, qr/name: 'D3', what: 'the chart library'/, 'D3 is the library named for a chart';
	like $page, qr/name: 'Leaflet', what: 'the map library'/, 'and Leaflet for a map';
	like $page, qr/announceLibMissing\(lib, json\.kind, title\)/, 'and a card whose library is missing is announced by name';
	like $page, qr/finished redrawing/, 'an edited map says when it has finished redrawing';
	like $page, qr/could not be redrawn:/, 'and names Leaflet when it cannot be redrawn';
};

subtest 'A canvas loads D3 from the configured URL' => sub {
	# The canvas script tag follows d3_url like the chart pages do, so a
	# self-hosted copy is used for cards appended in place as well.
	plan skip_all => 'data/sales.csv not found'
		unless -f $t->app->home->child('data/sales.csv');
	local $t->app->config->{d3_url} = '/static/d3/d3.min.js';

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			%BASE_SPEC,
			name    => 'Self-hosted D3 canvas',
			visuals => [
				{ kind => 'table', encode => { columns => ['region'] }, title => 'Rows' },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $page = $t->tx->res->body;
	like $page, qr{<script src="/static/d3/d3\.min\.js"></script>},
		'the canvas loads D3 from the configured URL';
	unlike $page, qr{cdnjs\.cloudflare\.com|d3js\.org},
		'and asks no CDN for D3';
};

subtest 'A canvas seeded from a chart page keeps the chart options' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };
	require Mojo::Util;

	# Each case takes the spec the chart page offers New Canvas, saves it as a
	# canvas and reads the rendered card.  The marker is a line of the drawn
	# chart, so it is the card that has to keep the option, not just the spec.
	my @cases = (
		{
			label       => 'a horizontal bar',
			url         => '/bar?l=table:sales&cat=region&val=amount&orient=h',
			orientation => 'h',
			marker      => qr/var yScale = d3\.scaleBand\(\)/,
			what        => 'a seeded canvas draws it horizontally',
		},
		{
			label       => 'a capped bar',
			url         => '/bar?l=table:sales&cat=region&val=amount&max=1',
			orientation => 'vertical',
			max_items   => 1,
			marker      => qr/"label":"Other"/,
			what        => 'the top-N cap is kept, with its Other bar',
		},
		{
			label       => 'a horizontal stacked bar',
			url         => '/stacked?l=table:sales&cat=region&seg=product&val=amount&orient=h',
			orientation => 'h',
			marker      => qr/var yScale = d3\.scaleBand\(\)/,
			what        => 'a seeded canvas draws it horizontally',
		},
		{
			label       => 'a heatmap with values shown',
			url         => '/heatmap?l=table:sales&x=region&y=product&val=amount&show_val=1',
			show_values => 1,
			marker      => qr/var showVals\d* = 1;/,
			what        => 'a seeded canvas shows the cell values',
		},
	);

	for my $case (@cases) {
		$t->get_ok($case->{url})->status_is(200, "$case->{label}: the chart page renders");

		my ($attr) = $t->tx->res->body =~ /id="new-canvas-panel" data-chart="([^"]*)"/;
		ok defined $attr, "$case->{label}: the page offers a chart spec" or next;
		my $spec = decode_json(Mojo::Util::html_unescape($attr));

		if (defined $case->{orientation}) {
			is $spec->{options}{orientation}, $case->{orientation},
				"$case->{label}: the spec carries the orientation";
		}
		if (defined $case->{max_items}) {
			is $spec->{options}{max_items}, $case->{max_items},
				"$case->{label}: the spec carries the bar cap";
		}
		if (defined $case->{show_values}) {
			is $spec->{options}{show_values}, $case->{show_values},
				"$case->{label}: the spec carries show_values";
		}

		my $cid = $t->post_ok('/api/analyses',
			{ 'Content-Type' => 'application/json' },
			encode_json({
				name     => 'Seeded: ' . $case->{label},
				datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
				visuals  => [ $spec ],
			})
		)->status_is(201)->tx->res->json->{id};

		$t->get_ok("/a/$cid")->status_is(200);
		like $t->tx->res->body, $case->{marker}, $case->{what};
	}
};

subtest 'A treemap card renders when the canvas is opened' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	# The treemap snippet takes { path, value } rows, not [label, value]
	# pairs; giving it pairs made the whole canvas 500, which the browser seed
	# test found.  This is the non-browser guard for it.
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Treemap canvas',
			datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
			visuals  => [ {
				kind   => 'treemap',
				encode => { cat => 'product', value => 'amount' },
				title  => 'Treemap',
			} ],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")
		->status_is(200, 'the canvas opens')
		->content_like(qr/id="vis-0"/, 'the card has the treemap element')
		->content_like(qr/Treemap/, 'and the card is titled');
};

subtest 'POST /api/analyses/:id/visuals rejects a visual it cannot draw' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Reject visuals',
			datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
			visuals  => [ { kind => 'table', encode => {}, title => 'All rows' } ],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'bar', encode => { cat => 'no_such_column', value => 'amount' } })
	)->status_is(400);
	like $t->tx->res->json->{error}, qr/Column not found/,
		'the error names the missing column';

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'sankey', encode => {} })
	)->status_is(400);
	like $t->tx->res->json->{error}, qr/Unsupported visual kind/,
		'the error names the unsupported kind';

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is scalar @{ $t->tx->res->json->{visuals} }, 1,
		'a rejected visual is not stored';
};

subtest 'POST /api/analyses/:id/visuals returns 404 for unknown canvas' => sub {
	$t->post_ok('/api/analyses/nosuchcanvas/visuals',
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'table', encode => {} })
	)->status_is(404);
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
	my $ro_dir = tempdir(CLEANUP => 1);
	# Create the analyses.json first so the app can read but not write
	Mojo::File->new($ro_dir)->child('analyses.json')
		->spurt(encode_json({}));

	# Skips where chmod cannot stop a file being created: root, Cygwin and
	# Windows ACLs, some network and container filesystems.
	skip_unless_can_revoke('create', 4, $ro_dir);

	with_revoked('create', $ro_dir, sub {
		my $ro_t = Test::Mojo->new('Database::BI');
		$ro_t->app->config->{model_dir} = $ro_dir;

		$ro_t->post_ok('/api/analyses',
			{ 'Content-Type' => 'application/json' },
			encode_json(\%BASE_SPEC)
		)->status_is(503, 'write to read-only dir returns 503');

		$ro_t->get_ok('/api/analyses')
		  ->status_is(200, 'read still works on read-only dir');
	});
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
	like $body, qr{class="back-link".*<a href="/">&larr; Home</a>}s,
		'canvas has a breadcrumb back to the home page';

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

	# The marks stop filtering while a drill is in force, so the help they point
	# at has to say so -- and name the column whose marks do the drilling.  A
	# drill is in force from dl=0: the canvas is read through the hierarchy, and
	# its marks drill rather than filter, so the help speaks of it there too.
	$t->get_ok("/a/$cid")->status_is(200);
	my $b_plain = $t->tx->res->body;
	unlike $b_plain, qr/This canvas is drilled/,
		'a canvas that is not drilled says nothing about drilling';
	like $b0, qr/This canvas is drilled/,
		'and one opened on the hierarchy says so before a level is entered';
	like $b0, qr/id="cf-help"[^<]*\bregion\b/s,
		'and names the column the first level drills on';
	like $b1, qr/id="cf-help"[^>]*>[^<]*This canvas is drilled/s,
		'a drilled canvas says that its marks drill rather than filter';
	like $b1, qr/id="cf-help"[^<]*\bproduct\b/s,
		'and names the column the current level drills on';
	like $b1, qr/id="cf-help"[^<]*marks and words on the other columns wait/s,
		'and says the rest of the marks and words wait until it is cleared';
	like $b1, qr/id="cf-help"[^<]*drill\s+path above the canvas says what the canvas\s+is\s+filtered\s+by/s,
		'and points at the drill path, which is the chip a drilled canvas has';
	unlike $b1, qr/id="cf-help"[^<]*chip above the canvas/s,
		'and does not send a drilled reader to a chip the toolbar does not show';
	unlike $b1, qr/id="cf-help"[^<]*to filter by its value/s,
		'and does not tell a drilled reader that a mark filters, since it drills';

	# A drill is a hierarchy the canvas has.  A bookmark can outlive the one it
	# was saved on: the name is then in the URL and nothing else, and a page that
	# believed it would stop making its marks controls and would have no column
	# for the help to name.
	$t->get_ok("/a/$cid?dd=NoSuchHierarchy&dl=1")->status_is(200);
	my $b_stale = $t->tx->res->body;
	unlike $b_stale, qr/data-drill-name=/, 'a hierarchy the canvas does not have drills nothing';
	unlike $b_stale, qr/This canvas is drilled/,
		'and the help does not claim a drill that is not there';
	like $b_stale, qr/id="cf-help"[^<]*chip above the canvas/s,
		'and still points the reader at the chip, which is what filters it';
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
# The marks of a chart card are the controls #cf-help describes
#
# A mark is in the tab order, labelled with the value it would filter by, and
# described by the canvas help -- which is what the paragraph promises, and
# what it is only worth promising if the code that writes the attributes reads
# the datum.  d3 gives an attr() callback the datum first; an event listener is
# called with the event first, and reading the datum from there left every mark
# with the index instead, so no mark was focusable while a click still worked.
# ---------------------------------------------------------------------------

subtest '3.3: a mark is a labelled control, and the help lists what it is' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	my $spec = {
		name     => 'MarkCanvas',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'bar',      encode => { cat => 'region', value => 'amount' }, title => 'Bars' },
			{ kind => 'pie',      encode => { cat => 'region', value => 'amount' }, title => 'Slices' },
			{ kind => 'treemap',  encode => { cat => 'product', value => 'amount' }, title => 'Tiles' },
			{ kind => 'heatmap',  encode => { x => 'region', y => 'product', value => 'amount' }, title => 'Cells' },
			{ kind => 'stacked',  encode => { cat => 'region', series => 'product', value => 'amount' }, title => 'Stacked' },
		],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;

	# The help, in the words the page can keep: every kind of mark that answers a
	# key is named, and so is what the chip and the source card do.
	like $b, qr/id="cf-help"[^<]*bar,\s+tile,\s+cell,\s+slice or point/s,
		'the help names the mark shapes a chart card draws';
	like $b, qr/id="cf-help"[^<]*word-cloud/s, 'and the words of a word cloud';
	like $b, qr/id="cf-help"[^<]*rows that contain it/s,
		'and says a word filters by containment';
	like $b, qr/id="cf-help"[^<]*stays\s+whole/s,
		'and that the card whose mark was used is left whole';
	like $b, qr/id="cf-help"[^<]*chip above the canvas/s,
		'and points at the chip that clears the filter';

	# The writes that make a mark a control: the datum first, and the shapes the
	# snippets actually draw -- the pie puts its class on the group, and each
	# point kind names its own.
	like $b, qr/\.attr\('tabindex', function \(d\)/,
		'the tab order is worked out from the datum, not from the index';
	like $b, qr/\.attr\('aria-label', function \(d\)/, 'and so is the label';
	like $b, qr/\.attr\('aria-describedby', function \(d\)/,
		'and the reference to the help the label is read with';
	like $b, qr/g\.arc > path/, 'a pie slice is a path inside its arc group';
	like $b, qr/circle\.sc-circle/, 'a scatter point is a circle';
	like $b, qr/circle\.cc-dot/, 'and so is a combo point';
	unlike $b, qr/selectAll\('rect,\s*path/,
		'nothing selects every path, which would make a line series a control';

	# A drilled canvas answers one column, and the help says the others wait:
	# a mark on one of them is drawn but not made a control, because the press
	# it would offer is ignored, and a word is only ever a filter -- it never
	# drills, and a drilled canvas shows no chip to clear it by.
	like $b, qr/if \(drillName && cfCol !== drillCol\) return null/,
		'a mark on another column is not a control while the canvas is drilled';
	like $b, qr/if \(drillName\) \{\s*word\.removeAttribute\('href'\)/,
		'and a word is left as the word it shows';
	like $b, qr/word\.removeAttribute\('aria-describedby'\)/,
		'with nothing to describe, since it does nothing';

	# The value the label carries: a stacked segment's datum is a position in
	# its group, so its category comes out of the data the segment kept.
	like $b, qr/d\.data\.cat !== undefined/, 'a stacked segment filters by its category';
	like $b, qr/\[\s*\d+\s*,\s*\d+\s*\]/, 'and not by the position it sits at';

	# One encoding: the value goes into the query string as it is, because
	# searchParams encodes what it is given.  Encoding it twice filtered by a
	# value no row has (Gadget%2520Pro) and the chip showed the escaping.
	like $b, qr/searchParams\.append\('cf', cfCol \+ ':' \+ op \+ ':' \+ val\)/,
		'a filter value is encoded once';
	unlike $b, qr/'cf', cfCol \+ ':' \+ op \+ ':' \+ encodeURIComponent/,
		'not once before the query string encodes it again';
};

# ---------------------------------------------------------------------------
# Each card's chart script has a scope of its own
#
# HTML::D3 writes a chart as an inline snippet that declares its SVG with
# `const`, and a top-level const belongs to the page's shared lexical
# environment rather than to the <script> that holds it.  Two such snippets on
# one canvas therefore threw "Identifier 'svg' has already been declared" and
# the second card drew an empty box, while either card on a page of its own was
# fine.  Every card's script is closed over a function of its own, so the
# collision is gone whatever names the snippets declare.
# ---------------------------------------------------------------------------

subtest '3.3: every card\'s chart script has a scope of its own' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	# A pie and a line: both are snippets that declare their SVG with const, so
	# this is the canvas that used to lose its second card.
	my $spec = {
		name     => 'Two Scripts',
		datasets => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals  => [
			{ kind => 'pie',  encode => { cat => 'region', value => 'amount' }, title => 'Slices' },
			{ kind => 'line', encode => { x => 'sale_date', y => 'amount' },  title => 'Line' },
		],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;

	my @scripts = $body =~ /<script(?![^>]*\bsrc=)[^>]*>(.*?)<\/script>/sg;
	my @svg     = grep { /\bconst\s+svg\b/ } @scripts;
	is(scalar @svg, 2, 'both cards draw with a snippet that declares its SVG');

	for my $i (0 .. $#svg) {
		like $svg[$i], qr/\A\s*\(function \(\) \{\n/,
			'card ' . ($i + 1) . '\'s script is a function of its own';
		like $svg[$i], qr/\}\)\(\);\s*\z/, 'which closes where it was opened';
		my $open  = index($svg[$i], '(function () {');
		my $const = index($svg[$i], 'const svg');
		ok($open >= 0 && $const > $open,
			"so its const is in that scope, not the page's");
	}

	# The scope is put on once, where every card is rendered.  A card that also
	# arrived wrapped would be wrapped again here, and a function inside a
	# function is a second chance for the bug above rather than a fix for it.
	unlike $body, qr/\(function \(\) \{\s*\n\s*\(function \(\) \{/,
		'no card script on the page is wrapped inside another';

	# The library the snippets draw with is loaded once, from its src: it is
	# not a card's snippet and is left alone.
	like $body, qr{<script[^>]*\bsrc=[^>]*>\s*</script>},
		'the library is still loaded from its src';
	unlike $body, qr{<script[^>]*\bsrc=[^>]*>\s*\(function},
		'and is not closed over a function';

	# The same seam serves a card added or repaired once the page is up, so a
	# card that arrives later cannot collide with the cards already drawn.
	my $added = $t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'pie', encode => { cat => 'region', value => 'amount' }, title => 'More slices' })
	)->status_is(201)->tx->res->json->{html};
	like $added, qr{<script>\s*\(function \(\) \{\n.*?\bconst\s+svg\b}s,
		'a card added after the page is up is given a scope too';

	my $repaired = $t->patch_ok("/api/analyses/$cid/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => {} })
	)->status_is(200)->tx->res->json->{html};
	like $repaired, qr{<script>\s*\(function \(\) \{\n.*?\bconst\s+svg\b}s,
		'as is one whose plan is repaired in place';
};

# ---------------------------------------------------------------------------
# Reading the renderer as a program
#
# Three rules of the renderer cannot be seen on a page: a rule applied twice
# still does the same thing once, a failure path is only reached by the
# condition that produces it, and an exclusion is one comparison among many.
# What they share is the source, so the source is what these guards read --
# through the helpers below, which answer the small questions a rule asks
# (which subs exist, what one is made of, which guard a line sits in), so that
# a new invariant costs a few assertions rather than another scanner.
# ---------------------------------------------------------------------------

# A module's source, split into lines and with its prose removed: POD blocks
# and comments talk about these subs by name with their arguments, and a
# sentence must not be read as a call.
sub _source {
	my ($path) = @_;
	my @lines = -f $path ? split(/\n/, $path->slurp) : ();
	my (@code, $in_pod);
	for my $line (@lines) {
		if    ($line =~ /^=cut\b/) { $in_pod = 0; next }
		elsif ($line =~ /^=\w/)    { $in_pod = 1; next }
		push @code, $line unless $in_pod || $line =~ /^\s*#/;
	}
	return { file => $path, lines => \@lines, code => \@code };
}

my $src = _source($t->app->home->child('lib/Database/BI/Controller/Dashboard.pm'));
my $tpl = _source($t->app->home->child('templates/web/en/canvas.html.tt'));

# The code of one sub, comments removed: a sentence about a rule must not be
# read as the rule.  Undef when the module has no such sub.
sub _sub_code {
	my ($src, $name) = @_;
	my $lines = $src->{lines};
	my ($from) = grep { $lines->[$_] =~ /^sub \Q$name\E\b/ } 0 .. $#$lines;
	return undef unless defined $from;
	my ($to) = grep { $lines->[$_] =~ /^sub / && $_ > $from } 0 .. $#$lines;
	$to = $#$lines + 1 unless defined $to;
	return [ grep { !/^\s*#/ } @$lines[$from .. $to - 1] ];
}

# The sub a line sits in: subs are declared at the left margin, and everything
# inside one is indented.
sub _sub_of {
	my ($code, $at) = @_;
	for (my $j = $at; $j >= 0; $j--) {
		return $1 if $code->[$j] =~ /^sub (\w+)/;
	}
	return '';
}

# The indexes of the lines of $code matching $re.
sub _lines_like {
	my ($code, $re) = @_;
	return [ grep { $code->[$_] =~ $re } 0 .. $#$code ];
}

# The guard a line sits in: the nearest "if (...) {" above it, which is how
# "only when" is written in Perl.
sub _guard_of {
	my ($code, $at) = @_;
	for (my $j = $at; $j >= 0; $j--) {
		return $code->[$j] if $code->[$j] =~ /^\s*if\s*\(/;
	}
	return '';
}

# A rule that has to happen once: its line, and the sub it is in.  Returns the
# line's index, for the callers that also check what the line says.
sub _one_place {
	my ($src, $pattern, $sub, $what) = @_;
	my $code = $src->{code};
	my @at   = @{ _lines_like($code, $pattern) };
	return undef unless is(scalar @at, 1, "$what: one line");
	is(_sub_of($code, $at[0]), $sub, "$what: in $sub");
	return $at[0];
}

# A sub's statements: a ';' ends one only outside a string, and a comment runs
# to the end of its line -- an error message may hold a ';', and a sentence
# about a blank return must not be read as one.
sub _statements {
	my ($body) = @_;
	my (@statements, $cur, $quote, $esc, $comment);
	($cur, $esc) = ('', 0);
	for my $ch (split //, $body) {
		if ($comment) { undef $comment if $ch eq "\n"; next }
		if (defined $quote) {
			$cur .= $ch;
			if    ($esc)          { $esc = 0 }
			elsif ($ch eq '\\')   { $esc = 1 }
			elsif ($ch eq $quote) { undef $quote }
			next;
		}
		if ($ch eq q{'} || $ch eq q{"}) { $quote = $ch; $cur .= $ch; next }
		if ($ch eq '#') { $comment = 1; next }
		$cur .= $ch;
		if ($ch eq ';') { push @statements, $cur; $cur = '' }
	}
	push @statements, $cur if $cur =~ /\S/;
	return \@statements;
}

# ---------------------------------------------------------------------------
# The renderer's card-level rules are each applied in one place
#
# The cards of a page share it: their scripts must not collide, Leaflet is one
# library however many maps a canvas has, and one card's cross-row numbers must
# not be written into the rows its neighbours draw from.  Each of those is a
# line somewhere in the renderer, and each would go on working if a second
# place applied it again -- scoping twice is scoping once, a map head handed
# over twice is the same head -- while the two places drift apart.  Nothing
# rendered can see that, so the source is what is read here: one line, in the
# sub whose job it is.
# ---------------------------------------------------------------------------

subtest '3.3: each card-level rule of the renderer happens in one place' => sub {
	plan skip_all => 'the controller source is not in this checkout'
		unless -f $src->{file};
	my $code = $src->{code};
	ok(scalar @$code, 'the controller has code to read');

	# A card's script is a program of its own, closed over a function by the
	# renderer every card passes through -- not by a caller that renders one.
	my $scope_at = _one_place($src, qr/_scope_card_scripts\(/, '_render_visual_html',
		'card script scoping');
	if (defined $scope_at) {
		like($code->[$scope_at],
			qr/\$rendered->\{html\} = _scope_card_scripts\(\$rendered->\{html\}\);/,
			'which scopes the html the renderer just built');
	}
	_one_place($src, qr/_wrap_card_script\(/, '_scope_card_scripts',
		'the wrapper around one script');

	# A card is only ever built through that renderer: a caller reaching the
	# builder directly would get a card nothing had scoped.
	_one_place($src, qr/_render_visual_markup\(/, '_render_visual_html',
		'building a card');

	# Leaflet's stylesheet and script are the same for every map on a page, so
	# the page is handed the first map card's head and no other.
	_one_place($src, qr/\$canvas_map_head \|\|=/, 'canvas_render',
		'taking the first map head of a canvas');
	_one_place($src, qr/extra_head\s*=>\s*\$canvas_map_head/, 'canvas_render',
		'and handing that one head to the page');

	# A map card owns its map's size, so the page-wide #map rule is stripped
	# from the head it carries -- where the card is assembled, once.
	_one_place($src, qr/\$head =~ s\{<style>/, '_canvas_map_html',
		"dropping the page's map style from a card's head");

	# The pass writes its column onto the rows it is handed, and those rows are
	# the same hashrefs every card draws from: it is given copies, never them.
	_one_place($src, qr/my \$own\s*=.*\{ %\$_ \}/, '_render_visual_markup',
		'copying the rows a card runs its plan over');
	_one_place($src, qr/_apply_cross_row\(\$own\b/, '_render_visual_markup',
		'and running the pass on those copies');
	unlike(join("\n", @$code), qr/_apply_cross_row\(\$vis_recs\b/,
		'never on the rows the other cards draw from');

	# Every chart on a page needs an element id of its own, so the id is made
	# here from the card's index rather than left to the library's default.
	_one_place($src, qr/my \$svg_id = 'vis-'/, '_render_visual_markup',
		"a card's own element id");

	# A card's answer reaches the page: the error it reports is handed to the
	# card that draws it, so a failed card says why where it stands instead of
	# leaving a blank cell that looks like a card with no data.
	_one_place($src, qr/error\s*=>\s*\$result->\{error\}/, 'canvas_render',
		"handing a card's error to the page");
	_one_place($src, qr/return \$rendered unless defined \$rendered->\{html\};/,
		'_render_visual_html', 'letting a failed card pass through unscoped');
};

# ---------------------------------------------------------------------------
# A card that cannot be drawn says why
#
# A card has two answers: the html it drew, or the reason it could not.  A
# branch of the dispatcher that returns neither gives the page a card that
# shows nothing and reports nothing, which reads exactly like a card with no
# data; a branch that dies takes the whole canvas down for one card's sake.
# Both look like ordinary code, and each is only reachable through the
# condition that produces it, so the dispatcher is read as a program here:
# its statements, and what each one answers with.
# ---------------------------------------------------------------------------

subtest '3.3: a card that cannot be drawn answers with an error' => sub {
	plan skip_all => 'the controller source is not in this checkout'
		unless -f $src->{file};
	my $body = _sub_code($src, '_render_visual_markup');
	plan skip_all => 'the card renderer is not in this controller'
		unless defined $body;
	$body = join "\n", @$body;
	ok(length $body, 'the renderer has a body to read');

	my $statements = _statements($body);
	ok(scalar @$statements > 20, 'the renderer is read as the statements it is made of');

	# Each return is one of the two answers.  An error answer also carries a
	# message: an empty one is a blank card with an explanation-shaped hole.
	my (@error, @drawn, @bare, @other);
	for my $st (@$statements) {
		next unless $st =~ /\breturn\b/;
		if    ($st =~ /\breturn\s*;/) { push @bare,  $st }
		elsif ($st =~ /\berror\s*=>/) { push @error, $st }
		elsif ($st =~ /\bhtml\s*=>/)  { push @drawn, $st }
		else                          { push @other, $st }
	}

	is scalar @bare, 0, 'no branch of the dispatcher returns nothing at all'
		or diag explain \@bare;
	ok(scalar @error, 'a card says why it could not be drawn');
	ok(scalar @drawn, 'and hands back the html when it can');
	is scalar @other, 0, 'every other return is one of those two answers'
		or diag explain \@other;

	my @empty = grep { /\berror\s*=>\s*(?:''|""|undef\b|0\b)/ } @error;
	is scalar @empty, 0, 'and each of those answers carries a message'
		or diag explain \@empty;

	# A kind nobody implemented is a card's error like any other, not a card
	# that draws nothing.
	my @returns = grep { /\breturn\b/ } @$statements;
	like($returns[-1], qr/\bUnknown visual kind\b/,
		'as is a kind the renderer has no branch for');

	# A card's failure is its own: the renderer answers rather than dying, which
	# would take the page down for one card's sake.
	unlike($body, qr/^\s*(?:die|exit)\b|\b(?:croak|confess)\b/m,
		'and none of it dies');
};

# ---------------------------------------------------------------------------
# A card is never filtered by its own cross-filter
#
# A click on a card marks it as the filter's source (?cv=), and every other
# card is narrowed by what was clicked (?cf=).  The source is not narrowed: it
# stays whole, which is what makes the click readable -- you see the thing you
# clicked, beside everything it changed.  Two places draw a card -- the page's
# loop, and the endpoint that adds or repairs one -- so both are read here, and
# so is the context both share: the specs are handed out unapplied, because a
# context that applied them could not know which card, if any, is the source.
# ---------------------------------------------------------------------------

subtest '3.3: a card is never filtered by its own cross-filter' => sub {
	plan skip_all => 'the controller source is not in this checkout'
		unless -f $src->{file};

	# -- the page's loop ---------------------------------------------------
	my $canvas = _sub_code($src, 'canvas_render');
	ok($canvas, 'the canvas renderer is there to read');

	my $applied =	_lines_like($canvas, qr/_apply_filter_spec\(\$vis_recs, \$cfs\)/);
	is scalar @$applied, 1, 'a card is narrowed by the cross-filter on one line';
	if (@$applied) {
		like _guard_of($canvas, $applied->[0]),
			qr/\$cf_active\s*&&\s*\$i\s*!=\s*\$cf_source\b/,
			'and only inside a guard that says this card is not the source';
	}

	# The rows the pass is run on are the card's own copy: a cross-filter applied
	# to $records would take the rows away from the source card and from every
	# card after it, which is the same bug from the other end.  The page-wide
	# time range is the one filter that does narrow those rows, because it is the
	# page's range rather than a card's click.
	is scalar @{	_lines_like($canvas, qr/_apply_filter_spec\(\$records, \$cfs/) }, 0,
		'no cross-filter is applied to the rows the whole page draws from';
	my $on_records =	_lines_like($canvas, qr/_apply_filter_spec\(\$records, /);
	is scalar @$on_records, 1,
		'whose one page-wide narrowing is the time range, applied once';
	if (@$on_records) {
		my ($in_loop) = grep { $_ < $on_records->[0] && $canvas->[$_] =~ /^\s*for\b/ }
			reverse 0 .. $on_records->[0];
		like((defined $in_loop ? $canvas->[$in_loop] : ''), qr/range_specs/,
			'and it sits in the loop over the range the page named');
	}
	is scalar @{	_lines_like($canvas, qr/^\s*my \$vis_recs\s*=\s*\$records;/) }, 1,
		'each card starts from those rows';

	# The renderer is told its rows are narrowed by the same question, so it
	# cannot decide for itself that a card wanted filtering.
	my ($call_at) = @{	_lines_like($canvas, qr/_render_visual_html\(/) };
	ok(defined $call_at, 'the card is drawn through the renderer');
	my ($call_end) = defined $call_at
		? grep { $_ > $call_at && $canvas->[$_] =~ /^\s*\);/ } 0 .. $#$canvas
		: ();
	if (defined $call_at && defined $call_end) {
		my @asked = grep {
			$canvas->[$_] =~ /\$cf_active\s*&&\s*\$i\s*!=\s*\$cf_source\s*\?\s*1\s*:\s*0/
		} $call_at .. $call_end;
		is scalar @asked, 1,
			'and is told, by that same question, that its rows are already narrowed';
	}
	else {
		fail('the renderer call has an argument list to read');
	}

	# The page still has to know which card made the filter: that is how the
	# source is drawn as the source rather than as a card that failed to narrow.
	is scalar @{	_lines_like($canvas, qr/cf_source\s*=>\s*\(\$i == \$cf_source \? 1 : 0\)/) },
		1, 'the card that made the filter is marked as its source, once';

	# -- the endpoint that draws one card ----------------------------------
	my $patch = _sub_code($src, 'analyses_update_visual');
	ok($patch, 'the endpoint that draws a single card is there to read');

	my $patch_applied =	_lines_like($patch, qr/_apply_filter_spec\(\$records, \$spec\)/);
	is scalar @$patch_applied, 1, 'it narrows a card in one place too';
	my ($guard_at) = grep {$patch->[$_] =~ /\$ctx->\{cf_source\}\s*!=\s*\$index\b/}
		0 .. $#$patch;
	ok(defined $guard_at, 'and asks whether the card it is drawing is the source');
	if (@$patch_applied && defined $guard_at) {
		is(_guard_of($patch, $patch_applied->[0]), $patch->[$guard_at],
			'narrowing it only on the branch where it is not');

		# The flag handed to the renderer is set on that branch and no other:
		# elsewhere it would tell the renderer to skip the SQL push-over for a
		# card nothing had narrowed.
		my ($indent) = $patch->[$guard_at] =~ /\A(\s*)/;
		my ($block_end) = grep { $_ > $guard_at && $patch->[$_] =~ /\A\Q$indent\E\}/ }
			0 .. $#$patch;
		my ($flag_at) = @{	_lines_like($patch, qr/^\s*\$prefiltered = 1;/) };
		ok(defined $block_end && defined $flag_at
				&& $flag_at > $guard_at && $flag_at < $block_end,
			'and only there is the renderer told the rows are narrowed');
	}
	else {
		fail('the endpoint applies the cross-filter under a guard');
	}

	# -- the context both of them draw through -----------------------------
	# cf_specs is returned unapplied on purpose: the caller is the only thing
	# that knows which card is the source, so a context that narrowed the rows
	# would narrow the source's too, with no way to put them back.
	my $ctx = _sub_code($src, '_canvas_render_context');
	ok($ctx, 'the context a card is drawn through is there to read');
	is scalar @{	_lines_like($ctx, qr/_apply_filter_spec\(/) }, 0,
		'and hands the cross-filters out unapplied, for the caller to place';
};

# ---------------------------------------------------------------------------
# The page is told what each card is
#
# A renderer's answer only reaches a reader if the page is built for it: a
# card's error is drawn in the card, the one card that needs to carry a head
# carries it, a card's own plan fails as that card rather than as the page, and
# a measure is refused before any kind is drawn.  Each of those is a line that
# could be dropped without a healthy canvas noticing, so each is read here.
# ---------------------------------------------------------------------------

subtest '3.3: the page is told what each card is' => sub {
	plan skip_all => 'the controller source is not in this checkout'
		unless -f $src->{file};
	plan skip_all => 'the canvas template is not in this checkout'
		unless -f $tpl->{file};

	# -- a card's error is drawn in the card -------------------------------
	# Once by the page for the cards it already has, and once by the script for
	# a card added while the page is up: both put the message where the reader
	# is looking, and the message is escaped because it may quote a column name
	# the reader typed.
	my $in_card = _lines_like($tpl->{code}, qr/class="visual-error">\[\% v\.error/);
	is scalar @$in_card, 1, "the template draws a card's error inside the card"
		or diag explain $in_card;
	if (@$in_card) {
		like($tpl->{code}[ $in_card->[0] ] // '', qr/\| html %\]/,
			'and escapes it rather than writing it as markup');
	}
	is scalar @{ _lines_like($tpl->{code},
		qr/element\('div', \{ 'class': 'visual-error' \}, json\.error\)/) }, 1,
		'as does a card added after the page is up';

	# -- only a map card carries a head ------------------------------------
	my $markup = _sub_code($src, '_render_visual_markup');
	ok($markup, 'the card renderer is there to read');
	my $heads = _lines_like($markup, qr/\bhead\s*=>/);
	is scalar @$heads, 1, 'one kind of card hands the page a head';
	if (@$heads) {
		# The map branch, and no branch after it: a chart could otherwise put
		# its stylesheet or its library on the page through a key nobody reads
		# for it.
		my ($map_at) = @{ _lines_like($markup, qr/^\s*if \(\$kind eq 'map'\)/) };
		my ($next_kind) = grep { defined $map_at && $_ > $map_at
				&& $markup->[$_] =~ /^\s*if \(\$kind eq / } 0 .. $#$markup;
		ok(defined $map_at && $heads->[0] > $map_at
				&& (!defined $next_kind || $heads->[0] < $next_kind),
			'and that kind is the map');
	}

	# -- a card's own plan fails as that card ------------------------------
	# The page's plan was validated when it was saved; a card's own is validated
	# as the card is drawn, because the columns a canvas has are the columns its
	# data file has today.  That fault is the card's error, not a 400 that takes
	# every other card down with it.
	my $plan_err = _lines_like($markup, qr/return \{ error => \$plan->\{error\} \}/);
	is scalar @$plan_err, 1, "a card's own plan can fail on its own line";
	if (@$plan_err) {
		like(_guard_of($markup, $plan_err->[0]),
			qr/ref \$vis->\{cross_row\} eq 'HASH'/,
			'and only where the plan it checked is the card\'s own');
	}

	# -- a measure is refused before any kind is drawn ---------------------
	# encode.agg names a function, and a misspelt one is this card's error
	# whatever kind it is, rather than a chart drawn some other way.
	my $checked = _lines_like($markup, qr/_measure_fn_ok\(/);
	is scalar @$checked, 1, 'the card\'s measure is checked once';
	my ($first_kind) = @{ _lines_like($markup, qr/^\s*if \(\$kind eq /) };
	ok(@$checked && defined $first_kind && $checked->[0] < $first_kind,
		'before the first kind gets a chance to draw itself another way');
};

subtest '3.2: card sizes survive a cross-filter and a drill-through visit' => sub {
	# The arrangement a canvas was given is the layout in the analysis.  A visit
	# that filters the data - a cross-filter, or a drill path - shows the same
	# cards in the same cells: the layout is applied to whatever the filter
	# leaves, and a card that has nothing to show keeps its size like any other.
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name        => 'Sized canvas',
		datasets    => [ { spec => "path:$sales_path", alias => 'left' } ],
		visuals     => [
			{ kind => 'table', encode => { columns => ['region', 'amount'] }, title => 'Wide' },
			{ kind => 'table', encode => { columns => ['region', 'amount'] }, title => 'Tall' },
		],
		layout      => [
			{ visual => 0, x => 1, y => 1, w => 8, h => 2 },
			{ visual => 1, x => 9, y => 1, w => 4, h => 4 },
		],
		hierarchies => [ { name => 'Geo', levels => [qw(region product)] } ],
	};
	my $res = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201, 'sized canvas created')->tx->res->json;
	my $cid = $res->{id};

	# The style the server writes for a card, read out of the rendered page.
	my $cell_of = sub {
		my ($body, $visual) = @_;
		$body =~ /id="visual-$visual"[^>]*style="([^"]*)"/;
		return $1 // '';
	};

	my $want = {
		0 => 'grid-column:1/span 8;grid-row:1/span 2',
		1 => 'grid-column:9/span 4;grid-row:1/span 4',
	};

	require Mojo::Util;
	my %visit = (
		'no filter'     => "/a/$cid",
		'cross-filter'  => '/a/' . $cid . '?cf=' . Mojo::Util::url_escape('region:eq:North') . '&cv=0',
		'drill-through' => '/a/' . $cid . '?dd=Geo&dl=1&cf=' . Mojo::Util::url_escape('region:eq:North'),
	);

	for my $label (sort keys %visit) {
		$t->get_ok($visit{$label})->status_is(200, "the $label visit renders");
		my $body = $t->tx->res->body;

		for my $visual (sort keys %$want) {
			is $cell_of->($body, $visual), $want->{$visual},
				"the $label visit puts card $visual in the cell it was given";
		}
	}

	# And the visit read the layout rather than rewriting it.
	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is_deeply $t->tx->res->json->{layout}, $spec->{layout},
		'the saved layout is unchanged by the visits';
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
	like $b, qr{href="[^"]*\?f=region}, 'bookmark href contains state';
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

# ---------------------------------------------------------------------------
# Phase 3.2 -- the resize handles are operable without a pointer
# ---------------------------------------------------------------------------

subtest '3.2: resize handles take focus, answer the arrow keys and are announced' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'ResizeKeyboard',
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

	# The handle is a control, not a decoration: in the tab order, with the value
	# semantics of a slider, and no longer hidden from assistive technology.
	like $b, qr/<span class="visual-resize-handle"[^>]*role="slider"/s,
		'the handle is exposed as a slider';
	like $b, qr/<span class="visual-resize-handle"[^>]*tabindex="0"/s,
		'the handle is in the tab order';
	like $b, qr/<span class="visual-resize-handle"[^>]*aria-valuemin="1"/s,
		'the slider declares its minimum';
	like $b, qr/<span class="visual-resize-handle"[^>]*aria-orientation="horizontal"/s,
		'the width is the axis the value tracks';
	unlike $b, qr/<span class="visual-resize-handle"[^>]*aria-hidden/s,
		'the handle is no longer hidden from assistive technology';

	# A name and a description that resolve: a dangling aria-labelledby or
	# aria-describedby is worse than no reference at all.
	my @labelled = $b =~ /class="visual-resize-handle"[^>]*aria-labelledby="([^"]+)"/gs;
	is scalar(@labelled), 2, 'both handles are named by something';
	for my $ref (@labelled) {
		like $b, qr/id="\Q$ref\E"/, "the label $ref exists on the page";
	}
	like $b, qr/class="visual-resize-handle"[^>]*aria-describedby="resize-help"/s,
		'both handles point at the instructions';
	like $b, qr/id="resize-help"[^>]*>[^<]*arrow keys/s,
		'the instructions name the arrow keys';

	# The keys, and the announcement of what they did.
	like $b, qr/function onResizeKey/,           'keyboard resize handler defined';
	like $b, qr/addEventListener\('keydown'/,    'handler wired to the handle';
	like $b, qr/ArrowRight/,                     'right widens the card';
	like $b, qr/ArrowLeft/,                      'left narrows it';
	like $b, qr/ArrowDown/,                      'down makes it taller';
	like $b, qr/ArrowUp/,                        'up makes it shorter';
	like $b, qr/setAttribute\('aria-valuenow'/,  'the width is announced as the value';
	like $b, qr/setAttribute\('aria-valuetext'/, 'both dimensions are announced';
	like $b, qr/updateResizeAria/,               'the announcement is refreshed after a drag too';
	like $b, qr/scheduleSave/,                   'keyboard resizes are persisted';
	like $b, qr/addEventListener\('blur'/,       'leaving the handle writes the pending size';
	like $b, qr/e\.preventDefault\(\)/,        'the arrow keys do not scroll the page';

	# ... and the focus affordance that makes the control findable by eye.
	like $b, qr/\.visual-resize-handle:focus-visible/, 'the focused handle is visible';
	like $b, qr/\.visual-card:focus-within/,           'the focused card is visible';
};

# ---------------------------------------------------------------------------
# Phase 2 -- chart pages: the corner grip is operable without a pointer, the
# same treatment the canvas card handles get
# ---------------------------------------------------------------------------

subtest '2: chart resize handles take focus, answer the arrow keys and are announced' => sub {
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	$t->get_ok('/bar?l=table:sales&cat=region&val=amount')
		->status_is(200, 'bar chart page loads');
	my $b = $t->tx->res->body;

	# The grip is created by the chart-page script, so these are the writes that
	# make it a control rather than a decoration.
	like $b, qr/handle\.setAttribute\('role', 'slider'\)/,
		'the grip is exposed as a slider';
	like $b, qr/handle\.setAttribute\('tabindex', '0'\)/,
		'the grip is in the tab order';
	like $b, qr/'aria-label', 'Resize ' \+ title/,
		'the grip is named for the chart it resizes';
	like $b, qr/'aria-describedby', 'chart-resize-help'/,
		'the grip points at the instructions';
	like $b, qr/'aria-orientation', 'horizontal'/,
		'the width is the axis the value tracks';
	like $b, qr/'aria-valuemin', String\(MIN_W\)/,
		'the slider declares its minimum';

	# A name and a description that resolve: the instructions are on the page,
	# not left to the script to invent, so a reader without JavaScript is told
	# what the grip would do.
	like $b, qr/<p class="sr-only" id="chart-resize-help">/,
		'the instructions are on the page';
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*arrow keys/s,
		'the instructions name the arrow keys';
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*Home and End/s,
		'the instructions name the two ends';
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*Shift/s,
		'the instructions name the faster step';

	# The keys, and the announcement of what they did.
	like $b, qr/function onChartResizeKey/,      'keyboard resize handler defined';
	like $b, qr/'keydown',\s+onChartResizeKey/,  'handler wired to the grip';
	like $b, qr/ArrowRight/,                     'right widens the chart';
	like $b, qr/ArrowLeft/,                      'left narrows it';
	like $b, qr/ArrowDown/,                      'down makes it taller';
	like $b, qr/ArrowUp/,                        'up makes it shorter';
	like $b, qr/e\.key === 'Home'/,              'Home goes to the narrowest width';
	like $b, qr/e\.key === 'End'/,               'End goes to the widest width';
	like $b, qr/function maxWidth\(wrap\)/, 'the widest width is measured for the chart';
	like $b, qr/wrap\.closest\(CONTAINERS\)/, 'inside the container it is drawn in';
	like $b, qr/rect\.left\s*\+ \(parseFloat\(style\.paddingLeft\)/, 'from that container\'s left edge';
	like $b, qr/return Math\.max\(MIN_W, Math\.floor\(right - left\)\);/,
		'so the grip stays on screen at the widest size';
	like $b, qr/e\.preventDefault\(\)/,
		'the arrow keys do not scroll the page';
	like $b, qr/setAttribute\('aria-valuenow'/,  'the width is announced as the value';
	like $b, qr/setAttribute\('aria-valuetext'/, 'both dimensions are announced';
	like $b, qr/function onUp[\s\S]*?updateChartAria\(handle, svg, wrap\)/,
		'the announcement is refreshed after a drag too';

	# ... and the focus affordance that makes the control findable by eye, and
	# says which chart the keys will resize.
	like $b, qr/\.chart-resize-handle:focus-visible/, 'the focused grip is visible';
	like $b, qr/\.chart-resize-handle:focus-visible\s*\{[^}]*opacity\s*:\s*1/s,
		'the focused grip is drawn at full strength, not at its resting 35%';
	like $b, qr/\.chart-svg-wrap:focus-within/,       'the focused chart is visible';
};

subtest '2: a chart page keeps the size it was left at' => sub {
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	$t->get_ok('/bar?l=table:sales&cat=region&val=amount')->status_is(200);
	my $b = $t->tx->res->body;

	# One key per kind of chart, not per URL: the size is how this reader wants
	# to look at a bar chart, so changing the filter does not lose it.
	like $b, qr/SIZE_KEY = 'bi:chart-size:'/, 'the size is kept under a key of its own';
	like $b, qr/function sizeKey\(\) \{ return SIZE_KEY \+ location\.pathname; \}/,
		'one key per chart page, whatever its query string';

	# Written by both routes to the size: a keyboard press, and a drag when the
	# grip is let go rather than on every pointer move.
	like $b, qr/function saveChartSize\(w, h\)/, 'there is one place that saves';
	like $b, qr/saveChartSize\(applied\.w, applied\.h\);/, 'the keyboard resize saves';
	like $b, qr/function onUp\(\)[\s\S]*?saveChartSize\(st\.w, st\.h\);/, 
		'and the drag saves when the grip is let go';
	like $b, qr/window\.localStorage\.setItem\(sizeKey\(\), JSON\.stringify\(\{ w: w, h: h \}\)\)/,
		'as the two numbers the grip announces';

	# Read back at load, before the grip is created, so the grip opens saying the
	# size the chart is drawn at rather than the size it was served at.
	like $b, qr/var saved = savedChartSize\(wrap\);[\s\S]*?if \(saved\) applyChartSize\(svg, wrap, saved\.w, saved\.h\);/,
		'the saved size is applied at load';
	like $b, qr/function savedChartSize\(wrap\)/, 'and read from the store';
	like $b, qr/return \{ w: clampWidth\(size\.w, wrap\), h: clampHeight\(size\.h\) \};/,
		'clamped to what this window allows, measured from the chart';
	like $b, qr/if \(!size \|\| typeof size\.w !== 'number' \|\| typeof size\.h !== 'number'\) return null;/,
		'a stored value that is not two numbers is ignored rather than applied';
	like $b, qr/catch \(e\) \{ \/\* a browser that cannot store it still resizes \*\/ \}/,
		'and storage that fails does not break the grip';

	# The instructions say what happens to the size, since it now outlives the
	# visit.
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*remembered/s, 
		'the help says the size is remembered';
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*same kind/s,
		'and that it is kept per kind of chart';

	# ... and it can be forgotten.  A remembered size that no longer suits the
	# window or the reader is not something to drag back by hand, so the export
	# bar gets a visible button: it is in the tab order and named for what it
	# does, rather than being another key a reader has to be told about.
	like $b, qr/var bar = document\.querySelector\('\.graph-export-bar'\);/,
		'the reset control goes in the export bar every chart page has';
	like $b, qr/button\.className = 'btn-graph-export chart-reset-size';/,
		'as a button styled with the page controls';
	like $b, qr/button\.textContent = 'Reset size';/,
		'whose label says what it does';
	like $b, qr/function resetChartSizes\(\)/, 'the reset is one function';
	like $b, qr/window\.localStorage\.removeItem\(sizeKey\(\)\)/,
		'and removes the key rather than overwriting it with the default';
	like $b, qr/var defaults = \{[\s\S]*?w: svgW \|\| wrap\.getBoundingClientRect\(\)\.width \|\| MIN_W/,
		'it remembers the size the server sent before a saved one is applied';
	like $b, qr/applyChartSize\(chart\.svg, chart\.wrap, chart\.defaults\.w, chart\.defaults\.h, chart\.handle\)/,
		'so every chart on the page goes back to the server default';
	like $b, qr/svg\.parentNode\.insertBefore\(wrap, svg\);/,
		'the wrap goes around the SVG where it sits, so a nested one (the pie) gets the control too';
	like $b, qr/id="chart-resize-status" role="status" aria-live="polite"/,
		'and the reset is announced politely';
	like $b, qr/id="chart-resize-help"[^>]*>[^<]*Reset size button/s,
		'while the help names the control for a reader who does not see it';
};

subtest '3.2: a visual can be put in a chosen cell, not the next free one' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'PositionedCanvas',
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

	# Not the next free cell in either case: the first visual is in row 5 with four
	# empty rows above it, the second in the right-hand half of row 1.
	my $positioned = [
		{ visual => 0, x => 1, y => 5, w => 6, h => 2 },
		{ visual => 1, x => 7, y => 1, w => 6, h => 1 },
	];
	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => $positioned })
	)->status_is(200, 'a layout with gaps is accepted');

	# What was saved is what is there: no packing, no closing of the gap.
	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is_deeply $t->tx->res->json->{layout}, $positioned,
		'the chosen cells are stored as they were given';

	$t->get_ok("/a/$cid")->status_is(200);
	my $b = $t->tx->res->body;
	like $b, qr/id="visual-0"[^>]*style="grid-column:1\/span 6;grid-row:5\/span 2"/,
		'visual 0 renders in the cell it was put in';
	like $b, qr/id="visual-1"[^>]*style="grid-column:7\/span 6;grid-row:1\/span 1"/,
		'visual 1 renders where it was put';

	# Two visuals cannot hold the same cell: overlapping entries share columns and
	# rows here, which would draw one visual on top of the other.
	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => [
			{ visual => 0, x => 1, y => 1, w => 6, h => 2 },
			{ visual => 1, x => 4, y => 2, w => 6, h => 1 },
		] })
	)->status_is(400, 'an overlapping layout is rejected');

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is_deeply $t->tx->res->json->{layout}, $positioned,
		'the rejected overlap was not stored';
};

subtest '3.2: cards are dragged to a cell, and moved with the arrow keys' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'MoveCanvas',
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

	# The header handle is a control that moves the card, named for the visual it
	# moves, and no longer an aria-hidden decoration that says "reorder".
	like $b, qr/<span class="drag-handle"[^>]*role="button"[^>]*tabindex="0"/s,
		'the header handle is a focusable control';
	like $b, qr/aria-label="Move Left"/,  'the handle is named for its visual';
	like $b, qr/aria-label="Move Right"/, 'and so is the other one';
	like $b, qr/class="drag-handle"[^>]*aria-describedby="move-help"/s,
		'the handle is described by the instructions';
	like $b, qr/id="move-help"[^>]*>[^<]*arrow keys/s, 'the instructions name the arrow keys';
	like $b, qr/id="canvas-live"[^>]*role="status"/,  'there is a polite announcer for a move';

	# Dropping a cell and dropping on a card are the same gesture now, so the
	# native drag machinery is gone: the card is not a drag source and nothing
	# listens for a native drop.
	unlike $b, qr/<div class="visual-card[^"]*"[^>]*draggable/s,
		'the card is no longer a native drag source';
	# The template itself has no native drag machinery left.  The page as a whole
	# still has both, for the file-drop upload overlay in the shared layout, so
	# this is checked against the canvas template rather than the rendered page.
	my $src = $t->app->home->child('templates/web/en/canvas.html.tt')->to_string;
	open my $fh, '<', $src or die "Cannot read $src: $!";
	my $tt = do { local $/; <$fh> };
	close $fh;
	unlike $tt, qr/dataTransfer/, 'no native drag payload is read';
	unlike $tt, qr/\bdraggable\b/, 'nothing in the canvas is a native drag source';

	# The drag: pointer events, a ghost showing the landing cell, and the cards it
	# lands on pushed out of the way.
	like $b, qr/function onMoveStart/,      'the move handler is defined';
	like $b, qr/addEventListener\('pointermove'/, 'the drag tracks the pointer';
	like $b, qr/function placeGhost/,       'the landing cell is drawn while dragging';
	like $b, qr/function pushApart/,        'cards in the way are pushed down';
	like $b, qr/function commitMove/,       'the drop places the card and saves';
	like $b, qr/function overlaps/,         'overlap is what decides who moves';
	like $b, qr/\.visual-drop-ghost\s*\{[^}]*dashed/s, 'the ghost is outlined';
	like $b, qr/\.visual-card\.moving/,    'the card being dragged is marked';

	# The keyboard equivalent, and the announcement of where the card went.
	like $b, qr/function onMoveKey/,        'the keyboard move handler is defined';
	like $b, qr/e\.shiftKey/,              'Shift jumps to the edge of the canvas';
	like $b, qr/function gridBottom/,       'the bottom of the canvas is computed';
	like $b, qr/function announce/,         'each move is announced';
	like $b, qr/\.drag-handle:focus-visible/, 'the focused handle is visible';

	# The announcement covers the arrangement the move leaves behind, not just
	# the card that was moved: a reader who is told only about their own card
	# loses track of the one that was pushed out of its cell, and the next key
	# press starts from a canvas they do not have.
	like $b, qr/return moved;/, 'pushApart reports the cards it had to move down';
	like $b, qr/function displacedText/, 'the announcement has one place to name them';
	like $b, qr/titleOf\(m\.card\) \+ ' moved down to row ' \+ m\.to/,
		'each named with the row it was pushed to';
	my $displaced = () = $b =~ /displacedText\(moved\)/g;
	is $displaced, 3,
		'and both a move and a size change say what they pushed aside (one definition, two calls)';
};

# ---------------------------------------------------------------------------
# Phase 3.2 -- the size menu: a preset width per card, chosen without a drag
# ---------------------------------------------------------------------------

subtest '3.2: each card has a size menu that sets its width without a drag' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'SizeMenu',
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

	# One menu per card, in the card's own header, named for the card it sizes.
	my $menus = () = $b =~ /class="visual-size-select"/g;
	is $menus, 2, 'one size menu per visual';
	like $b, qr/<select class="visual-size-select" id="visual-size-0"/,
		'the menu belongs to its own card';
	like $b, qr/visual-card-header">[\s\S]*?visual-size-select[\s\S]*?visual-card-body">/,
		'and sits in the card header';

	# The size is on the card as well as in the menu (3.2): one badge per card,
	# in the header it sizes, beside the menu it mirrors.  Neither of these cards
	# has a saved span, so the browser places them and there is no size to print
	# yet: the badge is rendered empty, and :empty is what keeps that from being
	# a small blank pill of padding rather than nothing.  The script fills it in.
	my $badges = () = $b =~ /class="visual-size-badge"/g;
	is $badges, 2, 'one size badge per visual, on the same cards as the menus';
	like $b, qr{<span class="visual-size-badge" data-size-badge="1"></span>},
		'a card with no saved span is rendered with an empty badge';
	like $b, qr{visual-size-select[\s\S]*?visual-size-badge[\s\S]*?visual-card-body">},
		'which sits in the header beside the menu it mirrors';
	like $b, qr/\.visual-size-badge:empty \{ display: none; \}/,
		'and takes no room while it is empty';
	like $b, qr/\.visual-size-badge \{[^}]*flex-shrink:\s*0/s,
		'it does not shrink, where the menu it sits beside does';
	like $b, qr/id="visual-size-0"[^>]*aria-label="Size of Left"/s,
		'it is named for the visual it sizes';
	like $b, qr/id="visual-size-0"[^>]*aria-describedby="size-help"/s,
		'with the way to use it described for anyone who needs telling';
	like $b, qr/<p class="sr-only" id="size-help">Size a visual without dragging/,
		'the help is on the page, and takes no room on it';

	# The presets, as widths in grid columns: full, half, a third and a quarter.
	like $b, qr/<option value="12">Full width<\/option>/,   'full width is a preset';
	like $b, qr/<option value="6">Half width<\/option>/,    'half width is a preset';
	like $b, qr/<option value="4">Third width<\/option>/,   'third width is a preset';
	like $b, qr/<option value="3">Quarter width<\/option>/, 'quarter width is a preset';
	like $b, qr/GRID_COLS\s*=\s*12/, 'and full width is the whole twelve-column grid';
	like $b, qr/<optgroup label="Width">/, 'the widths are grouped under their name';

	# Height presets in the same menu, so the second dimension needs no drag
	# either.  The values are prefixed, because a select carries one value and
	# "2" would be read as a width.
	like $b, qr/<optgroup label="Height">/, 'the heights are grouped too';
	like $b, qr/<option value="h1">1 row high<\/option>/, 'one row is a preset';
	like $b, qr/<option value="h2">2 rows high<\/option>/, 'two rows is a preset';
	like $b, qr/<option value="h3">3 rows high<\/option>/, 'three rows is a preset';
	like $b, qr/<option value="h6">6 rows high<\/option>/,  'and six, the tallest a card can be';
	like $b, qr/MAX_ROW_SPAN\s*=\s*6/, 'which is the row span limit';

	# One option is not a choice but the size the card is, written by the script
	# from the measured span so a drag cannot leave the menu lying.
	like $b, qr/<option value="" data-current="1">Size<\/option>/,
		'the first option is the size the card actually is';
	like $b, qr/function sizeSummary/,
		'which is written from both dimensions';
	like $b, qr/function presetLabel/, 'in the preset words, where the card is on one';
	like $b, qr/current\.textContent = sizeSummary\(sel, st\.w, st\.h\);/,
		'width and height together';

	# The menu and the corner grip are two ways to the same write.
	like $b, qr/function commitSize\(card, w, h\)/,
		'a chosen width and height are applied by commitSize';
	like $b, qr/h = clampSpan\(h, 1, MAX_ROW_SPAN\);/, 'the height within the row limit';
	like $b, qr/var isRow   = raw\.charAt\(0\) === 'h';/,
		'a prefixed value is a height, a bare one a width';
	like $b, qr/if \(isRow\) commitSize\(card, st\.w, value\);/, 'a height keeps the width';
	like $b, qr/else       commitSize\(card, value, st\.h\);/, 'a width keeps the height';
	like $b, qr/function initSizeMenus/,
		'each menu is wired up';
	like $b, qr/^\s*initSizeMenus\(\);\r?$/m, 'at load';
	like $b, qr/function updateSizeSelect/,
		'the menu shows the size the card actually is';
	like $b, qr/function updateSizeBadge\(card, state\)/,
		'and the card shows it too, rather than only the menu';
	like $b, qr/option\[data-current="1"\]/,
		'and the option that says what the card is is found by its own marker';
	like $b, qr/id="size-help"[^>]*>[^<]*height to one, two, three or six rows/s,
		'the help says the menu sets the height as well';
	like $b, qr/badge\.textContent = st\.w \+ ' \\u00D7 ' \+ st\.h;/,
		'as the two numbers the menu spells out in words';
	like $b, qr/\? sizeSummary\(sel, st\.w, st\.h\)/,
		'with the menu words for the presets as the title';
	like $b, qr/function updateSizeControls\(card, state\) \{/,
		'both readings of the size are written through one function';
	like $b, qr/^\t\tupdateSizeSelect\(card, state\);\r?$/m,
		'which writes the menu';
	like $b, qr/^\t\tupdateSizeBadge\(card, state\);\r?$/m,
		'and the card, so the two cannot disagree';
	like $b, qr/updateSizeControls\(card, st\)/,
		'so a drag, which leaves any width, is reflected in the menu and on the card';
	like $b, qr/updateSizeBadge\(card, \{ w: w, h: h \}\);/,
		'and the size on the card follows the grip while it is being dragged';
	like $b, qr/if \(w !== shownW \|\| h !== shownH\) \{/,
		'written only when the drag crosses a column or a row';
	like $b, qr/if \(isNaN\(value\) \|\| value === \(isRow \? st\.h : st\.w\)\) return;/,
		'choosing the size it already is does nothing at all';
	like $b, qr/var index = sel\.selectedIndex;/, 'the entry that was chosen is remembered';
	like $b, qr/sel\.selectedIndex = index;/,
		'and stays selected, so the arrow keys walk the list rather than being pulled back';
	like $b, qr/announce\(titleOf\(card\) \+ ' is now ' \+/, 'the new size is announced';
	like $b, qr/lowerFirst\(sel \? sizeSummary\(sel, w, h\)/,
		'both dimensions of it, in the menu words, not just drawn';
	like $b, qr/closest\('\.visual-resize-handle, button, a, select'\)/,
		'a press on the menu does not start a card drag';
	like $b, qr/\@media print.*?\.visual-size-select[^{]*\{[^}]*display\s*:\s*none/s,
		'the menu is not printed';
	like $b, qr/\@media print.*?\.visual-size-badge[^{]*\{[^}]*display\s*:\s*none/s,
		'and neither is the size on the card: the printed canvas is two columns';
	like $b, qr/\.visual-size-select \{[^}]*max-width:\s*11\.5rem/s,
		'and is wide enough to read the longest size it can report';
	like $b, qr/Size menu\s+in\s+its header to set its width and height without a drag/,
		'and the first-visit tip names it too';
	like $b, qr/same size is written on the card itself, beside the\s+menu/,
		'and the size help says where the size is written';

	# A card that has to move to be the width that was chosen is moved, and what
	# it grew over is pushed down - the same fix the resize paths now make.
	my $pushes = () = $b =~ /pushApart\(card\);/g;
	is $pushes, 4,
		'growing over a neighbour is resolved in the menu, both resize paths and a drop';

	# That push is not decoration: without it the grown layout is two cards
	# sharing cells 7-12, which the server refuses, so the width would be lost at
	# the next reload.  With it, the layout the menu produces is accepted.
	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => [
			{ visual => 0, x => 1, y => 1, w => 12, h => 1 },
			{ visual => 1, x => 1, y => 2, w => 12, h => 1 },
		] })
	)->status_is(200, 'a full-width card, and the neighbour pushed below it, is accepted');

	my $accepted = [
		{ visual => 0, x => 1, y => 1, w => 12, h => 1 },
		{ visual => 1, x => 1, y => 2, w => 12, h => 1 },
	];

	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => [
			{ visual => 0, x => 1, y => 1, w => 12, h => 1 },
			{ visual => 1, x => 7, y => 1, w => 6,  h => 1 },
		] })
	)->status_is(400,
		'the same growth without the push is refused, which is why commitSize pushes');

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is_deeply $t->tx->res->json->{layout}, $accepted,
		'and the refused layout left the saved one alone';

	# The size on the card, rendered: the numbers are the card's own saved spans,
	# written by the template, so a reload shows them with no JavaScript involved
	# - a card a drag left at a width no preset names says which width that was.
	$t->get_ok("/a/$cid")->status_is(200);
	$b = $t->tx->res->body;
	like $b, qr{<span class="visual-size-badge" data-size-badge="1" title="12 columns wide, 1 row high">12 &times; 1</span>},
		'the saved 12 by 1 card is rendered with its own two numbers';

	$t->patch_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({ layout => [
			{ visual => 0, x => 1, y => 1, w => 12, h => 1 },
			{ visual => 1, x => 1, y => 2, w => 4,  h => 2 },
		] })
	)->status_is(200, 'a card two rows high and a third of the width is accepted');

	$t->get_ok("/a/$cid")->status_is(200);
	$b = $t->tx->res->body;
	like $b, qr{<span class="visual-size-badge" data-size-badge="1" title="12 columns wide, 1 row high">12 &times; 1</span>},
		'the card that did not change still reports its own size';
	like $b, qr{<span class="visual-size-badge" data-size-badge="1" title="4 columns wide, 2 rows high">4 &times; 2</span>},
		'and the other reports the size it was given, in both dimensions';
};

subtest '3.2: the first-visit tip names both grips and is dismissed for good' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $spec = {
		name     => 'TipCanvas',
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

	# The tip is in the page but hidden, and it is the script that uncovers it
	# for a reader who has not dismissed it: someone who has turned it off does
	# not get a flash of it while the page loads.
	like $b, qr{<div class="canvas-hint" id="canvas-hint" hidden>},
		'the tip is rendered hidden';
	like $b, qr{<button type="button" class="canvas-hint-close" id="canvas-hint-close"},
		'and it has a dismiss button';
	like $b, qr{id="canvas-hint-close"[^>]*>[^<]*Got it}s, 'which says what it does';
	like $b, qr{id="canvas-hint-close"[^>]*aria-describedby="canvas-hint-text"}s,
		'and is described by the tip, so what is being dismissed is not guesswork';

	# What it points at: the header drag and the corner grip, in the words the
	# reader can see on the card, and the keyboard route to both of them.
	like $b, qr/drag a visual by its header to move it/, 'the tip names the header drag';
	like $b, qr/grip in the card's bottom right corner to resize it/,
		'the tip names the corner grip';
	like $b, qr/Both\s+work\s+from\s+the\s+keyboard\s+as\s+well/,
		'and says both answer the keyboard';
	# The grip is the control, not the header it sits in: the header takes no
	# focus, and a tip that sends a keyboard reader to it sends them nowhere.
	like $b, qr/focus the\s+<span[^>]*>::<\/span>\s+grip in the header to move the visual/s,
		'including what to focus to use them without a pointer';
	unlike $b, qr/focus the header to move/, 'and not the header, which takes no focus';

	# Once dismissed, never again: one flag, written where the page can read it
	# on the next visit, and read before the tip is uncovered.
	like $b, qr/HINT_KEY = 'bi:canvas:hint'/,
		'the tip keeps its answer under a key of its own';
	like $b, qr/localStorage\.getItem\(HINT_KEY\) === '1'/,
		'which is read before the tip is shown';
	like $b, qr/localStorage\.setItem\(HINT_KEY, '1'\)/,
		'and written when it is dismissed';
	like $b, qr/if \(!card \|\| hintSeen\(\)\) return;/,
		'a canvas with nothing to point at says nothing';

	# Dismissing hides the tip, unmarks the card it named, leaves focus on the
	# control it named rather than on a button that has gone, and says so where a
	# screen reader will hear it.
	like $b, qr/card\.classList\.add\('pointing'\)/, 'the card the tip names is marked while it is up';
	like $b, qr/card\.classList\.remove\('pointing'\)/, 'and unmarked when it goes';
	like $b, qr/hint\.hidden = true/, 'dismissing hides the tip';
	like $b, qr/announce\('Canvas tip dismissed'\)/, 'and announces that it has gone';
	like $b, qr/e\.key === 'Escape'/, 'Escape dismisses it as well';
	like $b, qr{drag-handle\[role="button"\]'\)[\s\S]*?\.focus\(\)},
		'and focus lands on the header handle the tip named';

	# The two things it points at are drawn on that card while it is up, so the
	# sentence and the screen are talking about the same thing; the tip itself
	# never reaches paper, and takes no room while it is hidden.
	like $b, qr/\.visual-card\.pointing \.visual-card-header/, 'the marked header is ringed';
	like $b, qr/\.visual-card\.pointing \.visual-resize-handle/, 'and the marked grip is tinted';
	like $b, qr/\.canvas-hint\[hidden\] \{ display: none; \}/, 'the hidden tip takes no room';

	my ($print_css) = $b =~ m{\@media print \{(.*?)\n\}}s;
	ok $print_css, 'the page has a print stylesheet' or return;
	like $print_css, qr/\.canvas-hint/, 'the tip is not printed';
};

# ---------------------------------------------------------------------------
# The remaining custom controls: a pivot header, a home-page card and a treemap
# tile were all reachable with a pointer only.  Each is given the same
# treatment: a name, a description that resolves, a way in from the tab order,
# and a live region for what a key press changed.
# ---------------------------------------------------------------------------

subtest 'pivot: a column header sorts and moves from the keyboard' => sub {
	require Mojo::Util;

	my $url = '/pivot?l=' . Mojo::Util::url_escape('table:sales')
		. '&rows=region&m=' . Mojo::Util::url_escape(':count:rows');
	$t->get_ok($url)->status_is(200, 'the pivot page renders');
	my $b = $t->tx->res->body;

	# The instructions are on the page, not left to the title attribute: a
	# header with a keyboard route nobody can discover is not much of one.
	like $b, qr/<p class="sr-only" id="pivot-head-help">/,
		'the instructions are on the page';
	like $b, qr/id="pivot-head-help"[^>]*>[^<]*Enter or\s+Space/s,
		'and name the keys that sort';
	like $b, qr/id="pivot-head-help"[^>]*>[^<]*Shift\+Left or Shift\+Right/s,
		'and the pair that moves the column';
	like $b, qr/<p class="sr-only" id="pivot-live" role="status" aria-live="polite">/,
		'and there is a polite announcer for a sort or a move';

	# The header is made a control by the script that gives it the behaviour:
	# without it the table cannot be sorted at all, so a focusable header
	# declared in the markup would be a control that does nothing.
	like $b, qr/th\.setAttribute\('tabindex', '0'\)/,
		'the header is put in the tab order';
	like $b, qr/th\.setAttribute\('aria-describedby', 'pivot-head-help'\)/,
		'and points at the instructions';
	like $b, qr/th\.setAttribute\('aria-sort', 'none'\)/, 'it declares that it is unsorted';
	like $b, qr/Click to sort \| Enter to sort/,
		'and its title says what the keys do, not only what a pointer does';
	like $b, qr/\(\!HASTWO \? ' \| Drag to reorder \| Shift\+Left\/Right to move column' : ''\)/,
		'with the move offered only where a drag is offered';

	# The keys, and what each of them does.
	like $b, qr/th\.addEventListener\('keydown'/,
		'the header has a keyboard handler';
	like $b, qr/e\.key === 'Enter' \|\| e\.key === ' '/,
		'Enter and Space sort, because that is what a click does';
	like $b, qr/if \(HASTWO \|\| !e\.shiftKey\) return;/,
		'Shift+Left/Right moves a column, where a drag is offered';
	like $b, qr/e\.key === 'ArrowLeft'/,  'left moves the column one place left';
	like $b, qr/e\.key === 'ArrowRight'/, 'and right one place right';
	like $b, qr/if \(from < 0 \|\| to < 0 \|\| to >= leafHeaders\.length\) return;/,
		'a column at the edge is not moved off it';
	like $b, qr/e\.preventDefault\(\)/, 'the keys do not scroll the page instead';

	# What happened is said, since neither gesture moves the focus.
	like $b, qr/function announce\(text\)/, 'there is one place that announces';
	like $b, qr/announce\('Sorted by ' \+ headerName\(leafIdx\)/,
		'a sort names the column and the direction';
	like $b, qr/announce\('Moved ' \+ headerName\(to\) \+ ' to column '/,
		'a move names where the column went';
	like $b, qr/th\.focus\(\);/, 'and focus stays on the column that was moved';

	# ... and the focus affordance, on the dark header the ring has to show on.
	like $b, qr/\.pivot-table thead th:focus-visible/, 'the focused header is visible';
	like $b, qr/\.pivot-table thead th:focus-visible \{[^}]*outline\s*:/s,
		'with a ring drawn, not only a colour change';
};

subtest 'home: a card shows on focus what a pointer is shown on hover' => sub {
	$t->get_ok('/')->status_is(200, 'the home page renders');
	my $b = $t->tx->res->body;

	# The details of a file - its type, size and date - were hover-only.  They
	# are now the card's description as well, so tabbing to the card says them;
	# a fetched size arrives after focus, hence the polite live region.
	like $b, qr/tip\.setAttribute\('role', 'tooltip'\)/, 'the tip is a tooltip';
	like $b, qr/tip\.setAttribute\('aria-live', 'polite'\)/,
		'and announces a size it fetched after it was shown';

	my $described = () = $b =~ /card\.setAttribute\('aria-describedby', tip\.id\)/g;
	is $described, 3,
		'all three card lists describe a card by its tip (files, recent entries, canvases)';

	my $focused = () = $b =~ /card\.addEventListener\('focus',\s+showTip\)/g;
	is $focused, 3, 'and all three show it when the card takes focus';
	my $blurred = () = $b =~ /card\.addEventListener\('blur',\s+hideTip\)/g;
	is $blurred, 3, 'and hide it when focus leaves, as a mouse does';
	like $b, qr/function showTip\(\)/, 'hover and focus share one show';
	like $b, qr/function hideTip\(\)/, 'and one hide, so they cannot disagree';

	# The remove button that sits on a card is in the tab order as soon as it
	# exists, and was revealed by hovering the list item only: a keyboard reader
	# could focus a button that was invisible.  Focus now reveals it too.
	like $b, qr/\.db-list li:focus-within \.recent-remove/, 'focus reveals the remove button';
	like $b, qr/\.recent-remove:focus-visible \{[^}]*opacity\s*:\s*1/s,
		'and the focused button is drawn at full strength';
	like $b, qr/\.recent-remove:focus-visible \{[^}]*outline\s*:/s,
		'with a ring, so it is not only a colour change';
};

subtest 'treemap: a tile says its value, and shows it on focus' => sub {
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	$t->get_ok('/treemap?l=table:sales&cat=product&val=amount')
		->status_is(200, 'the treemap page renders');
	my $b = $t->tx->res->body;

	# The area a tile is drawn at encodes its value, and area is not read out:
	# the value goes in the name the tile is announced by.
	like $b, qr/var value = \(d\.value == null\) \? '' : d\.value;/,
		'the tile reads its value, empty where there is none';
	like $b, qr/g\.setAttribute\('aria-label', 'Filter table to ' \+ label \+ ' \(' \+ value \+ '\)'\)/,
		'and announces the name and the value together';
	like $b, qr/g\.setAttribute\('title', 'Filter table to: ' \+ label \+ ' \(' \+ value \+ '\)'\)/,
		'as the pointer tip does too';

	# The tooltip D3 shows on hover is shown on focus, from the tile's own
	# position, since a focused tile has no pointer to take one from.
	like $b, qr/function showTileTip\(g, label, value\)/, 'the tip can be shown without a pointer';
	like $b, qr/g\.addEventListener\('focus', function \(\) \{ showTileTip\(g, label, value\); \}\)/,
		'focus shows it';
	like $b, qr/g\.addEventListener\('blur',\s+hideTileTip\)/, 'and blur hides it';
	like $b, qr/var r = g\.getBoundingClientRect\(\);/,
		'positioned from the tile rather than from a pointer';
	like $b, qr/tip\.appendChild\(name\);/, 'with the name in bold, as D3 writes it';
	like $b, qr/function hideTileTip\(\)/, 'and one place that hides it';
};

subtest 'chart legends: a series is hidden from the keyboard too' => sub {
	plan skip_all => 'HTML::D3 not available' unless eval { require HTML::D3; 1 };

	# A stacked legend entry toggles its series on click.  The entry is now a
	# switch as well: focusable, named, and saying whether the series is drawn.
	$t->get_ok('/stacked?l=table:sales&cat=region&seg=product&val=amount')
		->status_is(200, 'the stacked page renders');
	my $b = $t->tx->res->body;

	like $b, qr/<p class="sr-only" id="stacked-legend-help">/,
		'the instructions are on the page';
	like $b, qr/id="stacked-legend-help"[^>]*>[^<]*Enter or\s+Space/s,
		'and name the keys that toggle';
	like $b, qr/document\.querySelectorAll\('#stacked_bar \.sb-legend-item'\)/,
		'each legend entry is found by the class D3 gives it';
	like $b, qr/item\.setAttribute\('tabindex', '0'\)/, 'and put in the tab order';
	like $b, qr/item\.setAttribute\('role', 'button'\)/, 'as a button';
	like $b, qr/item\.setAttribute\('aria-label', 'Toggle ' \+ name\)/,
		'named for the series it toggles';
	like $b, qr/item\.setAttribute\('aria-pressed', 'true'\)/,
		'with the state of that series';
	like $b, qr/item\.addEventListener\('click', function \(\) \{/,
		'which follows a pointer click as well';
	like $b, qr/var pressed = item\.getAttribute\('aria-pressed'\) !== 'true';/,
		'and is reversed with the series';
	like $b, qr/item\.setAttribute\('aria-pressed', pressed \? 'true' : 'false'\);/,
		'which is written back on the entry';
	like $b, qr/<p class="sr-only" id="stacked-live" role="status" aria-live="polite">/,
		'and there is a polite announcer for the series appearing or going';
	like $b, qr/live\.textContent = name \+ \(pressed \? ' shown' : ' hidden'\);/,
		'which says which series was shown or hidden';
	like $b, qr/item\.addEventListener\('keydown'/, 'the entry has a keyboard handler';
	like $b, qr/e\.key === 'Enter' \|\| e\.key === ' '/,
		'Enter and Space toggle it';
	like $b, qr/item\.dispatchEvent\(new MouseEvent\('click'/,
		'by sending the click D3 listens for';
	like $b, qr/#stacked_bar \.sb-legend-item:focus-visible rect/,
		'and the focused entry is drawn, on the swatch it toggles';

	# The multi-series line chart has a legend of its own; a single-series
	# chart has none, and must not be given instructions for one.
	$t->get_ok('/graph?l=table:sales&x=sale_date&y=amount&series=region')
		->status_is(200, 'the multi-series page renders');
	$b = $t->tx->res->body;
	like $b, qr/<p class="sr-only" id="line-legend-help">/,
		'its instructions are on the page';
	like $b, qr/document\.querySelectorAll\('#chart \.msl-leg-item'\)/,
		'each legend entry is found';
	like $b, qr/item\.setAttribute\('aria-label', 'Toggle ' \+ name\)/,
		'and named for its series';
	like $b, qr/item\.addEventListener\('keydown'/, 'and answers the keyboard';
	like $b, qr/<p class="sr-only" id="line-live" role="status" aria-live="polite">/,
		'with an announcer of its own';
	like $b, qr/live\.textContent = name \+ \(pressed \? ' shown' : ' hidden'\);/,
		'which says which line was shown or hidden';
	like $b, qr/item\.dispatchEvent\(new MouseEvent\('click'/,
		'by sending the click the legend listens for';
	like $b, qr/#chart \.msl-leg-item:focus-visible rect/, 'and the focused entry is drawn';

	$t->get_ok('/graph?l=table:sales&x=sale_date&y=amount')
		->status_is(200, 'a single-series chart renders');
	unlike $t->tx->res->body, qr/id="line-legend-help"/,
		'and is given no instructions for a legend it does not have';
};

# ---------------------------------------------------------------------------
# Phase 3.2 -- a canvas card picks its own aggregate function
# ---------------------------------------------------------------------------

subtest 'a saved card aggregates with the function it picked' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	# North holds 1250 and 1875, so one column gives four distinguishable
	# answers: sum 3125, median 1562.5, range 625, count 2.  A card that picked a
	# function can therefore not be mistaken for one that summed.
	my $spec = {
		name     => 'Measure picking',
		datasets => [ { spec => "path:$sales_path" } ],
		visuals  => [
			{ kind => 'bar', encode => { cat => 'region', value => 'amount', agg => 'median' } },
			{ kind => 'bar', encode => { cat => 'region', value => 'amount' } },
		],
	};
	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($spec)
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $body = $t->tx->res->body;

	# The snippet writes each row as JSON from a hash, so its key order is not
	# the test's to assume: the pair is asserted on the value alone, and the
	# counts below say which card it belongs to.
	like $body, qr/"value":1562\.5/,
		'the card that picked a median draws the median';
	like $body, qr/median\(amount\) by region/,
		'and its own title says which function it used';

	# Each card answers for North once, and differently: the median of 1250 and
	# 1875 is 1562.5, the sum 3125.  One occurrence each is what says the card
	# that picked a function did not fall back to the default.
	my $medians = () = $body =~ /"value":1562\.5/g;
	my $sums    = () = $body =~ /"value":3125/g;
	is $medians, 1, 'only the card that picked the median drew one';
	is $sums,    1, 'and only the card that summed drew the sum';

	like $body, qr/amount by region/,
		'the card that picked nothing keeps the title it has always had';

	# first and last are the row order, which is not a sum of anything.
	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'bar',
			encode => { cat => 'region', value => 'amount', agg => 'range' } })
	)->status_is(201)
	 ->json_is('/title' => 'range(amount) by region');
	like $t->tx->res->json->{html}, qr/"value":625/,
		'a range card draws the spread it asked for';

	# One card, one function: a combo aggregates both its series with it.
	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'combo',
			encode => { cat => 'region', bar_val => 'amount', line_val => 'amount',
			            agg => 'median' } })
	)->status_is(201)
	 ->json_is('/title' => 'median of amount and amount by region');

	# A saved card can change its function without losing its place: p50 is the
	# median under the name a pivot uses for it.
	$t->patch_ok("/api/analyses/$cid/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ encode => { cat => 'region', value => 'amount', agg => 'p50' } })
	)->status_is(200)
	 ->json_is('/title' => 'p50(amount) by region');
	like $t->tx->res->json->{html}, qr/"value":1562\.5/,
		'and p50 is the median it is meant to be';
};

subtest 'a card function that cannot be drawn is refused, not stored' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Refused measures',
			datasets => [ { spec => "path:$sales_path" } ],
			visuals  => [ { kind => 'table', encode => {}, title => 'All rows' } ],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'bar',
			encode => { cat => 'region', value => 'amount', agg => 'banana' } })
	)->status_is(400)
	 ->json_like('/error' => qr/Unknown aggregate function 'banana'/,
		'a function the fold cannot compute is refused rather than summed');
	like $t->tx->res->json->{error}, qr/median/,
		'and the message carries the vocabulary, so the reader can pick one';

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'bar',
			encode => { cat => 'region', value => '__count__', agg => 'median' } })
	)->status_is(400)
	 ->json_like('/error' => qr/needs a value column/,
		'a function that needs a column is refused when the card counts rows');

	$t->post_ok("/api/analyses/$cid/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'bar',
			encode => { cat => 'region', value => 'amt', agg => 'median' } })
	)->status_is(400)
	 ->json_like('/error' => qr/Column not found: amt/,
		'and a column that is not there is still the column\'s error');

	$t->get_ok("/api/analyses/$cid")->status_is(200);
	is scalar @{ $t->tx->res->json->{visuals} }, 1,
		'none of the refused cards was appended';

	# A card stored by a whole-document PUT is not rendered on the way in, so a
	# function it names is reported by the card itself rather than a 500.
	$t->put_ok("/api/analyses/$cid",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Refused measures',
			datasets => [ { spec => "path:$sales_path" } ],
			visuals  => [ { kind => 'bar',
				encode => { cat => 'region', value => 'amount', agg => 'nonsense' } } ],
		})
	)->status_is(200);

	$t->get_ok("/a/$cid")->status_is(200);
	my $page = $t->tx->res->body;
	# The card's error is written into the page, so the quotes in it arrive
	# HTML-escaped; the message and the name it refused are what matter.
	like $page, qr/Unknown aggregate function/, 
		'the canvas says so in the card rather than failing the page';
	like $page, qr/nonsense/, 'and names the function it could not compute';
};

subtest 'the Add current view panel offers the functions a card may pick' => sub {
	my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
	plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

	my $cid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Panel vocabulary',
			datasets => [ { spec => "path:$sales_path" } ],
			visuals  => [ { kind => 'table', encode => {}, title => 'All rows' } ],
		})
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$cid")->status_is(200);
	my $page = $t->tx->res->body;

	like $page, qr/<select id="ac-agg">/, 'the panel has an aggregate picker';

	# The picker is written out by hand in the template, so the vocabulary it
	# offers is asserted here against the one the server validates: a function
	# added to the server's list and not to the panel (or the reverse) is what
	# this catches.  Sum is the one function spelled by not naming it, which is
	# how a card that picked the default has always carried it, so it is
	# asserted as the default option rather than as a name.
	like $page, qr/<option value="">Sum \(default\)<\/option>/,
		'the picker starts at the sum a card gets by not choosing';
	for my $fn (qw( avg min max count_distinct median stdev first last range )) {
		like $page, qr/<option value="\Q$fn\E">/,
			"and offers $fn, so a card can pick it without spelling it itself";
	}
	like $page, qr/<option value="p">/, 'and a percentile';
	like $page, qr/<input id="ac-agg-p"/, 'whose level is a field of its own';
	like $page, qr/data-agg-for="p"/, 'shown only while Percentile is chosen';

	# Counting rows is the value column's job -- "Count (no column needed)" --
	# so it is not a second way to say the same thing in the picker.
	unlike $page, qr/<option value="count">/,
		'counting rows stays with the value column rather than the picker';

	like $page, qr/var AGG_KINDS = \{ bar: 1, pie: 1, stacked: 1, treemap: 1, heatmap: 1, combo: 1 \};/,
		'the kinds that aggregate are exactly the kinds the picker is offered to';
	like $page, qr/if \(agg\) encode\.agg = agg;/,
		'and the choice travels with the card when it is added';
};

done_testing;
