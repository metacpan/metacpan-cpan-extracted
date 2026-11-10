#!/usr/bin/perl
use strict;
use warnings;

# ---------------------------------------------------------------------------
# The line graph's series picker.
#
# GET /graph?series=<col> draws one line per value of the column, with or
# without agg= and span=.  The table page's graph panel offers it as "Lines by
# (optional)", whose first choice, none, sends series= empty.  This suite pins:
#   * the panel's select is named series, starts with an empty "none" option
#     and lists every column;
#   * series= empty draws the single line, the same page as no series=;
#   * series=<col> draws one named line per value, plain and aggregated;
#   * an unknown series column is a 400.
#
# What is NOT here: the drawn lines and the legend toggles need a browser.
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

# data/sales.csv: 6 rows over 2025-01-15..20; region is North South East West
# North East.
my $BASE = '/graph?l=' . url_escape('table:sales') . '&x=sale_date&y=amount';

sub body_of {
	my ($query, $name) = @_;
	$t->get_ok("$BASE$query", $name)->status_is(200);
	return $t->tx->res->body;
}

# The series array a multi-series chart is drawn from, or undef.
sub series_of {
	my ($body) = @_;
	my ($json) = $body =~ /^\s*var series = (\[.*\]);\s*$/m;
	return defined $json ? decode_json($json) : undef;
}

# The page with its data arrays taken out: their key order is random.
sub without_data {
	my ($body) = @_;
	$body =~ s/^\s*(?:const allData|var series)\s*=.*$//mg;
	# Each request has its own Content-Security-Policy nonce.
	$body =~ s/\bnonce="[^"]*"/nonce=""/g;
	# The Preferences link names the page it is on, URL and all.
	$body =~ s{(id="site-nav-preferences" href=")[^"]*"}{$1"};
	return $body;
}

