use strict;
use warnings;
use utf8;

# Word cloud -- GET /wordcloud.
#
# The page reads one text column, counts a word once per row, removes the
# English stopwords and draws the result with HTML::TagCloud.  The fixture is
# small enough to count by hand, and it pins the three readings that a word
# cloud gets wrong easily:
#
#   * "red apple red" counts red once, not twice -- a row is a document, so a
#     long note cannot outweigh ten short rows that say the same thing;
#   * "Red" and "red" are one word;
#   * "don't" is one word, not "don" and "t".
#
#   prove -l t/wordcloud.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::JSON qw(encode_json);
use File::Temp ();
use Encode qw(encode);

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

my @rows = ('id,note,kind');
push @rows, '1,red apple red,fruit';
push @rows, '2,red apple,fruit';
push @rows, '3,green apple,fruit';
push @rows, '4,Red pear,fruit';
push @rows, '5,the apple and the pear,mixed';
push @rows, '6,,mixed';
push @rows, "7,don't stop,mixed";
push @rows, '8,<b>bold</b>,mixed';
Mojo::File->new($data_dir)->child('notes.csv')->spew(join("\n", @rows) . "\n");

# A second file for the encoding check: the bytes on disc are UTF-8, and the
# drill-down URL has to carry the word as UTF-8 as well.
my $accented = "id,note\n1,café\n2,Café\n3,naïve\n";
Mojo::File->new($data_dir)->child('accented.csv')->spew(encode('UTF-8', $accented));

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

# _cells($row) -> arrayref of the <td> elements of one table row, in order
#
# Read from the row's own child nodes rather than through children('td').  A
# selector puts the read in Mojo::DOM::CSS's hands, and that is where a harness
# goes wrong quietly: on a node with no root above it (a text node, a row taken
# out of its tree) a plain read answers with the node above it, and a selector
# that asks for the root -- matching, or :scope -- walks the parent pointers
# forever instead of returning.  A hang reports nothing, so the cells are taken
# without asking CSS anything.
sub _cells {
	my ($row) = @_;
	return [] unless $row && $row->type eq 'tag';
	return [
		grep { $_->type eq 'tag' && $_->tag eq 'td' } @{ $row->child_nodes }
	];
}

# The word/count table, in the order the page shows it: count descending, then
# alphabetically, which is the order HTML::TagCloud ranks words by.
sub _counts {
	my ($body) = @_;
	my $dom = Mojo::DOM->new($body);
	my @counts;
	for my $tr (@{ $dom->find('.wordcloud-counts tbody tr')->to_array }) {
		# all_text(), not text(): a linked word is a child element, and text()
		# reads only a node's own text, so a count table with drill-down links
		# would look empty.
		my @cell = map { $_->all_text } @{ _cells($tr) };
		push @counts, [ $cell[0], $cell[1] + 0 ];
	}
	return \@counts;
}

sub _cloud_words {
	my ($body) = @_;
	my $cloud = Mojo::DOM->new($body)->at('#htmltagcloud');
	return [] unless $cloud;
	return [ grep { length } split /\s+/, $cloud->all_text ];
}

sub _cloud_links {
	my ($body) = @_;
	return [ @{ Mojo::DOM->new($body)->find('#htmltagcloud a')->to_array } ];
}

# ---------------------------------------------------------------------------
# What the cloud says
# ---------------------------------------------------------------------------

