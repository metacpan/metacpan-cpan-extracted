#!/usr/bin/perl
use strict;
use warnings;

# ---------------------------------------------------------------------------
# The histogram's bar colour: GET /histogram?scheme=<name>.
#
# HTML::D3 fills a histogram's bars with the first colour of a categorical
# scheme when given one, and steelblue otherwise.  This suite pins:
#   * no scheme= keeps steelblue, and saves no scheme in data-chart;
#   * each of the five names fills the bars with its first colour, and is
#     saved in data-chart for "Add to canvas";
#   * any other name is ignored -- steelblue, nothing saved, nothing of it in
#     the script -- as bar and pie charts ignore one;
#   * a canvas histogram card draws its saved scheme, and ignores a bad one;
#   * the table page's histogram panel and the canvas's Add current view both
#     offer the five names, with steel blue first.
#
# What is NOT here: the drawn bars need a browser.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::DOM ();
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(url_escape html_unescape);

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

plan skip_all => 'data/sales.csv not found' unless -f 'data/sales.csv';

my $BASE = '/histogram?l=' . url_escape('table:sales') . '&col=amount';

# First colour of each categorical palette, as HTML::D3 writes it.
my %FIRST_COLOUR = (
	tableau10  => '#4e79a7',
	category10 => '#1f77b4',
	set2       => '#66c2a5',
	set3       => '#8dd3c7',
	paired     => '#a6cee3',
);
my @SCHEMES = qw(tableau10 category10 set2 set3 paired);

sub body_of {
	my ($query, $name) = @_;
	$t->get_ok("$BASE$query", $name)->status_is(200);
	return $t->tx->res->body;
}

# The bar fill as the script sets it.
sub fill_of {
	my ($html) = @_;
	my ($fill) = $html =~ /\.attr\("fill",\s*([^)]*\]\[0\]|"[^"]*")\)/;
	return $fill // '';
}

sub chart_spec_of {
	my ($body) = @_;
	my ($json) = $body =~ /id="new-canvas-panel" data-chart="([^"]*)"/;
	return defined $json ? decode_json(html_unescape($json)) : undef;
}

subtest 'no scheme= keeps steelblue' => sub {
	my $body = body_of('', 'plain');
	is fill_of($body), '"steelblue"', 'bars are steelblue';
	is_deeply chart_spec_of($body)->{options}, { bins => 10 }, 'no scheme saved';
};

subtest 'each scheme fills the bars with its first colour' => sub {
	for my $scheme (@SCHEMES) {
		my $body = body_of("&scheme=$scheme", "scheme=$scheme");
		like fill_of($body), qr/^\['\Q$FIRST_COLOUR{$scheme}\E'.*\]\[0\]$/, "$scheme: first colour";
		is chart_spec_of($body)->{options}{scheme}, $scheme, "$scheme saved in data-chart";
	}
};

subtest 'any other scheme is ignored' => sub {
	for my $bad ('Blues', 'Set2', '', q{tableau10"]);alert(1)//}) {
		my $body = body_of('&scheme=' . url_escape($bad), "scheme='$bad'");
		is fill_of($body), '"steelblue"', "'$bad': bars are steelblue";
		ok !exists chart_spec_of($body)->{options}{scheme}, "'$bad': no scheme saved";
	}
	my $body = body_of('&scheme=' . url_escape(q{x"]);alert(1)//}), 'hostile');
	unlike $body, qr/alert\(1\)/, 'a hostile name is nowhere in the page';
};

# A canvas over data/sales.csv holding the given visuals; returns the page body.
sub canvas_body {
	my ($name, @visuals) = @_;
	$t->post_ok('/api/analyses' => json => {
		name     => $name,
		datasets => [ { spec => 'table:sales' } ],
		visuals  => \@visuals,
	})->status_is(201, "$name: canvas created");
	my $id = $t->tx->res->json->{id};
	$t->get_ok("/a/$id")->status_is(200, "$name: canvas drawn");
	return $t->tx->res->body;
}

subtest 'a card saved from /histogram?scheme= keeps its colour' => sub {
	my $spec = chart_spec_of(body_of('&scheme=set2&bins=4', 'page'));
	my $body = canvas_body('From page', $spec);
	like fill_of($body), qr/^\['\Q$FIRST_COLOUR{set2}\E'/, 'set2 on the card';
};

subtest 'a card without a scheme, or with a bad one, is steelblue' => sub {
	for my $options ({ bins => 5 }, { bins => 5, scheme => 'Blues' },
	                 { bins => 5, scheme => q{x"]);alert(1)//} }) {
		my $label = $options->{scheme} // 'none';
		# The canvas name is shown on the page, so it must not hold the scheme.
		my $body  = canvas_body('Card',
			{ kind => 'histogram', encode => { value => 'amount' }, options => $options });
		is fill_of($body), '"steelblue"', "scheme $label: steelblue";
		unlike $body, qr/alert\(1\)/, "scheme $label: not written into the page";
	}
};

subtest 'the histogram panel offers Bar colour' => sub {
	$t->get_ok('/view/sales')->status_is(200);
	my $sel = $t->tx->res->dom->at('#histogram-panel select[name="scheme"]');
	ok $sel, 'a select named scheme in #histogram-panel';
	return unless $sel;
	is_deeply [ map { $_->attr('value') } $sel->find('option')->each ], [ '', @SCHEMES ],
		'steel blue first, then the five names';
};

subtest 'the canvas add-view panel offers Bar colour for a histogram' => sub {
	my $body = canvas_body('Panel', { kind => 'histogram', encode => { value => 'amount' } });
	my $dom  = Mojo::DOM->new($body);
	my $sel  = $dom->at('#ac-form .ac-field[data-for="histogram"] #ac-hist-scheme');
	ok $sel, '#ac-hist-scheme is shown only for a histogram';
	is_deeply [ map { $_->attr('value') } $dom->find('#ac-hist-scheme option')->each ], [ '', @SCHEMES ],
		'steel blue first, then the five names';
	like $body, qr/options\.scheme\s*=\s*histSchemeSel\.value/, 'sent as options.scheme';

	$t->post_ok('/api/analyses' => json => {
		name => 'Panel post', datasets => [ { spec => 'table:sales' } ], visuals => [],
	})->status_is(201);
	my $id = $t->tx->res->json->{id};
	$t->post_ok("/api/analyses/$id/visuals" => json => {
		kind => 'histogram', encode => { value => 'amount' }, options => { bins => 10, scheme => 'paired' },
	})->status_is(201);
	like fill_of($t->tx->res->json->{html} // ''), qr/^\['\Q$FIRST_COLOUR{paired}\E'/,
		'the added card draws paired';
};

done_testing();
