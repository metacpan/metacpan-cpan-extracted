#!/usr/bin/perl
# benchmarking/bench-sklearn-scoring.pl
#
# Compares scoring throughput among three Perl backends and scikit-learn's
# IsolationForest across two axes:
#   * query-set size       (fixed feature count)
#   * feature-vector width (fixed query-set size)
#
# Perl backends benchmarked (when available):
#   pure perl   -- no Inline::C  (use_c => 0)
#   C serial    -- Inline::C, single-threaded  (use_c => 1, use_openmp => 0)
#   C+OpenMP    -- Inline::C + OpenMP parallel (use_c => 1, use_openmp => 1)
#
# The same training CSV and query CSVs are used by all sides so the
# comparison is on identical data.  Models are pre-trained before any
# timing starts.
#
# Method correspondence:
#   Perl score_samples         <-->  clf.score_samples(X)      (same formula, opposite sign)
#   Perl predict               <-->  clf.predict(X)            (same semantics, 0/1 vs -1/+1)
#   Perl score_predict_samples <-->  (no sklearn equivalent)
#   Perl score_predict_split   <-->  (no sklearn equivalent)
#   Perl path_lengths          <-->  (no sklearn equivalent)
#   (no Perl equivalent)       <-->  clf.decision_function(X)  (threshold-shifted score)
#
# The ratio column shows sklearn ops/s / best-Perl ops/s.
# >1 means sklearn is faster; <1 means Perl is faster.
#
# Unavailable backends (Inline::C not installed, OpenMP not linked,
# scikit-learn not installed) are omitted from the table.
#
# Run with:
#   perl -Ilib benchmarking/bench-sklearn-scoring.pl

use strict;
use warnings;
use lib '../lib';
use FindBin;
use lib "$FindBin::Bin";
use BenchAccel  qw(wall_rate);
use File::Temp  qw(tempfile);
use JSON::PP    ();
use Algorithm::Classifier::IsolationForest;

use constant PI => 3.14159265358979;

my $HAS_C      = $Algorithm::Classifier::IsolationForest::HAS_C;
my $HAS_OPENMP = $Algorithm::Classifier::IsolationForest::HAS_OPENMP;

# -----------------------------------------------------------------------
# Data generation
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Parameters
# -----------------------------------------------------------------------
my $N_TRAIN    = 1000;
my $N_FEATURES = 2;       # used for the query-size sweep
my $N_TREES    = 100;
my $PSI        = 256;
my $BENCH_SECS = 2;

my @query_sizes        = ( 100, 500, 1_000, 5_000, 10_000 );
my @feature_sizes      = ( 2, 5, 10, 25, 50, 100 );
my $FEATURE_QUERY_SIZE = 1_000;

# -----------------------------------------------------------------------
# Helpers for building experiments
# -----------------------------------------------------------------------
sub write_csv {
    my ($data) = @_;
    my ( $fh, $path ) = tempfile( SUFFIX => '.csv', UNLINK => 1 );
    print $fh join( ',', @$_ ) . "\n" for @$data;
    close $fh;
    return $path;
}

sub build_model {
    my ( $train, %opts ) = @_;
    return Algorithm::Classifier::IsolationForest->new(
        n_trees     => $N_TREES,
        sample_size => $PSI,
        seed        => 1,
        %opts,
    )->fit($train);
}

# -----------------------------------------------------------------------
# Build experiments (data + model variants) once, outside all timing.
#
# Each experiment is:
#   { sweep, label, train_csv, query_csv, query_data, n_features,
#     pure_model, c_model, omp_model }
#
# pure_model is always built (use_c => 0).
# c_model    is built when $HAS_C      (use_c => 1, use_openmp => 0).
# omp_model  is built when $HAS_OPENMP (use_c => 1, use_openmp => 1).
#
# Experiments sharing a training set reuse the same model objects.
# -----------------------------------------------------------------------
srand(42);

my @experiments;

# Query-size sweep: vary query size, fix features at $N_FEATURES.
{
    my $train_data = make_data( $N_TRAIN, $N_FEATURES );
    my $train_csv  = write_csv($train_data);
    my $pure_model = build_model( $train_data, use_c => 0, use_openmp => 0 );
    my $c_model    = $HAS_C      ? build_model( $train_data, use_c => 1, use_openmp => 0 ) : undef;
    my $omp_model  = $HAS_OPENMP ? build_model( $train_data, use_c => 1, use_openmp => 1 ) : undef;
    for my $sz (@query_sizes) {
        my $q = make_data( $sz, $N_FEATURES );
        push @experiments, {
            sweep      => 'qsize',
            label      => $sz,
            train_csv  => $train_csv,
            query_csv  => write_csv($q),
            query_data => $q,
            pure_model => $pure_model,
            c_model    => $c_model,
            omp_model  => $omp_model,
            n_features => $N_FEATURES,
        };
    }
}

