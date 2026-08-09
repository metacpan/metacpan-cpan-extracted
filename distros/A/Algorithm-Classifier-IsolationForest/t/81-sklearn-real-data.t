#!perl
# 81-sklearn-real-data.t
#
# Cross-language validation against scikit-learn on REAL data, rather than
# the synthetic blobs and grids of 80-sklearn-comparison.t.  Well-separated
# synthetic outliers are easy: any faithful implementation finds them, so
# they check that the algorithm is not broken but say little about how it
# behaves on the messy, overlapping, differently-scaled columns real data
# has.  These four UCI datasets supply that.
#
# Unlike 80-sklearn-comparison.t this file does NOT need Python.  sklearn's
# scores are checked in beside each dataset (t/data/*.sklearn), so the
# comparison runs everywhere -- including CPAN smokers with no Python at
# all, where the synthetic file skips entirely.  When Python and sklearn
# ARE present an extra arm re-runs sklearn live and confirms the checked-in
# reference still matches what the installed version produces, so drift in
# a newer sklearn is caught rather than silently trusted.
#
# The two implementations cannot produce identical scores -- they draw from
# different RNGs -- so agreement is measured on the ORDERING, by Spearman
# rank correlation and by overlap of the top 5% most anomalous points (the
# part of the ranking anyone actually acts on).
#
# Both are checked twice.  An absolute floor catches an outright collapse.
# The check that does the real work is relative: agreement with sklearn is
# required to be no worse than our agreement with OURSELVES across seeds.
# An Isolation Forest is a random estimator, so that seed-to-seed spread is
# the ceiling -- if we track sklearn as closely as we track a different
# seed of ourselves, there is no cross-implementation divergence to find.
# Stating it that way also stops the thresholds from encoding how hard a
# particular dataset happens to be to rank.  See the constants below.
#
# Separately, the C and pure-Perl backends must agree with each other
# exactly -- the module's own guarantee, checked here on real data with 30+
# correlated columns rather than on a Gaussian blob.
#
# See t/data/README for provenance, citations and licensing of the data.

use strict;
use warnings;
use Test::More;
use FindBin ();
use File::Spec;
use List::Util qw(sum);

use Algorithm::Classifier::IsolationForest;

my $DATA = File::Spec->catdir( $FindBin::Bin, 'data' );

my @SETS = qw(glass ionosphere seeds wdbc);

my @SEEDS = ( 1, 7, 42 );

# An Isolation Forest is a random estimator, so two fits of the SAME
# implementation with different seeds already disagree.  That seed-to-seed
# spread is the ceiling on any cross-implementation comparison, and it is
# what these checks are stated against.
#
# Absolute floors are deliberately not tuned per dataset.  How closely two
# runs agree is mostly a property of the data -- a set whose points are
# near-tied in isolatedness has an unstable ranking no matter who ranks it
# -- so a per-dataset floor ends up measuring the dataset rather than the
# code, and needs retuning whenever data is added.  These two only have to
# catch a collapse; the relative checks below do the real work.
#
# Measured over 20 disjoint 3-seed groups (the statistic below is a mean
# over one such group), worst case across the four datasets:
#
#   mean spearman vs sklearn    0.9419 (seeds)
#   mean top-5% overlap         0.788  (seeds)
use constant MIN_AGREEMENT   => 0.90;
use constant MIN_TOP_OVERLAP => 0.70;

# The real invariant: agreement with sklearn must not sit meaningfully
# below our agreement with OURSELVES across seeds.  If we track sklearn as
# closely as we track a different seed of ourselves then there is no
# cross-implementation divergence, whatever the absolute number happens to
# be for a given dataset.  This is what would catch a change that biased
# our splits relative to sklearn's while leaving our own seed-to-seed
# stability intact -- which an absolute floor cannot see.
#
# Worst (self - cross) over those same 20 groups:
#
#   spearman   +0.0104 (wdbc)      -> 0.05 allows ~5x that
#   overlap    +0.074  (ionosphere) -> 0.15 allows ~2x that
#
# Both are usually negative, i.e. we match sklearn slightly more closely
# than we match our own other seeds.
use constant AGREEMENT_MARGIN => 0.05;
use constant OVERLAP_MARGIN   => 0.15;

