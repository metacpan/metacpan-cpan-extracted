#!/usr/bin/perl
use strict;
use warnings;

# ---------------------------------------------------------------------------
# Pre-binned histogram (HTML::D3 >= 0.20) from the Database::BI side.
#
# HTML::D3 0.20 added a "binned" input mode to render_histogram_snippet: the
# caller supplies [ { label, count, lo, hi }, ... ] and the snippet treats those
# counts as authoritative, drawing one bar per entry instead of calling
# d3.bin() in the browser.  /histogram uses that mode (Dashboard.pm
# histogram_view passes binned => 1), so the bins shown to the user are the
# ones BI computed over the filtered records -- which is what makes them
# testable without a browser.
#
# This suite pins the contract end to end:
#   * the labels and counts in the page equal an independently computed
#     expectation for the same fixture (not just "a chart rendered");
#   * the default is 10 bins and ?bins= clamps to 1..200 without a 500;
#   * a value equal to the maximum lands in the highest bin, so a bins=N
#     request draws N bars and no separate overflow bar;
#   * the emitted markup contains BI's pre-binned array and no d3.bin() call,
#     which is exactly what regresses if the installed HTML::D3 is older than
#     0.20 (the raw-value path bins client-side);
#   * the bins agree with ?c=band:bin(value,width) on the same width, i.e. the
#     histogram edge and the calculated-column label cannot disagree.
#
# What is NOT here: the rendered SVG geometry and the exported PNG/SVG need a
# browser and are checked manually.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mojo;
use File::Spec ();
use File::Temp qw(tempdir);
use Mojo::File ();
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(url_escape);

# Test::Mojo must be constructed before the model store is touched so the
# Bootstrap/CHECK-phase ordering used by the rest of the suite is preserved.
my $t = Test::Mojo->new('Database::BI');

# Never write into the workspace's .bi/models.json.
my $TEST_MODEL_DIR = tempdir(CLEANUP => 1);
$t->app->config->{model_dir} = $TEST_MODEL_DIR;

# ---------------------------------------------------------------------------
# Fixture: 12 rows spanning 0..110 in steps of 10.  Every bin is non-empty for
# both bins=5 (width 22) and the default bins=10 (width 11), and the top edge
# is the maximum value, so the "max lands in the highest bin" rule is
# observable rather than hypothetical.
# ---------------------------------------------------------------------------

my @VALUES = map { $_ * 10 } 0 .. 11;
my @LABELS = ('a' .. 'l');

