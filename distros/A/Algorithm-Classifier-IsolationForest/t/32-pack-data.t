#!perl
# 32-pack-data.t
#
# Verifies pack_data + accept-packed semantics on the five scoring
# methods: passing the PackedData wrapper produces the same results
# as passing the original arrayref, on the same model.

use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

plan skip_all => 'pack_data requires the Inline::C backend'
    unless $Algorithm::Classifier::IsolationForest::HAS_C;

# Small but non-trivial dataset: 200 Gaussian-ish inliers + 5 outliers
# in 4 dims.  Enough that scoring exercises the C path meaningfully but
# fast enough to keep the test snappy.
sub gaussian {
    my ( $mu, $sigma ) = @_;
    my $u1 = rand() || 1e-12;
    my $u2 = rand();
    return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * 3.14159265358979 * $u2 );
}

srand(123);
my @train;
push @train, [ map { gaussian(0, 1) } 1 .. 4 ] for 1 .. 200;
push @train, [ map { 6 + rand() } 1 .. 4 ] for 1 .. 5;

my $f = $CLASS->new( n_trees => 100, sample_size => 256, seed => 7 );
$f->fit( \@train );

# Query data: mix of inlier-like + a couple of obvious outliers.
srand(456);
my @query;
push @query, [ map { gaussian(0, 1) } 1 .. 4 ] for 1 .. 50;
push @query, [ 7, -7, 6, -6 ];
push @query, [ -8, 8, -7, 7 ];

# ----- pack_data sanity -----
my $packed = $f->pack_data( \@query );
isa_ok( $packed, 'Algorithm::Classifier::IsolationForest::PackedData',
    'pack_data returns a PackedData' );
is( $packed->n_pts,   scalar @query, 'PackedData->n_pts matches' );
is( $packed->n_feats, 4,             'PackedData->n_feats matches' );

# ----- score_samples -----
subtest 'score_samples: packed == arrayref' => sub {
    my $sa = $f->score_samples( \@query );
    my $sp = $f->score_samples($packed);
    is( scalar @$sa, scalar @$sp, 'same length' );
    my $diffs = grep { $sa->[$_] != $sp->[$_] } 0 .. $#$sa;
    is( $diffs, 0, 'every score matches bit-for-bit' );
};

# ----- predict -----
subtest 'predict: packed == arrayref' => sub {
    my $la = $f->predict( \@query, 0.55 );
    my $lp = $f->predict( $packed,  0.55 );
    is( scalar @$la, scalar @$lp, 'same length' );
    my $diffs = grep { $la->[$_] != $lp->[$_] } 0 .. $#$la;
    is( $diffs, 0, 'every label matches' );
};

# ----- path_lengths -----
subtest 'path_lengths: packed == arrayref' => sub {
    my $pa = $f->path_lengths( \@query );
    my $pp = $f->path_lengths($packed);
    is( scalar @$pa, scalar @$pp, 'same length' );
    my $diffs = grep { $pa->[$_] != $pp->[$_] } 0 .. $#$pa;
    is( $diffs, 0, 'every path length matches' );
};

# ----- score_predict_samples -----
subtest 'score_predict_samples: packed == arrayref' => sub {
    my $pa = $f->score_predict_samples( \@query, 0.55 );
    my $pp = $f->score_predict_samples( $packed,  0.55 );
    is( scalar @$pa, scalar @$pp, 'same length' );
    my $diffs = 0;
    for my $i ( 0 .. $#$pa ) {
        $diffs++ if $pa->[$i][0] != $pp->[$i][0];
        $diffs++ if $pa->[$i][1] != $pp->[$i][1];
    }
    is( $diffs, 0, 'every [score, label] pair matches' );
};

# ----- score_predict_split -----
subtest 'score_predict_split: packed == arrayref' => sub {
    my ( $sa, $la ) = $f->score_predict_split( \@query, 0.55 );
    my ( $sp, $lp ) = $f->score_predict_split( $packed,  0.55 );
    is( scalar @$sa, scalar @$sp, 'scores same length' );
    is( scalar @$la, scalar @$lp, 'labels same length' );
    my $score_diffs = grep { $sa->[$_] != $sp->[$_] } 0 .. $#$sa;
    my $label_diffs = grep { $la->[$_] != $lp->[$_] } 0 .. $#$la;
    is( $score_diffs, 0, 'every score matches' );
    is( $label_diffs, 0, 'every label matches' );
};

# ----- feature-count mismatch is fatal -----
subtest 'feature-count mismatch is detected' => sub {
    my $other_f = $CLASS->new( n_trees => 10, sample_size => 16, seed => 1 );
    $other_f->fit( [ map { [ gaussian(0,1), gaussian(0,1) ] } 1 .. 30 ] );
    eval { $other_f->score_samples($packed) };
    like(
        $@,
        qr/PackedData has 4 features but model expects 2/,
        'mismatched feature count croaks with a clear message'
    );
};

# ----- pack_data error paths -----
subtest 'pack_data croaks before fit()' => sub {
    my $unfit = $CLASS->new( n_trees => 10, sample_size => 16 );
    eval { $unfit->pack_data( \@query ) };
    like( $@, qr/not fitted/,
        'pack_data on an unfitted model croaks via _check_fitted' );
};

subtest 'pack_data croaks on non-arrayref input' => sub {
    eval { $f->pack_data('not an arrayref') };
    like( $@, qr/expects an arrayref/,
        'pack_data on a scalar croaks with a clear message' );

    eval { $f->pack_data( { wrong => 'shape' } ) };
    like( $@, qr/expects an arrayref/,
        'pack_data on a hashref croaks with a clear message' );
};

done_testing;