# The reader every count assertion goes through is checked on its own: a wrong
# one would hang the suite rather than fail it, and a hook that hangs reports
# nothing.
subtest 'the cell reader reads a row\'s children, not a selector' => sub {
	my $dom = Mojo::DOM->new(
		"<table><tbody><tr>\n\t<td>word</td>\n\t<td>3</td>\n</tr></tbody></table>");
	my $row = $dom->at('tbody tr');
	ok($row, 'a row to read');
	is_deeply [ map { $_->all_text } @{ _cells($row) } ], [ 'word', '3' ],
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

subtest 'a word counts once per row, whatever its case' => sub {
	$t->get_ok('/wordcloud?l=table:notes&col=note')->status_is(200);

	my $body = $t->tx->res->body;

	is_deeply(
		_counts($body),
		[
			[ 'apple', 4 ], [ 'red', 3 ], [ 'pear', 2 ],
			[ 'bold', 1 ], [ "don't", 1 ], [ 'green', 1 ], [ 'stop', 1 ],
		],
		'every word and count: apple in four rows, red in three (not four), then the single rows',
	);

	# The cloud itself is alphabetical, as HTML::TagCloud draws it, with the
	# font size carrying the rank rather than the position.
	is_deeply(
		_cloud_words($body),
		[ 'apple', 'bold', "don't", 'green', 'pear', 'red', 'stop' ],
		'the cloud shows every word once, alphabetically',
	);

	my $dom  = Mojo::DOM->new($body);
	my $size = sub {
		my ($word) = @_;
		for my $span (@{ $dom->find('#htmltagcloud span')->to_array }) {
			next unless $span->all_text eq $word;
			my ($level) = ($span->{class} // '') =~ /tagcloud(\d+)/;
			return $level // -1;
		}
		return -1;
	};
	cmp_ok($size->('apple'), '>', $size->('stop'),
		'the word in more rows is drawn larger');

	like($dom->at('.graph-point-count')->text, qr/7 of 7 different words/,
		'the page says how many different words there are');
	like($dom->at('.graph-point-count')->text, qr/13 words in 8 rows/,
		'and how many words and rows it read');

	# The stopwords are the point of the list: without them the cloud is a
	# picture of English grammar.
	unlike($body, qr/>the</, 'the stopword "the" is not a tag');
	unlike($body, qr/>and</, 'nor is "and"');

	ok(!$dom->at('#htmltagcloud b'), 'markup inside a cell does not become markup in the page');
	like($dom->at('#htmltagcloud')->all_text, qr/\bbold\b/,
		'but the word inside it is still counted');
};

# ---------------------------------------------------------------------------
# The three knobs
# ---------------------------------------------------------------------------

subtest 'topn, minlen and stop narrow the cloud' => sub {
	$t->get_ok('/wordcloud?l=table:notes&col=note&topn=2')->status_is(200);
	is_deeply(_counts($t->tx->res->body),
		[ [ 'apple', 4 ], [ 'red', 3 ] ],
		'topn=2 keeps the two biggest words');
	like($t->tx->res->body, qr/2 of 7 different words/,
		'and the summary still counts every different word');

	$t->get_ok('/wordcloud?l=table:notes&col=note&minlen=5')->status_is(200);
	is_deeply(_counts($t->tx->res->body),
		[ [ 'apple', 4 ], [ "don't", 1 ], [ 'green', 1 ] ],
		'minlen=5 drops every word shorter than five characters');

	$t->get_ok('/wordcloud?l=table:notes&col=note&stop=apple,pear')->status_is(200);
	is_deeply(_counts($t->tx->res->body),
		[ [ 'red', 3 ], [ 'bold', 1 ], [ "don't", 1 ], [ 'green', 1 ], [ 'stop', 1 ] ],
		'stop= adds the words the reader does not want, and keeps the built-in list');

	# A count that is absent or unreadable is the default, not a clamp of one:
	# ?topn= with nothing after it must not silently show a single word.
	$t->get_ok('/wordcloud?l=table:notes&col=note&topn=')->status_is(200);
	is(scalar @{ _counts($t->tx->res->body) }, 7, 'an empty topn= shows the default');

	$t->get_ok('/wordcloud?l=table:notes&col=note&topn=abc')->status_is(200);
	is(scalar @{ _counts($t->tx->res->body) }, 7, 'an unreadable topn= shows the default');

	# A minimum of zero is a minimum of one: the clamp is real, and a
	# single-letter word appears only because it was asked for.
	$t->get_ok('/wordcloud?l=table:notes&col=note&minlen=0')->status_is(200);
	my $single = _counts($t->tx->res->body);
	ok((grep { $_->[0] eq 'b' } @$single),
		'minlen=0 is clamped to 1, so one-letter words are counted');
};

# ---------------------------------------------------------------------------
# The pipeline around it
# ---------------------------------------------------------------------------

subtest 'a filter narrows the words as well as the rows' => sub {
	$t->get_ok('/wordcloud?l=table:notes&col=note&f=kind:eq:fruit')->status_is(200);
	is_deeply(_counts($t->tx->res->body),
		[ [ 'apple', 3 ], [ 'red', 3 ], [ 'green', 1 ], [ 'pear', 1 ] ],
		'only the fruit rows are read');
	like($t->tx->res->body, qr/8 words in 4 rows/, 'and the summary says so');
};

subtest 'the route refuses what it cannot draw' => sub {
	$t->get_ok('/wordcloud?l=table:notes')->status_is(400)
		->content_like(qr/Missing col= parameter/);

	$t->get_ok('/wordcloud?l=table:notes&col=nope')->status_is(400)
		->content_like(qr/Column not found: nope/);

	$t->get_ok('/wordcloud?l=table:nosuch&col=note')->status_is(404)
		->content_like(qr/Could not open data source/);

	$t->get_ok('/wordcloud?l=table:notes&col=note&f=kind:eq:none')->status_is(200);
	my $body = $t->tx->res->body;
	like($body, qr/No words:/, 'an empty view says why there is nothing to draw');
	unlike($body, qr/id="htmltagcloud"/, 'and draws no cloud');
};

# ---------------------------------------------------------------------------
# Drill-down
# ---------------------------------------------------------------------------

subtest 'each word links to the rows that contain it' => sub {
	$t->get_ok('/wordcloud?l=table:notes&col=note&back=%2Fview%2Fnotes')->status_is(200);

	my $body  = $t->tx->res->body;
	my $links = _cloud_links($body);

	is(scalar @$links, 7, 'every word is a link when the page knows where it came from');

	my ($apple) = grep { $_->text eq 'apple' } @$links;
	ok($apple, 'the word is the link text');
	like($apple->{href}, qr{\A/view/notes\?f=note%3Acontains%3Aapple},
		'the link filters the view to that word');
	like($apple->{href}, qr{&back2=%2Fwordcloud%3F}, 'and comes back to the cloud');
	like($apple->{href}, qr{back2_label=Back%20to%20word%20cloud}, 'with a label for the breadcrumb');

	is(Mojo::DOM->new($body)->at('.wordcloud-counts tbody tr a')->{href}, $apple->{href},
		'the counts table links the same way');

	my ($back_link) = grep { ($_->{href} // '') eq '/view/notes' }
		@{ Mojo::DOM->new($body)->find('.back-link a')->to_array };
	ok($back_link, 'the breadcrumb links to the page the cloud came from');
	is($back_link ? $back_link->text : '', 'notes', 'and names it');

	# A bare URL has no table to filter, so a click has nowhere to go: better a
	# cloud that is only a picture than a link to "/?f=...".
	$t->get_ok('/wordcloud?l=table:notes&col=note')->status_is(200);
	is(scalar @{ _cloud_links($t->tx->res->body) }, 0,
		'a cloud opened without back= is not a set of dead links');
};

subtest 'a word that needs encoding survives the link' => sub {
	$t->get_ok('/wordcloud?l=table:accented&col=note&back=%2Fview%2Faccented')->status_is(200);

	# The response body is bytes, so the words are compared as the UTF-8 bytes
	# a browser reads, not as the characters this file is written in.
	my $CAFE  = "caf\x{c3}\x{a9}";
	my $NAIVE = "na\x{c3}\x{af}ve";
	my $body  = $t->tx->res->body;

	is_deeply(_counts($body), [ [ $CAFE, 2 ], [ $NAIVE, 1 ] ],
		'accented words are counted as words, in either case');

	my ($cafe) = grep { $_->all_text eq $CAFE } @{ _cloud_links($body) };
	ok($cafe, 'the accented word is a link');
	like($cafe->{href}, qr{f=note%3Acontains%3Acaf%C3%A9},
		'and the filter value is percent-encoded as UTF-8, not as Latin-1');
};

# ---------------------------------------------------------------------------
# The way in
# ---------------------------------------------------------------------------

subtest 'the table page offers the cloud' => sub {
	$t->get_ok('/view/notes')->status_is(200);

	my $body = $t->tx->res->body;
	my $dom  = Mojo::DOM->new($body);

	ok($dom->at('#btn-wordcloud'), 'the toolbar has a Word cloud button');
	is($dom->at('#wordcloud-form')->{action}, '/wordcloud', 'the panel submits to the route');
	is($dom->at('#wordcloud-col-sel')->{name}, 'col', 'the panel asks for a text column');
	is($dom->at('#wordcloud-topn-inp')->{name}, 'topn', 'and for how many words to show');
	is($dom->at('#wordcloud-minlen-inp')->{name}, 'minlen', 'and for the shortest word');
	ok($dom->at('#btn-do-wordcloud'), 'the panel has a submit button');

	# Every other panel closes when this one opens: the panel is in the one
	# list of panels biClosePanels() walks.
	my ($list) = $body =~ /var BI_PANELS = \[([^\]]*)\]/;
	like($list // '', qr/'wordcloud-panel'/, 'the panel is in BI_PANELS');
};

# ---------------------------------------------------------------------------
# The cloud as a card on a saved canvas
# ---------------------------------------------------------------------------
#
# A canvas holds the cloud as a card of its own, counted from that card's rows
# by the same function the page uses -- so the two cannot disagree about what a
# word is worth -- and drawn without HTML::TagCloud's page-wide style sheet.

# The words a card shows, in the order it shows them (the module's alphabetical
# order), with the size written on each word.
sub _card_words {
	my ($html) = @_;
	my @words;
	for my $word (@{ Mojo::DOM->new($html)->find('.wordcloud-word')->to_array }) {
		my ($size) = ($word->{style} // '') =~ /font-size:\s*(\d+)px/;
		push @words, [ $word->all_text, $size // -1 ];
	}
	return \@words;
}

my $canvas_id;

subtest 'a saved canvas can hold a word-cloud card' => sub {
	my $created = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Cloud canvas',
			datasets => [ { spec => 'table:notes', alias => 'left' } ],
		})
	)->status_is(201)->tx->res->json;
	$canvas_id = $created->{id};
	ok($canvas_id, 'the canvas is saved');

	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'wordcloud',
			encode => { col => 'note' },
			options => { topn => 3 },
		})
	)->status_is(201)
	 ->json_is('/visual' => 0)
	 ->json_is('/kind'   => 'wordcloud')
	 ->json_is('/title'  => 'Words in note');

	my $html = $t->tx->res->json->{html};
	my $dom  = Mojo::DOM->new($html);

	is_deeply(
		[ map { $_->[0] } @{ _card_words($html) } ],
		[ 'apple', 'pear', 'red' ],
		'topn=3 keeps the three words the page would rank first, drawn as it draws them',
	);
	like($dom->at('.wordcloud-summary')->all_text, qr/3 of 7 different words/,
		'and the card says how many different words the column has');
	like($dom->at('.wordcloud-summary')->all_text, qr/13 words in 8 rows/,
		'and how many words and rows it read');

	my %size = map { $_->[0] => $_->[1] } @{ _card_words($html) };
	cmp_ok($size{apple}, '>', $size{pear},
		'a word in more rows is drawn larger');
	unlike($html, qr/id="htmltagcloud"/,
		'the card carries no page-wide id, so two clouds on a canvas cannot clash');
};