# Feature sweep: vary feature count, fix query size at $FEATURE_QUERY_SIZE.
for my $nf (@feature_sizes) {
    my $train_data = make_data( $N_TRAIN, $nf );
    my $train_csv  = write_csv($train_data);
    my $pure_model = build_model( $train_data, use_c => 0, use_openmp => 0 );
    my $c_model    = $HAS_C      ? build_model( $train_data, use_c => 1, use_openmp => 0 ) : undef;
    my $omp_model  = $HAS_OPENMP ? build_model( $train_data, use_c => 1, use_openmp => 1 ) : undef;
    my $q          = make_data( $FEATURE_QUERY_SIZE, $nf );
    push @experiments, {
        sweep      => 'features',
        label      => $nf,
        train_csv  => $train_csv,
        query_csv  => write_csv($q),
        query_data => $q,
        pure_model => $pure_model,
        c_model    => $c_model,
        omp_model  => $omp_model,
        n_features => $nf,
    };
}

sub exp_key { "$_[0]{sweep}_$_[0]{label}" }

# -----------------------------------------------------------------------
# Locate Python + scikit-learn
# -----------------------------------------------------------------------
my $python_bin;
for my $cmd (qw(python3 python)) {
    my $probe = `$cmd -c "import sklearn; print('ok')" 2>/dev/null`;
    if ( defined $probe && $probe =~ /\bok\b/ ) {
        $python_bin = $cmd;
        last;
    }
}

# -----------------------------------------------------------------------
# Python benchmarking script (embedded, written to a temp file).
# -----------------------------------------------------------------------
my $py_script = <<'END_PY';
import sys, json
import time as pytime
import numpy as np
from sklearn.ensemble import IsolationForest

def bench(fn, seconds):
    t0 = pytime.perf_counter()
    while pytime.perf_counter() - t0 < 0.3:
        fn()
    t0 = pytime.perf_counter()
    n = 0
    while pytime.perf_counter() - t0 < seconds:
        fn()
        n += 1
    return n / (pytime.perf_counter() - t0)

def load_csv(path):
    with open(path) as f:
        return np.array([[float(v) for v in ln.strip().split(',')]
                         for ln in f if ln.strip()])

bench_secs = float(sys.argv[1])
specs      = sys.argv[2:]

models = {}
results = {}
for spec in specs:
    train_csv, query_csv, label = spec.split('|', 2)
    clf = models.get(train_csv)
    if clf is None:
        X_train = load_csv(train_csv)
        psi = min(256, len(X_train))
        clf = IsolationForest(n_estimators=100, max_samples=psi,
                              contamination='auto', random_state=1)
        clf.fit(X_train)
        models[train_csv] = clf
    X_q = load_csv(query_csv)
    results[label] = {
        'score_samples':     bench(lambda X=X_q: clf.score_samples(X),     bench_secs),
        'predict':           bench(lambda X=X_q: clf.predict(X),           bench_secs),
        'decision_function': bench(lambda X=X_q: clf.decision_function(X), bench_secs),
    }

print(json.dumps(results))
END_PY

# -----------------------------------------------------------------------
# Run Python (one subprocess for all experiments)
# -----------------------------------------------------------------------
my $sk;
if ( defined $python_bin ) {
    my ( $py_fh, $py_path ) = tempfile( SUFFIX => '.py', UNLINK => 1 );
    print $py_fh $py_script;
    close $py_fh;

    my $specs = join( ' ',
        map { qq("$_->{train_csv}|$_->{query_csv}|@{[exp_key($_)]}") }
            @experiments );
    my $raw = `$python_bin "$py_path" $BENCH_SECS $specs 2>/dev/null`;
    $sk     = eval { JSON::PP->new->decode($raw) };
}

# -----------------------------------------------------------------------
# Run Perl benchmarks for all three backends
# -----------------------------------------------------------------------
my ( %pure_pl, %c_pl, %omp_pl );

