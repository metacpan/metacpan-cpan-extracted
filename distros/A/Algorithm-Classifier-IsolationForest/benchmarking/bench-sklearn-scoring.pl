#!/usr/bin/perl
# benchmarking/bench-sklearn-scoring.pl
#
# Compares scoring throughput between this module and scikit-learn's
# IsolationForest across two axes:
#   * query-set size       (fixed feature count)
#   * feature-vector width (fixed query-set size)
#
# The same training CSV and query CSVs are used by both sides so the
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
# The table shows "ratio = sklearn ops/s / Perl ops/s" for methods that
# have direct equivalents.  >1 means sklearn is faster; <1 means Perl.
#
# scikit-learn is optional: if not installed, only Perl results are shown.
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
    my ($train) = @_;
    return Algorithm::Classifier::IsolationForest->new(
        n_trees     => $N_TREES,
        sample_size => $PSI,
        seed        => 1,
    )->fit($train);
}

# -----------------------------------------------------------------------
# Build experiments (data + Perl model) once, outside all timing.
#
# Each experiment is:
#   { sweep, label, train_csv, query_csv, query_data, perl_model, n_features }
# sweep is 'qsize' or 'features' and groups results into output tables.
# Experiments that share a train_csv reuse the same Perl model (and
# Python side caches its sklearn model by train_csv path too).
# -----------------------------------------------------------------------
srand(42);

my @experiments;

# Query-size sweep: vary query size, fix features at $N_FEATURES.
{
    my $train_data = make_data( $N_TRAIN, $N_FEATURES );
    my $train_csv  = write_csv($train_data);
    my $model      = build_model($train_data);
    for my $sz (@query_sizes) {
        my $q = make_data( $sz, $N_FEATURES );
        push @experiments, {
            sweep      => 'qsize',
            label      => $sz,
            train_csv  => $train_csv,
            query_csv  => write_csv($q),
            query_data => $q,
            perl_model => $model,
            n_features => $N_FEATURES,
        };
    }
}

# Feature sweep: vary feature count, fix query size at $FEATURE_QUERY_SIZE.
# Each feature count needs its own training set (and therefore its own model).
for my $nf (@feature_sizes) {
    my $train_data = make_data( $N_TRAIN, $nf );
    my $train_csv  = write_csv($train_data);
    my $model      = build_model($train_data);
    my $q          = make_data( $FEATURE_QUERY_SIZE, $nf );
    push @experiments, {
        sweep      => 'features',
        label      => $nf,
        train_csv  => $train_csv,
        query_csv  => write_csv($q),
        query_data => $q,
        perl_model => $model,
        n_features => $nf,
    };
}

# Unique key per experiment, used to join Perl + Python results.
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
#
# Receives:  bench_secs  spec1  spec2  ...
# where each spec is  "train_csv|query_csv|label"  (| chosen to avoid
# any collision with characters in tempfile paths).
#
# Models are cached by train_csv path so a single training set shared by
# many experiments (e.g. the query-size sweep) is fit only once.
#
# Outputs JSON keyed by label:
#   { "qsize_100": { "score_samples": N, "predict": N, ... }, ... }
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
# Run Python (one subprocess, all experiments, to avoid repeated import cost)
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
# Run Perl benchmarks (all methods, all experiments)
# -----------------------------------------------------------------------
my %pl;
for my $exp (@experiments) {
    my $model = $exp->{perl_model};
    my $q     = $exp->{query_data};

    # Pre-pack the query data once so the *_packed rows measure scoring
    # in isolation, without the per-call pack_input_xs cost.  Only the
    # C backend supports packed input; if it's missing, just reuse $q
    # so the bench still runs (and the "packed" rows match the unpacked
    # ones).
    my $packed
        = $Algorithm::Classifier::IsolationForest::HAS_C
        ? $model->pack_data($q)
        : $q;

    $pl{ exp_key($exp) } = {
        score_samples         => wall_rate( sub { $model->score_samples($q)              }, $BENCH_SECS ),
        score_samples_packed  => wall_rate( sub { $model->score_samples($packed)         }, $BENCH_SECS ),
        predict               => wall_rate( sub { $model->predict($q)                    }, $BENCH_SECS ),
        predict_packed        => wall_rate( sub { $model->predict($packed)               }, $BENCH_SECS ),
        score_predict_samples => wall_rate( sub { $model->score_predict_samples($q)      }, $BENCH_SECS ),
        score_predict_split   => wall_rate( sub { $model->score_predict_split($q)        }, $BENCH_SECS ),
        score_predict_split_packed
                              => wall_rate( sub { $model->score_predict_split($packed)   }, $BENCH_SECS ),
        path_lengths          => wall_rate( sub { $model->path_lengths($q)               }, $BENCH_SECS ),
    };
}

