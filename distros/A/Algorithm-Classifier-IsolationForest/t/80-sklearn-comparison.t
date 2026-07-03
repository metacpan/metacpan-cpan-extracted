#!perl
# 80-sklearn-comparison.t
#
# Cross-language validation: trains both this module and Python scikit-learn's
# IsolationForest on the same dataset and verifies that the two implementations
# agree on anomaly ordering.  The whole file is skipped when Python or
# scikit-learn is not installed.
#
# The same battery of checks is run against multiple datasets so we exercise
# more than the 2-feature case:
#
#   * "2d_grid"      -- 225 inliers on a regular grid in [-1,1]^2 + 8 outliers
#   * "5d_gaussian"  -- 200 Gaussian inliers + 8 corner-style outliers (5 dims)
#   * "10d_gaussian" -- 200 Gaussian inliers + 8 corner-style outliers (10 dims)
#
# Agreement is verified by three complementary checks per dataset:
#   1. Both models clearly separate the obvious outliers from the inliers
#      (score direction test -- Perl: higher = anomalous; sklearn: lower).
#   2. Both models rank the obvious outliers as the top-N anomalies.
#   3. The Spearman rank correlation between the two score vectors is >= 0.85.
#
# Because the models use different RNG implementations they cannot produce
# identical floating-point scores, but any faithful Isolation Forest
# implementation produces highly correlated anomaly rankings on
# well-separated data.

use strict;
use warnings;
use Test::More;
use List::Util qw(sum min max);
use File::Temp qw(tempfile);
use JSON::PP   ();

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# Compare each backend against sklearn: pure-Perl always, C when it compiled.
# A missing C backend skips that arm rather than failing.  sklearn itself is
# run only once (it is unaffected by which Perl backend scores).
my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
    if $Algorithm::Classifier::IsolationForest::HAS_C;

use constant PI => 3.14159265358979;

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------
sub mean { @_ ? sum(@_) / @_ : 0 }

# Assign 1-based ranks; lower value gets lower rank.
sub _assign_ranks {
    my @v   = @_;
    my @idx = sort { $v[$a] <=> $v[$b] } 0 .. $#v;
    my @r;
    $r[ $idx[$_] ] = $_ + 1 for 0 .. $#idx;
    return @r;
}

# Pearson correlation of two rank vectors (= Spearman rho of the originals).
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

# -----------------------------------------------------------------------
# Datasets
#
# Each dataset hashref has:
#   label    -- short identifier (used as Python output key + subtest name)
#   n_feat   -- feature count
#   inliers  -- arrayref of inlier rows
#   outliers -- arrayref of outlier rows
#   data     -- inliers followed by outliers (order matters: tests index by
#               position to pick out outliers in the combined score vector)
#   n_in     -- scalar @inliers
#   n_out    -- scalar @outliers
# -----------------------------------------------------------------------

# 2D regular grid + corner/axis outliers (the original dataset).
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
    return {
        label    => '2d_grid',
        n_feat   => 2,
        inliers  => \@inliers,
        outliers => \@outliers,
        data     => [ @inliers, @outliers ],
        n_in     => scalar @inliers,
        n_out    => scalar @outliers,
    };
}

# N-D Gaussian inliers + corner-style outliers far from origin in every axis.
# Deterministic via a fixed srand seed derived from the dimension.
sub make_nd_gaussian_dataset {
    my ($nf) = @_;
    srand( 20260629 + $nf );

    my @inliers;
    push @inliers, [ map { gaussian( 0, 0.3 ) } 1 .. $nf ] for 1 .. 200;

    # Outliers: each coordinate at magnitude 5..8 with random sign so the
    # point sits at a "corner" of the bounding box, well outside the inlier
    # cluster along *every* axis.  Eight of them, to match the 2D dataset.
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

    return {
        label    => "${nf}d_gaussian",
        n_feat   => $nf,
        inliers  => \@inliers,
        outliers => \@outliers,
        data     => [ @inliers, @outliers ],
        n_in     => scalar @inliers,
        n_out    => scalar @outliers,
    };
}

my @datasets = (
    make_2d_grid_dataset(),
    make_nd_gaussian_dataset(5),
    make_nd_gaussian_dataset(10),
);

# -----------------------------------------------------------------------
# Locate Python + scikit-learn; skip the whole file if unavailable
# -----------------------------------------------------------------------
my $python_bin;
for my $cmd (qw(python3 python)) {
    my $probe = `$cmd -c "import sklearn; print('ok')" 2>/dev/null`;
    if ( defined $probe && $probe =~ /\bok\b/ ) {
        $python_bin = $cmd;
        last;
    }
}

unless ( defined $python_bin ) {
    plan skip_all =>
        'Python with scikit-learn is not installed; skipping cross-language comparison';
}

# -----------------------------------------------------------------------
# Python helper: train sklearn IsolationForest per dataset and emit JSON.
#
# Receives "csv_path|label" pairs on argv and returns a JSON object keyed
# by label with the corresponding score_samples() output.  Batching all
# datasets into a single subprocess avoids paying Python + sklearn import
# cost more than once.
#
# sklearn score_samples convention: lower score = more anomalous.  That
# is the opposite direction from this module (higher = more anomalous),
# so we negate sklearn scores before computing rank correlation.
# -----------------------------------------------------------------------
my $py_script = <<'END_PY';
import sys, json
import numpy as np
from sklearn.ensemble import IsolationForest

results = {}
for spec in sys.argv[1:]:
    csv_path, label = spec.split('|', 1)
    rows = []
    with open(csv_path) as f:
        for line in f:
            line = line.strip()
            if line:
                rows.append([float(x) for x in line.split(',')])
    X = np.array(rows)
    psi = min(256, len(X))
    clf = IsolationForest(
        n_estimators=100,
        max_samples=psi,
        contamination='auto',
        random_state=42,
    )
    clf.fit(X)
    results[label] = clf.score_samples(X).tolist()