subtest 'the word cloud page offers to save itself to a canvas' => sub {
	my $body = $t->get_ok('/wordcloud?l=table:notes&col=note&topn=3&minlen=4&stop=pear&back=/view/notes')
		->status_is(200)->tx->res->body;
	my $dom = Mojo::DOM->new($body);

	ok($dom->at('#new-canvas-btn'),    'the page has a New canvas button');
	ok($dom->at('#add-to-canvas-btn'), 'and an Add to existing canvas button');

	my $panel = $dom->at('#new-canvas-panel');
	ok($panel, 'the New canvas panel is on the page') or return;
	my $spec = Mojo::JSON::decode_json($panel->{'data-chart'});
	is($spec->{kind}, 'wordcloud', 'the spec is a word-cloud card');
	is_deeply($spec->{encode}, { col => 'note' }, 'of the column the page draws');
	is_deeply($spec->{options}, { topn => 3, minlen => 4, stop => 'pear' },
		'with the page\'s own counts and stopwords');

	# What the buttons send is that spec; a canvas has to draw it as a card.
	my $created = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Saved from the page',
			datasets => [ { spec => 'table:notes', alias => 'left' } ],
			visuals  => [ { kind => $spec->{kind}, encode => $spec->{encode},
				options => $spec->{options}, title => $spec->{title} } ],
		})
	)->status_is(201)->tx->res->json;
	my $page = $t->get_ok("/a/$created->{id}")->status_is(200)->tx->res->body;
	my @words = map { $_->[0] } @{ _card_words($page) };
	ok(scalar(@words) && scalar(@words) <= 3, 'the canvas draws the cloud with topn=3');
	ok(!(grep { $_ eq 'pear' } @words), 'and keeps the page\'s stopword out');
	ok(!(grep { length($_) < 4 } @words), 'and its shortest-word limit');
	$t->delete_ok("/api/analyses/$created->{id}");
};

