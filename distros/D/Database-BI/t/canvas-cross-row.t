#!/usr/bin/env perl
use strict;
use warnings;

# The cross-row pass on a canvas.
#
# A canvas names cs=/by=/order= once, in its own query string.  The pass runs
# once per card, after that card's own filters and after the page's
# cross-filter, so each card's window is over the rows that card is drawn from.
# The fixture makes the three possible answers different numbers:
#
#   all rows (by day)  10, 30, 130, 330
#   North only         10, 30
#   South only         100, 300
#
# A pass shared across the cards would give every card the first row of
# numbers (or, if it ran before the filters, the same totals everywhere), and
# this file exists to keep that from happening.
#
#   prove -l t/canvas-cross-row.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::JSON qw(encode_json);
use File::Temp qw(tempdir);

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(tempdir(CLEANUP => 1))->to_string;

Mojo::File->new($data_dir)->child('orders.csv')->spew(join("\n",
	'id,day,region,amount',
	'1,2026-01-01,North,10',
	'2,2026-01-02,North,20',
	'3,2026-01-03,South,100',
	'4,2026-01-04,South,200',
) . "\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

my $SPEC = {
	name     => 'Cross-row canvas',
	datasets => [ { spec => 'table:orders', alias => 'left' } ],
	visuals  => [
		{ kind => 'table', title => 'All rows',
		  encode => { columns => [qw(day region amount rt)] } },
		{ kind => 'table', title => 'North',
		  encode => { columns => [qw(day region amount rt)] },
		  filters => ['region:eq:North'] },
		{ kind => 'table', title => 'South',
		  encode => { columns => [qw(day region amount rt)] },
		  filters => ['region:eq:South'] },
		# A card that plots the produced column, not just a table that shows
		# it: the aggregation has to fold in Perl, because "rt" exists in no
		# backend.
		{ kind => 'bar', title => 'Running total by region',
		  encode => { cat => 'region', value => 'rt' } },
	],
};

# _card($dom, $n) -> the card element, or undef
sub _card {
	my ($dom, $n) = @_;
	return $dom->at("#visual-$n");
}

# _cells($row) -> arrayref of the <td> elements of one table row, in order
#
# The cells of a row are its own child nodes, so they are read as such.  A
# selector would put the read in Mojo::DOM::CSS's hands, and that is where a
# harness goes wrong quietly: on a node with no root above it (a text node, a
# row taken out of its tree) a plain read answers with the node above it, and
# any selector that asks for the root -- matching does, and so does :scope --
# walks the parent pointers forever instead of returning.  A hang reports
# nothing at all, so the cells are taken without asking CSS anything.
sub _cells {
	my ($row) = @_;
	return [] unless $row && $row->type eq 'tag';
	return [
		grep { $_->type eq 'tag' && $_->tag eq 'td' } @{ $row->child_nodes }
	];
}

# _column($card, $idx) -> arrayref of the $idx-th cell of every table row
sub _column {
	my ($card, $idx) = @_;
	return [] unless $card;
	my @values;
	for my $tr (@{ $card->find('tbody tr')->to_array }) {
		my @cell = map { $_->all_text } @{ _cells($tr) };
		push @values, $cell[$idx];
	}
	return \@values;
}

sub _error {
	my ($card) = @_;
	return '' unless $card;
	my $error = $card->at('.visual-error');
	return $error ? $error->all_text : '';
}

# The reader every cell assertion below goes through is checked on its own: a
# wrong one would hang the suite rather than fail it, and a hook that hangs
# reports nothing.
subtest 'the cell reader reads a row\'s children, not a selector' => sub {
	my $dom = Mojo::DOM->new(
		"<table><tbody><tr>\n\t<td>a</td>\n\t<td>b</td>\n</tr></tbody></table>");
	my $row = $dom->at('tbody tr');
	ok($row, 'a row to read');
	is_deeply [ map { $_->all_text } @{ _cells($row) } ], [ 'a', 'b' ],
		'its cells come back in order, with the whitespace between them skipped';

	# A text node has no root above it: CSS reads it as its parent, and a
	# root-asking selector never returns from it.  Here it answers no cells.
	my $text = $row->child_nodes->[0];
	is($text->type, 'text', 'a text node, as sits between a row and its cells');
	is_deeply _cells($text), [], 'which has no cells, and is read as having none';

	# Pinned structurally, because the regression this guards against would
	# hang rather than fail: a selector in this file is one waiting to happen.
	my @code = grep { !/^\s*#/ } split /\n/, Mojo::File->new(__FILE__)->slurp;
	my $file = join("\n", @code);
	unlike $file, qr/\bchildren\s*\(/, 'no cell in this file is read by selector';
	like $file, qr/\bchild_nodes\b/, 'they come from the row\'s own children';
};

my $id = $t->post_ok('/api/analyses',
	{ 'Content-Type' => 'application/json' },
	encode_json($SPEC),
)->status_is(201)->tx->res->json->{id};

ok $id, 'the canvas was saved';

# ---------------------------------------------------------------------------
# One plan, one run per card
# ---------------------------------------------------------------------------

subtest 'each card totals the rows that card shows' => sub {
	$t->get_ok("/a/$id?cs=amount:running_total:rt&order=day")->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);

	is_deeply _column(_card($dom, 0), 3), [ 10, 30, 130, 330 ],
		'the card with no filters totals every row, in day order';
	is_deeply _column(_card($dom, 1), 3), [ 10, 30 ],
		'the North card totals only North rows, starting again at its first row';
	is_deeply _column(_card($dom, 2), 3), [ 100, 300 ],
		'the South card totals only South rows';

	# The same three answers cannot come from one shared pass: a pass over all
	# rows would end the North card at 130, and a pass over the filterless rows
	# would give the South card 10 and 30.
	unlike join(',', @{ _column(_card($dom, 1), 3) }), qr/\b130\b/,
		'the North card does not carry the other card\'s rows into its total';
};

subtest 'a card can plot the column the pass produced' => sub {
	$t->get_ok("/a/$id?cs=amount:running_total:rt&order=day")->status_is(200);

	my $card = _card(Mojo::DOM->new($t->tx->res->body), 3);
	ok($card->at('svg'), 'the bar card is drawn from the running total column');
	is(_error($card), '', 'and no card reports an unknown column');

	# Without cs= the column does not exist, and the card says so rather than
	# drawing something else: the pass, not a saved field, is what creates it.
	$t->get_ok("/a/$id")->status_is(200);
	like(_error(_card(Mojo::DOM->new($t->tx->res->body), 3)),
		qr/Column not found: rt/, 'without cs= the card names the missing column');
};

# ---------------------------------------------------------------------------
# The cross-filter is part of "this card's rows"
# ---------------------------------------------------------------------------

subtest 'the pass sees the cross-filter, applied per card' => sub {
	$t->get_ok("/a/$id?cs=amount:running_total:rt&order=day&cf=region%3Aeq%3ANorth&cv=0")
		->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);

	is_deeply _column(_card($dom, 0), 3), [ 10, 30, 130, 330 ],
		'the source card is unfiltered, so its total runs over every row';
	is_deeply _column(_card($dom, 1), 3), [ 10, 30 ],
		'the North card is filtered twice over and still totals its two rows';

	# The South card's own filter and the cross-filter have no row in common:
	# the card has nothing to draw, rather than South totals computed from
	# rows the page is not showing.
	is(_error(_card($dom, 2)), 'No data to display',
		'a card with no rows left reports it instead of a stale total');
};

# ---------------------------------------------------------------------------
# A card added in place is drawn like its neighbours
# ---------------------------------------------------------------------------

subtest 'a card added to the canvas while cs= is on is drawn with it' => sub {
	$t->post_ok("/api/analyses/$id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'table',
			title  => 'Added in place',
			encode => { columns => [qw(day region rt)] },
			query  => '?cs=amount:running_total:rt&order=day',
		}),
	)->status_is(201)->json_is('/visual' => 4);

	my $html = $t->tx->res->json->{html};
	my @values = $html =~ m{<td>(-?[\d.]+)</td>}g;
	is_deeply [ @values[ 0 .. 3 ] ], [ 10, 30, 130, 330 ],
		'the new card carries the running total of the rows it draws';
};

