#!perl
use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Deterministic, well-spread training data (no randomness in the data itself).
my @data;
for my $i ( 0 .. 19 ) {
    for my $j ( 0 .. 4 ) {
        push @data, [ $i, $j ];
    }
}

my $f = $CLASS->new( n_trees => 60, sample_size => 64, seed => 42 );
$f->fit( \@data );

subtest 'score_samples shape and range' => sub {
    my $scores = $f->score_samples( \@data );
    is( ref $scores, 'ARRAY', 'score_samples returns an arrayref' );
    is( scalar @$scores, scalar @data, 'one score per input sample' );

    my $bad = grep { !defined $_ || $_ <= 0 || $_ > 1 } @$scores;
    is( $bad, 0, 'every anomaly score lies in (0, 1]' );
};

subtest 'path_lengths shape and range' => sub {
    my $lengths = $f->path_lengths( \@data );
    is( ref $lengths, 'ARRAY', 'path_lengths returns an arrayref' );
    is( scalar @$lengths, scalar @data, 'one mean path length per sample' );

    my $bad = grep { !defined $_ || $_ < 0 } @$lengths;
    is( $bad, 0, 'every mean path length is non-negative' );
};

subtest 'scoring an arbitrary query set' => sub {
    my @query  = ( [ 2, 2 ], [ 100, 100 ] );    # one in-range, one far out
    my $scores = $f->score_samples( \@query );
    is( scalar @$scores, 2, 'scores returned for an out-of-training query set' );
    cmp_ok( $scores->[1], '>', $scores->[0],
        'a point far outside the data scores higher than one inside it' );
};

subtest 'predict returns 0/1 labels, one per sample' => sub {
    my $labels = $f->predict( \@data );
    is( ref $labels, 'ARRAY', 'predict returns an arrayref' );
    is( scalar @$labels, scalar @data, 'one label per sample' );
    my $bad = grep { $_ ne '0' && $_ ne '1' } @$labels;
    is( $bad, 0, 'every label is exactly 0 or 1' );
};

subtest 'predict honours an explicit threshold' => sub {
    # Scores are always in (0, 1], so these thresholds give deterministic,
    # platform-independent results regardless of the random partitioning.
    my $all_one  = $f->predict( \@data, -1 );
    my $all_zero = $f->predict( \@data, 100 );

    is( sum(@$all_one), scalar @data,
        'threshold below every score flags all samples (label 1)' );
    is( sum(@$all_zero), 0,
        'threshold above every score flags nothing (label 0)' );
};

subtest 'predict defaults to a 0.5 threshold without contamination' => sub {
    my $scores  = $f->score_samples( \@data );
    my $labels  = $f->predict( \@data );          # no threshold, no contamination
    my $mismatch = 0;
    for my $i ( 0 .. $#$scores ) {
        my $expected = $scores->[$i] >= 0.5 ? 1 : 0;
        $mismatch++ if $labels->[$i] != $expected;
    }
    is( $mismatch, 0, 'default predict() matches a manual 0.5 cutoff on scores' );
};

done_testing;
