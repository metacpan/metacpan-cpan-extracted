#!perl
use strict;
use warnings;
use Test::More;
use List::Util qw(sum min max);

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Build a deterministic dataset: a dense, well-populated cluster of "normal"
# points inside [-1, 1]^2, plus a handful of outliers placed far outside it.
# The data contains no randomness, so the only stochastic element is the
# forest's own partitioning, which we seed for reproducibility. The clusters
# are separated widely enough that the qualitative result (outliers score
# higher) holds for any reasonable RNG, not just one platform's.
my ( @inliers, @outliers );
for my $i ( -7 .. 7 ) {
    for my $j ( -7 .. 7 ) {
        push @inliers, [ $i / 7, $j / 7 ];
    }
}
@outliers = ( [ 6, 6 ], [ -6, 6 ], [ 6, -6 ], [ -6, -6 ],
    [ 0, 8 ], [ 8, 0 ], [ -8, 0 ], [ 0, -8 ] );

sub mean { @_ ? sum(@_) / @_ : 0 }

subtest 'axis-parallel Isolation Forest separates outliers from inliers' => sub {
    my $f = $CLASS->new( n_trees => 100, sample_size => 256, seed => 42 );
    $f->fit( [ @inliers, @outliers ] );

    my $in_scores  = $f->score_samples( \@inliers );
    my $out_scores = $f->score_samples( \@outliers );

    my $mean_in  = mean(@$in_scores);
    my $mean_out = mean(@$out_scores);

    cmp_ok( $mean_out, '>', $mean_in + 0.2,
        'outliers score clearly higher on average than inliers' );
    cmp_ok( max(@$in_scores), '<', 0.55,
        'inliers stay well below the 0.5 anomaly line' );
    cmp_ok( min(@$out_scores), '>', 0.6,
        'outliers sit well above the 0.5 anomaly line' );
    cmp_ok( min(@$out_scores), '>', max(@$in_scores),
        'every outlier scores higher than every inlier' );

    # predict() with the default 0.5 cutoff should recover the labelling.
    is( sum( @{ $f->predict( \@outliers ) } ),
        scalar @outliers, 'predict() flags all outliers at the default cutoff' );
    cmp_ok( sum( @{ $f->predict( \@inliers ) } ), '<', 0.05 * @inliers,
        'predict() flags very few inliers (< 5%)' );
};

subtest 'Extended Isolation Forest also separates the outliers' => sub {
    my $f = $CLASS->new(
        n_trees     => 100,
        sample_size => 256,
        mode        => 'extended',
        seed        => 7,
    );
    $f->fit( [ @inliers, @outliers ] );

    my $mean_in  = mean( @{ $f->score_samples( \@inliers ) } );
    my $mean_out = mean( @{ $f->score_samples( \@outliers ) } );
    cmp_ok( $mean_out, '>', $mean_in + 0.15,
        'extended-mode outliers also score clearly higher than inliers' );
};

subtest 'seeding makes training reproducible' => sub {
    my @train = ( @inliers, @outliers );

    my $a = $CLASS->new( n_trees => 40, sample_size => 128, seed => 99 );
    my $b = $CLASS->new( n_trees => 40, sample_size => 128, seed => 99 );
    $a->fit( \@train );
    $b->fit( \@train );

    my $sa = $a->score_samples( \@train );
    my $sb = $b->score_samples( \@train );

    my $diffs = grep { $sa->[$_] != $sb->[$_] } 0 .. $#$sa;
    is( $diffs, 0,
        'two forests built with the same seed produce identical scores' );
};

done_testing;