# ---------------------------------------------------------------------------
# Refusals belong to the page, not to one card
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# A card's own plan
# ---------------------------------------------------------------------------
#
# The page's cs= is the page's.  A card may bring a plan of its own -- which
# replaces the page's rather than adding to it -- or say that it has none, so a
# canvas of running totals can hold one card of raw numbers.

# _header($card) -> arrayref of the card's column headings
sub _header {
	my ($card) = @_;
	return [] unless $card;
	return [ map { $_->all_text } @{ $card->find('thead th')->to_array } ];
}

my $own = {
	name     => 'Cards with their own cross-row plans',
	datasets => [ { spec => 'table:orders', alias => 'left' } ],
	visuals  => [
		# Its own unpartitioned running total, under a name of its own.
		{ kind => 'table', title => 'Own total',
		  encode => { columns => [qw(day amount total)] },
		  cross_row => { cs => ['amount:running_total:total'], order => ['day'] } },
		# No plan of its own: it runs whatever the page names.
		{ kind => 'table', title => 'Inherits',
		  encode => { columns => [qw(day amount rt)] } },
		# An empty plan: this card has no cross-row column at all.
		{ kind => 'table', title => 'None',
		  encode => { columns => [qw(day amount)] },
		  cross_row => { cs => [] } },
	],
};

my $own_id = $t->post_ok('/api/analyses',
	{ 'Content-Type' => 'application/json' },
	encode_json($own),
)->status_is(201)->tx->res->json->{id};

ok $own_id, 'the canvas with per-card plans was saved';

