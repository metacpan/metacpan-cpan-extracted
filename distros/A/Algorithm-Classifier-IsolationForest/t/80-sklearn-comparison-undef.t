#!perl
# 80-sklearn-comparison-undef.t
#
# Verifies consistent handling of undef (Perl) / NaN (Python) when one or
# more feature columns are missing during scoring and prediction.
#
# Perl coerces undef to 0 in numeric comparisons, so score_samples and
# predict on data with undef columns are bit-for-bit identical to the same
# calls with explicit 0 in those columns.  The Python side uses
# numpy.where(isnan, 0, x) to apply the same substitution before scoring.
#
# The same battery runs against multiple datasets so the undef handling is
# exercised on more than the 2-feature case:
#
#   * "2d_grid"      -- 225 grid inliers + 8 outliers (2 dims); y-column undef
#   * "5d_gaussian"  -- 200 Gaussian inliers + 8 corner outliers (5 dims);
#                       4 trailing columns undef
#   * "10d_gaussian" -- same shape in 10 dims; 9 trailing columns undef
#
# For each dataset:
#   1. score_samples([x, undef, ...]) == score_samples([x, 0, ...])  exact
#   2. predict([x, undef, ...])       == predict([x, 0, ...])        exact
#   3. Spearman rho between Perl(undef→0) and sklearn(NaN→0) scores >= 0.90
#   4. Both implementations still rank the x-axis outliers above the
#      inliers after the trailing columns are erased.
#
# Subtests 3 and 4 are skipped per-dataset if Python or scikit-learn is
# unavailable.

use strict;
use warnings;
use Test::More;
use List::Util qw(sum min max);
use File::Temp qw(tempfile);
use JSON::PP   ();

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

use constant PI => 3.14159265358979;

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------
sub mean { @_ ? sum(@_) / @_ : 0 }

sub _assign_ranks {
    my @v   = @_;
    my @idx = sort { $v[$a] <=> $v[$b] } 0 .. $#v;
    my @r;
    $r[ $idx[$_] ] = $_ + 1 for 0 .. $#idx;
    return @r;
}

sub spearman_rho {
    my ( $xs, $ys ) = @_;
    my @rx = _assign_ranks(@$xs);
    my @ry = _assign_ranks(@$ys);
    my $n  = scalar @rx;
    my ( $sa, $sb, $saa, $sbb, $sab ) = (0) x 5;
    for my $i ( 0 .. $n - 1 ) {
        $sa  += $rx[$i];
        $sb  += $ry[$i];
        $saa += $rx[$i]**2;
        $sbb += $ry[$i]**2;
        $sab += $rx[$i] * $ry[$i];
    }
    my ( $ma, $mb ) = ( $sa / $n, $sb / $n );
    my $cov = $sab / $n - $ma * $mb;
    my $da  = sqrt( $saa / $n - $ma**2 );
    my $db  = sqrt( $sbb / $n - $mb**2 );
    return ( $da > 0 && $db > 0 ) ? $cov / ( $da * $db ) : 0;
}

sub gaussian {
    my ( $mu, $sigma ) = @_;
    return $mu + $sigma
        * sqrt( -2 * log( rand() || 1e-12 ) )
        * cos( 2 * PI * rand() );
}

# Test points used by every dataset: column 0 (x) carries the signal,
# columns 1..nf-1 are undef.  The matching @zero variant replaces undef
# with explicit 0.0 so the pure-Perl identity test has something to
# compare against.
sub make_undef_test_points {
    my ($nf) = @_;
    my @undef_test = (
        ( map { [ $_ * 0.1, (undef) x ( $nf - 1 ) ] } -9 .. 9 ),               # 19 inlier-like
        ( map { [ $_,       (undef) x ( $nf - 1 ) ] } ( 6, 7, 8, -6, -7, -8 ) ), # 6 outlier-like
    );
    my @zero_test = map {
        [ $_->[0], (0.0) x ( $nf - 1 ) ]
    } @undef_test;
    return ( \@undef_test, \@zero_test );
}

# -----------------------------------------------------------------------
# Datasets
#
# Each dataset hashref has:
#   label      -- short id (Python output key + subtest name)
#   n_feat     -- feature count
#   train      -- arrayref of training rows (no undef)
#   undef_test -- arrayref of test rows with undef in columns 1..nf-1
#   zero_test  -- same test rows but with explicit 0.0 in place of undef
#   n_in_test  -- number of leading inlier-like test rows
#   n_out_test -- number of trailing outlier-like test rows
#   mean_gap_min -- lower bound for mean(outlier) - mean(inlier) Perl scores.
#                   Set per-dataset because the gap shrinks as nf grows:
#                   trees that don't split on the lone signal column treat
#                   inlier-like and outlier-like test points identically, so
#                   their contribution to the score is the same.  Ordering
#                   (min/max separation) still holds in every dimension.
# -----------------------------------------------------------------------

