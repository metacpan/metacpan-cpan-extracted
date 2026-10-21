use strict;
use warnings;

# The tutorial is part of the application, not the POD.  This test keeps it
# that way: the page must render, every chapter must appear in it, and every
# GET page in the application must have a chapter or a stated exemption.
#
# The route check is the maintenance tool.  When a page is added, this test
# fails until the tutorial says something about it.  When a page is renamed or
# removed, this test fails until the chapter is corrected.  A chapter is data
# in lib/Database/BI/Tutorial.pm, so the fix is one hash, not HTML.
#
# It also checks the contextual link in the shared layout: every covered page
# action must name the chapter that helps with it, so the pie chart screen
# sends the reader to the pie chart chapter rather than the tutorial's top.
# A chapter may carry a walk-through: a worked example made of do/see pairs.
# Every one of those is rendered and every sentence in it is checked for the
# same plain-English limit as the rest of the page.
# Each chapter's example link is opened too: a tutorial that promises a page
# but cannot open it is worse than one with no link at all.
#
#   prove -l t/tutorial.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Database::BI::Tutorial;

my $t = Test::Mojo->new('Database::BI');

my $chapters = Database::BI::Tutorial->chapters;
my $parts    = Database::BI::Tutorial->parts;
my $faq      = Database::BI::Tutorial->faq;
my $glossary = Database::BI::Tutorial->glossary;

# ---------------------------------------------------------------------------
# The page
# ---------------------------------------------------------------------------

subtest 'GET /tutorial renders the tutorial' => sub {
	$t->get_ok('/tutorial')->status_is(200);

	my $body = $t->tx->res->body;
	my $dom  = Mojo::DOM->new($body);

	like($body, qr/<html lang="en">/, 'the page states its language');
	like($dom->all_text, qr/\QDatabase::BI version $Database::BI::VERSION\E/,
		'the page says which version it describes');
	like($body, qr/\Q$_\E/, "the intro says: $_") for @{ Database::BI::Tutorial->intro };
	unlike($body, qr/\[%/, 'no template markup is left in the page');

	for my $part (@$parts) {
		is($dom->at("#$part->{id} h2")->text, $part->{name},
			"the page has the $part->{name} heading");
	}

	for my $chapter (@$chapters) {
		is($dom->at("#$chapter->{id} h3")->text, $chapter->{title},
			"the page shows $chapter->{title}");
		is($dom->at("#$chapter->{id} .tutorial-lead")->text, $chapter->{lead},
			"the page shows the lead for $chapter->{id}");
	}

	my $questions = $dom->at('#questions')->all_text;
	like($questions, qr/\Q$_->{question}\E/, "the page asks: $_->{question}") for @$faq;

	my $words = $dom->at('#glossary')->all_text;
	like($words, qr/\Q$_->{term}\E/, "the glossary defines $_->{term}") for @$glossary;
};

subtest 'The difficult topics have a rendered walk-through' => sub {
	$t->get_ok('/tutorial')->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);
	my @with = grep { $_->{walkthrough} } @$chapters;

	ok(@with, 'the tutorial has at least one walk-through');
	for my $id (qw(calc pivot canvas join)) {
		ok((grep { $_->{id} eq $id } @with), "$id has a walk-through");
	}

	my $toc_tags = () = $dom->at('#tutorial-contents')->all_text =~ /walk-through/g;
	is($toc_tags, scalar @with, 'every walk-through is marked in the contents');

	for my $chapter (@$chapters) {
		my $box = $dom->at("#$chapter->{id} .tutorial-walkthrough");
		my $walk = $chapter->{walkthrough};

		if (!$walk) {
			ok(!$box, "$chapter->{id}: no walk-through is rendered");
			next;
		}

		ok($box, "$chapter->{id}: the walk-through is on the page")
			or next;

		is($box->at('h4')->text, $walk->{title},
			"$chapter->{id}: the walk-through has its title");
		is($box->at('.tutorial-walkthrough-intro')->text, $walk->{intro},
			"$chapter->{id}: the walk-through has its introduction");

		my $text = $box->all_text;
		for my $step (@{ $walk->{steps} }) {
			like($text, qr/\Q$step->{do}\E/, "$chapter->{id}: it says to: $step->{do}");
			like($text, qr/\Q$step->{see}\E/, "$chapter->{id}: it shows: $step->{see}");
		}

		like($box->at('.tutorial-walkthrough-result')->all_text,
			qr/\QResult: $walk->{result}\E/,
			"$chapter->{id}: the walk-through states its result");
	}
};