subtest 'a card runs its own plan, not the page\'s' => sub {
	# The page partitions by region, which would give 10, 30, 100, 300.  The
	# card's own plan does not partition, so its numbers are 10, 30, 130, 330:
	# a card that stacked both plans would have neither set.
	$t->get_ok("/a/$own_id?cs=amount:running_total:rt&by=region&order=day")->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);

	is_deeply _column(_card($dom, 0), 2), [ 10, 30, 130, 330 ],
		'the card with its own plan totals every row, under its own name';
	is_deeply _header(_card($dom, 0)), [qw(day amount total)],
		'and it does not also gain the page\'s column';

	is_deeply _column(_card($dom, 1), 2), [ 10, 30, 100, 300 ],
		'a card with no plan of its own still runs the page\'s, partition and all';

	is_deeply _header(_card($dom, 2)), [qw(day amount)],
		'a card that says it has none gets no cross-row column';
	is_deeply _column(_card($dom, 2), 1), [ 10, 20, 100, 200 ],
		'and its rows are the plain amounts';
};

subtest 'an own plan survives a reload, and the page need name nothing' => sub {
	$t->get_ok("/a/$own_id")->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);
	is_deeply _column(_card($dom, 0), 2), [ 10, 30, 130, 330 ],
		'the saved plan is the card\'s, so a bare canvas URL still draws it';
	# The inheriting card names rt, and nothing on this URL makes it: the card
	# says which column it cannot find rather than printing a heading with no
	# cells under it, which is what a reader would take for missing data.
	like _error(_card($dom, 1)), qr/Column not found: rt/,
		'while the inheriting card, with no page plan to inherit, names the column
		it is drawn against that nothing makes';

	$t->get_ok("/api/analyses/$own_id")->status_is(200);
	my $saved = $t->tx->res->json->{visuals}[0]{cross_row};
	is_deeply $saved, { cs => ['amount:running_total:total'], order => ['day'] },
		'and the plan is stored as the URL spells it, so one parser reads both';
};

# ---------------------------------------------------------------------------
# Repairing a saved card's plan
# ---------------------------------------------------------------------------
#
# A plan is stored data like a column, so it can be replaced without deleting
# the card and losing its place on the canvas.  The three states a saved card
# can be in -- a plan of its own, no plan of its own, and a plan that runs
# nothing -- are the three things a repair can ask for.

my $rep = $t->post_ok('/api/analyses',
	{ 'Content-Type' => 'application/json' },
	encode_json({
		name     => 'Repair canvas',
		datasets => [ { spec => 'table:orders', alias => 'left' } ],
		visuals  => [
			{ kind => 'table', title => 'Own',
			  encode => { columns => [qw(day amount total)] },
			  cross_row => { cs => ['amount:running_total:total'], order => ['day'] } },
			{ kind => 'table', title => 'Inherits',
			  encode => { columns => [qw(day amount rt)] } },
		],
	}),
)->status_is(201)->tx->res->json->{id};

ok $rep, 'the canvas to be repaired was saved';

subtest 'a repair replaces the plan and leaves the card where it is' => sub {
	# The card inherited the page's plan and had none of its own; now it has one,
	# without a word about its columns -- the same column, a different function.
	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => { cs => ['amount:rank:rt'], order => ['day'] } }),
	)->status_is(200)
	 ->json_is('/visual' => 1)
	 ->json_is('/kind'   => 'table');

	$t->get_ok("/a/$rep")->status_is(200);
	is_deeply _column(_card(Mojo::DOM->new($t->tx->res->body), 1), 2), [ 4, 3, 2, 1 ],
		'a bare canvas URL now draws the plan the repair wrote';

	# A repair that renames the column the pass produces writes both keys in the
	# one request, so the card is never left drawn against a column the plan no
	# longer makes.
	$t->patch_ok("/api/analyses/$rep/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			encode    => { columns => [qw(day amount rk)] },
			cross_row => { cs => ['amount:running_total:rk'], by => 'region', order => ['day'] },
		}),
	)->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->json->{html});
	is_deeply _header($dom), [qw(day amount rk)],
		'the renamed column is what the card now shows';
	is_deeply _column($dom, 2), [ 10, 30, 100, 300 ],
		'and it totals the partition the repair named';

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	is_deeply $t->tx->res->json->{visuals}[0]{cross_row},
		{ cs => ['amount:running_total:rk'], by => 'region', order => ['day'] },
		'both keys are stored as the canvas spells them';
	is(scalar @{ $t->tx->res->json->{visuals} }, 2,
		'the card was changed, not removed and appended');
};

