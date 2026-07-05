#!/usr/bin/perl
# benchmarking/bench-voting.pl
#
# Head-to-head comparison of mean aggregation (classic IForest) vs
# majority voting (MVIForest -- Chabchoub, Togbe, Boly & Chiky 2022) for
# both speed and detections.
#
# voting => 'majority' is aggregation-only: it builds the exact same
# trees as voting => 'mean' and differs solely in how the per-tree path
# lengths are combined at score/predict time.  So a fair comparison holds
# the trees fixed (same seed + data) and varies only the aggregation.
#
# Two things are measured:
#
#   1. SPEED.  predict() is where majority voting can win: it stops
#      walking a point's trees as soon as the majority outcome is decided
#      (the paper's "stop at majority"), whereas mean aggregation always
#      walks every tree.  score_samples() has no such early exit (the
#      vote fraction needs the full count), so it is shown as a contrast.
#      Timed across n_trees, query-set size, and feature count, under the
#      default backend (C + OpenMP when available).
#
#      How much predict() saves depends on the data: early exit triggers
#      sooner when points are clearly inliers or clearly outliers, later
#      when they sit near the decision boundary.  The gaussian-cluster +
#      planted-outlier data here is fairly separable, so this is closer
#      to a best case than to a worst case.
#
#      The speed timings run on the SERIAL C backend (use_openmp => 0).
#      The majority-vote win is algorithmic -- it walks fewer trees per
#      point -- and forcing serial isolates that from OpenMP scheduling:
#      early exit makes different points finish after different numbers
#      of trees, so an OpenMP `parallel for` sees uneven per-point work
#      and its load-imbalance jitter would otherwise swamp the effect
#      being measured (wall_cmpthese times a single window, unlike
#      wall_rate's windowed median -- see BenchAccel).  The fewer-walks
#      saving carries over to the OpenMP path; it is just far noisier to
#      measure there.
#
#   2. DETECTIONS.  On data with a known planted-outlier block we report,
#      per decision threshold, how many points each mode flags, how many
#      of the true outliers it catches (recall), how many inliers it
#      flags (false alarms), and how often the two modes agree.  The
#      threshold means different things in each mode -- a forest-level
#      score cutoff for mean, a per-tree cutoff for majority -- but the
#      paper compares them at the same nominal value (0.6), so we do too.
#
# Run with:
#   perl -Ilib benchmarking/bench-voting.pl

use strict;
use warnings;
use lib '../lib';
use FindBin;
use lib "$FindBin::Bin";
use BenchAccel qw(wall_cmpthese);
use Algorithm::Classifier::IsolationForest;

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	return $mu + $sigma * sqrt( -2 * log( rand() || 1e-12 ) ) * cos( 2 * PI * rand() );
}

# Returns ($rows, $n_inliers): the first $n_inliers rows are the gaussian
# cluster, the remaining rows are the planted outliers (a 5% block pushed
# 5-8 sigma out).  Keeping the split point lets the detection section
# score recall (true outliers caught) against false alarms (inliers
# flagged).
sub make_data {
	my ( $n, $nf ) = @_;
	my @rows = map {
		[ map { gaussian( 0, 1 ) } 1 .. $nf ]
	} 1 .. $n;
	my $n_inliers = scalar @rows;
	for ( 1 .. int( $n * 0.05 ) ) {
		my $r = 5 + rand() * 3;
		push @rows, [ map { $r * ( rand() > 0.5 ? 1 : -1 ) } 1 .. $nf ];
	}
	return ( \@rows, $n_inliers );
} ## end sub make_data

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

# Build a mean model and a majority model over identical trees (same seed
# + data), so any difference is purely the aggregation.
sub build_pair {
	my (%opts) = @_;
	my $data = delete $opts{_data};
	return {
		mean => Algorithm::Classifier::IsolationForest->new(
			%opts, voting => 'mean',
		)->fit($data),
		majority => Algorithm::Classifier::IsolationForest->new(
			%opts, voting => 'majority',
		)->fit($data),
	};
} ## end sub build_pair

