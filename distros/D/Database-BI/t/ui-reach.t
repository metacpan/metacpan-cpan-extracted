use strict;
use warnings;

# Every feature can be reached from the pages, not only from a URL or a script:
#
#   * every route is named by some page, so nothing is left reachable only by
#     typing its address;
#   * the saved lookups and extractions have toolbar panels, as calculated
#     fields, groups and date formats do, and a saved group shows in the table
#     as it does in the charts;
#   * a definition saved for a dataset that can no longer be applied leaves its
#     table page drawn, saying what is wrong, so the panels that mend it can be
#     reached;
#   * a request a browser makes that is refused gets a page with the trail and
#     a way back, rather than a line of plain text;
#   * a canvas can be shared, embedded, saved as a file and imported again;
#   * "Remember columns" on the map panel replaces the old choice, and can be
#     forgotten;
#   * Canvases in the main navigation opens a page, not a scroll of the home
#     page;
#   * a panel reopened after a save lists what was saved, not a reply the
#     browser kept from before it.
#
#   prove -l t/ui-reach.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::JSON ();
use Mojo::Util qw(url_escape);
use File::Temp ();

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1));

$data_dir->child('sales.csv')->spew(
	"id,region,email,amount\n1,North,ann\@x.com,10\n2,South,bob\@y.org,5\n3,East,cy\@x.com,7\n");
$data_dir->child('managers.csv')->spew("region,manager\nNorth,Ann\nSouth,Bob\n");
# Its own dataset, so breaking it leaves the others alone.
my $contacts = $data_dir->child('contacts.csv');
$contacts->spew("id,email,amount\n1,ann\@x.com,3\n2,bob\@y.org,4\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir->to_string,
	model_dir => $model_dir->to_string,
});
$t->app->log->level('fatal');

my %BROWSER = (Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');

sub _dom { Mojo::DOM->new($t->tx->res->body) }
sub _heads { [ _dom()->find('#bi-table thead th')->map('all_text')->each ] }

subtest 'every route is named by a page' => sub {
	my @routes = Mojo::File->new('lib/Database/BI.pm')->slurp
		=~ /\$r->(?:get|post|put|patch|delete|any)\('([^']+)'/g;
	ok(scalar(@routes) > 50, 'the routes are found');
	my $pages = join '', map { Mojo::File->new($_)->slurp }
		glob('templates/web/en/*.html.tt templates/web/en/layouts/*.html.tt');
	# Reached on purpose without a page of their own: GET / is the home page
	# itself, and /line is another name for /graph, which the pages use.
	my %by_design = map { $_ => 1 } ('/', '/line');
	for my $route (grep { !$by_design{$_} } @routes) {
		(my $stem = $route) =~ s{/:\w+.*\z}{/};
		ok(index($pages, "'$stem") >= 0 || index($pages, "\"$stem") >= 0,
			"a page names $route");
	}
};