# Compare against the pure-Perl backend always, and the C backend when it
# compiled.  Both must agree with sklearn, and with each other.
my @BACKENDS = ( [ 'pure-perl' => 0 ] );
push @BACKENDS, [ 'C' => 1 ]
	if $Algorithm::Classifier::IsolationForest::HAS_C;

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub mean { @_ ? sum(@_) / scalar @_ : 0 }

# 1-based ranks, smallest value getting rank 1.  Ties break by index, which
# is fine here: the correlation floors have enough slack to absorb it.
sub _ranks {
	my @v   = @_;
	my @idx = sort { $v[$a] <=> $v[$b] } 0 .. $#v;
	my @r;
	$r[ $idx[$_] ] = $_ + 1 for 0 .. $#idx;
	return @r;
}

# Spearman rho: Pearson correlation of the two rank vectors.
sub spearman {
	my ( $xs, $ys ) = @_;
	my @a = _ranks(@$xs);
	my @b = _ranks(@$ys);
	my $n = scalar @a;
	my ( $sa, $sb, $saa, $sbb, $sab ) = (0) x 5;
	for my $i ( 0 .. $n - 1 ) {
		$sa  += $a[$i];
		$sb  += $b[$i];
		$saa += $a[$i]**2;
		$sbb += $b[$i]**2;
		$sab += $a[$i] * $b[$i];
	}
	my ( $ma, $mb ) = ( $sa / $n, $sb / $n );
	my $cov = $sab / $n - $ma * $mb;
	my $da  = sqrt( $saa / $n - $ma**2 );
	my $db  = sqrt( $sbb / $n - $mb**2 );
	return ( $da > 0 && $db > 0 ) ? $cov / ( $da * $db ) : 0;
} ## end sub spearman

# Indices of the $k largest values, most extreme first.
sub _top_k {
	my ( $v, $k ) = @_;
	my @idx = sort { $v->[$b] <=> $v->[$a] } 0 .. $#$v;
	return @idx[ 0 .. $k - 1 ];
}

# Fraction of the two top-k sets that coincide.
sub top_overlap {
	my ( $xs, $ys, $frac ) = @_;
	my $k = int( $frac * scalar(@$xs) + 0.5 );
	$k = 1 if $k < 1;
	my %want = map  { $_ => 1 } _top_k( $ys, $k );
	my $hit  = grep { $want{$_} } _top_k( $xs, $k );
	return $hit / $k;
}

# Read a fixture CSV: a header naming the features, then numeric rows.
# Returns (\@rows, \@feature_names).
sub load_csv {
	my ($path) = @_;
	open my $fh, '<', $path or die "$path: $!";
	my $header = <$fh>;
	chomp $header;
	my @names = split /,/, $header;
	my @rows;
	while ( my $line = <$fh> ) {
		chomp $line;
		next if $line =~ /\A\s*\z/;
		push @rows, [ split /,/, $line ];
	}
	close $fh;
	return ( \@rows, \@names );
} ## end sub load_csv

# Read one value per line, skipping '#' comments.  Serves both the .labels
# and .sklearn fixtures.
sub load_column {
	my ($path) = @_;
	open my $fh, '<', $path or die "$path: $!";
	my @v;
	while ( my $line = <$fh> ) {
		next if $line =~ /\A\s*#/;
		chomp $line;
		next if $line =~ /\A\s*\z/;
		push @v, $line;
	}
	close $fh;
	return \@v;
} ## end sub load_column

# -----------------------------------------------------------------------
# Is a live sklearn available for the drift check?
# -----------------------------------------------------------------------
my $PYTHON;
for my $candidate (qw(python3 python)) {
	my $probe = `$candidate -c "import sklearn" 2>&1`;
	if ( $? == 0 ) { $PYTHON = $candidate; last }
}

# Re-run sklearn on $csv with the same parameters the checked-in reference
# used, returning its scores or undef when anything goes wrong.  A failure
# here skips the drift check rather than failing the file: this arm is a
# bonus, and the checked-in reference is the contract.
sub live_sklearn {
	my ($csv) = @_;
	return undef unless $PYTHON;

	my $script = <<'PY';
import csv, sys
from sklearn.ensemble import IsolationForest
with open(sys.argv[1], newline="") as fh:
    rows = list(csv.reader(fh))
data = [[float(c) for c in r] for r in rows[1:]]
m = IsolationForest(n_estimators=100, max_samples=256,
                    random_state=42, contamination="auto").fit(data)
for s in m.score_samples(data):
    print("%.17g" % s)
PY
	my ( $fh, $tmp );
	require File::Temp;
	( $fh, $tmp ) = File::Temp::tempfile( SUFFIX => '.py', UNLINK => 1 );
	print {$fh} $script;
	close $fh;

	my @out = `$PYTHON $tmp $csv 2>/dev/null`;
	return undef if $? != 0 || !@out;
	chomp @out;
	return \@out;
} ## end sub live_sklearn