print "=" x 70, "\n";
print " mean vs majority-vote aggregation\n";
print " Algorithm::Classifier::IsolationForest\n";
print "=" x 70, "\n";
printf "Backend availability: HAS_C=%d  HAS_OPENMP=%d  HAS_SIMD=%d\n",
	$HAS_C, $HAS_OPENMP,
	$Algorithm::Classifier::IsolationForest::HAS_SIMD;
print "(rates shown as calls/second wall-clock; higher is faster)\n";

# =======================================================================
# PART 1 -- SPEED
# =======================================================================
print "\n", "=" x 70, "\n";
print " PART 1: speed (predict is where majority voting can win)\n";
print " (serial C backend -- isolates the fewer-tree-walks effect)\n";
print "=" x 70, "\n";

# -----------------------------------------------------------------------
# 1a. Method comparison at a fixed size.
# -----------------------------------------------------------------------
print "\n--- methods  (n_trees=100, 1000 query points, 2 features) ---\n";
srand(42);
my ($train1) = make_data( 1000, 2 );
my ($q1k)    = make_data( 1000, 2 );
my $pair     = build_pair(
	n_trees     => 100,
	sample_size => 256,
	mode        => 'axis',
	seed        => 1,
	use_openmp  => 0,         # serial C -- see the OpenMP note in the header
	_data       => $train1,
);

for my $method (qw(predict score_predict_samples score_predict_split score_samples)) {
	printf "\n  %s\n", $method;
	my %v;
	for my $voting ( sort keys %$pair ) {
		my $m = $pair->{$voting};
		$v{$voting}
			= $method eq 'score_samples'
			? sub { $m->$method($q1k) }
			: sub { $m->$method( $q1k, 0.6 ) };
	}
	wall_cmpthese( -3, \%v );
} ## end for my $method (qw(predict score_predict_samples score_predict_split score_samples))

# -----------------------------------------------------------------------
# 1b. predict() across n_trees.  More trees means more chances for the
# majority to be reached early, so the early-exit advantage should grow.
# Uses a 5000-point query set so each call does enough work to time
# steadily across the whole n_trees range.
# -----------------------------------------------------------------------
print "\n--- predict() vs n_trees  (5000 query points, 2 features) ---\n";
srand(42);
my ($train2) = make_data( 1000, 2 );
my ($q5k)    = make_data( 5000, 2 );
for my $nt ( 50, 100, 200, 500 ) {
	printf "\n  n_trees=%d\n", $nt;
	my $p = build_pair(
		n_trees     => $nt,
		sample_size => 256,
		mode        => 'axis',
		seed        => 1,
		use_openmp  => 0,
		_data       => $train2,
	);
	my %v;
	$v{$_} = do {
		my $m = $p->{$_};
		sub { $m->predict( $q5k, 0.6 ) }
		}
		for sort keys %$p;
	wall_cmpthese( -3, \%v );
} ## end for my $nt ( 50, 100, 200, 500 )

# -----------------------------------------------------------------------
# 1c. predict() across query-set size.
# -----------------------------------------------------------------------
print "\n--- predict() vs query size  (n_trees=100, 2 features) ---\n";
srand(99);
my %qsize;
( $qsize{$_} ) = make_data( $_, 2 ) for ( 1_000, 10_000, 50_000 );
for my $n ( 1_000, 10_000, 50_000 ) {
	printf "\n  %d query points\n", $n;
	my %v;
	$v{$_} = do {
		my $m = $pair->{$_};
		my $q = $qsize{$n};
		sub { $m->predict( $q, 0.6 ) }
		}
		for sort keys %$pair;
	wall_cmpthese( -3, \%v );
} ## end for my $n ( 1_000, 10_000, 50_000 )

# -----------------------------------------------------------------------
# 1d. predict() across feature count (extended mode -- the heavier walk).
# -----------------------------------------------------------------------
print "\n--- predict() vs feature count  (extended, n_trees=100, 1000 query) ---\n";
srand(42);
for my $nf ( 2, 5, 10, 20, 50 ) {
	printf "\n  %d features\n", $nf;
	my ($tr) = make_data( 1000, $nf );
	my ($qr) = make_data( 1000, $nf );
	my $p    = build_pair(
		n_trees     => 100,
		sample_size => 256,
		mode        => 'extended',
		seed        => 1,
		use_openmp  => 0,
		_data       => $tr,
	);
	my %v;
	$v{$_} = do {
		my $m = $p->{$_};
		sub { $m->predict( $qr, 0.6 ) }
		}
		for sort keys %$p;
	wall_cmpthese( -3, \%v );
} ## end for my $nf ( 2, 5, 10, 20, 50 )

