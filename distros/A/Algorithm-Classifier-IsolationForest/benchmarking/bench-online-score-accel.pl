#!/usr/bin/perl
# benchmarking/bench-online-score-accel.pl
#
# Benchmarks Online Isolation Forest batch scoring under each acceleration
# backend:
#   pure_perl   -- use_c => 0                   (pure Perl tree walk)
#   c_serial    -- use_c => 1, use_openmp => 0  (C tree walk, single thread)
#   c_openmp    -- use_c => 1, use_openmp => 1  (C tree walk, OpenMP parallel)
#
# The online class scores through the parent's C backend by lazily packing
# its mutable trees into the parent's node layout; learning invalidates the
# packed snapshot and the next scoring call repacks once.  Learning itself
# (and the per-row walks inside score_learn) runs in C directly against the
# live trees.  Sections 1 and 2 measure steady-state batch scoring (snapshot
# reused across calls); section 3 interleaves a learned point before every
# scoring call, so each call pays the repack -- the worst case for the C
# path; sections 4 and 5 measure the prequential score_learn /
# score_learn_tagged stream loop, where the mutable-tree C walks are what
# matters.
#
# Reference numbers (2026-07-08, 8-core dev box, 100 trees, window 2048,
# 5 features): batch scoring of 20k query points -- pure Perl ~3.6 s/call,
# C serial ~58 ms, C+OpenMP ~9 ms; score_learn stream -- pure Perl ~270
# pts/s, C ~2,400 pts/s.
#
# Run with:
#   perl -Ilib benchmarking/bench-online-score-accel.pl

use strict;
use warnings;
use lib '../lib';
use FindBin;
use lib "$FindBin::Bin";
use BenchAccel                                     qw(wall_cmpthese);
use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	return $mu + $sigma * sqrt( -2 * log( rand() || 1e-12 ) ) * cos( 2 * PI * rand() );
}

sub make_data {
	my ( $n, $nf ) = @_;
	return [
		map {
			[ map { gaussian( 0, 1 ) } 1 .. $nf ]
		} 1 .. $n
	];
}

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

# One model per accel config.  Each learn is reseeded so every model
# sees the identical draw sequence; with the C/Perl learn parity
# guarantee that makes the trees identical across configs, so the
# scoring sections compare equal work.
sub build_models {
	my ( $stream, %opts ) = @_;
	my %m;
	$m{pure_perl} = Algorithm::Classifier::IsolationForest::Online->new( %opts, use_c => 0 );
	$m{c_serial}  = Algorithm::Classifier::IsolationForest::Online->new( %opts, use_c => 1, use_openmp => 0 )
		if $HAS_C;
	$m{c_openmp} = Algorithm::Classifier::IsolationForest::Online->new( %opts, use_c => 1, use_openmp => 1 )
		if $HAS_C && $HAS_OPENMP;
	for my $name ( sort keys %m ) {
		srand(1);
		$m{$name}->learn($stream);
	}
	return \%m;
} ## end sub build_models

print "=" x 70, "\n";
print " online (streaming) scoring accel benchmarks\n";
print " Algorithm::Classifier::IsolationForest::Online\n";
print "=" x 70, "\n";
printf "Backend availability: HAS_C=%d  HAS_OPENMP=%d  online_learn_xs=%d\n",
	$HAS_C, $HAS_OPENMP,
	Algorithm::Classifier::IsolationForest::Online::_HAS_ONLINE_XS;
print "(rates shown as calls/second wall-clock; higher is faster)\n";
print "(online_learn_xs=0 means the loaded C object predates the online\n"
	. " learn accelerators -- rebuild or rerun with IF_RUNTIME_BUILD=1)\n"
	unless Algorithm::Classifier::IsolationForest::Online::_HAS_ONLINE_XS;

