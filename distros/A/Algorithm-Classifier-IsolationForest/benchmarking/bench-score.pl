#!/usr/bin/perl
# benchmarking/bench-score.pl
#
# Benchmarks the five public scoring/prediction methods:
#   score_samples, predict, score_predict_samples, score_predict_split,
#   path_lengths
#
# Sections:
#   1. Scoring method comparison  -- which method has the lowest overhead
#   2. Query set size scaling     -- throughput vs number of points scored
#   3. n_trees scaling on scoring -- effect of model size on score time
#   4. Feature count 2–10         -- fine-grained column-count sweep on scoring
#
# Models are pre-trained before any timing begins.
#
# Run with:
#   perl -Ilib benchmarking/bench-score.pl

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
    return $mu + $sigma
        * sqrt( -2 * log( rand() || 1e-12 ) )
        * cos( 2 * PI * rand() );
}

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
print " scoring benchmarks -- Algorithm::Classifier::IsolationForest\n";
print "=" x 62, "\n";
print "(rates shown as calls/second wall-clock; higher is faster)\n";

# -----------------------------------------------------------------------
# Pre-train models with different n_trees on the same 1000-sample dataset
# -----------------------------------------------------------------------
srand(42);
my $train = make_data( 1000, 2 );
my %model;
for my $nt ( 10, 50, 100, 200, 500 ) {
    $model{$nt} = Algorithm::Classifier::IsolationForest->new(
        n_trees     => $nt,
        sample_size => 256,
        seed        => 1,
    )->fit($train);
}

# Pre-generate query sets of varying sizes
srand(99);
my %q;
$q{$_} = make_data( $_, 2 ) for ( 100, 500, 1_000, 5_000, 10_000 );
my $q1k = $q{1_000};

# -----------------------------------------------------------------------
# 1. Scoring methods compared  (n_trees=100, 1000 query points)
# -----------------------------------------------------------------------
print "\n--- scoring methods  (n_trees=100, 1000 query points) ---\n";
my $m = $model{100};
wall_cmpthese(
    -2,
    {
        'score_samples'         => sub { $m->score_samples($q1k)         },
        'predict'               => sub { $m->predict($q1k)               },
        'score_predict_samples' => sub { $m->score_predict_samples($q1k) },
        'score_predict_split'   => sub { $m->score_predict_split($q1k)   },
        'path_lengths'          => sub { $m->path_lengths($q1k)          },
    }
);

# -----------------------------------------------------------------------
# 2. Query set size  (n_trees=100, score_samples)
# -----------------------------------------------------------------------
print "\n--- query set size  (n_trees=100, score_samples) ---\n";
wall_cmpthese(
    -2,
    {
        '100 pts'   => sub { $m->score_samples( $q{100}    ) },
        '500 pts'   => sub { $m->score_samples( $q{500}    ) },
        '1k pts'    => sub { $m->score_samples( $q{1_000}  ) },
        '5k pts'    => sub { $m->score_samples( $q{5_000}  ) },
        '10k pts'   => sub { $m->score_samples( $q{10_000} ) },
    }
);

# -----------------------------------------------------------------------
# 3. n_trees effect on scoring  (1000 query points, score_samples)
# -----------------------------------------------------------------------
print "\n--- n_trees effect on score_samples  (1000 query points) ---\n";
wall_cmpthese(
    -2,
    {
        'n_trees=10'  => sub { $model{10} ->score_samples($q1k) },
        'n_trees=50'  => sub { $model{50} ->score_samples($q1k) },
        'n_trees=100' => sub { $model{100}->score_samples($q1k) },
        'n_trees=200' => sub { $model{200}->score_samples($q1k) },
        'n_trees=500' => sub { $model{500}->score_samples($q1k) },
    }
);

# -----------------------------------------------------------------------
# 4. Feature count 2–10  (n_trees=100, sample_size=256, 1000 query points)
# -----------------------------------------------------------------------
print "\n--- feature count 2-10  (n_trees=100, sample_size=256, 1000 query points) ---\n";
srand(42);
my ( %fc_model, %fc_query );
for my $nf ( 2..10 ) {
    my $tr = make_data( 1000, $nf );
    $fc_model{$nf} = Algorithm::Classifier::IsolationForest->new(
        n_trees     => 100,
        sample_size => 256,
        seed        => 1,
    )->fit($tr);
    $fc_query{$nf} = make_data( 1000, $nf );
}
wall_cmpthese(
    -2,
    {
        ' 2 cols' => sub { $fc_model{2} ->score_samples( $fc_query{2}  ) },
        ' 3 cols' => sub { $fc_model{3} ->score_samples( $fc_query{3}  ) },
        ' 4 cols' => sub { $fc_model{4} ->score_samples( $fc_query{4}  ) },
        ' 5 cols' => sub { $fc_model{5} ->score_samples( $fc_query{5}  ) },
        ' 6 cols' => sub { $fc_model{6} ->score_samples( $fc_query{6}  ) },
        ' 7 cols' => sub { $fc_model{7} ->score_samples( $fc_query{7}  ) },
        ' 8 cols' => sub { $fc_model{8} ->score_samples( $fc_query{8}  ) },
        ' 9 cols' => sub { $fc_model{9} ->score_samples( $fc_query{9}  ) },
        '10 cols' => sub { $fc_model{10}->score_samples( $fc_query{10} ) },
    }
);