# -----------------------------------------------------------------------
# Display
# -----------------------------------------------------------------------
# Row definitions: [ label, perl_key, sklearn_key ]
my @rows = (
    [ 'score_samples',              'score_samples',              'score_samples'     ],
    [ 'score_samples (packed)',     'score_samples_packed',       undef               ],
    [ 'predict',                    'predict',                    'predict'           ],
    [ 'predict (packed)',           'predict_packed',             undef               ],
    [ 'score_predict_samples',      'score_predict_samples',      undef               ],
    [ 'score_predict_split',        'score_predict_split',        undef               ],
    [ 'score_predict_split (packed)','score_predict_split_packed',undef               ],
    [ 'path_lengths',               'path_lengths',               undef               ],
    [ 'decision_function',          undef,                        'decision_function' ],
);

sub print_point {
    my ($key) = @_;

    if ( defined $sk ) {
        printf "  %-28s  %12s  %14s  %8s\n",
            'method', 'Perl (ops/s)', 'sklearn (ops/s)', 'ratio';
        printf "  %-28s  %12s  %14s  %8s\n",
            '-' x 28, '-' x 12, '-' x 14, '-' x 8;
    }
    else {
        printf "  %-28s  %12s\n", 'method', 'Perl (ops/s)';
        printf "  %-28s  %12s\n", '-' x 28, '-' x 12;
    }

    for my $row (@rows) {
        my ( $label, $pl_key, $sk_key ) = @$row;
        my $pl_rate = $pl_key ? $pl{$key}{$pl_key}        : undef;
        my $sk_rate = ( $sk_key && $sk ) ? $sk->{$key}{$sk_key} : undef;

        if ( defined $sk ) {
            my $ratio
                = ( $pl_rate && $sk_rate )
                ? sprintf( '%.2f', $sk_rate / $pl_rate )
                : '--';
            printf "  %-28s  %12s  %14s  %8s\n",
                $label,
                $pl_rate ? sprintf( '%.1f', $pl_rate ) : '--',
                $sk_rate ? sprintf( '%.1f', $sk_rate ) : '--',
                $ratio;
        }
        else {
            printf "  %-28s  %12s\n",
                $label,
                $pl_rate ? sprintf( '%.1f', $pl_rate ) : '--';
        }
    }
    print "\n";
}

print "=" x 67, "\n";
print " Perl vs scikit-learn -- scoring speed (ops/second, higher = faster)\n";
print "=" x 67, "\n";
printf " Training: %d samples, n_trees=%d, sample_size=%d\n",
    $N_TRAIN, $N_TREES, $PSI;
printf " Each measurement: %.0fs wall-clock with 0.3s warmup\n", $BENCH_SECS;
print " ratio = sklearn ops/s / Perl ops/s  (>1 = sklearn faster)\n";
print " --  = no equivalent method on that side\n\n";

unless ( defined $sk ) {
    print " (scikit-learn not available; showing Perl results only)\n\n";
}

# ---- Query-size sweep ------------------------------------------------
print "#" x 67, "\n";
printf "# Query-size sweep (features fixed at %d)\n", $N_FEATURES;
print "#" x 67, "\n";
for my $exp ( grep { $_->{sweep} eq 'qsize' } @experiments ) {
    printf "--- %d query points ---\n", $exp->{label};
    print_point( exp_key($exp) );
}

# ---- Feature-dimension sweep ----------------------------------------
print "#" x 67, "\n";
printf "# Feature-dimension sweep (query size fixed at %d)\n",
    $FEATURE_QUERY_SIZE;
print "#" x 67, "\n";
for my $exp ( grep { $_->{sweep} eq 'features' } @experiments ) {
    printf "--- %d features ---\n", $exp->{label};
    print_point( exp_key($exp) );
}