srand(42);
my $stream = make_data( 3000, 5 );
my $models = build_models(
	$stream,
	n_trees          => 100,
	window_size      => 2048,
	max_leaf_samples => 32,
	seed             => 1,
);

# -----------------------------------------------------------------------
# 1. Scoring method comparison  (1000 query points, snapshot reused)
# -----------------------------------------------------------------------
print "\n--- scoring methods  (100 trees, 1000 query points, 5 features) ---\n";
srand(43);
my $q1k = make_data( 1000, 5 );

for my $method (
	qw(score_samples predict score_predict_samples
	score_predict_split path_lengths)
	)
{
	printf "\n  %s\n", $method;
	my %v;
	for my $name ( keys %$models ) {
		my $m = $models->{$name};
		$v{$name} = sub { my @r = $m->$method($q1k); 1 };
	}
	wall_cmpthese( 1, \%v );
} ## end for my $method ( qw(score_samples predict score_predict_samples...))

# -----------------------------------------------------------------------
# 2. Query set size scaling  (where OpenMP parallelism shines)
# -----------------------------------------------------------------------
for my $n_q ( 1000, 10000, 50000 ) {
	print "\n--- score_samples, $n_q query points ---\n";
	srand(44);
	my $q = make_data( $n_q, 5 );
	my %v;
	for my $name ( keys %$models ) {
		my $m = $models->{$name};
		$v{$name} = sub { my $s = $m->score_samples($q); 1 };
	}
	wall_cmpthese( 1, \%v );
} ## end for my $n_q ( 1000, 10000, 50000 )

# -----------------------------------------------------------------------
# 3. Interleaved learn + score  (every call repacks the snapshot)
# -----------------------------------------------------------------------
print "\n--- learn(1 row) + score_samples(1000)  (repack per call) ---\n";
srand(45);
my $q_mut = make_data( 1000, 5 );
my @drip  = @{ make_data( 100000, 5 ) };
my %v;
for my $name ( keys %$models ) {
	my $m = $models->{$name};
	$v{$name} = sub {
		$m->learn( [ shift(@drip) // [ (0) x 5 ] ] );
		my $s = $m->score_samples($q_mut);
		1;
	};
}
wall_cmpthese( 1, \%v );

# -----------------------------------------------------------------------
# 4. score_learn  -- the prequential stream loop (per-point mutation)
# -----------------------------------------------------------------------
print "\n--- score_learn, 200-row chunks  (multiply rate by 200 for pts/s) ---\n";
srand(46);
my $feed = make_data( 20000, 5 );
my $pos  = 0;
my %v_sl;
for my $name ( keys %$models ) {
	my $m = $models->{$name};
	$v_sl{$name} = sub {
		$pos = 0 if $pos + 200 > @$feed;
		my $s = $m->score_learn( [ @{$feed}[ $pos .. $pos + 199 ] ] );
		$pos += 200;
		1;
	};
}
wall_cmpthese( 1, \%v_sl );

# -----------------------------------------------------------------------
# 5. score_learn_tagged  -- single named-feature rows (rate = points/s)
# -----------------------------------------------------------------------
print "\n--- score_learn_tagged, one hashref row per call ---\n";
srand(47);
my @tag_names     = qw(f0 f1 f2 f3 f4);
my $tagged_models = build_models(
	$stream,
	n_trees          => 100,
	window_size      => 2048,
	max_leaf_samples => 32,
	seed             => 1,
	feature_names    => \@tag_names,
);
my $tpos = 0;
my %v_slt;
for my $name ( keys %$tagged_models ) {
	my $m = $tagged_models->{$name};
	$v_slt{$name} = sub {
		$tpos = 0 if $tpos >= @$feed;
		my %row;
		@row{@tag_names} = @{ $feed->[ $tpos++ ] };
		my $s = $m->score_learn_tagged( \%row );
		1;
	};
} ## end for my $name ( keys %$tagged_models )
wall_cmpthese( 1, \%v_slt );

print "\ndone\n";