subtest 'a null plan gives the plan up and takes the page\'s again' => sub {
	# The card plots rk, and here only its own plan makes rk.  Giving the plan up
	# would leave the card drawn against a column nothing produces, so the repair
	# is refused and the card keeps the plan it had: replacing a plan is no more
	# a way to break a card than editing one is.
	$t->patch_ok("/api/analyses/$rep/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => undef }),
	)->status_is(400)
	 ->json_like('/error' => qr/Column not found: rk/);

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	is_deeply $t->tx->res->json->{visuals}[0]{cross_row},
		{ cs => ['amount:running_total:rk'], by => 'region', order => ['day'] },
		'the refused repair left the card with the plan it was drawn with';

	# Given up on a page that does make the column, it is the repair it always
	# was: the card takes the page's plan instead of carrying one of its own.
	$t->patch_ok("/api/analyses/$rep/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => undef, query => '?cs=amount:rank:rk&order=day' }),
	)->status_is(200);

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	my $stored = $t->tx->res->json;
	ok(!exists $stored->{visuals}[0]{cross_row},
		'the card has no plan of its own, rather than a plan that runs nothing');
	is_deeply $stored->{visuals}[0]{encode}, { columns => [qw(day amount rk)] },
		'and giving the plan up did not touch its columns';
	is_deeply $stored->{visuals}[0]{cross_row}, undef,
		'the key is gone, not stored as null';

	# With no plan of its own it runs the page's: a page that ranks shows the rank
	# in the column the card still has, which its old running total did not give.
	$t->get_ok("/a/$rep?cs=amount:rank:rk&order=day")->status_is(200);
	is_deeply _column(_card(Mojo::DOM->new($t->tx->res->body), 0), 2), [ 4, 3, 2, 1 ],
		'the page\'s plan is the card\'s plan again';
};

subtest 'a repair the canvas cannot honour is refused, and keeps the card' => sub {
	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => { cs => ['missing:running_total:rt'], order => ['day'] } }),
	)->status_is(400)
	 ->json_like('/error' => qr/names the column "missing"/);

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	is_deeply $t->tx->res->json->{visuals}[1]{cross_row},
		{ cs => ['amount:rank:rt'], by => '', order => ['day'] },
		'a refused repair left the saved plan alone';

	# The body has to say which of the two things it is changing.
	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({}),
	)->status_is(400)
	 ->json_like('/error' => qr/encode or cross_row must be given/);

	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => 'rank' }),
	)->status_is(400)
	 ->json_like('/error' => qr/cross_row must be an object or null/);

	# A part of the plan that is the wrong kind is said so: storing an empty plan
	# instead would answer 200 and change the card to something nobody asked for.
	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => { cs => 'amount:rank:rt' } }),
	)->status_is(400)
	 ->json_like('/error' => qr/cross_row\.cs must be a list/);

	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => { cs => [] , by => ['region'] } }),
	)->status_is(400)
	 ->json_like('/error' => qr/cross_row\.by must be a column name/);

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	is_deeply $t->tx->res->json->{visuals}[1]{cross_row},
		{ cs => ['amount:rank:rt'], by => '', order => ['day'] },
		'none of the refused repairs changed the card';

	# An empty plan is a choice, not a doubt: it is the card saying it runs no
	# cross-row pass even where the page runs one.  It is not a way to leave the
	# card showing a column only the page's plan made, so a request that empties
	# the plan alone is refused, and the column goes in the same request.
	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => {} }),
	)->status_is(400)
	 ->json_like('/error' => qr/Column not found: rt/);

	$t->patch_ok("/api/analyses/$rep/visuals/1",
		{ 'Content-Type' => 'application/json' },
		encode_json({ cross_row => {}, encode => { columns => [qw(day amount)] } }),
	)->status_is(200);

	$t->get_ok("/api/analyses/$rep")->status_is(200);
	is_deeply $t->tx->res->json->{visuals}[1]{cross_row}, { cs => [], by => '', order => [] },
		'an empty plan is stored as the card that runs none';
	is_deeply $t->tx->res->json->{visuals}[1]{encode}, { columns => [qw(day amount)] },
		'with the column it no longer makes dropped from its columns';

	$t->get_ok("/a/$rep?cs=amount:rank:rt&order=day")->status_is(200);
	is_deeply _header(_card(Mojo::DOM->new($t->tx->res->body), 1)), [qw(day amount)],
		'and the page\'s plan does not reach it';
};

subtest 'a card plan that cannot be honoured is that card\'s error' => sub {
	my $broken = {
		name     => 'Broken card plans',
		datasets => [ { spec => 'table:orders', alias => 'left' } ],
		visuals  => [
			{ kind => 'table', title => 'Unknown column',
			  encode => { columns => [qw(day x)] },
			  cross_row => { cs => ['nope:running_total:x'], order => ['day'] } },
			{ kind => 'table', title => 'No order',
			  encode => { columns => [qw(day ma3)] },
			  cross_row => { cs => ['amount:window_avg:ma3:3'] } },
		],
	};
	my $bid = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json($broken),
	)->status_is(201)->tx->res->json->{id};

	$t->get_ok("/a/$bid")->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);

	like(_error(_card($dom, 0)), qr/names the column "nope"/,
		'the card whose own column does not exist names it');
	like(_error(_card($dom, 1)), qr/needs order=/,
		'and the card whose plan reads rows in no order is told what it needs');
	ok($dom->at('#visual-0') && $dom->at('#visual-1'),
		'both cards are still on the page: one bad plan does not take the canvas down');
};