subtest 'The join walk-through works on the store database' => sub {
	plan skip_all => 'data/store.db not found' unless -f 'data/store.db';

	my $path = Mojo::File->new('data/store.db')->realpath;
	my $open = '/open?path=' . Mojo::Util::url_escape("$path") . '&it=sales';

	$t->get_ok($open)->status_is(200)
		->content_like(qr{name="l" value="table:store/sales"},
			'opening sales keeps the internal table in the join spec')
		->content_like(qr{<option value="table:store/customer">store / customer</option>},
			'the join panel lists the customer table inside store');

	$t->get_ok('/api/columns?table=store%2Fcustomer')->status_is(200);
	is_deeply([sort @{ $t->tx->res->json->{columns} }], [qw(email id name)],
		'the customer table offers its id, name and email as join keys');

	my $join = '/join?l=' . Mojo::Util::url_escape('table:store/sales')
		. '&j=' . Mojo::Util::url_escape('table:store/customer|customer_id|id');

	$t->get_ok($join)->status_is(200);

	my $dom   = Mojo::DOM->new($t->tx->res->body);
	my @heads = map { my $text = $_->text; $text =~ s/\s+//g; $text }
		@{ $dom->find('thead th')->to_array };

	ok((grep { $_ eq 'name' } @heads), 'the joined table has a name column');
	ok((grep { $_ eq 'email' } @heads), 'the joined table has an email column');
	is($dom->find('tbody tr')->size, 4, 'the joined table keeps all four sales');

	my $text = $dom->at('table')->all_text;
	like($text, qr/Alice Smith/, 'the first customer name appears');
	like($text, qr/Bob Jones/,   'the second customer name appears');
	like($text, qr/Carol White/, 'the third customer name appears');
};

subtest 'Every page links to the tutorial and to its own chapter' => sub {
	$t->get_ok('/')->content_like(qr{href="/tutorial"}, 'the home page links to the tutorial');
	$t->get_ok('/view/sales')->content_like(qr{href="/tutorial"}, 'a table page links to the tutorial');

	my @cases = (
		[ '/', 'open-file', 'Open your first data file' ],
		[ '/view/sales', 'read-table', 'Read and move around a table' ],
		[ '/graph?l=table:sales&x=sale_date&y=amount', 'line-chart', 'Line chart' ],
		[ '/pie?l=table:sales&cat=region&val=amount', 'pie-chart', 'Pie chart' ],
		[ '/bar?l=table:sales&cat=region&val=amount', 'bar-chart', 'Bar chart' ],
		[ '/map?l=table:sales&lat=id&lon=id', 'map-chart', 'Map' ],
	);

	for my $case (@cases) {
		my ($url, $id, $title) = @$case;

		$t->get_ok($url)->status_is(200)
			->content_like(qr{href="/tutorial#\Q$id\E"}, "$url: Help points at $id")
			->content_like(qr{Help: \Q$title\E}, "$url: Help names $title");
	}

	$t->get_ok('/tutorial')->content_unlike(qr{class="site-nav-help"},
		'the tutorial page has no Help link to itself');
};

subtest 'The tutorial always opens in a new tab, and F1 follows the same link' => sub {
	my @urls = (
		'/',
		'/view/sales',
		'/pie?l=table:sales&cat=region&val=amount',
		'/tutorial',
	);

	for my $url (@urls) {
		$t->get_ok($url)->status_is(200);

		my $body = $t->tx->res->body;
		my $dom  = Mojo::DOM->new($body);

		# Every link into the tutorial, not just the header's, so a new entry
		# point cannot quietly replace the tutorial in the current view.
		my @links = grep { ($_->{href} // '') =~ m{\A/tutorial(?:\#|\z)} }
			@{ $dom->find('a')->to_array };

		ok(@links, "$url: it links to the tutorial");
		for my $link (@links) {
			is($link->{target}, '_blank', "$url: $link->{href} opens in a new tab");
			like($link->{rel} // '', qr/\bnoopener\b/,
				"$url: $link->{href} cannot reach back into this page");
		}

		like($body, qr/e\.key !== 'F1'/, "$url: F1 is the Help key");
		like($body, qr/link\.click\(\)/, "$url: F1 follows the header link");
	}

	# F1 must be contextual where there is a chapter: the same destination as
	# the header's Help link, not the tutorial's top.
	$t->get_ok('/pie?l=table:sales&cat=region&val=amount')->status_is(200);

	my $dom = Mojo::DOM->new($t->tx->res->body);
	is($dom->at('#site-nav-help')->{href}, '/tutorial#pie-chart',
		'the Help link is the chapter F1 opens');
};

# ---------------------------------------------------------------------------
# The chapter data
# ---------------------------------------------------------------------------

subtest 'Every chapter is complete and has a stable anchor' => sub {
	my %seen;

	for my $chapter (@$chapters) {
		my $where = $chapter->{id} // '(no id)';

		like($chapter->{id} // '', qr/\A[a-z0-9-]+\z/, "$where: the id is a link anchor");
		ok(!$seen{ $chapter->{id} }++, "$where: the id is unique");
		ok(length($chapter->{title} // ''), "$where: it has a title");
		ok(length($chapter->{part} // ''), "$where: it belongs to a part");
		ok(length($chapter->{lead} // ''), "$where: it has a one-sentence lead");
		is(ref($chapter->{steps}), 'ARRAY', "$where: the steps are a list");

		ok(@{ $chapter->{steps} } || $chapter->{table},
			"$where: it has steps or a table");

		ok(!ref($chapter->{tip}) && length($chapter->{tip} // ''),
			"$where: it has a Good to know line");

		ok(!$chapter->{routes} || ref($chapter->{routes}) eq 'ARRAY',
			"$where: the covered routes are a list");

		if ($chapter->{table}) {
			my $table = $chapter->{table};
			ok(length($table->{caption} // ''), "$where: the table has a caption");
			is(ref($table->{head}), 'ARRAY', "$where: the table has headings");
			is(ref($table->{rows}), 'ARRAY', "$where: the table has rows");
			if ($chapter->{id} eq 'chart-types') {
				my @charts = grep { $_->{chart} } @$chapters;
				is_deeply(
					[map { $_->[0] } @{ $table->{rows} }],
					[map { $_->{title} } @charts],
					"$where: the table lists every chart chapter in order",
				);
			}
			for my $row (@{ $table->{rows} }) {
				is(scalar @$row, scalar @{ $table->{head} },
					"$where: every table row has one cell per heading");
			}
		}

		if ($chapter->{try}) {
			like($chapter->{try}{href} // '', qr{\A/}, "$where: the try link is inside the application");
			ok(length($chapter->{try}{label} // ''), "$where: the try link has a label");
		}

		if ($chapter->{walkthrough}) {
			my $walk = $chapter->{walkthrough};

			ok(length($walk->{title} // ''), "$where: the walk-through has a title");
			ok(length($walk->{intro} // ''), "$where: the walk-through has an introduction");
			is(ref($walk->{steps}), 'ARRAY', "$where: the walk-through steps are a list");
			ok(@{ $walk->{steps} || [] }, "$where: the walk-through has steps");
			ok(length($walk->{result} // ''), "$where: the walk-through says what the result is");

			for my $step (@{ $walk->{steps} || [] }) {
				is(ref($step), 'HASH', "$where: a walk-through step is a pair");
				ok(length($step->{do} // ''), "$where: a walk-through step says what to do");
				ok(length($step->{see} // ''), "$where: a walk-through step says what to look for");
			}
		}
	}
};

# ---------------------------------------------------------------------------
# Example links: a reader who clicks one must land somewhere usable
# ---------------------------------------------------------------------------

subtest 'Every tutorial example link opens a usable page' => sub {
	$t->get_ok('/tutorial')->status_is(200);

	my $dom   = Mojo::DOM->new($t->tx->res->body);
	my @links = @{ $dom->find('.tutorial-try a')->to_array };

	# Read the links from the page, not only from the chapter data: that lets
	# this test follow a link that a new chapter adds, however it is written.
	my @declared = map { $_->{try}{href} } grep { $_->{try} } @$chapters;
	is_deeply(
		[ map { $_->{href} } @links ],
		\@declared,
		'each chapter with a try link renders exactly one',
	);
	ok(@links, 'the tutorial has at least one example link');

	for my $link (@links) {
		my $href  = $link->{href};
		my $label = $link->all_text;

		ok(length($label), "$href: the example link has a label");
		like($href, qr{\A/}, "$href: the example link stays inside the application");

		$t->get_ok($href)->status_is(200)->content_type_like(qr{text/html});

		my $body = $t->tx->res->body;
		my $page = Mojo::DOM->new($body);
		my $main = $page->at('main');

		unlike($body, qr/\[%/, "$href: no template markup is left in the page");
		unlike($body, qr/(?:Internal Server Error|Template process failed)/i,
			"$href: the application did not fail while rendering it");
		ok($main, "$href: the page has a main region");
		ok($main && $main->all_text =~ /\S/,
			"$href: the page has something to read");
		ok(!$page->at('.error'), "$href: the page does not show an error message");
		ok($main && $main->at('a, button, table, svg, input, select'),
			"$href: the page has something to use");

		my $title = $page->at('title');
		like($title ? $title->text : '', qr/\S/,
			"$href: the page has a title");
	}
};

# ---------------------------------------------------------------------------
# Route coverage: the reason this page stays correct
# ---------------------------------------------------------------------------

subtest 'Every GET page is covered by a chapter or exempt with a reason' => sub {
	my $source = Mojo::File->new('lib/Database/BI.pm')->slurp;
	my (%app_routes, %app_actions);

	while ($source =~ /\$r->get\(\s*(['"])([^'"]+)\1/g) {
		$app_routes{$2} = 1;
	}

	while ($source =~ /\$r->get\(\s*(['"])([^'"]+)\1\s*\)\s*->to\(\s*(['"])Dashboard#([A-Za-z0-9_]+)\3/g) {
		$app_actions{$2} = $4;
	}

	ok(keys %app_routes, 'the application routes were found');

	my $covered = Database::BI::Tutorial->covered_routes;
	my $exempt  = Database::BI::Tutorial->exempt_routes;

	for my $route (sort keys %app_routes) {
		my $chapter = $covered->{$route};

		ok($chapter || $exempt->{$route},
			"GET $route is covered by a chapter or exempt")
			or diag('Add a chapter in lib/Database/BI/Tutorial.pm, or add the route to exempt_routes() with a reason.');

		ok(!($chapter && $exempt->{$route}),
			"GET $route is not both covered and exempt")
			or diag("The route is in chapter $chapter and also in exempt_routes().");
	}

	for my $route (sort keys %$covered) {
		ok($app_routes{$route}, "the tutorial route $route still exists");

		my $action  = $app_actions{$route} // '';
		my $chapter = Database::BI::Tutorial->chapter_for_action($action);
		ok($chapter, "GET $route (action $action) has a Help chapter")
			or diag("Add $action to the action map in lib/Database/BI/Tutorial.pm.");
	}

	for my $route (sort keys %$exempt) {
		ok($app_routes{$route}, "the exempt route $route still exists");
		ok(length($exempt->{$route}), "the exemption for $route says why");
	}

	for my $chapter (@$chapters) {
		next unless $chapter->{try};

		my ($path) = $chapter->{try}{href} =~ /\A([^?#]+)/;
		ok($app_routes{$path}, "$chapter->{id}: the try link $path is a real page");
	}
};

# ---------------------------------------------------------------------------
# Plain English
# ---------------------------------------------------------------------------

subtest 'The tutorial keeps its sentences short' => sub {
	my $limit = 25;

	my @texts;
	push @texts, map { [ 'intro', $_ ] } @{ Database::BI::Tutorial->intro };
	push @texts, map { [ $faq->[$_]{question}, $faq->[$_]{answer} ] } 0 .. $#$faq;
	push @texts, map { [ $_->{term}, $_->{meaning} ] } @$glossary;

	for my $chapter (@$chapters) {
		push @texts, [ "$chapter->{id} lead", $chapter->{lead} ];
		push @texts, map { [ "$chapter->{id} step", $_ ] } @{ $chapter->{steps} };
		push @texts, [ "$chapter->{id} tip", $chapter->{tip} ];

		if ($chapter->{walkthrough}) {
			my $walk = $chapter->{walkthrough};
			push @texts, [ "$chapter->{id} walk-through title", $walk->{title} ];
			push @texts, [ "$chapter->{id} walk-through intro", $walk->{intro} ];
			push @texts, map { [ "$chapter->{id} walk-through do", $_->{do} ] } @{ $walk->{steps} };
			push @texts, map { [ "$chapter->{id} walk-through see", $_->{see} ] } @{ $walk->{steps} };
			push @texts, [ "$chapter->{id} walk-through result", $walk->{result} ];
		}
	}

	for my $text (@texts) {
		my ($where, $body) = @$text;
		my @long;

		for my $sentence (grep { /\S/ } split /(?<=[.!?])\s+/, $body) {
			my $words = () = $sentence =~ /\S+/g;
			push @long, "($words words) $sentence" if $words > $limit;
		}

		ok(!@long, "$where: no sentence is longer than $limit words")
			or diag(join("\n", @long));
	}
};

done_testing();