subtest 'the graph panel offers Lines by' => sub {
	$t->get_ok('/view/sales')->status_is(200);
	my $panel = $t->tx->res->dom->at('#graph-panel');
	ok $panel, '#graph-panel present';
	return unless $panel;

	my $sel = $panel->at('select[name="series"]');
	ok $sel, 'a select named series in the panel';
	return unless $sel;
	is $sel->attr('id'), 'graph-series-sel', 'with its own id';
	ok $panel->at('label[for="graph-series-sel"]'), 'and a label';
	ok !exists $sel->attr->{required}, 'it is optional';

	my @values = map { $_->attr('value') } $sel->find('option')->each;
	is $values[0], '', 'the first choice is none';
	is_deeply [ sort @values[1 .. $#values] ],
		[ sort qw(id product region sales_rep amount sale_date) ],
		'then every column';
};

subtest 'series= empty is the single line' => sub {
	my $plain = body_of('', 'no series=');
	my $empty = body_of('&series=', 'series= empty');
	ok !defined series_of($plain), 'no series array without series=';
	ok !defined series_of($empty), 'no series array with series= empty';
	is without_data($empty), without_data($plain), 'the same page';
};

subtest 'series=region draws one line per region' => sub {
	my $body   = body_of('&series=region', 'series=region');
	my $series = series_of($body);
	ok $series, 'series array emitted';
	is_deeply [ sort map { $_->{name} } @{ $series // [] } ], [qw(East North South West)],
		'one line per region';
	my ($north) = grep { $_->{name} eq 'North' } @{ $series // [] };
	is_deeply [ sort map { $_->{label} } @{ $north->{data} // [] } ], [qw(2025-01-15 2025-01-19)],
		'each line holds its own rows';
	like $body, qr{<title>amount vs sale_date by region}, 'the title names the series';
};

subtest 'series= with agg= and span= totals per line' => sub {
	my $body   = body_of('&series=region&agg=sum&span=1d', 'aggregated');
	my $series = series_of($body);
	is_deeply [ sort map { $_->{name} } @{ $series // [] } ], [qw(East North South West)],
		'one line per region';
	my ($east) = grep { $_->{name} eq 'East' } @{ $series // [] };
	is_deeply [ sort { $a <=> $b } map { $_->{value} } @{ $east->{data} // [] } ], [ 725.25, 2100 ],
		'East has its two days';
};

subtest 'an unknown series column is a 400' => sub {
	$t->get_ok("$BASE&series=no_such")->status_is(400)
	  ->content_like(qr/Column not found: no_such/);
};

# ---------------------------------------------------------------------------
# The same chart as a canvas card.  "Add to canvas" saves the page's
# data-chart, so a card made from /graph?series= must draw one line per value
# too, not one line running through every group's points.
# ---------------------------------------------------------------------------

# The chart_spec the page hands to "Add to canvas".
sub chart_spec_of {
	my ($body) = @_;
	my ($json) = $body =~ /id="new-canvas-panel" data-chart="([^"]*)"/;
	return defined $json ? decode_json(html_unescape($json)) : undef;
}

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

subtest 'a card saved from /graph?series= draws one line per value' => sub {
	my $page = body_of('&series=region', 'page');
	my $spec = chart_spec_of($page);
	is_deeply $spec->{encode}, { x => 'sale_date', y => 'amount', series => 'region' },
		'data-chart encodes the series';

	my $body   = canvas_body('From page', $spec);
	my $series = series_of($body);
	ok $series, 'the card draws a multi-series chart';
	is_deeply [ map { $_->{name} } @{ $series // [] } ],
		[ map { $_->{name} } @{ series_of($page) // [] } ],
		'the same lines in the same order as the page, so the same colours';
	my ($north) = grep { $_->{name} eq 'North' } @{ $series // [] };
	is_deeply [ map { $_->{value} } @{ $north->{data} // [] } ], [ 1250, 1875 ],
		'each line holds only its own rows';
	like $body, qr/id="vis-0"/, 'drawn under the card\'s own id';
};

subtest 'an aggregated card totals per line' => sub {
	my $body = canvas_body('Aggregated', {
		kind   => 'line',
		encode => { x => 'product', y => 'amount', series => 'region', agg => 'sum' },
	});
	my $series = series_of($body);
	is_deeply [ map { $_->{name} } @{ $series // [] } ], [qw(East North South West)],
		'lines in name order';
	my ($north) = grep { $_->{name} eq 'North' } @{ $series // [] };
	is_deeply $north->{data},
		[ { label => 'Gadget Pro', value => 1875 }, { label => 'Widget A', value => 1250 } ],
		'North: one total per product, in label order';
};

subtest 'a line card without a series is unchanged' => sub {
	my $body = canvas_body('Plain', { kind => 'line', encode => { x => 'sale_date', y => 'amount' } });
	ok !defined series_of($body), 'no series array';
	like $body, qr/id="vis-0"/, 'card drawn';
};

subtest 'an unknown series column is that card\'s error' => sub {
	my $body = canvas_body('Bad series',
		{ kind => 'line', encode => { x => 'sale_date', y => 'amount', series => 'no_such' } });
	like $body, qr/Column not found: no_such/, 'reported on the card';
};

subtest 'the canvas add-view panel offers Lines by for a line card' => sub {
	my $body = canvas_body('Panel', { kind => 'line', encode => { x => 'sale_date', y => 'amount' } });
	my $dom  = Mojo::DOM->new($body);
	ok $dom->at('#ac-form .ac-field[data-for="line"] #ac-line-series'),
		'#ac-line-series is shown only for a line card';
	like $body, qr/encode\.series\s*=\s*lineSeriesSel\.value/, 'sent as encode.series';

	# What the panel sends.
	$t->post_ok('/api/analyses' => json => {
		name => 'Panel post', datasets => [ { spec => 'table:sales' } ], visuals => [],
	})->status_is(201);
	my $id = $t->tx->res->json->{id};
	$t->post_ok("/api/analyses/$id/visuals" => json => {
		kind => 'line', encode => { x => 'sale_date', y => 'amount', series => 'region' }, options => {},
	})->status_is(201);
	my $html = $t->tx->res->json->{html} // '';
	is_deeply [ sort map { $_->{name} } @{ series_of($html) // [] } ], [qw(East North South West)],
		'the added card draws one line per region';
};

done_testing();