print(json.dumps(results))
END_PY

my ( $py_fh, $py_path ) = tempfile( SUFFIX => '.py', UNLINK => 1 );
print $py_fh $py_script;
close $py_fh;

# Write one CSV per dataset, then build the argv spec.
my @specs;
for my $ds (@datasets) {
    my ( $csv_fh, $csv_path ) = tempfile( SUFFIX => '.csv', UNLINK => 1 );
    for my $row ( @{ $ds->{data} } ) {
        print $csv_fh join( ',', @$row ) . "\n";
    }
    close $csv_fh;
    push @specs, qq("$csv_path|$ds->{label}");
}

my $raw = `$python_bin "$py_path" @{[ join ' ', @specs ]} 2>/dev/null`;
my $py  = eval { JSON::PP->new->decode($raw) };

unless ( defined $py && ref $py eq 'HASH' ) {
    plan skip_all => 'Python/sklearn script returned unusable output; skipping';
}

# -----------------------------------------------------------------------
# Per-dataset test battery
# -----------------------------------------------------------------------
sub run_dataset_tests {
    my ( $ds, $sk_all, $use_c ) = @_;

    my $label = $ds->{label};
    my $n_in  = $ds->{n_in};
    my $n_out = $ds->{n_out};

    my $f = $CLASS->new(
        n_trees => 100, sample_size => 256, seed => 42, use_c => $use_c );
    $f->fit( $ds->{data} );

    my $perl_in_scores  = $f->score_samples( $ds->{inliers} );
    my $perl_out_scores = $f->score_samples( $ds->{outliers} );
    my $perl_all_scores = $f->score_samples( $ds->{data} );

    my @sk_in  = @{$sk_all}[ 0 .. $n_in - 1 ];
    my @sk_out = @{$sk_all}[ $n_in .. $n_in + $n_out - 1 ];

    subtest 'Perl: outliers score clearly higher than inliers' => sub {
        cmp_ok( mean( @$perl_out_scores ), '>', mean( @$perl_in_scores ) + 0.2,
            'mean outlier Perl score exceeds mean inlier score by at least 0.2' );
        cmp_ok( min( @$perl_out_scores ), '>', max( @$perl_in_scores ),
            'every outlier has a strictly higher Perl score than every inlier' );
    };

    subtest 'sklearn: outliers score clearly lower (more anomalous) than inliers' => sub {
        cmp_ok( mean(@sk_out), '<', mean(@sk_in),
            'mean outlier sklearn score is lower (more anomalous) than mean inlier score' );
        cmp_ok( max(@sk_out), '<', min(@sk_in),
            'every outlier has a strictly lower sklearn score than every inlier' );
    };

    subtest "both models rank all $n_out outliers in the top-$n_out anomalies" => sub {
        # Perl: sort by descending score; highest scores are the most anomalous.
        my @perl_rank = sort { $perl_all_scores->[$b] <=> $perl_all_scores->[$a] }
                        0 .. $#$perl_all_scores;
        my %perl_top = map { $_ => 1 } @perl_rank[ 0 .. $n_out - 1 ];

        # sklearn: sort by ascending score; lowest scores are the most anomalous.
        my @sk_rank = sort { $sk_all->[$a] <=> $sk_all->[$b] }
                      0 .. $#$sk_all;
        my %sk_top  = map { $_ => 1 } @sk_rank[ 0 .. $n_out - 1 ];

        my $perl_caught = grep { $perl_top{$_} } $n_in .. $n_in + $n_out - 1;
        my $sk_caught   = grep { $sk_top{$_}   } $n_in .. $n_in + $n_out - 1;

        is( $perl_caught, $n_out, "Perl top-$n_out contains all $n_out outlier points" );
        is( $sk_caught,   $n_out, "sklearn top-$n_out contains all $n_out outlier points" );
    };

    subtest 'Perl predict at 0.5 threshold flags all outliers and almost no inliers' => sub {
        my $in_labels  = $f->predict( $ds->{inliers} );
        my $out_labels = $f->predict( $ds->{outliers} );

        is( sum( @$out_labels ), $n_out,
            "Perl predict() flags all $n_out outliers at the 0.5 threshold" );
        cmp_ok( sum( @$in_labels ), '<', 0.05 * $n_in,
            'fewer than 5% of inliers are flagged by Perl predict()' );
    };

    subtest 'Spearman rank correlation between Perl and sklearn scores >= 0.85' => sub {
        # Negate sklearn scores so both vectors point in the same direction
        # (higher value = more anomalous) before ranking.
        my @neg_sk = map { -$_ } @$sk_all;
        my $rho = spearman_rho( $perl_all_scores, \@neg_sk );
        cmp_ok( $rho, '>=', 0.85,
            sprintf( 'Spearman rho(Perl, -sklearn) = %.4f (must be >= 0.85)', $rho ) );
    };
}

# -----------------------------------------------------------------------
# Run the battery for each dataset
# -----------------------------------------------------------------------
for my $be (@BACKENDS) {
    my ( $be_name, $USE_C ) = @$be;
    for my $ds (@datasets) {
        my $sk_all = $py->{ $ds->{label} };
        unless ( ref $sk_all eq 'ARRAY' && @$sk_all == @{ $ds->{data} } ) {
            fail( "sklearn output missing or wrong length for dataset '$ds->{label}'" );
            next;
        }
        subtest "[$be_name] $ds->{label} ($ds->{n_feat} features)" => sub {
            run_dataset_tests( $ds, $sk_all, $USE_C );
        };
    }
}

done_testing;
