#!/usr/bin/perl
use strict;
use warnings;

# ---------------------------------------------------------------------------
# Treemap colour by a measure, and the combo chart's colours (HTML::D3 0.29).
#
#   GET /treemap?color=<col>&color_agg=<fn>&color_scheme=<name>
#     shades each tile by <fn> of <col> over that tile's rows (avg when
#     color_agg= is absent), on a sequential scale (YlOrRd when the name is
#     not one of the six).  The Other tile is folded over the rows it holds,
#     not from the tiles' colours.  A colour column that is not in the view,
#     or a function that is not one, is a 400.
#   GET /combo?scheme=<name>
#     takes the bar and line colours from a categorical scheme; any other
#     name keeps steel blue and red.
#
# Both are saved in data-chart for "Add to canvas", drawn by the canvas
# cards, and offered by the table page's panels and the canvas's Add current
# view.
#
# What is NOT here: the drawn colours need a browser.
#
# data/sales.csv: North 1250, 1875; South 875.50; East 2100, 725.25; West 950.
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

my $L = 'l=' . url_escape('table:sales');
my $TREEMAP = "/treemap?$L&group=region&size=amount";
my $COMBO   = "/combo?$L&x=region&bar=amount&line=amount";

my @SEQUENTIAL  = qw(YlOrRd Blues Greens Purples RdPu YlGnBu);
my @CATEGORICAL = qw(tableau10 category10 set2 set3 paired);

sub body_of {
	my ($url, $name) = @_;
	$t->get_ok($url, $name)->status_is(200, "$name: 200");
	return $t->tx->res->body;
}

# The treemap's tiles as the script holds them: { region => colour value }.
sub tile_colours {
	my ($html) = @_;
	my ($json) = $html =~ /var rawData = (\[.*?\]);\n/;
	return undef unless defined $json;
	my %colour;
	for my $tile (@{ decode_json($json) }) {
		(my $name = $tile->{path}) =~ s{^Root/}{};
		$colour{$name} = $tile->{color_value};
	}
	return \%colour;
}

sub combo_colours {
	my ($html) = @_;
	my ($bar)  = $html =~ /var barColor\s*=\s*"([^"]*)"/;
	my ($line) = $html =~ /var lineColor\s*=\s*"([^"]*)"/;
	return [ $bar // '', $line // '' ];
}

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

# ------------------------------------------------------------------ treemap --

subtest 'no color= leaves the tiles uncoloured' => sub {
	my $body = body_of($TREEMAP, 'plain');
	my $c = tile_colours($body);
	ok $c, 'tiles found';
	ok !(grep { defined } values %$c), 'no tile has a colour value';
	ok !exists chart_spec_of($body)->{encode}{color}, 'no colour column saved';
	ok !exists chart_spec_of($body)->{options}{color_scheme}, 'no colour scale saved';
};

subtest 'color= shades each tile by the average' => sub {
	my $body = body_of("$TREEMAP&color=amount", 'avg');
	is_deeply tile_colours($body),
		{ North => 1562.5, South => 875.5, East => 1412.625, West => 950 },
		'avg(amount) per region';
	like $body, qr/interpolateYlOrRd/, 'YlOrRd by default';
	like $body, qr/colorLabel = "avg\(amount\)"/, 'the legend names the measure';
	my $spec = chart_spec_of($body);
	is $spec->{encode}{color}, 'amount', 'colour column saved';
	is $spec->{options}{color_agg}, 'avg', 'function saved';
	is $spec->{options}{color_scheme}, 'YlOrRd', 'scale saved';
	like $spec->{title}, qr/coloured by avg\(amount\)/, 'title says so';
};

subtest 'color_agg= and color_scheme=' => sub {
	my $body = body_of("$TREEMAP&color=amount&color_agg=max&color_scheme=Blues", 'max');
	is_deeply tile_colours($body),
		{ North => 1875, South => 875.5, East => 2100, West => 950 }, 'max(amount)';
	like $body, qr/interpolateBlues/, 'Blues';
	for my $s (@SEQUENTIAL) {
		like body_of("$TREEMAP&color=amount&color_scheme=$s", $s), qr/interpolate$s\b/, "$s drawn";
	}
};