# 2D regular grid + corner/axis outliers (the original undef dataset).
sub make_2d_grid_dataset {
    my @inliers;
    for my $i ( -7 .. 7 ) {
        for my $j ( -7 .. 7 ) {
            push @inliers, [ $i / 7.0, $j / 7.0 ];
        }
    }
    my @outliers = (
        [ 6, 6 ], [ -6, 6 ], [ 6, -6 ], [ -6, -6 ],
        [ 0, 8 ], [ 8, 0 ],  [ -8, 0 ], [ 0,  -8 ]
    );
    my ( $undef_test, $zero_test ) = make_undef_test_points(2);
    return {
        label        => '2d_grid',
        n_feat       => 2,
        train        => [ @inliers, @outliers ],
        undef_test   => $undef_test,
        zero_test    => $zero_test,
        n_in_test    => 19,
        n_out_test   => 6,
        mean_gap_min => 0.20,
    };
}

# N-D Gaussian inliers + corner outliers far from origin in every axis.
# Test points still only carry signal in column 0; the other nf-1 columns
# are undef.  Seeded deterministically per dimension.
sub make_nd_gaussian_dataset {
    my ($nf) = @_;
    srand( 20260629 + $nf );

    my @inliers;
    push @inliers, [ map { gaussian( 0, 0.3 ) } 1 .. $nf ] for 1 .. 200;

    my @outliers;
    for ( 1 .. 8 ) {
        my @row;
        for ( 1 .. $nf ) {
            my $mag  = 5 + rand() * 3;
            my $sign = rand() > 0.5 ? 1 : -1;
            push @row, $mag * $sign;
        }
        push @outliers, \@row;
    }

    # Empirical gaps with 1 signal column out of nf, 100 trees, seed 42:
    #   nf=5  -> ~0.13   nf=10 -> ~0.05
    # The threshold is set well under the observed value so trivial RNG
    # noise doesn't flap the test, but high enough to still detect a real
    # regression that would collapse the gap further.
    my $mean_gap_min = $nf <= 5 ? 0.08 : 0.025;

    my ( $undef_test, $zero_test ) = make_undef_test_points($nf);
    return {
        label        => "${nf}d_gaussian",
        n_feat       => $nf,
        train        => [ @inliers, @outliers ],
        undef_test   => $undef_test,
        zero_test    => $zero_test,
        n_in_test    => 19,
        n_out_test   => 6,
        mean_gap_min => $mean_gap_min,
    };
}

my @datasets = (
    make_2d_grid_dataset(),
    make_nd_gaussian_dataset(5),
    make_nd_gaussian_dataset(10),
);

# -----------------------------------------------------------------------
# Locate Python + scikit-learn (cross-language subtests are skipped if
# absent; pure-Perl subtests still run)
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
# Python helper: scores all datasets in one subprocess.  Each argv spec
# is "csv_path|label|n_train"; the CSV concatenates training rows then
# test rows, and n_train is the split point.  Test rows may use the
# token "nan" / "undef" / empty for missing values.
#
# sklearn score_samples convention: lower = more anomalous (opposite of
# Perl), so we negate sklearn scores before computing rank correlation.
# -----------------------------------------------------------------------
my $py_script = <<'END_PY';
import sys, json
import numpy as np
from sklearn.ensemble import IsolationForest

def parse_csv(path):
    rows = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            row = []
            for tok in line.split(','):
                tok = tok.strip()
                if tok.lower() in ('nan', 'undef', ''):
                    row.append(float('nan'))
                else:
                    row.append(float(tok))
            rows.append(row)
    return rows

results = {}
for spec in sys.argv[1:]:
    csv_path, label, n_train = spec.split('|', 2)
    n_train = int(n_train)
    rows    = parse_csv(csv_path)
    X_train = np.array(rows[:n_train], dtype=float)
    X_test  = np.array(rows[n_train:], dtype=float)
    # Mirror Perl's undef-to-0 numeric coercion.
    X_test_clean = np.where(np.isnan(X_test), 0.0, X_test)
    psi = min(256, len(X_train))
    clf = IsolationForest(
        n_estimators=100,
        max_samples=psi,
        contamination='auto',
        random_state=42,
    )
    clf.fit(X_train)
    results[label] = clf.score_samples(X_test_clean).tolist()

print(json.dumps(results))
END_PY

# Run Python once for all datasets, keyed by label.
my $sk_by_label;
if ( defined $python_bin ) {
    my ( $py_fh, $py_path ) = tempfile( SUFFIX => '.py', UNLINK => 1 );
    print $py_fh $py_script;
    close $py_fh;

    my @specs;
    for my $ds (@datasets) {
        my ( $csv_fh, $csv_path ) = tempfile( SUFFIX => '.csv', UNLINK => 1 );
        for my $row ( @{ $ds->{train} } ) {
            print $csv_fh join( ',', @$row ) . "\n";
        }
        for my $row ( @{ $ds->{undef_test} } ) {
            print $csv_fh join( ',', map { defined $_ ? $_ : 'nan' } @$row )
                . "\n";
        }
        close $csv_fh;
        my $n_train = scalar @{ $ds->{train} };
        push @specs, qq("$csv_path|$ds->{label}|$n_train");
    }

    my $raw = `$python_bin "$py_path" @{[ join ' ', @specs ]} 2>/dev/null`;
    my $py  = eval { JSON::PP->new->decode($raw) };
    if ( defined $py && ref $py eq 'HASH' ) {
        $sk_by_label = $py;
    }
    else {
        note 'Python/sklearn script did not return usable output; cross-language subtests will be skipped';
    }
}
else {
    note 'Python with scikit-learn not found; cross-language subtests will be skipped';
}

