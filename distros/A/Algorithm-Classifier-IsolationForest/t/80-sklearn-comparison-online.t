#!perl
# 80-sklearn-comparison-online.t
#
# Cross-language validation of the Online Isolation Forest: streams a dataset
# through Algorithm::Classifier::IsolationForest::Online and verifies that, as
# the model learns more of the stream, its scores approach -- and at the full
# stream match -- what Python scikit-learn's (batch) IsolationForest says
# about the same data.  The whole file is skipped when Python or scikit-learn
# is not installed.
#
# The online model runs with window_size => 0 (no forgetting), so at the
# final checkpoint it has learned exactly the rows sklearn was fitted on --
# same data, same size.  The stream order is a deterministic shuffle of the
# dataset (the generators append outliers at the end; an unshuffled stream
# would starve the model of outlier exposure until the very last points and
# bias the early checkpoints).
#
# The checks come in two tiers, because the two implementations degrade
# differently with dimensionality:
#
#   Tier 1 (implementation correctness -- asserted for EVERY dataset):
#     both models put all 8 planted outliers in their top-8, the online
#     model separates outlier from inlier mean scores by a clear gap, and
#     sklearn agrees on direction.  These held at every dimensionality
#     measured (up to 30 features) and are what a routing / count /
#     normalisation bug would break.
#
#   Tier 2 (ranking fidelity -- thresholds decay with dimension BY DESIGN):
#     Spearman rank correlation against sklearn at checkpoints along the
#     stream must climb (the "approaching" check) and end above a
#     per-dataset floor (the "matching" check).  Online trees never store
#     points -- splits below the first generation are simulated from
#     uniform samples inside a node's bounding box, and a box is an
#     increasingly crude density summary as dimensions grow -- so the
#     achievable full-ranking correlation has a ceiling that falls with
#     n_features.  That ceiling is inherent to the algorithm (Leveni et
#     al. 2024), not a bug, and more data does not lift it (N=2000 at 20
#     features measured no better than N=1000).
#
# The "approaching" check is anchored at a warm-up checkpoint taken after
# exactly max_leaf_samples points: no leaf can have split yet (the depth
# budget is still zero), every eval point scores identically, and the rank
# correlation is structurally near zero.  Anchoring at a stream fraction
# instead would be flaky -- with a small dataset a lucky shuffle can put the
# 10% checkpoint's rho within noise of the final value.
#
# Calibration measurements behind the thresholds (2026-07-08, prove -Ilib,
# rho at the warm-up + 10/25/50/75/100% checkpoints; "gap" is mean outlier
# score minus mean inlier score at 100%; two different deterministic stream
# shuffles shown for the final rho to expose the order sensitivity):
#
#   dataset            eta  warmup  rho @ checkpoints                final(alt)  gap
#   2d,  200 inliers    8   0.116   0.877 0.840 0.857 0.875 0.890     0.946     0.297
#   5d, 1000 inliers    8   0.054   0.750 0.791 0.808 0.811 0.807     0.897     0.133
#   10d, 1000 inliers  32   0.050   0.704 0.786 0.781 0.805 0.811     0.852     0.163
#   20d, 1000 inliers   8   0.023   0.600 0.642 0.669 0.702 0.707     0.737     0.128
#
# Ceiling-vs-dimension context (do NOT tighten the high-d floors upward --
# these plateaus persist regardless of eta, growth mode, or N):
#
#   2d ~0.95   5d ~0.90   10d ~0.85   20d ~0.73   30d ~0.65
#
# Per-dimension eta choice: small eta (deeper trees) wins at low dimension,
# larger eta (better-estimated splits) wins around 10 features.  Assertion
# floors sit ~0.08-0.10 under the WORST measured shuffle because both the
# stream order and Perl's platform-dependent rand() (Drand01) move the
# final rho by several hundredths across systems.

use strict;
use warnings;
use Test::More;
use List::Util qw(sum min max);
use File::Temp qw(tempfile);
use JSON::PP   ();

use Algorithm::Classifier::IsolationForest::Online;

my $CLASS = 'Algorithm::Classifier::IsolationForest::Online';

use constant PI => 3.14159265358979;

# Stream fractions at which the online model is checkpointed against sklearn.
my @CHECKPOINTS = ( 0.10, 0.25, 0.50, 0.75, 1.00 );

# How far a checkpoint's rho may fall below its predecessor before it counts
# as a collapse rather than normal wobble (largest measured dip: 0.037).
use constant STEP_TOLERANCE => 0.10;

