#!/usr/bin/perl
# benchmarking/bench-fit.pl
#
# Benchmarks the fit() method across five dimensions:
#   1. n_trees          -- number of isolation trees
#   2. sample_size/psi  -- sub-sample size used to build each tree
#   3. dataset size     -- number of training samples
#   4. feature count    -- dimensionality (wide range: 2, 5, 10, 20, 50)
#   5. feature count    -- fine-grained 2–10 columns
#
# Each section uses BenchAccel::wall_cmpthese so results include both the raw
# rate (fits/sec) and relative %-difference between variants.
# Data generation is done before timing starts.
#
# Run with:
#   perl -Ilib benchmarking/bench-fit.pl

use strict;
use warnings;
use lib '../lib';
use FindBin;
use lib "$FindBin::Bin";
use BenchAccel qw(wall_cmpthese);
use Algorithm::Classifier::IsolationForest;

use constant PI => 3.14159265358979;

# Simple Box-Muller Gaussian sample
sub gaussian {
    my ( $mu, $sigma ) = @_;
    return $mu + $sigma
        * sqrt( -2 * log( rand() || 1e-12 ) )
        * cos( 2 * PI * rand() );
}

# Generate $n inlier samples ($nf features each) plus ~5% outliers placed at
# radius 5-8 from the origin.
sub make_data {
    my ( $n, $nf ) = @_;
    my @rows = map { [ map { gaussian( 0, 1 ) } 1 .. $nf ] } 1 .. $n;
    for ( 1 .. int( $n * 0.05 ) ) {
        my $r = 5 + rand() * 3;
        push @rows, [ map { $r * ( rand() > 0.5 ? 1 : -1 ) } 1 .. $nf ];
    }
    return \@rows;
}

print "=" x 62, "\n";
print " fit() benchmarks -- Algorithm::Classifier::IsolationForest\n";
print "=" x 62, "\n";
print "(rates shown as fits/second wall-clock; higher is faster)\n";

# -----------------------------------------------------------------------
# 1. n_trees
# -----------------------------------------------------------------------
print "\n--- n_trees  (1000 samples, 2 features, sample_size=256) ---\n";
srand(42);
my $d1k = make_data( 1000, 2 );
wall_cmpthese(
    -2,
    {
        'n_trees=10'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 10,  sample_size => 256 )->fit($d1k) },
        'n_trees=50'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 50,  sample_size => 256 )->fit($d1k) },
        'n_trees=100' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit($d1k) },
        'n_trees=200' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 200, sample_size => 256 )->fit($d1k) },
        'n_trees=500' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 500, sample_size => 256 )->fit($d1k) },
    }
);

# -----------------------------------------------------------------------
# 2. sample_size (psi)
# -----------------------------------------------------------------------
print "\n--- sample_size/psi  (1000 samples, 2 features, n_trees=100) ---\n";
wall_cmpthese(
    -2,
    {
        'psi=32'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 32  )->fit($d1k) },
        'psi=64'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 64  )->fit($d1k) },
        'psi=128' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 128 )->fit($d1k) },
        'psi=256' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit($d1k) },
        'psi=512' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 512 )->fit($d1k) },
    }
);

# -----------------------------------------------------------------------
# 3. Dataset size
# -----------------------------------------------------------------------
print "\n--- dataset size  (n_trees=100, sample_size=256, 2 features) ---\n";
srand(42);
my %ds;
$ds{$_} = make_data( $_, 2 ) for ( 500, 1_000, 2_500, 5_000, 10_000 );
wall_cmpthese(
    -2,
    {
        '500 samples'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $ds{500}    ) },
        '1k samples'   => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $ds{1_000}  ) },
        '2.5k samples' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $ds{2_500}  ) },
        '5k samples'   => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $ds{5_000}  ) },
        '10k samples'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $ds{10_000} ) },
    }
);

# -----------------------------------------------------------------------
# 4. Feature count / dimensionality  (wide range)
# -----------------------------------------------------------------------
print "\n--- feature count  (1000 samples, n_trees=100, sample_size=256) ---\n";
srand(42);
my %dfd;
$dfd{$_} = make_data( 1000, $_ ) for ( 2, 5, 10, 20, 50 );
wall_cmpthese(
    -2,
    {
        '2 features'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfd{2}  ) },
        '5 features'  => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfd{5}  ) },
        '10 features' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfd{10} ) },
        '20 features' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfd{20} ) },
        '50 features' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfd{50} ) },
    }
);

# -----------------------------------------------------------------------
# 5. Feature count / dimensionality  (fine-grained 2–10)
# -----------------------------------------------------------------------
print "\n--- feature count 2-10  (1000 samples, n_trees=100, sample_size=256) ---\n";
srand(42);
my %dfc;
$dfc{$_} = make_data( 1000, $_ ) for ( 2..10 );
wall_cmpthese(
    -2,
    {
        ' 2 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{2}  ) },
        ' 3 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{3}  ) },
        ' 4 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{4}  ) },
        ' 5 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{5}  ) },
        ' 6 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{6}  ) },
        ' 7 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{7}  ) },
        ' 8 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{8}  ) },
        ' 9 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{9}  ) },
        '10 cols' => sub { Algorithm::Classifier::IsolationForest->new( n_trees => 100, sample_size => 256 )->fit( $dfc{10} ) },
    }
);