# =======================================================================
# PART 2 -- DETECTIONS
# =======================================================================
print "\n", "=" x 70, "\n";
print " PART 2: outliers found (same trees, same data, both modes)\n";
print "=" x 70, "\n";

# Count how a label arrayref splits over a known inlier/outlier boundary.
# Returns (flagged_total, true_outliers_caught, inliers_flagged).
sub tally {
	my ( $labels, $n_inliers ) = @_;
	my ( $total, $caught, $false ) = ( 0, 0, 0 );
	for my $i ( 0 .. $#$labels ) {
		next unless $labels->[$i];
		$total++;
		if   ( $i >= $n_inliers ) { $caught++ }
		else                      { $false++ }
	}
	return ( $total, $caught, $false );
} ## end sub tally

sub agreement {
	my ( $a, $b ) = @_;
	my $same = grep { $a->[$_] == $b->[$_] } 0 .. $#$a;
	return $same;
}

srand(7);
my ( $det_data, $n_inliers ) = make_data( 2000, 8 );
my $n_out   = scalar(@$det_data) - $n_inliers;
my $n_total = scalar @$det_data;

my $det = build_pair(
	n_trees     => 200,
	sample_size => 256,
	mode        => 'axis',
	seed        => 5,
	_data       => $det_data,
);

printf "\n%d samples: %d inliers + %d planted outliers, 8 features, n_trees=200\n", $n_total, $n_inliers, $n_out;
print "(recall = planted outliers caught; false = inliers flagged)\n";

printf "\n  %-10s  %-8s  %9s  %8s  %8s  %8s\n", 'threshold', 'voting', 'flagged', 'recall', 'false', 'agree%';
print "  ", "-" x 62, "\n";

for my $thr ( 0.5, 0.6, 0.7 ) {
	my $ml = $det->{mean}->predict( $det_data, $thr );
	my $vl = $det->{majority}->predict( $det_data, $thr );

	my ( $mt, $mc, $mf ) = tally( $ml, $n_inliers );
	my ( $vt, $vc, $vf ) = tally( $vl, $n_inliers );
	my $agree_pct = 100 * agreement( $ml, $vl ) / $n_total;

	printf "  %-10.2f  %-8s  %9s  %7d/%d  %8d  %7.1f%%\n", $thr, 'mean',     $mt, $mc, $n_out, $mf, $agree_pct;
	printf "  %-10s  %-8s  %9s  %7d/%d  %8d  %7s\n",       '',   'majority', $vt, $vc, $n_out, $vf, '';
} ## end for my $thr ( 0.5, 0.6, 0.7 )

# Contamination-learned thresholds: each mode learns its own cutoff to
# flag ~5% of the training set, then we compare what they actually catch.
print "\n--- contamination => 0.05 (each mode learns its own cutoff) ---\n";
my %learned;
for my $voting (qw(mean majority)) {
	$learned{$voting} = Algorithm::Classifier::IsolationForest->new(
		n_trees       => 200,
		sample_size   => 256,
		mode          => 'axis',
		seed          => 5,
		voting        => $voting,
		contamination => 0.05,
	)->fit($det_data);
} ## end for my $voting (qw(mean majority))

printf "\n  %-8s  %10s  %9s  %8s  %8s\n", 'voting', 'threshold', 'flagged', 'recall', 'false';
print "  ", "-" x 52, "\n";
for my $voting (qw(mean majority)) {
	my $m      = $learned{$voting};
	my $labels = $m->predict($det_data);
	my ( $t, $c, $f ) = tally( $labels, $n_inliers );
	printf "  %-8s  %10.4f  %9d  %7d/%d  %8d\n", $voting, $m->decision_threshold, $t, $c, $n_out, $f;
}

print "\n";