my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'binned_src.csv');
Mojo::File->new($csv)->spurt(
	"value,label\n"
	. join('', map { "$VALUES[$_],$LABELS[$_]\n" } 0 .. $#VALUES)
);
my $LSPEC = url_escape("path:$csv");

# A single-distinct-value fixture: min == max, which takes the one-bin path.
my $flat_csv = File::Spec->catfile($dir, 'binned_flat.csv');
Mojo::File->new($flat_csv)->spurt("value\n5\n5\n5\n");
my $FLAT_LSPEC = url_escape("path:$flat_csv");

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Independent restatement of the documented binning contract: ceil-free
# equal-width bins spanning [min,max]; the maximum belongs to the top bin.
# Deliberately written differently from Dashboard.pm (int+epsilon rather than
# sprintf('%.10g')+floor) so a change in either implementation shows up here.
# Returns [ { label => '[lo,hi)', count => N }, ... ] for non-empty bins only.
sub expected_bins {
	my ($values, $bins) = @_;

	my ($min, $max) = ($values->[0], $values->[0]);
	for my $v (@$values) {
		$min = $v if $v < $min;
		$max = $v if $v > $max;
	}

	return ({ label => "$min", count => scalar @$values }) if $min == $max;

	my $width = ($max - $min) / $bins;
	my $fmt   = ($width == int $width) ? '%d' : '%g';

	my @counts = (0) x $bins;
	for my $v (@$values) {
		my $i = int(($v - $min) / $width + 1e-9);
		$i = $bins - 1 if $i >= $bins;
		$i = 0         if $i < 0;
		$counts[$i]++;
	}

	my @out;
	for my $i (0 .. $bins - 1) {
		next unless $counts[$i];
		my $lo = $min + $i * $width;
		push @out, { label => sprintf("[${fmt},${fmt})", $lo, $lo + $width), count => $counts[$i] };
	}
	return @out;
}

# The snippet embeds the pre-binned rows as a JS array literal; that array is
# the authoritative statement of what the chart draws.
sub embedded_bins {
	my $body = shift;
	my ($json) = $body =~ /var\s+bins\s*=\s*(\[.*?\])\s*;/s;
	return undef unless defined $json;
	return eval { decode_json($json) };
}

# label/count pairs, in chart order, for comparison against expected_bins().
sub as_pairs {
	return [ map { [ $_->{label}, $_->{count} + 0 ] } @{ shift() } ];
}

sub fetch_histogram {
	my (%args) = @_;
	my $url = "/histogram?l=$args{lspec}&col=$args{col}";
	$url .= "&bins=$args{bins}" if defined $args{bins};
	$url .= "&c=" . url_escape($args{calc}) if defined $args{calc};
	$t->get_ok($url)->status_is(200, "GET $url -> 200");
	return $t->tx->res->body;
}

sub bins_from {
	my ($body, $desc) = @_;
	my $bins = embedded_bins($body);
	ok defined $bins, "$desc: response embeds the pre-binned data array"
		or diag substr($body, 0, 400);
	return $bins // [];
}

# ---------------------------------------------------------------------------
subtest 'default bin count is 10 and the counts match an independent expectation' => sub {
	my $body = fetch_histogram(lspec => $LSPEC, col => 'value');

	like $body, qr/12 values in 10 bins/, 'page reports 12 values in 10 bins';

	my $bins = bins_from($body, 'default');
	is scalar @$bins, 10, 'ten bins are emitted';
	is_deeply as_pairs($bins), as_pairs([ expected_bins(\@VALUES, 10) ]),
		'labels and counts equal the independent expectation';

	my $total = 0;
	$total += $_->{count} for @$bins;
	is $total, scalar @VALUES, 'every value is counted exactly once';
};

# ---------------------------------------------------------------------------
subtest '?bins=5 produces five bars whose labels and counts are BI-computed' => sub {
	my $body = fetch_histogram(lspec => $LSPEC, col => 'value', bins => 5);

	like $body, qr/12 values in 5 bins/, 'page reports 12 values in 5 bins';

	my $bins = bins_from($body, 'bins=5');
	is scalar @$bins, 5, 'exactly five bins are emitted';
	is_deeply as_pairs($bins), as_pairs([ expected_bins(\@VALUES, 5) ]),
		'labels and counts equal the independent expectation';

	# The lopsided fixture makes the counts meaningful: the low and high bins
	# hold three values each, the middles two.
	is_deeply [ map { $_->{count} } @$bins ], [ 3, 2, 2, 2, 3 ],
		'counts are the per-bin tallies, not re-derived by the browser';
};

# ---------------------------------------------------------------------------
subtest 'the maximum lands in the highest bin; no overflow bar is drawn' => sub {
	my $body = fetch_histogram(lspec => $LSPEC, col => 'value', bins => 5);
	my $bins = bins_from($body, 'max edge');

	# Read the top bin through a scalar: indexing -1 directly inside a
	# prototyped assertion autovivifies, which would turn a missing/empty data
	# array into a hard error instead of a readable failure.
	my $top = $bins->[-1];
	ok defined $top, 'at least one bin is present' or return;
	is $top->{label}, '[88,110)', 'top bin is left-closed at 88 and ends at the maximum';
	is $top->{count}, 3,          'the maximum is included in the top bin (90, 100, 110)';

	my $labels = join ' ', map { $_->{label} } @$bins;
	unlike $labels, qr/\[110,/, 'no bin starts at the maximum (no overflow bar)';

	# Every bin other than the top one is a proper right-open interval.
	for my $bin (@$bins[0 .. $#$bins - 1]) {
		my ($lo, $hi) = $bin->{label} =~ /\A\[(-?[\d.]+),(-?[\d.]+)\)\z/
			or fail "bin label not parseable: $bin->{label}";
		is $hi - $lo, 22, "bin $bin->{label} is one width wide";
	}
};

# ---------------------------------------------------------------------------
subtest '?bins clamps to 1..200 and never returns 500' => sub {
	my $one = fetch_histogram(lspec => $LSPEC, col => 'value', bins => 0);
	like $one, qr/12 values in 1 bins/, 'bins=0 clamps to a single bin';
	my $bins = bins_from($one, 'bins=0');
	is scalar @$bins, 1, 'one bin emitted';
	my $only = $bins->[0];
	is $only && $only->{count}, 12, 'all twelve values fall in it';

	# A non-numeric ?bins= is coerced by int() (which warns) and then clamped;
	# that warning is pre-existing controller behaviour, not a test failure.
	my $abc = fetch_histogram(lspec => $LSPEC, col => 'value', bins => 'abc');
	like $abc, qr/12 values in 1 bins/, 'bins=abc clamps to a single bin';

	my $neg = fetch_histogram(lspec => $LSPEC, col => 'value', bins => -5);
	like $neg, qr/12 values in 1 bins/, 'negative bins clamps to a single bin';

	my $many = fetch_histogram(lspec => $LSPEC, col => 'value', bins => 999);
	like $many, qr/12 values in 200 bins/, 'bins=999 clamps to the documented maximum of 200';
	my $many_bins = bins_from($many, 'bins=999');
	cmp_ok scalar @$many_bins, '<=', 200, 'at most 200 bins are emitted';
	my $total = 0;
	$total += $_->{count} for @$many_bins;
	is $total, 12, 'no value is lost when the width is fractional';
};

# ---------------------------------------------------------------------------
subtest 'binning is server-side: the page carries no d3.bin() call' => sub {
	# This is the 0.20 contract.  Against an older HTML::D3 the binned input is
	# ignored and the snippet bins in the browser, which would put a d3.bin()
	# call back into the emitted script and re-derive counts the server cannot
	# account for -- the exact regression this file exists to catch.
	for my $case ([ default => undef ], [ 'bins=5' => 5 ]) {
		my ($desc, $bins) = @$case;
		my $body = fetch_histogram(lspec => $LSPEC, col => 'value', bins => $bins);
		like   $body, qr/var\s+bins\s*=\s*\[/, "$desc: pre-binned array is emitted";
		unlike $body, qr/d3\.bin\s*\(/,         "$desc: no client-side d3.bin() call";
		like   $body, qr/id="histogram"/,       "$desc: chart container is present";
	}
};

# ---------------------------------------------------------------------------
subtest 'bins agree with ?c=band:bin(value,width) on the same width' => sub {
	# /histogram with bins=5 uses width 22 over this fixture.  The same width
	# expressed through the bin() calculated field must produce the same edges,
	# so a pivot's bin labels and the histogram's cannot drift apart.
	my $hist = bins_from(fetch_histogram(lspec => $LSPEC, col => 'value', bins => 5), 'bins=5');

	my $url = "/pivot?l=$LSPEC&c=" . url_escape('band:bin(value,22)')
		. "&rows=band&m=" . url_escape(':count:n') . '&format=json';
	$t->get_ok($url)->status_is(200, 'bin() calculated column aggregates');
	my $rows = decode_json($t->tx->res->body);

	my %pivot = map { $_->{band} => $_->{n} + 0 } @$rows;

	for my $bin (@$hist[0 .. $#$hist - 1]) {
		is $pivot{ $bin->{label} }, $bin->{count},
			"$bin->{label}: histogram count equals the bin() group count";
	}

	# The single documented disagreement: bin() is right-open, so the maximum
	# gets its own [110,132) group, while the histogram folds it into the top
	# bin.  Asserting the relationship keeps both behaviours honest.
	my $top = $hist->[-1];
	ok defined $top, 'top histogram bin is available' or return;
	my $top_label = $top->{label};
	is $pivot{$top_label} + ($pivot{'[110,132)'} // 0), $top->{count},
		"$top_label: top bin = the bin() group plus the maximum's overflow group";

	my @want = map { $_->{label} } @$hist;
	push @want, '[110,132)';
	my @got = sort keys %pivot;
	@want = sort @want;
	is_deeply \@got, \@want,
		'the pivot bin labels are the histogram labels plus the maximum edge';
};

# ---------------------------------------------------------------------------
subtest 'a calculated column can be the binned column' => sub {
	# ?c= creates a virtual column, which does not exist in the source file.
	# Binning it must not attempt (or depend on) a SQL push of that column.
	my @doubled = map { $_ * 2 } @VALUES;

	my $body = fetch_histogram(lspec => $LSPEC, col => 'dbl', calc => 'dbl:value*2');
	like $body, qr/12 values in 10 bins/, 'virtual column is binned with the default bin count';

	my $bins = bins_from($body, 'virtual column');
	is_deeply as_pairs($bins), as_pairs([ expected_bins(\@doubled, 10) ]),
		'labels and counts cover the doubled range';
	my ($first, $last) = ($bins->[0], $bins->[-1]);
	is $first && $first->{label}, '[0,22)',     'first bin starts at the doubled minimum';
	is $last  && $last->{label},  '[198,220)',  'top bin ends at the doubled maximum';
};

# ---------------------------------------------------------------------------
subtest 'a single distinct value collapses to one bin' => sub {
	my $body = fetch_histogram(lspec => $FLAT_LSPEC, col => 'value');
	my $bins = bins_from($body, 'flat fixture');
	is scalar @$bins, 1, 'one bin for a zero-width range';
	my $only = $bins->[0];
	is $only && $only->{label}, '5', 'the bin is labelled with the only value';
	is $only && $only->{count}, 3,   'all three rows are counted';
};

# ---------------------------------------------------------------------------
subtest 'empty state and error handling' => sub {
	# A non-numeric column has no values to bin: the documented empty state is
	# a 200 with an explanation, not a 500 and not an empty chart.
	$t->get_ok("/histogram?l=$LSPEC&col=label")->status_is(200)
		->content_like(qr/No plottable data/, 'non-numeric column renders the empty state');

	$t->get_ok("/histogram?l=$LSPEC")->status_is(400)
		->content_like(qr/Missing col=/, 'missing col= is a 400 naming the parameter');

	$t->get_ok("/histogram?l=$LSPEC&col=nosuchcolumn")->status_is(400)
		->content_like(qr/Column not found: nosuchcolumn/, 'unknown column is a 400');
};

done_testing();