subtest 'the card is drawn from the rows it is given, not the whole file' => sub {
	# The same card, added while the canvas is cross-filtered: the card counts
	# the fruit rows only, as the cards beside it would.
	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'wordcloud',
			encode => { col => 'note' },
			query  => '?cf=kind:eq:fruit',
		})
	)->status_is(201)->json_is('/visual' => 1);

	my $html = $t->tx->res->json->{html};
	is_deeply(
		[ map { $_->[0] } @{ _card_words($html) } ],
		[ 'apple', 'green', 'pear', 'red' ],
		'only the fruit rows are counted',
	);
	unlike($html, qr/bold/, '"the" and "and" are still stopwords, and no other word leaks in');
	like(Mojo::DOM->new($html)->at('.wordcloud-summary')->all_text,
		qr/8 words in 4 rows/, 'and the summary says which rows it read');
};

subtest 'the card takes the same two counts as the page' => sub {
	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind    => 'wordcloud',
			encode  => { col => 'note' },
			options => { minlen => 5, topn => 1000, stop => 'apple' },
		})
	)->status_is(201);

	is_deeply(
		[ map { $_->[0] } @{ _card_words($t->tx->res->json->{html}) } ],
		[ "don't", 'green' ],
		'minlen and stop narrow the card; a topn past the maximum is only capped',
	);

	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'wordcloud',
			encode => { col => 'note' },
			query  => '?cf=kind:eq:none',
		})
	)->status_is(201);
	like($t->tx->res->json->{html}, qr/No words:/,
		'a card whose rows say nothing explains itself instead of failing');
};