# -----------------------------------------------------------------------
# The datasets
# -----------------------------------------------------------------------
for my $name (@SETS) {
	my $csv = File::Spec->catfile( $DATA, "$name.csv" );
	my $ref = File::Spec->catfile( $DATA, "$name.sklearn" );
	my $lab = File::Spec->catfile( $DATA, "$name.labels" );

	unless ( -r $csv && -r $ref && -r $lab ) {
		fail("$name: fixture files are missing from t/data");
		next;
	}

	my ( $rows, $names ) = load_csv($csv);
	my $sk     = load_column($ref);
	my $labels = load_column($lab);

	is( scalar @$sk,     scalar @$rows, "$name: reference score per data row" );
	is( scalar @$labels, scalar @$rows, "$name: label per data row" );

	# sklearn's convention is the opposite of ours: it returns the negated
	# anomaly score, so lower means more anomalous.  Flip it once here and
	# everything below reads "higher = more anomalous" on both sides.
	my @sk_anom = map { -$_ } @$sk;

	my %by_backend;
	for my $backend (@BACKENDS) {
		my ( $label, $use_c ) = @$backend;

		# One fit per seed, reused by both the cross- and self-comparisons
		# below.
		my @runs;
		for my $seed (@SEEDS) {
			my $model = Algorithm::Classifier::IsolationForest->new(
				n_trees     => 100,
				sample_size => 256,
				seed        => $seed,
				use_c       => $use_c,
			);
			$model->fit($rows);
			push @runs, $model->score_samples($rows);
		} ## end for my $seed (@SEEDS)
		$by_backend{$label} = \@runs;

		# Agreement with sklearn, averaged over the seeds.
		my $cross_rho = mean( map { spearman( $_, \@sk_anom ) } @runs );
		my $cross_ovl = mean( map { top_overlap( $_, \@sk_anom, 0.05 ) } @runs );

		# Agreement with ourselves, over every pair of those same seeds.
		my ( @self_rho, @self_ovl );
		for my $i ( 0 .. $#runs ) {
			for my $j ( $i + 1 .. $#runs ) {
				push @self_rho, spearman( $runs[$i], $runs[$j] );
				push @self_ovl, top_overlap( $runs[$i], $runs[$j], 0.05 );
			}
		}
		my $self_rho = mean(@self_rho);
		my $self_ovl = mean(@self_ovl);

		cmp_ok( $cross_rho, '>=', MIN_AGREEMENT,
			sprintf( '%s/%s: spearman vs sklearn %.4f >= %.2f', $name, $label, $cross_rho, MIN_AGREEMENT ) );
		cmp_ok(
			$cross_rho,
			'>=',
			$self_rho - AGREEMENT_MARGIN,
			sprintf(
				'%s/%s: spearman vs sklearn %.4f tracks our own seed spread %.4f (within %.2f)',
				$name, $label, $cross_rho, $self_rho, AGREEMENT_MARGIN
			)
		);

		cmp_ok(
			$cross_ovl,
			'>=',
			MIN_TOP_OVERLAP,
			sprintf(
				'%s/%s: top 5%% overlap with sklearn %.3f >= %.2f',
				$name, $label, $cross_ovl, MIN_TOP_OVERLAP
			)
		);
		cmp_ok(
			$cross_ovl,
			'>=',
			$self_ovl - OVERLAP_MARGIN,
			sprintf(
				'%s/%s: top 5%% overlap %.3f tracks our own seed spread %.3f (within %.2f)',
				$name, $label, $cross_ovl, $self_ovl, OVERLAP_MARGIN
			)
		);
	} ## end for my $backend (@BACKENDS)

	# The module promises the C backend only changes speed, never results.
	# Real data with 30+ correlated columns is a far better test of that
	# than a Gaussian blob.
	if ( @BACKENDS > 1 ) {
		my $perl = $by_backend{'pure-perl'}[0];
		my $c    = $by_backend{'C'}[0];
		my $diff = 0;
		for my $i ( 0 .. $#$perl ) {
			my $d = abs( $perl->[$i] - $c->[$i] );
			$diff = $d if $d > $diff;
		}
		cmp_ok( $diff, '<=', 1e-12, sprintf( '%s: C and pure-Perl scores agree (max diff %g)', $name, $diff ) );
	} ## end if ( @BACKENDS > 1 )

	# fit_from_csv reads these files straight off disk, so the header row
	# of real feature names exercises its auto-detection on something other
	# than a hand-written fixture.
	{
		my $streamed = Algorithm::Classifier::IsolationForest->new(
			n_trees     => 100,
			sample_size => 256,
			seed        => $SEEDS[0],
		);
		$streamed->fit_from_csv($csv);
		is(
			$streamed->{n_features},
			scalar @$names,
			"$name: fit_from_csv detected the header and $names->[0].." . $names->[-1]
		);

		my $rho = spearman( $streamed->score_samples($rows), \@sk_anom );
		cmp_ok( $rho, '>=', MIN_AGREEMENT,
			sprintf( '%s: fit_from_csv spearman vs sklearn %.4f >= %.2f', $name, $rho, MIN_AGREEMENT ) );
	}

	# Drift check: does the installed sklearn still produce the checked-in
	# reference?  Same parameters and random_state, so a matching version
	# reproduces it outright; a newer one should at worst reorder slightly.
SKIP: {
		skip "no python with scikit-learn", 1 unless $PYTHON;
		my $live = live_sklearn($csv);
		skip "live sklearn run failed", 1 unless $live && @$live == @$sk;
		my $rho = spearman( $live, $sk );
		cmp_ok( $rho, '>=', 0.98,
			sprintf( '%s: checked-in reference still matches live sklearn (rho %.4f)', $name, $rho ) );
	}
} ## end for my $name (@SETS)

