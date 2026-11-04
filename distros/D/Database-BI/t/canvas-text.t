#!/usr/bin/env perl
use strict;
use warnings;

# Text cards on a canvas: a title or an explanation, with a font, a size and
# colours of its own.  A text card reads no data, so what matters here is what it
# stores and what it can write into the page.  What the panel and the short rows
# do in a browser cannot be seen from Test::Mojo; these tests hold the structure.
#
#   prove -l t/canvas-text.t

use Test::More;
use Test::Mojo;
use Mojo::File;
use File::Temp qw(tempdir);

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(tempdir(CLEANUP => 1))->to_string;

Mojo::File->new($data_dir)->child('orders.csv')->spew(join("\n",
	'id,region,amount',
	'1,North,10',
	'2,South,20',
) . "\n");

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir, model_dir => $model_dir });

sub new_canvas {
	$t->post_ok('/api/analyses' => json => {
		name     => 'Report',
		datasets => [ { spec => 'table:orders' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	})->status_is(201);
	return $t->tx->res->json->{id};
}

sub add_text {
	my ($id, %options) = @_;
	return $t->post_ok("/api/analyses/$id/visuals" => json => { kind => 'text', options => \%options });
}

subtest 'adding a card' => sub {
	my $id = new_canvas();
	add_text($id, text => "Sales\nby region", font => 'georgia', size => 24, colour => '#AA0000',
		background => '#ffffff', align => 'center', bold => 1, italic => 1, plain => 1, junk => 'x')
		->status_is(201)
		->json_is('/visual', 1)
		->json_is('/kind', 'text')
		->json_is('/title', 'Sales')
		->json_is('/plain', 1);

	my $html = $t->tx->res->json->{html};
	like $html, qr/font-family:Georgia/, 'the font is the CSS for its key';
	like $html, qr/font-size:24pt/, 'the size is in points';
	like $html, qr/color:#aa0000/, 'the colour';
	like $html, qr/background-color:#ffffff/, 'the background';
	like $html, qr/font-weight:bold;font-style:italic;text-align:center/, 'bold, italic and alignment';
	like $html, qr{Sales<br>by region}, 'a line end survives the minifier';

	$t->get_ok("/api/analyses/$id")->status_is(200);
	my $stored = $t->tx->res->json->{visuals}[1];
	is $stored->{options}{text}, "Sales\nby region", 'the text is stored as typed';
	is $stored->{options}{colour}, '#aa0000', 'a colour has one spelling';
	ok !exists $stored->{options}{junk}, 'a setting nobody asked for is not stored';
};

subtest 'what a write refuses' => sub {
	my $id = new_canvas();
	my @bad = (
		[ {},                                     qr/needs some text/ ],
		[ { text => " \n\t" },                    qr/needs some text/ ],
		[ { text => [ 'x' ] },                    qr/needs some text/ ],
		[ { text => 'x' x 20_001 },               qr/at most 20000/ ],
		[ { text => 'x', font => 'Comic Sans' },  qr/not one of the choices/ ],
		[ { text => 'x', size => 7 },             qr/from 8 to 96/ ],
		[ { text => 'x', size => 97 },            qr/from 8 to 96/ ],
		[ { text => 'x', size => '12;color:red' }, qr/from 8 to 96/ ],
		[ { text => 'x', colour => 'red' },       qr/#rrggbb/ ],
		[ { text => 'x', background => '#fff' },  qr/#rrggbb/ ],
		[ { text => 'x', colour => "#000000\n" }, qr/#rrggbb/ ],
		[ { text => 'x', colour => { a => 1 } },  qr/#rrggbb/ ],
		[ { text => 'x', align => 'middle' },     qr/left, center or right/ ],
	);
	for my $case (@bad) {
		$t->post_ok("/api/analyses/$id/visuals" => json => { kind => 'text', options => $case->[0] })
			->status_is(400);
		like $t->tx->res->json->{error}, $case->[1], "refused: $case->[1]";
	}
	$t->get_ok("/api/analyses/$id");
	is scalar @{ $t->tx->res->json->{visuals} }, 1, 'nothing refused was stored';

	add_text($id, text => 'x', size => 8)->status_is(201);
	add_text($id, text => 'x', size => 96)->status_is(201);
	add_text($id, text => ('x' x 20_000))->status_is(201);
};

subtest 'nothing typed or stored can reach the page as markup' => sub {
	my $id = new_canvas();
	my $evil = q{</div><script>alert(1)</script><img src=x onerror=alert(2)>};
	add_text($id, text => $evil)->status_is(201);
	unlike $t->tx->res->json->{html}, qr/<script|<img/, 'the reply escapes it';

	# PUT and import store a visual as given, so the page cannot rely on the write.
	$t->get_ok("/api/analyses/$id");
	my $doc = $t->tx->res->json;
	push @{ $doc->{visuals} }, { kind => 'text', options => {
		text       => 'stored',
		font       => q{x"><script>alert(3)</script>},
		size       => q{1;background:url(//evil)},
		colour     => q{red;background:url(//evil)},
		background => q{"><script>alert(4)</script>},
		align      => q{left;position:fixed},
	} };
	$t->put_ok("/api/analyses/$id" => json => $doc)->status_is(200);

	$t->get_ok("/a/$id")->status_is(200);
	my $body = $t->tx->res->body;
	unlike $body, qr/alert\(\d\)<\/script>/, 'no script from the store';
	unlike $body, qr/<img src=x/, 'no element from the text';
	unlike $body, qr/url\(\/\/evil\)/, 'no style from the store';
	unlike $body, qr/position:fixed/, 'and no other property';

	my @cards = $t->tx->res->dom->find('.text-card-text')->each;
	is $cards[1]->attr('style'), undef, 'bad settings are dropped, and the card still draws';
	like $cards[1]->text, qr/stored/, 'with its text';
	is $t->tx->res->dom->at('.text-card-text')->all_text, $evil, 'the first card shows the text as typed';
};

subtest 'on the page' => sub {
	my $id = new_canvas();
	add_text($id, text => 'Plain title', plain => 1)->status_is(201);
	add_text($id, text => "  Framed\n\n    note")->status_is(201);

	$t->get_ok("/a/$id")->status_is(200);
	my $dom = $t->tx->res->dom;
	ok $dom->at('#btn-add-text'), 'the toolbar offers it';
	ok $dom->at('#tx-panel[hidden]'), 'the panel starts closed';

	ok !$dom->at('#visual-0.text-card'), 'a chart is not a text card';
	ok $dom->at('#visual-0 .visual-cs-btn'), 'and keeps its cross-row button';
	ok !$dom->at('#visual-0 .visual-text-btn'), 'and has no text button';

	ok $dom->at('#visual-1.text-card.text-card-plain'), 'a plain card says so';
	ok $dom->at('#visual-2.text-card:not(.text-card-plain)'), 'a framed one does not';
	ok $dom->at('#visual-1 .visual-text-btn[data-edit-text="1"]'), 'a text card can be edited';
	ok !$dom->at('#visual-1 .visual-cs-btn'), 'and has no columns to work out';
	ok !$dom->at('#visual-1')->attr('data-cf-col'), 'and filters nothing';
	is $dom->at('#visual-1 .visual-card-title')->text, 'Plain title', 'it is named by its text';
	like $t->tx->res->body, qr{&#160; Framed}, 'leading spaces survive the minifier';

	my @fonts = map { $_->attr('value') } $dom->find('#tx-font option')->each;
	is_deeply \@fonts, [ '', qw(arial georgia times verdana trebuchet courier) ], 'the panel offers the fonts the server takes';
	for my $font (grep { length } @fonts) {
		add_text($id, text => 'x', font => $font)->status_is(201);
	}
};

subtest 'it reads no data' => sub {
	my $id = new_canvas();
	add_text($id, text => 'Note', plain => 1)->status_is(201);
	$t->get_ok("/a/$id/visual/1/csv")->status_is(404)->content_like(qr/no data/);
	$t->get_ok("/a/$id/visual/0/csv")->status_is(200);

	# A cross-filter from the chart leaves it as it was.
	$t->get_ok("/a/$id?cf=region:eq:North&cv=0")->status_is(200);
	like $t->tx->res->dom->at('#visual-1 .text-card-text')->text, qr/Note/, 'a filtered canvas still shows it';

	# Its source going away does not stop it being added or edited.
	Mojo::File->new($data_dir)->child('gone.csv')->spew("id,x\n1,2\n");
	$t->post_ok('/api/analyses' => json => {
		name => 'Gone', datasets => [ { spec => 'table:gone' } ],
		visuals => [ { kind => 'bar', encode => { cat => 'x', value => 'x' } } ],
	})->status_is(201);
	my $gone = $t->tx->res->json->{id};
	Mojo::File->new($data_dir)->child('gone.csv')->remove;
	add_text($gone, text => 'Still works')->status_is(201);
	$t->patch_ok("/api/analyses/$gone/visuals/1" => json => { options => { text => 'Changed' } })->status_is(200);
};

subtest 'editing a card' => sub {
	my $id = new_canvas();
	add_text($id, text => 'First', size => 20)->status_is(201);
	$t->patch_ok("/api/analyses/$id" => json => {
		layout => [ { visual => 1, x => 1, y => 1, w => 12, h => 1 } ],
	})->status_is(200);

	$t->patch_ok("/api/analyses/$id/visuals/1" => json => { options => { text => 'Second', plain => 1 } })
		->status_is(200)->json_is('/title', 'Second')->json_is('/plain', 1);
	like $t->tx->res->json->{html}, qr/Second/, 'the reply is the new card';

	$t->get_ok("/api/analyses/$id");
	my $doc = $t->tx->res->json;
	is_deeply $doc->{visuals}[1]{options}, { text => 'Second', plain => 1 }, 'the options are replaced, not merged';
	is $doc->{layout}[0]{w}, 12, 'and its place is kept';

	$t->patch_ok("/api/analyses/$id/visuals/1" => json => { options => { text => '' } })->status_is(400);
	$t->patch_ok("/api/analyses/$id/visuals/1" => json => { text => 'x' })->status_is(400)
		->json_like('/error', qr/options must be given/);
	$t->patch_ok("/api/analyses/$id/visuals/1" => json => { options => { text => 'x' }, encode => {} })->status_is(400)
		->json_like('/error', qr/no columns/);
	$t->patch_ok("/api/analyses/$id/visuals/1" => json => { options => { text => 'x' }, cross_row => undef })->status_is(400);
	$t->get_ok("/api/analyses/$id");
	is $t->tx->res->json->{visuals}[1]{options}{text}, 'Second', 'a refused edit leaves the card';

	# A chart is not changed by a text card's request.
	$t->patch_ok("/api/analyses/$id/visuals/0" => json => { options => { text => 'x' } })->status_is(400);
};

subtest 'removing a card' => sub {
	my $id = new_canvas();
	add_text($id, text => 'Gone')->status_is(201);
	$t->post_ok("/api/analyses/$id/visuals" => json => { kind => 'pie', encode => { cat => 'region', value => 'amount' } })->status_is(201);
	add_text($id, text => 'Kept')->status_is(201);

	$t->patch_ok("/api/analyses/$id" => json => {
		layout => [
			{ visual => 0, x => 1, y => 2, w => 6, h => 1 },
			{ visual => 1, x => 1, y => 1, w => 12, h => 1 },
			{ visual => 2, x => 7, y => 2, w => 6, h => 1 },
			{ visual => 3, x => 1, y => 3, w => 12, h => 1 },
		],
		bookmarks => [
			{ name => 'after',  state => '?cf=region:eq:North&cv=2', created => 1 },
			{ name => 'before', state => '?cv=0&cf=region:eq:North', created => 2 },
			{ name => 'other',  state => '?xcv=9',                   created => 3 },
		],
	})->status_is(200);

	$t->delete_ok("/api/analyses/$id/visuals/0")->status_is(400)->json_like('/error', qr/Only a text card/);
	$t->delete_ok("/api/analyses/$id/visuals/9")->status_is(404);
	$t->delete_ok("/api/analyses/$id/visuals/x")->status_is(400);
	$t->delete_ok('/api/analyses/nosuch/visuals/0')->status_is(404);
	$t->delete_ok('/api/analyses/a-b/visuals/0')->status_is(400);

	$t->delete_ok("/api/analyses/$id/visuals/1")->status_is(200)->json_is('/deleted', 1);

	$t->get_ok("/api/analyses/$id");
	my $doc = $t->tx->res->json;
	is_deeply [ map { $_->{kind} } @{ $doc->{visuals} } ], [ qw(bar pie text) ], 'the card is gone';
	is_deeply [ map { "$_->{visual}:$_->{y}" } @{ $doc->{layout} } ], [ '0:2', '1:2', '2:3' ],
		'its layout entry too, and later cards keep their places under their new numbers';
	is_deeply [ map { $_->{state} } @{ $doc->{bookmarks} } ],
		[ '?cf=region:eq:North&cv=1', '?cv=0&cf=region:eq:North', '?xcv=9' ],
		'a bookmark still names the card it filtered from';
	$t->get_ok("/a/$id")->status_is(200);
	like $t->tx->res->dom->at('#visual-2 .text-card-text')->text, qr/Kept/, 'the page draws what is left';
};

subtest 'shared and embedded' => sub {
	my $id = new_canvas();
	add_text($id, text => 'Shared title', colour => '#123456', plain => 1)->status_is(201);
	$t->post_ok("/api/analyses/$id/share")->status_is(200);
	my $token = $t->tx->res->json->{token};

	$t->get_ok("/share/$id?token=$token")->status_is(200);
	my $dom = $t->tx->res->dom;
	like $dom->at('.text-card-text')->text, qr/Shared title/, 'a shared page shows it';
	ok !$dom->at('.visual-text-btn'), 'with no way to edit it';
	ok !$dom->at('#tx-panel'), 'and no panel';

	$t->get_ok("/embed/$id?token=$token")->status_is(200);
	$dom = $t->tx->res->dom;
	ok $dom->at('.visual-card.text-card.text-card-plain'), 'an embedded page marks it';
	like $dom->at('.text-card-text')->attr('style'), qr/color:#123456/, 'with its colour';
	ok !$dom->at('.text-card .visual-card-title'), 'and without its name above it';
};

subtest 'the page keeps a row of text short' => sub {
	my $tt = Mojo::File->new('templates/web/en/canvas.html.tt')->slurp;
	like $tt, qr/grid-auto-rows: minmax\(15rem, auto\)/, 'rows are still 15rem by default';
	like $tt, qr/function pushApart.*?fitTextRows\(\);\s*return moved;/s, 'every change to the layout fits the rows again';
	like $tt, qr/function appendCard.*?grid\.appendChild\(card\);\s*fitTextRows\(\);/s, 'and so does a new card';
	unlike $tt, qr/rowPitch/, 'nothing assumes every row is the same height';
	like $tt, qr/card\.classList\.contains\('text-card'\) && sp\.h === 1/, 'a taller text card keeps full rows';
};

done_testing();