subtest 'lookups and extractions have panels, like the other saved columns' => sub {
	my $dom = Mojo::DOM->new($t->get_ok('/view/sales')->status_is(200)->tx->res->body);
	for my $name (qw(calc groups dates lookups extract)) {
		ok($dom->at("div.toolbar #btn-$name.btn-tool"), "the toolbar has #btn-$name");
		ok($dom->at("#$name-panel"), "and its panel");
	}
	my @files = $dom->find('#lookups-file-sel option[data-table]')->map(attr => 'value')->each;
	ok((grep { $_ eq 'managers.csv' } @files), 'the lookup file menu lists the data directory');
	ok($dom->at('#extract-col-sel option[value="email"]'), 'the extraction column menu lists the columns');

	my $page = $t->tx->res->body;
	like($page, qr{fetch\('/lookups/list}, 'the lookup panel lists what is saved');
	like($page, qr{biModelPost\('/lookups/save'}, 'saves');
	like($page, qr{biModelPost\('/lookups/delete'}, 'and deletes');
	like($page, qr{sp\.append\('nolk', name\)}, 'and can skip one in a view');
	like($page, qr{biModelPost\('/extract/save'}, 'the extraction panel saves');
	like($page, qr{biModelPost\('/extract/delete'}, 'and deletes');

	# What the panels send, the routes take, and the table shows.
	$t->post_ok('/lookups/save' => form => {
		l => 'table:sales', name => 'managers', file => 'managers.csv', key => 'region',
		fields => 'manager', default => 'nobody',
	})->status_is(200)->json_is('/ok', 1);
	$t->post_ok('/extract/save' => form => {
		l => 'table:sales', name => 'em', col => 'email', pattern => '@(?<domain>[\w.-]+)',
	})->status_is(200)->json_is('/ok', 1);
	$t->get_ok('/view/sales')->status_is(200);
	my $heads = _heads();
	ok((grep { $_ eq 'manager' } @$heads), 'the looked-up column is in the table');
	ok((grep { $_ eq 'domain' } @$heads), 'and so is the extracted one');
	$t->content_like(qr{<td[^>]*>nobody</td>}, "a region the file lacks gets the default");

	$t->get_ok('/view/sales?nolk=managers')->status_is(200);
	ok(!(grep { $_ eq 'manager' } @{ _heads() }), "a view can skip the lookup the panel's link names");

	$t->post_ok('/lookups/delete' => form => { l => 'table:sales', name => 'managers' })->status_is(200);
	$t->post_ok('/extract/delete' => form => { l => 'table:sales', name => 'em' })->status_is(200);
	$t->get_ok('/view/sales')->status_is(200);
	ok(!(grep { $_ eq 'manager' || $_ eq 'domain' } @{ _heads() }), 'deleted, they are gone');
};

subtest 'a saved group shows in the table, as in its charts' => sub {
	$t->post_ok('/groups/save' => form => {
		l => 'table:sales', col => 'region', group => 'Northern', values => "North\nEast",
	})->status_is(200);
	$t->get_ok('/view/sales')->status_is(200);
	ok((grep { $_ eq 'region_group' } @{ _heads() }), '/view/:table shows the group column');
	$t->content_like(qr{<td[^>]*>Northern</td>});
	$t->get_ok('/bar?l=table:sales&cat=region_group')->status_is(200, 'which the bar chart draws');
	my $cv = $t->post_ok('/api/analyses' => json => {
		name     => 'Grouped',
		datasets => [ { spec => 'table:sales', alias => 'left' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region_group', val => 'amount' }, title => 'G' } ],
	})->status_is(201)->tx->res->json->{id};
	$t->get_ok("/a/$cv")->status_is(200)->content_like(qr/Northern/, 'and so does a canvas card');
	$t->post_ok('/groups/delete' => form => { l => 'table:sales', col => 'region' })->status_is(200);
	$t->get_ok('/view/sales')->status_is(200);
	ok(!(grep { $_ eq 'region_group' } @{ _heads() }), 'and deleted, it is gone');

	my $path = $data_dir->child('sales.csv')->to_string;
	$t->post_ok('/groups/save' => form => {
		l => "path:$path", col => 'region', group => 'Northern', values => 'North',
	})->status_is(200);
	$t->get_ok('/open?path=' . url_escape($path))->status_is(200);
	ok((grep { $_ eq 'region_group' } @{ _heads() }), '/open shows it too');
	$t->post_ok('/groups/delete' => form => { l => "path:$path" })->status_is(200);
};

subtest 'a broken saved definition leaves its table page usable' => sub {
	$t->post_ok('/extract/save' => form => {
		l => 'table:contacts', name => 'em', col => 'email', pattern => '@(?<domain>[\w.-]+)',
	})->status_is(200);
	$t->post_ok('/calc/save' => form => { l => 'table:contacts', name => 'dbl', expr => 'amount * 2' })
		->status_is(200);
	$t->get_ok('/view/contacts')->status_is(200);
	ok(!_dom()->at('#stored-error-note'), 'nothing to say while it works');
	is_deeply(_heads(), [qw(id email amount domain dbl)], 'and the saved columns are there');

	# The file loses the column the extraction reads.
	$contacts->spew("id,amount\n1,3\n2,4\n");
	utime time + 5, time + 5, $contacts->to_string;

	for my $url ('/view/contacts', '/view/contacts?f=' . url_escape('amount:gt:3'),
		'/open?path=' . url_escape($contacts->to_string)) {
		my $l = $url =~ /\A\/open/ ? 'path:' . $contacts->to_string : 'table:contacts';
		if ($l =~ /\Apath:/) {
			# A path: spec files its own definitions; break one there too.
			$t->post_ok('/extract/save' => form => {
				l => $l, name => 'em', col => 'amount', pattern => '(?<n>\d)',
			})->status_is(200);
			$t->post_ok('/extract/save' => form => {
				l => $l, name => 'gone', col => 'amount', pattern => '(?<m>\d)',
			})->status_is(200);
			$contacts->spew("id,cost\n1,3\n2,4\n");
			utime time + 10, time + 10, $contacts->to_string;
		}
		$t->get_ok($url)->status_is(200, "$url is still drawn");
		my $note = _dom()->at('#stored-error-note');
		ok($note, 'with a note') or next;
		like($note->all_text, qr/Extraction "em": column "\w+" is not in this dataset/, 'that says what is wrong');
		like($note->all_text, qr/shown without its saved calculated fields, lookups and extractions/,
			'and what was left out');
		for my $panel (qw(btn-calc btn-lookups btn-extract)) {
			ok($note->at(qq{button[data-open="$panel"]}), "it opens $panel");
			ok(_dom()->at("#$panel"), 'which is on the page');
		}
		ok(!(grep { $_ eq 'domain' || $_ eq 'dbl' } @{ _heads() }), 'the table has the columns it can show');
	}

	$t->get_ok('/bar?l=table:contacts&cat=amount')->status_is(400, 'a chart of it still refuses')
		->content_like(qr/Extraction "em"/, 'with the reason');
	$t->get_ok('/view/contacts?c=' . url_escape('bad:nosuch*2'))->status_is(400,
		"a mistake in the request's own c= is still refused");

	# The file has lost amount too, so the calculated field is the next fault.
	$t->post_ok('/extract/delete' => form => { l => 'table:contacts' })->status_is(200);
	$t->get_ok('/view/contacts')->status_is(200);
	my $note = _dom()->at('#stored-error-note');
	ok($note, 'with the extraction gone, the note names the next fault');
	like($note ? $note->all_text : '', qr/dbl/, 'the calculated field');
	$t->post_ok('/calc/delete' => form => { l => 'table:contacts', name => 'dbl' })->status_is(200);
	$t->get_ok('/view/contacts')->status_is(200);
	ok(!_dom()->at('#stored-error-note'), 'mended, the note goes');
	$t->get_ok('/bar?l=table:contacts&cat=cost')->status_is(200, 'and the charts draw again');
};

subtest 'a refused request in a browser gets a page with a way back' => sub {
	my $url = '/bar?l=table:sales&cat=' . url_escape('<b>nope</b>');
	$t->get_ok($url => \%BROWSER)->status_is(400)->content_type_like(qr{\Atext/html});
	my $dom = _dom();
	like($dom->at('.not-found-msg')->all_text, qr/<b>nope<\/b>/, 'the reason is on the page');
	unlike($t->tx->res->body, qr/<b>nope<\/b>/, 'escaped');
	ok($dom->at('#btn-error-back'), 'with a Back button');
	like($dom->at('nav.back-link')->all_text, qr/sales/, 'and the trail to the table');
	ok($dom->at('nav a[href="/canvases"], nav a[href="/catalog"], header, nav'), 'and the navigation');

	$t->get_ok($url)->status_is(400)->content_type_like(qr{\Atext/plain}, 'a script still gets plain text');
	$t->get_ok('/api/range?l=table:sales' => \%BROWSER)->status_is(400)
		->content_type_unlike(qr{text/html}, 'and an API route keeps its own reply');
	$t->post_ok('/lookups/save' => \%BROWSER => form => { l => 'table:sales' })->status_is(400)
		->content_type_like(qr{json}, 'as does a POST');
};

subtest 'a canvas can be shared, embedded, saved and imported' => sub {
	my $id = $t->post_ok('/api/analyses' => json => {
		name     => 'Shared',
		datasets => [ { spec => 'table:sales', alias => 'left' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region', val => 'amount' }, title => 'T' } ],
	})->status_is(201)->tx->res->json->{id};

	my $dom = Mojo::DOM->new($t->get_ok("/a/$id")->status_is(200)->tx->res->body);
	ok($dom->at('#btn-share'), 'the canvas has a Share button');
	ok($dom->at('#share-panel[role="dialog"]'), 'and its panel');
	is($dom->at('#share-export')->attr('href'), "/api/analyses/$id/export", 'which downloads the JSON');
	like($t->tx->res->body, qr{fetch\('/api/analyses/\Q$id\E/share', \{ method: 'POST' \}\)},
		'and asks for a link');

	my $share = $t->post_ok("/api/analyses/$id/share")->status_is(200)->tx->res->json;
	(my $path = $share->{url}) =~ s{\Ahttps?://[^/]+}{};
	$dom = Mojo::DOM->new($t->get_ok($path)->status_is(200, 'the link opens')->tx->res->body);
	ok(!$dom->at('#btn-share'), 'read-only, with no Share button');
	(my $embed = $path) =~ s{\A/share/}{/embed/};
	$t->get_ok($embed)->status_is(200, 'the embed code the panel builds from it opens too');

	my $json = $t->get_ok("/api/analyses/$id/export")->status_is(200)->tx->res->body;
	$dom = Mojo::DOM->new($t->get_ok('/canvases')->status_is(200)->tx->res->body);
	ok($dom->at('#cv-import-file[type="file"]'), 'the Canvases page can import a canvas');
	like($t->tx->res->body, qr{fetch\('/api/analyses/import', \{ method: 'POST', body: fd \}\)},
		'by posting the file');
	my $new = $t->post_ok('/api/analyses/import' => form => {
		file => { content => $json, filename => 'canvas.json', 'Content-Type' => 'application/json' },
	})->status_is(201)->tx->res->json->{id};
	isnt($new, $id, 'the file makes a new canvas');
	$t->get_ok("/a/$new")->status_is(200)->content_like(qr/Shared/, 'which opens');
};

subtest 'Canvases in the main navigation opens a page of its own' => sub {
	# It used to be /#bi-canvases: the home page, scrolled to a list that is
	# filled in after the page loads, and empty when there are no canvases.
	my $dom = Mojo::DOM->new($t->get_ok('/view/sales')->status_is(200)->tx->res->body);
	is($dom->at('#site-nav-canvases')->attr('href'), '/canvases', 'the link is /canvases');
	$dom = Mojo::DOM->new($t->get_ok('/canvases')->status_is(200)->tx->res->body);
	ok($dom->at('#bi-canvases[data-empty]'), 'which lists the canvases, and says when there are none');
	like($dom->at('#bi-canvases')->attr('data-empty'), qr/New canvas/, 'and how to make one');
	ok($dom->at('#cv-import-file'), 'with Import canvas');
	like($t->tx->res->body, qr{fetch\('/api/analyses'\)}, 'drawn from the list of canvases');
	$dom = Mojo::DOM->new($t->get_ok('/')->status_is(200)->tx->res->body);
	ok($dom->at('#bi-canvases'), 'the home page still lists them');
	ok(!$dom->at('#bi-canvases[data-empty]'), 'and says nothing when there are none');
	ok(!$dom->at('#cv-import-file'), 'Import canvas is on the Canvases page only');
};

subtest 'a panel reopened after a save lists what was saved' => sub {
	# With a Last-Modified and no Cache-Control a browser may reuse a reply
	# without asking, so a list fetched before a save came back after it.
	for my $url ('/calc/list?l=table:sales', '/lookups/list?l=table:sales', '/view/sales') {
		$t->get_ok($url)->status_is(200);
		ok(!defined $t->tx->res->headers->last_modified, "$url has no Last-Modified");
		ok($t->tx->res->headers->etag, 'only an ETag, which a browser revalidates');
	}
};

subtest 'the map panel remembers one choice of columns, and forgets it' => sub {
	my $l = 'l=' . url_escape('table:sales');
	$t->post_ok("/geo/save?$l&col=region&kind=location")->status_is(200);
	$t->post_ok("/geo/save?$l&replace=1&col=amount&kind=lat&col=id&kind=lon")->status_is(200);
	$t->get_ok("/geo/list?$l")->status_is(200)->json_is('/columns', {
		amount => { kind => 'lat' }, id => { kind => 'lon' },
	}, 'Remember replaces the place-name column with the latitude and longitude');
	$t->post_ok("/geo/save?$l&col=a&kind=lat&col=b")->status_is(400, 'a column without a kind is refused');
	my $page = $t->get_ok('/view/sales')->status_is(200)->tx->res->body;
	ok(Mojo::DOM->new($page)->at('#btn-map-forget'), 'the panel offers to forget them');
	like($page, qr{'&replace=1'}, 'and Remember sends replace=1');
	$t->post_ok("/geo/delete?$l")->status_is(200);
	$t->get_ok("/geo/list?$l")->json_is('/columns', {}, 'forgotten');
};

done_testing();