subtest 'a card added with an unworkable plan is refused, not stored' => sub {
	$t->post_ok("/api/analyses/$own_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind      => 'table',
			encode    => { columns => [qw(day nope)] },
			cross_row => { cs => ['missing:running_total:nope'], order => ['day'] },
		}),
	)->status_is(400)->json_like('/error' => qr/names the column "missing"/);

	$t->get_ok("/api/analyses/$own_id")->status_is(200);
	is(scalar @{ $t->tx->res->json->{visuals} }, 3,
		'and the canvas still has its three cards');

	# The other half of the choice: the added card says it wants no plan, which
	# is a stored empty plan rather than an absence.
	$t->post_ok("/api/analyses/$own_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind      => 'table',
			encode    => { columns => [qw(day amount)] },
			cross_row => { cs => [] },
			query     => '?cs=amount:running_total:rt&order=day',
		}),
	)->status_is(201)->json_is('/visual' => 3);

	my $html = $t->tx->res->json->{html};
	unlike($html, qr/<th>rt<\/th>/,
		'the new card opts out of the page\'s running total');
	like($html, qr/<td>10<\/td>/, 'and shows the plain amounts');
};

subtest 'a card can carry more than one cross-row column' => sub {
	# cs= is repeatable on a page, and a card's plan is the same list: a running
	# total and a rank belong to the one card that asked for them, and the rank
	# reads the same rows the running total does.
	$t->post_ok("/api/analyses/$own_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind      => 'table',
			title     => 'Two columns',
			encode    => { columns => [qw(day amount rt rk)] },
			cross_row => {
				cs    => ['amount:running_total:rt', 'amount:rank:rk'],
				order => ['day'],
			},
		}),
	)->status_is(201)->json_is('/visual' => 4);

	my $dom  = Mojo::DOM->new($t->tx->res->json->{html});
	my @rows = map {
		[ map { $_->all_text } @{ _cells($_) } ]
	} @{ $dom->find('tbody tr')->to_array };

	is_deeply [ map { $_->[2] } @rows ], [ 10, 30, 130, 330 ],
		'one of the two columns is the running total, in the order the card named';
	is_deeply [ map { $_->[3] } @rows ], [ 4, 3, 2, 1 ],
		'and the other is the rank, largest first';
};

subtest 'the add-view panel offers a plan for the card' => sub {
	$t->get_ok("/a/$own_id")->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);

	my $mode = $dom->at('#ac-cs-mode');
	ok($mode, 'the panel asks what the card should do about cross-row columns');
	is_deeply [ map { $_->{value} } @{ $mode->find('option')->to_array } ],
		[qw(inherit none own)],
		'with inherit, none and a plan of its own to choose from';

	ok($dom->at('#ac-cs-col'), 'a number column can be chosen');
	my $fns = $dom->at('#ac-cs-fn');
	ok($fns, 'and a function');
	is(scalar @{ $fns->find('option')->to_array }, 11,
		'every function the pass knows is offered');
	is($dom->at('#ac-cs-fn option[data-order="1"]') ? 1 : 0, 1,
		'and the ones that read rows in an order say so');
	ok($dom->at('#ac-cs-window'), 'the window is there for the moving functions');
	ok($dom->at('#ac-cs-alias'), 'as is a name for the new column');
	ok($dom->at('#ac-cs-order') && $dom->at('#ac-cs-dir'),
		'and the column and direction the rows are read in');
	ok($dom->at('#ac-cs-by'), 'and the partition to restart for each');

	# A card may carry several, so the fields describe one at a time and the
	# list holds the ones it will actually get -- each with a way out.
	ok($dom->at('#ac-cs-add'), 'the panel can put a column in the card\'s list');
	my $list = $dom->at('#ac-cs-list');
	ok($list, 'and the columns the card will carry are listed');
	is($list->tag, 'ul', 'as a list, so a reader hears how many there are');
	is($list->attr('aria-labelledby'), 'ac-cs-list-title',
		'named by the heading above it');
	is($dom->at('#ac-cs-list-title')->all_text, 'Columns this card will carry',
		'which says what the list is for');
	like($dom->at('#ac-cs-empty')->all_text, qr/the column described above/,
		'an empty list says the fields are the one column, so one needs no second click');
	like($dom->at('.ac-cs-addrow .ac-note')->all_text, qr/apply to every column/,
		'and the panel says the order and partition cover the whole list');
};