# How much the final rho must exceed the warm-up rho.  Measured improvements
# are 0.68-0.77; warm-up rho itself measured 0.02-0.12.
use constant APPROACH_MARGIN => 0.35;

# -----------------------------------------------------------------------
# Helpers (spearman_rho and friends match t/80-sklearn-comparison.t)
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
} ## end sub spearman_rho

sub gaussian {
	my ( $mu, $sigma ) = @_;
	return $mu + $sigma * sqrt( -2 * log( rand() || 1e-12 ) ) * cos( 2 * PI * rand() );
}

# -----------------------------------------------------------------------
# Datasets: N-D Gaussian inliers + corner-style outliers, the same shape
# t/80-sklearn-comparison.t uses (and the same srand convention), with the
# inlier count scaled up in higher dimensions so the online model's depth
# budget log4(N/eta) gives its trees enough resolution to rank inliers.
#
# Gaussian inliers (rather than the batch test's regular grid) in every
# dimension: the tier-2 rank correlation needs real density structure both
# models can rank, and ranking among identical-density grid points is noise.
#
# Per-dataset knobs:
#   eta     -- max_leaf_samples for the online model (see header)
#   rho_min -- tier-2 floor on the final-checkpoint Spearman rho
#   stream  -- deterministic shuffle of data, the learn order
# -----------------------------------------------------------------------
sub make_dataset {
	my (%spec) = @_;
	my ( $nf, $n_in ) = @spec{qw(n_feat n_in)};
	srand( 20260629 + $nf );

	my @inliers;
	push @inliers, [ map { gaussian( 0, 0.3 ) } 1 .. $nf ] for 1 .. $n_in;

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

	my @data = ( @inliers, @outliers );

	# Deterministic Fisher-Yates shuffle for the stream order.
	my @stream = @data;
	srand( 4242 + $nf );
	for my $i ( reverse 1 .. $#stream ) {
		my $j = int( rand( $i + 1 ) );
		@stream[ $i, $j ] = @stream[ $j, $i ];
	}

	return {
		%spec,
		label    => "${nf}d_gaussian",
		inliers  => \@inliers,
		outliers => \@outliers,
		data     => \@data,
		stream   => \@stream,
		n_out    => scalar @outliers,
	};
} ## end sub make_dataset

my @datasets = (
	make_dataset( n_feat => 2,  n_in => 200,  eta => 8,  rho_min => 0.80 ),
	make_dataset( n_feat => 5,  n_in => 1000, eta => 8,  rho_min => 0.72 ),
	make_dataset( n_feat => 10, n_in => 1000, eta => 32, rho_min => 0.70 ),
	make_dataset( n_feat => 20, n_in => 1000, eta => 8,  rho_min => 0.55 ),
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
	plan skip_all => 'Python with scikit-learn is not installed; skipping cross-language comparison';
}