for my $exp (@experiments) {
    my $key = exp_key($exp);
    my $q   = $exp->{query_data};

    # Pure Perl
    {
        my $m = $exp->{pure_model};
        $pure_pl{$key} = {
            score_samples         => wall_rate( sub { $m->score_samples($q)         }, $BENCH_SECS ),
            predict               => wall_rate( sub { $m->predict($q)               }, $BENCH_SECS ),
            score_predict_samples => wall_rate( sub { $m->score_predict_samples($q) }, $BENCH_SECS ),
            score_predict_split   => wall_rate( sub { $m->score_predict_split($q)   }, $BENCH_SECS ),
            path_lengths          => wall_rate( sub { $m->path_lengths($q)          }, $BENCH_SECS ),
        };
    }

    # C serial (single-threaded Inline::C)
    if ($HAS_C) {
        my $m      = $exp->{c_model};
        my $packed = $m->pack_data($q);
        $c_pl{$key} = {
            score_samples              => wall_rate( sub { $m->score_samples($q)              }, $BENCH_SECS ),
            score_samples_packed       => wall_rate( sub { $m->score_samples($packed)         }, $BENCH_SECS ),
            predict                    => wall_rate( sub { $m->predict($q)                    }, $BENCH_SECS ),
            predict_packed             => wall_rate( sub { $m->predict($packed)               }, $BENCH_SECS ),
            score_predict_samples      => wall_rate( sub { $m->score_predict_samples($q)      }, $BENCH_SECS ),
            score_predict_split        => wall_rate( sub { $m->score_predict_split($q)        }, $BENCH_SECS ),
            score_predict_split_packed => wall_rate( sub { $m->score_predict_split($packed)   }, $BENCH_SECS ),
            path_lengths               => wall_rate( sub { $m->path_lengths($q)               }, $BENCH_SECS ),
        };
    }

    # C + OpenMP (parallel Inline::C)
    if ($HAS_OPENMP) {
        my $m      = $exp->{omp_model};
        my $packed = $m->pack_data($q);
        $omp_pl{$key} = {
            score_samples              => wall_rate( sub { $m->score_samples($q)              }, $BENCH_SECS ),
            score_samples_packed       => wall_rate( sub { $m->score_samples($packed)         }, $BENCH_SECS ),
            predict                    => wall_rate( sub { $m->predict($q)                    }, $BENCH_SECS ),
            predict_packed             => wall_rate( sub { $m->predict($packed)               }, $BENCH_SECS ),
            score_predict_samples      => wall_rate( sub { $m->score_predict_samples($q)      }, $BENCH_SECS ),
            score_predict_split        => wall_rate( sub { $m->score_predict_split($q)        }, $BENCH_SECS ),
            score_predict_split_packed => wall_rate( sub { $m->score_predict_split($packed)   }, $BENCH_SECS ),
            path_lengths               => wall_rate( sub { $m->path_lengths($q)               }, $BENCH_SECS ),
        };
    }
}

# -----------------------------------------------------------------------
# Display
# -----------------------------------------------------------------------

# Row layout: [ label, pure_key, c_key, omp_key, sklearn_key ]
# undef means "not applicable for this backend/side"
my @rows = (
    [ 'score_samples',               'score_samples',        'score_samples',        'score_samples',             'score_samples'     ],
    [ 'score_samples (packed)',       undef,                  'score_samples_packed', 'score_samples_packed',      undef               ],
    [ 'predict',                     'predict',              'predict',              'predict',                   'predict'           ],
    [ 'predict (packed)',             undef,                  'predict_packed',       'predict_packed',            undef               ],
    [ 'score_predict_samples',       'score_predict_samples','score_predict_samples','score_predict_samples',     undef               ],
    [ 'score_predict_split',         'score_predict_split',  'score_predict_split',  'score_predict_split',       undef               ],
    [ 'score_predict_split (packed)', undef,                 'score_predict_split_packed','score_predict_split_packed', undef         ],
    [ 'path_lengths',                'path_lengths',         'path_lengths',         'path_lengths',              undef               ],
    [ 'decision_function',           undef,                  undef,                  undef,                       'decision_function' ],
);

my $MW = 28;    # method column width
my $NW = 12;    # numeric backend column width
my $SW = 14;    # sklearn column width
my $RW = 8;     # ratio column width

sub fmt_rate { defined $_[0] && $_[0] ? sprintf( '%.1f', $_[0] ) : '--' }