subtest 'the card refuses what the page refuses' => sub {
	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'wordcloud', encode => {} }),
	)->status_is(400)->json_like('/error' => qr/Missing col/);

	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({ kind => 'wordcloud', encode => { col => 'nope' } }),
	)->status_is(400)->json_like('/error' => qr/Column not found: nope/);

	$t->get_ok("/api/analyses/$canvas_id")->status_is(200);
	is(scalar @{ $t->tx->res->json->{visuals} }, 4,
		'no refused card was appended');
};

subtest 'a word is a control that cross-filters the canvas' => sub {
	$t->get_ok("/a/$canvas_id")->status_is(200);

	my $dom   = Mojo::DOM->new($t->tx->res->body);
	my @cards = @{ $dom->find('.visual-card')->to_array };
	my @links = @{ $cards[0]->find('a.wordcloud-word')->to_array };
	ok(scalar @links, 'the words of a word-cloud card are links, not labels');

	my ($apple) = grep { $_->all_text eq 'apple' } @links;
	ok($apple, 'each word is a control of its own');
	is($apple->attr('data-cf-value'), 'apple',
		'carrying the word as written, for the script to filter by');
	is($apple->attr('href'), '?cf=note%3Acontains%3Aapple&cv=0',
		'and a URL that filters this canvas to the rows that contain it, naming'
			. ' this card as the filter source');
	like($apple->attr('aria-label') // '', qr/\AFilter by note: apple\z/,
		'which the word says, since a word alone does not say what a click does');
	is($apple->attr('aria-describedby'), 'cf-help',
		'and it points at the canvas help, so pressing Enter on it is explained');
	my $help = $dom->at('#cf-help');
	like($help->all_text, qr/word-cloud\s+card/, 'the help speaks of words as well as marks');
	like($help->all_text, qr/rows that contain it/,
		'and says what a word filters by, which a mark does not');

	# An apostrophe is part of a word, so it has to survive both the attribute
	# and the URL: data-cf-value is the word as written, the href percent-encoded.
	my ($dont) = grep { $_->all_text eq "don't" } @{ $cards[2]->find('a.wordcloud-word')->to_array };
	ok($dont, 'a word with an apostrophe is a control too');
	is($dont->attr('data-cf-value'), "don't", 'the script reads it as one word');
	is($dont->attr('href'), '?cf=note%3Acontains%3Adon%27t&cv=2',
		'and the URL carries it whole');

	# Follow the URL the card itself writes: the card that was clicked keeps its
	# whole cloud, and every other card is the rows that contain the word.
	$t->get_ok("/a/$canvas_id?cf=note%3Acontains%3Ared&cv=0")->status_is(200);
	$dom = Mojo::DOM->new($t->tx->res->body);
	my @after = @{ $dom->find('.visual-card')->to_array };
	like($after[0]->at('.wordcloud-summary')->all_text, qr/13 words in 8 rows/,
		'the card that was clicked is still drawn from all its rows');
	like($after[1]->at('.wordcloud-summary')->all_text, qr/6 words in 3 rows/,
		'and the cards beside it are the three rows that say "red"');
	is($after[0]->{class} // '', 'visual-card cf-source',
		'the clicking card is marked as the source of the filter');
	like($dom->at('.cf-chip')->all_text, qr/note contains red/,
		'and the chip says which word the canvas is filtered by');
};