# Glass is the one set here with a genuinely rare class -- 9 of its 214
# samples are tableware (4.2%) -- so it can check the thing the module is
# actually for, rather than just agreement with another implementation:
# does an unsupervised fit push that class toward the anomalous end?  The
# other three have 33-37% "anomalies", which is a class split rather than
# an anomaly rate, so this would be meaningless there.
#
# The statistic is the rare class's mean normalised rank, where 0.5 is
# chance and 1.0 would put all nine at the very top.  A top-k lift was the
# obvious first choice and is a bad one: with only nine rare samples it is
# quantised to a couple of attainable values -- over a 60-seed sweep it
# returned exactly 1.13x or 2.26x and nothing between, turning on whether
# one specific sample cleared the cut.  sklearn scores 2.26x on the same
# data for the same reason, not because it is better.  The mean rank moves
# continuously and stays in 0.637-0.725 across those same 60 seeds.
{
	my ( $rows, undef ) = load_csv( File::Spec->catfile( $DATA, 'glass.csv' ) );
	my $labels = load_column( File::Spec->catfile( $DATA, 'glass.labels' ) );

	# Mean normalised rank of the labelled rows: 0 = least anomalous of the
	# set, 1 = most.
	my $mean_rank = sub {
		my ($scores) = @_;
		my $n        = scalar @$scores;
		my @asc      = sort { $scores->[$a] <=> $scores->[$b] } 0 .. $n - 1;
		my @pct;
		$pct[ $asc[$_] ] = $_ / ( $n - 1 ) for 0 .. $n - 1;
		my @rare = grep { $labels->[$_] } 0 .. $n - 1;
		return sum( @pct[@rare] ) / scalar @rare;
	};

	my $sk_rank = $mean_rank->( [ map { -$_ } @{ load_column( File::Spec->catfile( $DATA, 'glass.sklearn' ) ) } ] );

	for my $seed (@SEEDS) {
		my $model = Algorithm::Classifier::IsolationForest->new(
			n_trees     => 100,
			sample_size => 256,
			seed        => $seed,
		);
		$model->fit($rows);
		my $ours = $mean_rank->( $model->score_samples($rows) );

		cmp_ok( $ours, '>=', 0.58,
			sprintf( 'glass seed %d: rare class mean rank %.3f is above chance (0.500)', $seed, $ours ) );

		cmp_ok( abs( $ours - $sk_rank ),
			'<=', 0.12,
			sprintf( 'glass seed %d: rare-class ranking tracks sklearn (%.3f vs %.3f)', $seed, $ours, $sk_rank ) );
	} ## end for my $seed (@SEEDS)
}

done_testing();
