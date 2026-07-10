#!/usr/bin/env perl

# online-streaming.pl
#
# Online (streaming) Isolation Forest on a drifting stream. The stream starts
# as a Gaussian blob at the origin, then drifts to a blob at (6, 6). An
# offline model would keep flagging the new regime forever; the online model
# forgets points as they age out of its sliding window, so within one window
# of the drift it treats the new regime as normal and the OLD regime as the
# anomaly.
#
# Points are processed prequentially (score-then-learn), the standard way to
# evaluate a streaming detector: every score reflects the model as it stood
# before that point influenced it.
#
# Run from the distribution root:
#     perl -Ilib examples/online-streaming.pl
# or, if the module is installed:
#     perl examples/online-streaming.pl

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest::Online;

use constant PI => 3.14159265358979;

srand(7);    # reproducible data; the forest gets its own seed below

sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * $u2 );
}

sub blob {
	my ( $n, $mu ) = @_;
	return map { [ gaussian( $mu, 1 ), gaussian( $mu, 1 ) ] } 1 .. $n;
}

my $oif = Algorithm::Classifier::IsolationForest::Online->new(
	n_trees          => 100,
	window_size      => 512,    # the model reflects the last 512 points
	max_leaf_samples => 32,
	seed             => 42,
);

# Two probe points we re-score as the stream evolves: the centre of each
# regime.
my @probes = ( [ 0, 0 ], [ 6, 6 ] );

printf "%-28s  %-12s  %-12s\n", 'stream position', 'score(0,0)', 'score(6,6)';

# --- phase A: the stream sits at the origin ----------------------------------
$oif->score_learn( [ blob( 600, 0 ) ] );
my $s = $oif->score_samples( \@probes );
printf "%-28s  %-12.4f  %-12.4f\n", 'after 600 points at (0,0)', @$s;

# --- phase B: the stream drifts to (6, 6) ------------------------------------
# Watch the scores swap as the window turns over.
for my $chunk ( 1 .. 4 ) {
	$oif->score_learn( [ blob( 200, 6 ) ] );
	$s = $oif->score_samples( \@probes );
	printf "%-28s  %-12.4f  %-12.4f\n", "after ${\ ($chunk * 200) } points at (6,6)", @$s;
}

print "\nThe (6,6) probe started anomalous and became normal as it took over\n";
print "the window; the (0,0) probe did the reverse. window_count is capped:\n";
printf "window_count=%d  seen=%d\n", $oif->window_count, $oif->seen;