subtest 'a card header offers the panel that repairs its plan' => sub {
	$t->get_ok("/a/$own_id")->status_is(200);
	my $dom = Mojo::DOM->new($t->tx->res->body);

	# Every card carries the control, whatever its plan: the one with a plan of
	# its own, the one that inherits the page's, and the one that runs none.
	for my $n (0 .. 2) {
		my $card = _card($dom, $n);
		ok($card, "card $n is on the canvas");
		my $btn = $card->at('.visual-cs-btn');
		ok($btn, "card $n has an Edit cross-row control in its header");
		next unless $btn;
		like($btn->parent->attr('class') // '', qr/\bvisual-card-header\b/,
			'inside the header, where the card can be changed');
		is($btn->attr('aria-controls'), 'cr-panel', 'it says which panel it opens');
		is($btn->attr('aria-haspopup'), 'dialog', 'and that the panel is a dialog');
		is($btn->attr('aria-expanded'), 'false', 'closed until it is pressed');
		like($btn->attr('aria-label') // '', qr/\AEdit cross-row columns of \S/,
			'and is named for the card it edits');
	}

	my $panel = $dom->at('#cr-panel');
	ok($panel, 'the panel it opens is on the page');
	is($panel->attr('role'), 'dialog', 'as a dialog');
	# Mojo::DOM reads a valueless attribute as absent, so the markup is what
	# says the panel starts closed.
	like($panel->to_string, qr{\A<div\b[^>]*\bhidden\b},
		'hidden until a card asks for it');
	is($panel->attr('aria-labelledby'), 'cr-heading', 'named by its heading');

	my $mode = $panel->at('#cr-mode');
	is_deeply [ map { $_->{value} } @{ $mode->find('option')->to_array } ],
		[qw(inherit none own)],
		'the three states a saved card can be in are all offered';

	# The fields are the ones the PATCH validates, so the panel cannot build a
	# plan the server would refuse without saying why.
	for my $id (qw(cr-col cr-fn cr-window cr-alias cr-order cr-dir cr-by
				cr-list cr-add cr-save)) {
		ok($panel->at("#$id"), "the panel has $id");
	}
	is($panel->at('#cr-fn option[data-order="1"]') ? 1 : 0, 1,
		'the functions that read rows in an order say so');
	is($panel->at('#cr-save')->attr('type'), 'submit',
		'and the panel is saved by its button or by Enter');
	like($panel->at('#cr-empty')->all_text, qr/add the one described below/,
		'an empty list says what to do next rather than sitting blank');

	# The card's stored plan is listed in the same component the panel that adds
	# one uses, so a column is edited from the chip it already is rather than
	# retyped from the fields.
	my $list = $panel->at('#cr-list');
	is($list->tag, 'ul', 'the plan is listed, so a reader hears how many columns there are');
	like($list->attr('class') // '', qr/\bac-cs-list\b/,
		'as the same list Add current view draws');
	is($list->attr('aria-labelledby'), 'cr-list-title', 'named by the heading above it');
	is($panel->at('#cr-list-title')->all_text, 'Columns this card carries',
		'which says what the list is for');

	# Opening a chip puts it back in the fields; the button that adds one takes
	# a second face for that, and a way out of it is beside it and out of sight
	# until there is something to back out of.
	my $stop = $panel->at('#cr-add-cancel');
	ok($stop, 'an editor that has been reopened can be left alone');
	is($stop->all_text, 'Stop editing', 'by a control that says so');
	like($stop->to_string, qr/\bhidden\b/, 'which is out of sight until a chip is opened');
};

# ---------------------------------------------------------------------------
# Changing a chip where it stands
# ---------------------------------------------------------------------------
#
# A chip is the column it names, so it is also the control that changes it: the
# reader presses the column, the fields below take its values, and the button
# that added columns replaces that one where it sits.  Taking a column out and
# adding it again would lose its place in the plan, and the retyped one would
# have to say everything the old one said.  The script is inline, so what can
# be held here is the wiring it carries.

