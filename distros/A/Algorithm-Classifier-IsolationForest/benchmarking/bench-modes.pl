#!/usr/bin/perl
# benchmarking/bench-modes.pl
#
# Head-to-head comparison of axis-parallel (IF) vs oblique/extended (EIF)
# mode for both fit() and score_samples(), across a range of feature counts.
#
# For each feature count the script prints one cmpthese table that covers
# all four combinations: {axis, extended} x {fit, score}.  This makes it
# easy to see both the mode overhead and how it grows with dimensionality.
#
# Extended mode at high feature counts is where the SIMD pragma on the
# oblique dot product matters most, so the sweep extends up to 100
# features.  The closer the extended:score row gets to axis:score, the
# less the per-node dot product is costing.
#
# Run with:
#   perl -Ilib benchmarking/bench-modes.pl

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

sub make_data {
	my ( $n, $nf ) = @_;
	my @rows = map {
		[ map { gaussian( 0, 1 ) } 1 .. $nf ]
	} 1 .. $n;
	for ( 1 .. int( $n * 0.05 ) ) {
		my $r = 5 + rand() * 3;
		push @rows, [ map { $r * ( rand() > 0.5 ? 1 : -1 ) } 1 .. $nf ];
	}
	return \@rows;
} ## end sub make_data

print "=" x 62, "\n";
print " axis vs extended mode -- Algorithm::Classifier::IsolationForest\n";
print "=" x 62, "\n";
print "(1000 training samples, n_trees=100, sample_size=256)\n";
print "(1000 query points for score_samples)\n";
print "(rates shown as calls/second wall-clock; higher is faster)\n";

my @feature_counts = ( 2 .. 10, 20, 50, 100 );

# Pre-generate all datasets (training and query) before any timing.
srand(42);
my ( %train_data, %query_data );
for my $nf (@feature_counts) {
	$train_data{$nf} = make_data( 1000, $nf );
	$query_data{$nf} = make_data( 1000, $nf );
}

# Pre-train one axis and one extended model per feature count for the
# score_samples benchmarks.
my ( %axis_model, %ext_model );
for my $nf (@feature_counts) {
	$axis_model{$nf} = Algorithm::Classifier::IsolationForest->new(
		n_trees     => 100,
		sample_size => 256,
		mode        => 'axis',
		seed        => 1,
	)->fit( $train_data{$nf} );

	$ext_model{$nf} = Algorithm::Classifier::IsolationForest->new(
		n_trees     => 100,
		sample_size => 256,
		mode        => 'extended',
		seed        => 1,
	)->fit( $train_data{$nf} );
} ## end for my $nf (@feature_counts)

# One table per feature count
for my $nf (@feature_counts) {
	printf "\n--- %d feature%s ---\n", $nf, $nf == 1 ? '' : 's';
	wall_cmpthese(
		-2,
		{
			'axis:fit' => sub {
				Algorithm::Classifier::IsolationForest->new(
					n_trees     => 100,
					sample_size => 256,
					mode        => 'axis'
				)->fit( $train_data{$nf} );
			},
			'extended:fit' => sub {
				Algorithm::Classifier::IsolationForest->new(
					n_trees     => 100,
					sample_size => 256,
					mode        => 'extended'
				)->fit( $train_data{$nf} );
			},
			'axis:score'     => sub { $axis_model{$nf}->score_samples( $query_data{$nf} ) },
			'extended:score' => sub { $ext_model{$nf}->score_samples( $query_data{$nf} ) },
		}
	);
} ## end for my $nf (@feature_counts)
