#!/usr/bin/perl
# benchmarking/bench-extended-predict-accel.pl
#
# Benchmarks extended-mode (EIF) scoring/prediction under each
# acceleration backend:
#   pure_perl   -- use_c => 0                   (pure Perl tree walk)
#   c_serial    -- use_c => 1, use_openmp => 0  (C tree walk, single thread)
#   c_openmp    -- use_c => 1, use_openmp => 1  (C tree walk, OpenMP parallel)
#
# Extended mode adds an oblique dot product at every internal node.  The
# C backend uses `#pragma omp simd` to auto-vectorize that dot product
# (when OpenMP 4.0+ is available), so the c_serial vs c_openmp gap may
# be wider here than in axis mode, especially at high feature counts.
#
# Sections:
#   1. Scoring method comparison  -- all 5 methods under each backend
#   2. Query set size scaling     -- where OpenMP parallelism shines
#   3. n_trees scaling            -- more trees = more work per point
#   4. Feature count (wide)       -- 2, 5, 10, 20, 50
#   5. Feature count (2-10)       -- fine-grained sweep
#
# Models are pre-trained before any timing begins.
#
# Run with:
#   perl -Ilib benchmarking/bench-extended-predict-accel.pl

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

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

sub build_models {
    my (%opts) = @_;
    my $data = delete $opts{_data};
    my %m;
    $m{pure_perl} = Algorithm::Classifier::IsolationForest->new(
        %opts, use_c => 0,
    )->fit($data);
    if ($HAS_C) {
        $m{c_serial} = Algorithm::Classifier::IsolationForest->new(
            %opts, use_c => 1, use_openmp => 0,
        )->fit($data);
    }
    if ( $HAS_C && $HAS_OPENMP ) {
        $m{c_openmp} = Algorithm::Classifier::IsolationForest->new(
            %opts, use_c => 1, use_openmp => 1,
        )->fit($data);
    }
    return \%m;
}

print "=" x 70, "\n";
print " extended-mode scoring/predict accel benchmarks\n";
print " Algorithm::Classifier::IsolationForest\n";
print "=" x 70, "\n";
printf "Backend availability: HAS_C=%d  HAS_OPENMP=%d  HAS_SIMD=%d\n",
    $HAS_C, $HAS_OPENMP,
    $Algorithm::Classifier::IsolationForest::HAS_SIMD;
print "(rates shown as calls/second wall-clock; higher is faster)\n";

# -----------------------------------------------------------------------
# 1. Scoring method comparison  (n_trees=100, 1000 query points)
# -----------------------------------------------------------------------
print "\n--- scoring methods  (n_trees=100, 1000 query points, 2 features) ---\n";
srand(42);
my $train = make_data( 1000, 2 );
my $q1k   = make_data( 1000, 2 );
my $models = build_models(
    n_trees     => 100,
    sample_size => 256,
    mode        => 'extended',
    seed        => 1,
    _data       => $train,
);

for my $method (qw(score_samples predict score_predict_samples
    score_predict_split path_lengths))
{
    printf "\n  %s\n", $method;
    my %v;
    for my $accel ( sort keys %$models ) {
        my $m = $models->{$accel};
        if ( $method eq 'predict' || $method eq 'score_predict_samples'
            || $method eq 'score_predict_split' )
        {
            $v{$accel} = sub { $m->$method( $q1k, 0.5 ) };
        }
        else {
            $v{$accel} = sub { $m->$method($q1k) };
        }
    }
    wall_cmpthese( -2, \%v );
}

# -----------------------------------------------------------------------
# 2. Query set size scaling  (n_trees=100, score_samples)
# -----------------------------------------------------------------------
print "\n--- query set size  (n_trees=100, score_samples, 2 features) ---\n";
srand(99);
my %q;
$q{$_} = make_data( $_, 2 ) for ( 100, 500, 1_000, 5_000, 10_000 );
for my $n ( 100, 500, 1_000, 5_000, 10_000 ) {
    printf "\n  %d query points\n", $n;
    my %v;
    for my $accel ( sort keys %$models ) {
        $v{$accel} = sub { $models->{$accel}->score_samples( $q{$n} ) };
    }
    wall_cmpthese( -2, \%v );
}

# -----------------------------------------------------------------------
# 3. n_trees scaling  (1000 query points, score_samples)
# -----------------------------------------------------------------------
print "\n--- n_trees effect  (1000 query points, 2 features) ---\n";
srand(42);
my $train2 = make_data( 1000, 2 );
for my $nt ( 10, 50, 100, 200, 500 ) {
    printf "\n  n_trees=%d\n", $nt;
    my $ms = build_models(
        n_trees     => $nt,
        sample_size => 256,
        mode        => 'extended',
        seed        => 1,
        _data       => $train2,
    );
    my %v;
    for my $accel ( sort keys %$ms ) {
        $v{$accel} = sub { $ms->{$accel}->score_samples($q1k) };
    }
    wall_cmpthese( -2, \%v );
}

# -----------------------------------------------------------------------
# 4. Feature count (wide range)
# -----------------------------------------------------------------------
print "\n--- feature count  (n_trees=100, 1000 query points) ---\n";
srand(42);
for my $nf ( 2, 5, 10, 20, 50 ) {
    printf "\n  %d features\n", $nf;
    my $tr = make_data( 1000, $nf );
    my $qr = make_data( 1000, $nf );
    my $ms = build_models(
        n_trees     => 100,
        sample_size => 256,
        mode        => 'extended',
        seed        => 1,
        _data       => $tr,
    );
    my %v;
    for my $accel ( sort keys %$ms ) {
        $v{$accel} = sub { $ms->{$accel}->score_samples($qr) };
    }
    wall_cmpthese( -2, \%v );
}

# -----------------------------------------------------------------------
# 5. Feature count (fine-grained 2-10)
# -----------------------------------------------------------------------
print "\n--- feature count 2-10  (n_trees=100, 1000 query points) ---\n";
srand(42);
for my $nf ( 2 .. 10 ) {
    printf "\n  %d columns\n", $nf;
    my $tr = make_data( 1000, $nf );
    my $qr = make_data( 1000, $nf );
    my $ms = build_models(
        n_trees     => 100,
        sample_size => 256,
        mode        => 'extended',
        seed        => 1,
        _data       => $tr,
    );
    my %v;
    for my $accel ( sort keys %$ms ) {
        $v{$accel} = sub { $ms->{$accel}->score_samples($qr) };
    }
    wall_cmpthese( -2, \%v );
}
