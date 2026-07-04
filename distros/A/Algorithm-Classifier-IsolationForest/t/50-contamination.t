#!perl
use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Cluster + outliers, deterministic data (see 40-anomaly-detection.t).
my @data;
for my $i ( -7 .. 7 ) {
	for my $j ( -7 .. 7 ) {
		push @data, [ $i / 7, $j / 7 ];
	}
}
push @data, ( [ 6, 6 ], [ -6, 6 ], [ 6, -6 ], [ -6, -6 ], [ 0, 8 ], [ 8, 0 ], [ -8, 0 ], [ 0, -8 ] );

subtest 'no contamination => no learned threshold' => sub {
	my $f = $CLASS->new( n_trees => 50, seed => 5 );
	$f->fit( \@data );
	is( $f->decision_threshold, undef, 'decision_threshold stays undef when contamination is not set' );
};

subtest 'contamination => fit learns a usable threshold' => sub {
	my $f = $CLASS->new(
		n_trees       => 100,
		sample_size   => 256,
		contamination => 0.05,
		seed          => 5,
	);
	is( $f->decision_threshold, undef, 'threshold is not known until fit() is called' );

	$f->fit( \@data );

	my $thr = $f->decision_threshold;
	ok( defined $thr, 'decision_threshold is defined after fitting with contamination' );
	cmp_ok( $thr, '>',  0, 'learned threshold is positive' );
	cmp_ok( $thr, '<=', 1, 'learned threshold is within the score range' );
}; ## end 'contamination => fit learns a usable threshold' => sub

subtest 'predict() uses the learned threshold by default' => sub {
	my $contam = 0.05;
	my $f      = $CLASS->new(
		n_trees       => 100,
		sample_size   => 256,
		contamination => $contam,
		seed          => 5,
	);
	$f->fit( \@data );

	my $flagged = sum( @{ $f->predict( \@data ) } );
	my $target  = $contam * scalar @data;

	# The learned cutoff should flag roughly the requested fraction -- not
	# exact, but in the right ballpark (within a few points either way).
	cmp_ok( $flagged,                  '>=', 1, 'at least one point is flagged' );
	cmp_ok( abs( $flagged - $target ), '<=', 5, "fraction flagged (~$flagged) is close to the requested $target" );

	# An explicit threshold still overrides the learned one.
	is( sum( @{ $f->predict( \@data, 100 ) } ),
		0, 'an explicit threshold overrides the learned contamination cutoff' );
}; ## end 'predict() uses the learned threshold by default' => sub

done_testing;