# -----------------------------------------------------------------------
# Python helper: one batch sklearn IsolationForest per dataset, JSON out.
# Identical to the batch test's helper (sklearn is the fixed reference the
# streaming model converges toward; it is fit once on the full dataset).
#
# sklearn score_samples convention: lower score = more anomalous -- the
# opposite direction from this module, so scores are negated before rank
# correlation.
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
	my ( $ds, $sk_all ) = @_;

	my $n_in  = $ds->{n_in};
	my $n_out = $ds->{n_out};

	my @neg_sk = map { -$_ } @$sk_all;

	my $oif = $CLASS->new(
		n_trees          => 100,
		window_size      => 0,            # no forgetting: the full stream is "the dataset"
		max_leaf_samples => $ds->{eta},
		seed             => 42,
	);

	# Warm-up anchor: after exactly eta points no split can have happened
	# yet, so the rank correlation is structurally near zero -- the
	# baseline the stream must climb away from.
	my @stream = @{ $ds->{stream} };
	$oif->learn( [ @stream[ 0 .. $ds->{eta} - 1 ] ] );
	my $rho_warmup = spearman_rho( $oif->score_samples( $ds->{data} ), \@neg_sk );

	# Stream the rest in checkpointed slices; score the fixed eval set
	# (the dataset in generator order) with score_samples so measuring
	# never perturbs the stream.
	my $done = $ds->{eta};
	my @rhos;
	my $final_scores;
	for my $frac (@CHECKPOINTS) {
		my $upto = int( @stream * $frac + 0.5 );
		$oif->learn( [ @stream[ $done .. $upto - 1 ] ] ) if $upto > $done;
		$done = $upto if $upto > $done;
		my $scores = $oif->score_samples( $ds->{data} );
		push @rhos, spearman_rho( $scores, \@neg_sk );
		$final_scores = $scores;
	}
	is( $oif->seen, scalar @stream, 'the model has learned the full dataset at the last checkpoint' );

	my @online_in  = @{$final_scores}[ 0 .. $n_in - 1 ];
	my @online_out = @{$final_scores}[ $n_in .. $n_in + $n_out - 1 ];
	my @sk_in      = @{$sk_all}[ 0 .. $n_in - 1 ];
	my @sk_out     = @{$sk_all}[ $n_in .. $n_in + $n_out - 1 ];

	# --- tier 1: anomaly agreement (dimension-robust correctness checks) ---

	subtest 'online: outliers score clearly higher than inliers' => sub {
		cmp_ok(
			mean(@online_out), '>',
			mean(@online_in) + 0.08,
			'mean outlier online score exceeds mean inlier score by at least 0.08'
		);
	};

	subtest 'sklearn: outliers score clearly lower (more anomalous) than inliers' => sub {
		cmp_ok( mean(@sk_out), '<', mean(@sk_in),
			'mean outlier sklearn score is lower (more anomalous) than mean inlier score' );
	};

	subtest "both models rank all $n_out outliers in the top-$n_out anomalies" => sub {
		my @online_rank = sort { $final_scores->[$b] <=> $final_scores->[$a] } 0 .. $#$final_scores;
		my %online_top  = map  { $_ => 1 } @online_rank[ 0 .. $n_out - 1 ];

		my @sk_rank = sort { $sk_all->[$a] <=> $sk_all->[$b] } 0 .. $#$sk_all;
		my %sk_top  = map  { $_ => 1 } @sk_rank[ 0 .. $n_out - 1 ];

		my $online_caught = grep { $online_top{$_} } $n_in .. $n_in + $n_out - 1;
		my $sk_caught     = grep { $sk_top{$_} } $n_in .. $n_in + $n_out - 1;

		is( $online_caught, $n_out, "online top-$n_out contains all $n_out outlier points" );
		is( $sk_caught,     $n_out, "sklearn top-$n_out contains all $n_out outlier points" );
	}; ## end "both models rank all $n_out outliers in the top-$n_out anomalies" => sub

	# --- tier 2: rank-correlation convergence toward sklearn ---------------

	my $curve = join ' ', map { sprintf '%.3f', $_ } @rhos;

	subtest 'Spearman rho approaches and matches sklearn along the stream' => sub {
		cmp_ok( $rhos[-1], '>=', $ds->{rho_min},
			sprintf( 'final rho %.4f >= %.2f (checkpoints: %s)', $rhos[-1], $ds->{rho_min}, $curve ) );
		cmp_ok(
			$rhos[-1],
			'>',
			$rho_warmup + APPROACH_MARGIN,
			sprintf(
				'rho climbed from the warm-up baseline: %.4f (warm-up) -> %.4f (100%%), margin %.2f',
				$rho_warmup, $rhos[-1], APPROACH_MARGIN
			)
		);
		for my $i ( 1 .. $#rhos ) {
			cmp_ok(
				$rhos[$i],
				'>=',
				$rhos[ $i - 1 ] - STEP_TOLERANCE,
				sprintf(
					'checkpoint %d%% rho %.4f did not collapse from %.4f',
					$CHECKPOINTS[$i] * 100,
					$rhos[$i], $rhos[ $i - 1 ]
				)
			);
		} ## end for my $i ( 1 .. $#rhos )
	}; ## end 'Spearman rho approaches and matches sklearn along the stream' => sub
} ## end sub run_dataset_tests

# -----------------------------------------------------------------------
# Run the battery for each dataset
# -----------------------------------------------------------------------
for my $ds (@datasets) {
	my $sk_all = $py->{ $ds->{label} };
	unless ( ref $sk_all eq 'ARRAY' && @$sk_all == @{ $ds->{data} } ) {
		fail("sklearn output missing or wrong length for dataset '$ds->{label}'");
		next;
	}
	subtest "$ds->{label} ($ds->{n_in} inliers, eta $ds->{eta})" => sub {
		run_dataset_tests( $ds, $sk_all );
	};
} ## end for my $ds (@datasets)

done_testing;