subtest 'the canvas page draws the card and offers the view' => sub {
	$t->get_ok("/a/$canvas_id")->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);
	ok($dom->at('.wordcloud-card'), 'the canvas draws the word-cloud card');
	is($dom->at('.wordcloud-card')->{ 'data-col' }, 'note',
		'and the card remembers which column it reads');
	like($dom->at('.visual-card-title')->all_text, qr/Words in note/,
		'the card has a title of its own');

	my $kinds = $dom->at('#ac-kind');
	ok($kinds, 'the add-view panel is on a saved canvas');
	ok(scalar(grep { ($_->{value} // '') eq 'wordcloud' } @{ $kinds->find('option')->to_array }),
		'and offers a word cloud');
	is($dom->at('#ac-wc-col')->{id},  'ac-wc-col',  'the panel asks for a text column');
	is($dom->at('#ac-wc-topn')->{id}, 'ac-wc-topn', 'and for how many words to show');
	is($dom->at('#ac-wc-minlen')->{id}, 'ac-wc-minlen', 'and for the shortest word');
	is(scalar @{ $dom->find('#ac-form .ac-field[data-for="wordcloud"]')->to_array }, 3,
		'the three fields are shown only for this view');
	like($dom->at('#ac-form .ac-field[data-label="Title (optional)"]')->{ 'data-for' },
		qr/\bwordcloud\b/, 'a word-cloud card can be titled like any other');
};

done_testing();