subtest 'a chip is reopened in the fields and changed where it stands' => sub {
	$t->get_ok("/a/$own_id")->status_is(200);
	my $body  = $t->tx->res->body;
	my $panel = Mojo::DOM->new($body)->at('#cr-panel');
	ok($panel, 'the panel that repairs a plan is on the page');

	like($panel->at('.ac-help')->all_text, qr/Press a column's name to open it/,
		'the panel says a column can be pressed to change it');
	like($panel->at('.ac-help')->all_text, qr/where it stands/,
		'and that the change lands where the column already is');

	# The chip's own column is the control, not a label with a cross beside it.
	like($body, qr/text\.className = 'ac-cs-chip-text ac-cs-edit'/,
		'the column on a chip is a control');
	like($body, qr/text\.setAttribute\('title', 'Change this column'\)/,
		'which says what pressing it does');
	like($body, qr/'Change ' \+ entry\.label/,
		'and is named for the column it would change');
	like($body, qr/if \(index === crEditing\) text\.setAttribute\('aria-pressed', 'true'\)/,
		'and says when it is the column being changed');
	like($body, qr/li\.className = 'ac-cs-chip' \+ \(index === crEditing \? ' is-editing' : ''\)/,
		'which the chip shows as well as says');

	# Pressing it puts that column in the fields, values and all.
	like($body, qr/if \(target\.classList\.contains\('ac-cs-edit'\)\) \{\s*crEditStart\(index\)/,
		'pressing a chip opens it');
	like($body, qr/crSelectValue\(crCol, parts\[0\] \|\| ''\)/,
		'with the column it was saved with');
	like($body, qr/crSelectValue\(crFn,  parts\[1\] \|\| ''\)/,
		'and the function');
	like($body, qr/crAlias\.value = parts\[2\] \|\| ''/,
		'and the name it produces');
	like($body, qr/crWin\.value +=/, 'and its window, where the function takes one');
	like($body, qr/crAdd\.textContent = 'Update column'/,
		'the button that added columns now offers to change that one');
	like($body, qr/if \(crStop\) crStop\.hidden = false/,
		'and a way out of the change appears beside it');

	# The change replaces the entry it came from, so its place in the plan is
	# the place it had: an edited column is not a second column.
	like($body, qr/var edited = crEditing;/,
		'the button knows which chip it is changing');
	like($body, qr/crSpecs\[edited\] = draft;/,
		'and writes the changed column over it rather than beside it');
	like($body, qr/crEditStop\(0\);\s*var chip = crList\.children\[edited\]/,
		'leaving the fields and the focus on where the change landed');
	like($body, qr/crSpecs\.splice\(index, 1\)/,
		'while the cross still takes a column out altogether');

	# Backing out changes nothing, and Escape backs out of the change before it
	# backs out of the panel.
	like($body, qr/crAdd\.textContent = 'Add this column'/,
		'leaving the change puts the button back as it was');
	like($body, qr/if \(crEditing >= 0\) crEditStop\(1\);\s*else crClose\(1\);/,
		'and Escape backs out of the change before the panel');
};

# ---------------------------------------------------------------------------
# A repair that renames a column the card plots
# ---------------------------------------------------------------------------
#
# A card plots a column by naming it in its encode, so a plan that produces that
# name is what the plot reads.  Renaming the plan's column in the panel leaves
# the encode pointing at a column no card has, and the server refuses the repair
# as "Column not found" whatever kind the card is.
# The panel says so while the name can still be put back, and asks again as the
# plan is saved.

subtest 'a rename a card plots is warned about before the plan is saved' => sub {
	$t->get_ok("/a/$own_id")->status_is(200);
	like $t->tx->res->body, qr{var pageAliases\s*=\s*\[\];},
		'a canvas with no cs= hands the panel no page columns';

	# A card that takes the page's plan plots the columns that plan makes, so the
	# panel is told them: without them, giving such a card no plan would look
	# free and would cost it the column it is drawn from.
	$t->get_ok("/a/$own_id?cs=amount:running_total:rt&order=day")->status_is(200);
	my $body = $t->tx->res->body;
	like $body, qr{var pageAliases\s*=\s*\["rt"\];},
		'and one with a plan hands it the columns that plan makes';

	my $panel = Mojo::DOM->new($body)->at('#cr-panel');
	my $warn  = $panel->at('#cr-warning');
	ok($warn, 'the panel has somewhere to say it');
	is($warn->attr('role'), 'status', 'spoken without interrupting what is being typed');
	like($warn->to_string, qr{\A<p\b[^>]*\bhidden\b},
		'and silent until a repair would cost the card a column');

	# What the card plots, and what a plan makes of it: only the names a plan
	# produces, so a column the data itself has is never mistaken for one.
	like($body, qr/var crPlotted = \[\];/,
		'the panel keeps the columns the card plots that a plan makes');
	like($body, qr/crPlotted = crColumnPlots\(vis\.encode \|\| \{\}/,
		"read from the card's own encode when the panel opens");
	like($body, qr/return made\.indexOf\(name\) >= 0;/,
		"and only for the names a plan produces, not the data's own columns");
	like($body, qr/if \(crMode\.value === 'inherit'\) return pageAliases\.slice\(\);/,
		"a card on the page's plan makes the page's columns");
	like($body, qr/if \(crMode\.value !== 'own'\)\s+return \[\];/,
		'and one with no plan makes none');

	# Said while it can still be undone, then asked as the plan lands -- never
	# left to the card's own error afterwards.
	like($body, qr/var text = stranded\.length \? crRenameText\(missing\)/,
		'the panel names the column the card would lose');
	like($body, qr/: crFollowText\(renamed, renames\);/,
		'and names the one it follows when the plan has renamed it');
	like($body, qr/Keep the name, or save and drop /,
		'and, where the card lists its columns, says the column can go with the plan');
	like($body, qr/Keep the name, or the repair will be refused\./,
		'while a card drawn from that column itself is told the repair would be refused');
	like($body, qr/crWarnRenames\(\);/,
		'it is said whenever the list or the mode changes');
	like($body, qr/crWarnRenames\(plan && plan\.cs \? plan\.cs : \[\]\)/,
		'and again for the plan that would be saved, the pending column read in');

	# A chip renamed where it stands is the same column under another name, so
	# the card follows it instead of losing it: the old plan's aliases are kept
	# from when the panel opened, and the save sends the card's own reference
	# pointing at the new name.
	like($body, qr/var crPlanSaved = null;/, "the card's own aliases are kept");
	like($body, qr/crPlanSaved = \(plan && typeof plan === 'object'/,
		'from the plan it was opened with');
	like($body, qr/var crRenames = function \(specs\) \{/, 'a rename is worked out');
	like($body, qr/if \(\(before\[0\] \|\| ''\) !== \(after\[0\] \|\| ''\)\) continue;/,
		'only for the same column and the same function');
	like($body, qr/if \(before\[2\]\) map\[before\[2\]\] = after\[2\];/,
		'under a different name, which is what makes it a rename');
	like($body, qr/var follow    = \[\];/, 'so the save follows it');
	like($body, qr/if \(renames\[name\]\) follow\.push\(\[name, renames\[name\]\]\);/,
		'one pair per renamed column');
	like($body, qr/payload\.encode = crRenamedEncode\(follow, drop\);/,
		"with the card's own reference moved to the new name");
	like($body, qr/encode\[key\] = value\.map\(rename\)/, 'in a list of columns');
	like($body, qr/encode\[key\] = rename\(value\);/, 'and in a field that names one');
	like($body, qr/if \(key === 'agg'\)/, 'leaving the aggregate alone, which is no column');
	like($body, qr/so the card moves with it\./, 'and the panel says so while editing');

	# What is left is a column the plan has lost, not renamed: a card that lists
	# its columns can drop it, and the save is the same one click as before.
	like($body, qr/var crDroppable = function \(names\) \{/,
		'from the columns the card holds as a list');
	like($body, qr/return crCardColumns\.indexOf\(name\) >= 0;/,
		"which is the card's own encode.columns");
	like($body, qr/crCardColumns = Array\.isArray\(crCardEncode\.columns\)/,
		'read when the panel opens');
	like($body, qr/window\.confirm\(crDropText\(drop\)\)/,
		'asked before the PATCH, not after the card has been redrawn');
	like($body, qr/body    : JSON\.stringify\(payload\)/,
		'so the rename, the drop and the plan are one save');
	like($body, qr/Not saved: this card plots/,
		'and declining leaves the card as it was');
	like($body, qr/a chart cannot be drawn without the column it plots/,
		'a column the card is drawn from is not dropped, and the panel says why');

	# What that save looks like to the server: a table that showed rt keeps the
	# column, now under the plan's new name, and the card draws.
	my $keep_id = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Carry a rename through',
			datasets => [ { spec => 'table:orders', alias => 'left' } ],
			visuals  => [
				{ kind => 'table', title => 'Totals',
				  encode => { columns => [qw(day amount rt)] } },
			],
		}),
	)->status_is(201)->tx->res->json->{id};

	# The card follows the plan: the column it listed is still there, under the
	# name the plan now gives it, so a rename does not cost the card a column.
	$t->patch_ok("/api/analyses/$keep_id/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			cross_row => { cs => ['amount:running_total:rt2'], order => ['day'] },
			encode    => { columns => [qw(day amount rt2)] },
		}),
	)->status_is(200);

	$t->get_ok("/a/$keep_id?cs=amount:running_total:rt&order=day")->status_is(200);
	my $page    = $t->tx->res->body;
	my $renamed = _card(Mojo::DOM->new($page), 0);
	is_deeply _header($renamed), [qw(day amount rt2)],
		'the card lists the column under the plan\'s new name';
	like $page, qr{<td>330</td>}, 'with the running total still in it';
	is _error($renamed), '', 'and draws, rather than reporting a column it cannot find';

	# A column taken out of the plan is not a rename: it is dropped from a card
	# that lists it, and the page still draws.
	$t->patch_ok("/api/analyses/$keep_id/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			cross_row => { cs => ['amount:rank:total'], order => ['day'] },
			encode    => { columns => [qw(day amount)] },
			query     => '?cs=amount:running_total:rt&order=day',
		}),
	)->status_is(200);

	$t->get_ok("/a/$keep_id?cs=amount:running_total:rt&order=day")->status_is(200);
	my $dropped = _card(Mojo::DOM->new($t->tx->res->body), 0);
	is_deeply _header($dropped), [qw(day amount)],
		'the card is drawn without the column the new plan does not make';
	is _error($dropped), '', 'and draws, rather than reporting a column it cannot find';

	# Dropping is the whole difference there: the same repair without it is
	# refused, which is what makes the panel's one click the difference.
	$t->patch_ok("/api/analyses/$keep_id/visuals/0",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			cross_row => { cs => ['amount:rank:total2'], order => ['day'] },
			encode    => { columns => [qw(day amount total)] },
		}),
	)->status_is(400)
	 ->json_like('/error' => qr/Column not found: total/);
};

subtest 'the canvas refuses a spec it cannot honour' => sub {
	$t->get_ok("/a/$id?cs=amount:running_total:rt")->status_is(400)
		->content_like(qr/needs order=/,
			'a stream function without order= is refused, naming the need');

	$t->get_ok("/a/$id?cs=missing:running_total:rt&order=day")->status_is(400)
		->content_like(qr/names the column "missing", which is not in this view/,
			'an unknown column is refused once, for the page');

	$t->get_ok("/a/$id?cs=amount:running_total:amount&order=day")->status_is(400)
		->content_like(qr/already a column of this view/,
			'an alias that would shadow a real column is refused');

	$t->get_ok("/a/$id?cs=amount:window_avg:ma3:3&by=region&order=day")->status_is(200)
		->content_like(qr/id="visual-0"/, 'a window over a partition still renders');
};

done_testing();