sub print_point {
    my ($key) = @_;

    # Header row
    my @hdr = ( sprintf( "  %-*s", $MW, 'method' ) );
    push @hdr, sprintf( "  %*s", $NW, 'perl (ops/s)' );
    push @hdr, sprintf( "  %*s", $NW, 'C (ops/s)' )     if $HAS_C;
    push @hdr, sprintf( "  %*s", $NW, 'C+OMP(ops/s)' )  if $HAS_OPENMP;
    push @hdr, sprintf( "  %*s", $SW, 'sklearn(ops/s)' ) if defined $sk;
    push @hdr, sprintf( "  %*s", $RW, 'ratio' )          if defined $sk;
    print join( '', @hdr ), "\n";

    # Separator row
    my @sep = ( '  ' . '-' x $MW );
    push @sep, '  ' . '-' x $NW;
    push @sep, '  ' . '-' x $NW if $HAS_C;
    push @sep, '  ' . '-' x $NW if $HAS_OPENMP;
    push @sep, '  ' . '-' x $SW if defined $sk;
    push @sep, '  ' . '-' x $RW if defined $sk;
    print join( '', @sep ), "\n";

    for my $row (@rows) {
        my ( $label, $pure_key, $c_key, $omp_key, $sk_key ) = @$row;

        # Skip rows where every available column would show '--'
        next
            unless $pure_key
            || ( $c_key   && $HAS_C )
            || ( $omp_key && $HAS_OPENMP )
            || ( $sk_key  && $sk );

        my $pure_rate = $pure_key                    ? $pure_pl{$key}{$pure_key}       : undef;
        my $c_rate    = ( $c_key   && $HAS_C )       ? $c_pl{$key}{$c_key}             : undef;
        my $omp_rate  = ( $omp_key && $HAS_OPENMP )  ? $omp_pl{$key}{$omp_key}         : undef;
        my $sk_rate   = ( $sk_key  && $sk )          ? $sk->{$key}{$sk_key}            : undef;

        # Best available Perl rate for the ratio denominator
        my $best = $omp_rate // $c_rate // $pure_rate;

        my @cols = ( sprintf( "  %-*s", $MW, $label ) );
        push @cols, sprintf( "  %*s", $NW, fmt_rate($pure_rate) );
        push @cols, sprintf( "  %*s", $NW, fmt_rate($c_rate) )   if $HAS_C;
        push @cols, sprintf( "  %*s", $NW, fmt_rate($omp_rate) ) if $HAS_OPENMP;

        if ( defined $sk ) {
            push @cols, sprintf( "  %*s", $SW, fmt_rate($sk_rate) );
            my $ratio = ( $best && $sk_rate )
                ? sprintf( '%.2f', $sk_rate / $best ) : '--';
            push @cols, sprintf( "  %*s", $RW, $ratio );
        }

        print join( '', @cols ), "\n";
    }
    print "\n";
}

# -----------------------------------------------------------------------
# Banner
# -----------------------------------------------------------------------
my $TW = 2 + $MW + 2 + $NW
    + ( $HAS_C      ? 2 + $NW : 0 )
    + ( $HAS_OPENMP ? 2 + $NW : 0 )
    + ( defined $sk ? 2 + $SW + 2 + $RW : 0 );

my $backends = 'pure-Perl'
    . ( $HAS_C      ? ', C serial'  : '' )
    . ( $HAS_OPENMP ? ', C+OpenMP'  : '' );

print '=' x $TW, "\n";
printf " Perl (%s) vs scikit-learn -- scoring speed (ops/s)\n", $backends;
print '=' x $TW, "\n";
printf " Training: %d samples, n_trees=%d, sample_size=%d\n",
    $N_TRAIN, $N_TREES, $PSI;
printf " Each measurement: %.0fs wall-clock with warmup\n", $BENCH_SECS;
print  " ratio = sklearn ops/s / best-Perl ops/s  (>1 = sklearn faster)\n";
print  " --  = no equivalent or backend not available\n";
print  " packed = pre-packed input (skips per-call AoA walk; C backend only)\n";
print "\n";

unless ( defined $sk ) {
    print " (scikit-learn not available; showing Perl results only)\n\n";
}

# ---- Query-size sweep -----------------------------------------------
print '#' x $TW, "\n";
printf "# Query-size sweep (features fixed at %d)\n", $N_FEATURES;
print '#' x $TW, "\n";
for my $exp ( grep { $_->{sweep} eq 'qsize' } @experiments ) {
    printf "--- %d query points ---\n", $exp->{label};
    print_point( exp_key($exp) );
}

# ---- Feature-dimension sweep ----------------------------------------
print '#' x $TW, "\n";
printf "# Feature-dimension sweep (query size fixed at %d)\n",
    $FEATURE_QUERY_SIZE;
print '#' x $TW, "\n";
for my $exp ( grep { $_->{sweep} eq 'features' } @experiments ) {
    printf "--- %d features ---\n", $exp->{label};
    print_point( exp_key($exp) );
}