# -----------------------------------------------------------------------
# Per-dataset test battery
# -----------------------------------------------------------------------
sub run_dataset_tests {
    my ( $ds, $sk_scores ) = @_;

    my $f = $CLASS->new( n_trees => 100, sample_size => 256, seed => 42 );
    $f->fit( $ds->{train} );

    # ---- Subtest 1: score_samples bit-for-bit identity ----
    subtest 'Perl score_samples: undef columns give identical scores to explicit 0' => sub {
        my ( $s_undef, $s_zero );
        {
            local $SIG{__WARN__} = sub { };
            $s_undef = $f->score_samples( $ds->{undef_test} );
        }
        $s_zero = $f->score_samples( $ds->{zero_test} );

        is( scalar @$s_undef, scalar @$s_zero, 'same number of scores returned' );

        my $diffs = grep { $s_undef->[$_] != $s_zero->[$_] } 0 .. $#$s_undef;
        is( $diffs, 0,
            'every score with undef columns is bit-for-bit identical to score with explicit 0'
        );
    };

    # ---- Subtest 2: predict bit-for-bit identity ----
    subtest 'Perl predict: undef columns give identical labels to explicit 0' => sub {
        my ( $l_undef, $l_zero );
        {
            local $SIG{__WARN__} = sub { };
            $l_undef = $f->predict( $ds->{undef_test} );
        }
        $l_zero = $f->predict( $ds->{zero_test} );

        is( scalar @$l_undef, scalar @$l_zero, 'same number of labels returned' );

        my $diffs = grep { $l_undef->[$_] != $l_zero->[$_] } 0 .. $#$l_undef;
        is( $diffs, 0,
            'every predict label with undef columns is identical to label with explicit 0'
        );
    };

    return unless defined $sk_scores;

    # Perl scores for the same test points (undef → 0 coercion)
    my $perl_scores;
    {
        local $SIG{__WARN__} = sub { };
        $perl_scores = $f->score_samples( $ds->{undef_test} );
    }

    # ---- Subtest 3: Spearman rho between Perl and sklearn ----
    subtest 'Spearman rank correlation Perl(undef->0) vs sklearn(NaN->0) >= 0.90' => sub {
        my @neg_sk = map { -$_ } @$sk_scores;
        my $rho    = spearman_rho( $perl_scores, \@neg_sk );
        cmp_ok( $rho, '>=', 0.90,
            sprintf( 'Spearman rho(Perl, -sklearn) = %.4f (must be >= 0.90)', $rho ) );
    };

    # ---- Subtest 4: outliers still separated after column erasure ----
    subtest 'both agree: x-axis outliers still flagged after trailing columns erased' => sub {
        my $n_in  = $ds->{n_in_test};
        my $n_out = $ds->{n_out_test};

        my @perl_in  = @{$perl_scores}[ 0 .. $n_in - 1 ];
        my @perl_out = @{$perl_scores}[ $n_in .. $n_in + $n_out - 1 ];

        my $gap_min = $ds->{mean_gap_min};
        cmp_ok( mean(@perl_out), '>', mean(@perl_in) + $gap_min,
            sprintf( 'Perl: mean outlier score (undef cols) exceeds mean inlier score by at least %.3f',
                $gap_min ) );
        cmp_ok( min(@perl_out), '>', max(@perl_in),
            'Perl: every x-axis outlier scores strictly higher than every inlier (undef cols)' );

        my @sk_in  = @{$sk_scores}[ 0 .. $n_in - 1 ];
        my @sk_out = @{$sk_scores}[ $n_in .. $n_in + $n_out - 1 ];

        cmp_ok( mean(@sk_out), '<', mean(@sk_in),
            'sklearn: mean outlier score (NaN cols) is lower (more anomalous) than mean inlier score' );
        cmp_ok( max(@sk_out), '<', min(@sk_in),
            'sklearn: every x-axis outlier scores strictly lower than every inlier (NaN cols)' );
    };
}

# -----------------------------------------------------------------------
# Run the battery for each dataset
# -----------------------------------------------------------------------
for my $ds (@datasets) {
    my $sk_scores = $sk_by_label && $sk_by_label->{ $ds->{label} };
    if ( defined $sk_scores
        && !( ref $sk_scores eq 'ARRAY'
            && @$sk_scores == @{ $ds->{undef_test} } ) )
    {
        fail("sklearn output missing or wrong length for dataset '$ds->{label}'");
        $sk_scores = undef;
    }
    subtest "$ds->{label} ($ds->{n_feat} features)" => sub {
        run_dataset_tests( $ds, $sk_scores );
    };
}

done_testing;