subtest 'an unknown scale falls back to YlOrRd' => sub {
	for my $bad ('tableau10', 'blues', q{Blues");alert(1)//}) {
		my $body = body_of("$TREEMAP&color=amount&color_scheme=" . url_escape($bad), "scale '$bad'");
		like $body, qr/interpolateYlOrRd/, "'$bad': YlOrRd";
		unlike $body, qr/alert\(1\)/, "'$bad': not written into the page";
		is chart_spec_of($body)->{options}{color_scheme}, 'YlOrRd', "'$bad': YlOrRd saved";
	}
};

subtest 'the Other tile is folded over its own rows' => sub {
	# By count, North and East (two rows each) are the top two; South and West
	# go to Other, whose average is (875.50 + 950) / 2 -- not the average of
	# the two tiles' averages, which happens to agree here, so use max too.
	my $body = body_of("/treemap?$L&group=region&color=amount&topn=2", 'other');
	is_deeply tile_colours($body), { North => 1562.5, East => 1412.625, Other => 912.75 },
		'avg over the Other rows';
	$body = body_of("/treemap?$L&group=region&color=amount&color_agg=count&topn=2", 'other count');
	is_deeply tile_colours($body), { North => 2, East => 2, Other => 2 },
		'count over the Other rows is 2, not 1 + 1 averaged';
};

subtest 'a bad colour column or function is a 400' => sub {
	$t->get_ok("$TREEMAP&color=no_such_col")->status_is(400)
	  ->content_like(qr/Column not found: no_such_col/, 'unknown column');
	$t->get_ok("$TREEMAP&color=amount&color_agg=bogus")->status_is(400)
	  ->content_like(qr/Unknown aggregate function "bogus"/, 'unknown function');
};

subtest 'a treemap card draws its saved colour' => sub {
	my $spec = chart_spec_of(body_of("$TREEMAP&color=amount&color_agg=max&color_scheme=Greens", 'page'));
	my $body = canvas_body('From page', $spec);
	is_deeply tile_colours($body),
		{ North => 1875, South => 875.5, East => 2100, West => 950 }, 'max(amount) on the card';
	like $body, qr/interpolateGreens/, 'Greens on the card';

	$body = canvas_body('Default fn', { kind => 'treemap',
		encode => { group => 'region', value => 'amount', color => 'amount' } });
	is tile_colours($body)->{North}, 1562.5, 'no color_agg: avg';
	like $body, qr{amount by region coloured by avg\(amount\)}, 'the derived title says what colours it';
	like $body, qr/interpolateYlOrRd/, 'no color_scheme: YlOrRd';

	$body = canvas_body('Bad scale', { kind => 'treemap',
		encode  => { group => 'region', color => 'amount' },
		options => { color_scheme => q{x");alert(1)//} } });
	like $body, qr/interpolateYlOrRd/, 'a bad saved scale: YlOrRd';
	unlike $body, qr/alert\(1\)/, 'and it is not written into the page';
};

subtest 'a treemap card with a bad colour function or column reports it' => sub {
	my $body = canvas_body('Bad fn', { kind => 'treemap',
		encode  => { group => 'region', color => 'amount' },
		options => { color_agg => 'bogus' } });
	like $body, qr/Unknown aggregate function &quot;bogus&quot;|Unknown aggregate function "bogus"/,
		'the card says the function is unknown';
	ok !tile_colours($body), 'and draws no treemap';

	$body = canvas_body('Bad col', { kind => 'treemap',
		encode => { group => 'region', color => 'nope' } });
	like $body, qr/Column not found: nope/, 'the card says the column is missing';
};

# -------------------------------------------------------------------- combo --

subtest 'combo: no scheme= keeps steel blue and red' => sub {
	my $body = body_of($COMBO, 'combo plain');
	is_deeply combo_colours($body), [ 'steelblue', '#e15759' ], 'default colours';
	ok !exists((chart_spec_of($body)->{options} // {})->{scheme}), 'no scheme saved';
};

subtest 'combo: scheme= colours the bars and the line' => sub {
	my %first_two = (
		tableau10  => [ '#4e79a7', '#f28e2c' ],
		category10 => [ '#1f77b4', '#ff7f0e' ],
		set2       => [ '#66c2a5', '#fc8d62' ],
		set3       => [ '#8dd3c7', '#ffffb3' ],
		paired     => [ '#a6cee3', '#1f78b4' ],
	);
	for my $s (@CATEGORICAL) {
		my $body = body_of("$COMBO&scheme=$s", "combo $s");
		is_deeply combo_colours($body), $first_two{$s}, "$s: its first two colours";
		is chart_spec_of($body)->{options}{scheme}, $s, "$s saved";
	}
	for my $bad ('Blues', 'Set2', q{set2"]);alert(1)//}) {
		my $body = body_of("$COMBO&scheme=" . url_escape($bad), "combo '$bad'");
		is_deeply combo_colours($body), [ 'steelblue', '#e15759' ], "'$bad': default colours";
		unlike $body, qr/alert\(1\)/, "'$bad': not written into the page";
	}
};

subtest 'combo card draws its saved scheme, and ignores a bad one' => sub {
	my $spec = chart_spec_of(body_of("$COMBO&scheme=set2", 'combo page'));
	is_deeply combo_colours(canvas_body('Combo from page', $spec)), [ '#66c2a5', '#fc8d62' ],
		'set2 on the card';
	my $body = canvas_body('Combo bad', { kind => 'combo',
		encode  => { cat => 'region', bar_val => 'amount', line_val => 'amount' },
		options => { scheme => q{x"]);alert(1)//} } });
	is_deeply combo_colours($body), [ 'steelblue', '#e15759' ], 'a bad saved scheme: default';
	unlike $body, qr/alert\(1\)/, 'and it is not written into the page';
};

# ------------------------------------------------------------------- panels --

subtest 'the table page panels offer the colours' => sub {
	$t->get_ok('/view/sales')->status_is(200);
	my $dom = $t->tx->res->dom;
	my $col = $dom->at('#treemap-panel select[name="color"]');
	ok $col, 'treemap: Colour by';
	is $col && $col->at('option')->attr('value'), '', 'none first';
	my $agg = $dom->at('#treemap-panel select[name="color_agg"]');
	ok $agg && exists $agg->attr->{disabled}, 'treemap: function disabled until a column is chosen';
	my $sch = $dom->at('#treemap-panel select[name="color_scheme"]');
	ok $sch && exists $sch->attr->{disabled}, 'treemap: scale disabled until a column is chosen';
	is_deeply [ map { $_->attr('value') } $sch->find('option')->each ], \@SEQUENTIAL,
		'treemap: the six scales' if $sch;
	my $combo = $dom->at('#combo-panel select[name="scheme"]');
	ok $combo, 'combo: Colours';
	is_deeply [ map { $_->attr('value') } $combo->find('option')->each ], [ '', @CATEGORICAL ],
		'combo: default first, then the five names' if $combo;
};

subtest 'the canvas add-view panel offers the colours' => sub {
	my $body = canvas_body('Panel', { kind => 'histogram', encode => { value => 'amount' } });
	my $dom  = Mojo::DOM->new($body);
	ok $dom->at('#ac-form .ac-field[data-for="treemap"] #ac-tm-color'), 'Colour by, for a treemap';
	my $agg = $dom->at('#ac-form .ac-field[data-for="treemap"] #ac-tm-color-agg');
	ok $agg && exists $agg->attr->{disabled}, 'Colour from, disabled at first';
	my $sch = $dom->at('#ac-form .ac-field[data-for="treemap"] #ac-tm-color-scheme');
	ok $sch && exists $sch->attr->{disabled}, 'Colour scale, disabled at first';
	is_deeply [ map { $_->attr('value') } $dom->find('#ac-tm-color-scheme option')->each ], \@SEQUENTIAL,
		'the six scales';
	like $body, qr/encode\.color\s*=\s*tmColorSel\.value/, 'sent as encode.color';
	like $body, qr/options\.color_agg\s*=\s*tmColorAggSel\.value/, 'sent as options.color_agg';
	like $body, qr/options\.color_scheme\s*=\s*tmColorSchemeSel\.value/, 'sent as options.color_scheme';

	ok $dom->at('#ac-form .ac-field[data-for="combo"] #ac-combo-scheme'), 'Colours, for a combo';
	is_deeply [ map { $_->attr('value') } $dom->find('#ac-combo-scheme option')->each ], [ '', @CATEGORICAL ],
		'default first, then the five names';
	like $body, qr/options\.scheme\s*=\s*comboSchemeSel\.value/, 'sent as options.scheme';
};

done_testing();
