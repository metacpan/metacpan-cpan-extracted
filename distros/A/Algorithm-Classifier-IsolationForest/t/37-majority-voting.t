#!perl
# 37-majority-voting.t
#
# Exercises voting => 'majority' (Majority Voting Isolation Forest,
# MVIForest -- Chabchoub, Togbe, Boly & Chiky 2022):
#
#   * constructor validation of the voting knob
#   * score_samples returns the anomaly vote fraction: [0, 1], discrete
#     in steps of 1/n_trees, higher for obvious outliers
#   * predict labels are the majority of the per-tree votes, consistent
#     with the vote fractions, in both axis and extended mode
#   * score_predict_samples / score_predict_split agree with
#     score_samples + predict
#   * C-backed and pure-Perl paths produce identical votes and labels
#   * persistence: voting survives a to_json/from_json round trip, and
#     models saved before the knob existed load as 'mean'
#   * contamination learns a per-tree cutoff that flags roughly the
#     requested fraction of the training set (majority pivots are
#     quantized, so ties can shift the count to the nearest gap)
#   * a higher per-tree threshold never flags more points
#   * set_voting switches an existing model and recalibrates the
#     contamination threshold for the mode it was set to
#   * the tagged single-row helpers work under majority voting
#   * the CLI accepts --voting and stores it on the model

use strict;
use warnings;
use Test::More;
use File::Spec;

use Algorithm::Classifier::IsolationForest;

my $CLASS = 'Algorithm::Classifier::IsolationForest';
my $HAS_C = $Algorithm::Classifier::IsolationForest::HAS_C ? 1 : 0;

# Uniform cluster plus unmistakable outliers, as in 02-accel-selection.t.
srand(11);
my @data;
push @data, [ rand(), rand(), rand() ] for 1 .. 60;
push @data, [ 12, 12, 12 ], [ -11, -11, -11 ], [ 10, -10, 9 ];
my @outlier_idx = ( 60, 61, 62 );

subtest 'constructor validation' => sub {
	my $f = $CLASS->new( n_trees => 10, sample_size => 16 );
	is( $f->{voting}, 'mean', 'voting defaults to mean' );

	$f = $CLASS->new( n_trees => 10, sample_size => 16, voting => 'majority' );
	is( $f->{voting}, 'majority', 'voting => majority accepted' );

	eval { $CLASS->new( voting => 'plurality' ) };
	like( $@, qr/voting must be 'mean' or 'majority'/, 'invalid voting croaks' );
}; ## end 'constructor validation' => sub

for my $mode (qw(axis extended)) {
	subtest "majority scoring and prediction ($mode mode)" => sub {
		my $t = 50;
		my $f = $CLASS->new(
			n_trees     => $t,
			sample_size => 32,
			seed        => 7,
			mode        => $mode,
			voting      => 'majority',
		)->fit( \@data );

		my $scores = $f->score_samples( \@data );
		is( scalar @$scores, scalar @data, 'one score per sample' );

		my $bad = grep { !defined $_ || $_ < 0 || $_ > 1 } @$scores;
		is( $bad, 0, 'every vote fraction is in [0, 1]' );

		# Vote fractions are counts over $t trees; votes/t scaled back up
		# must land on an integer.
		my $offgrid = grep {
			my $v = $_ * $t;
			abs( $v - int( $v + 0.5 ) ) > 1e-9
		} @$scores;
		is( $offgrid, 0, "every score is a multiple of 1/$t" );

		my $labels = $f->predict( \@data );
		is( scalar @$labels, scalar @data, 'one label per sample' );

		# Labels must be the majority relation applied to the fractions:
		# anomalous iff votes >= int(t/2) + 1, i.e. fraction > 0.5.
		my $maj        = int( $t / 2 ) + 1;
		my $mismatches = grep {
			my $votes = int( $scores->[$_] * $t + 0.5 );
			( $votes >= $maj ? 1 : 0 ) != $labels->[$_]
		} 0 .. $#$labels;
		is( $mismatches, 0, 'labels equal the majority of the votes' );

		ok( ( grep { $labels->[$_] == 1 } @outlier_idx ) == @outlier_idx, 'all planted outliers are flagged' );

		# 0.5 is a weak per-tree bar (the paper recommends 0.6 as the
		# decision threshold), so allow some inlier false alarms at the
		# default and check the sharper separation at 0.6.
		my $inlier_flags = grep { $labels->[$_] } 0 .. 59;
		cmp_ok( $inlier_flags, '<=', 15, 'default cutoff flags a minority of the inliers' );

		my $labels06 = $f->predict( \@data, 0.6 );
		ok( ( grep { $labels06->[$_] == 1 } @outlier_idx ) == @outlier_idx,
			'outliers still flagged at threshold 0.6' );
		my $inlier_flags06 = grep { $labels06->[$_] } 0 .. 59;
		cmp_ok( $inlier_flags06, '<=', 3, 'few or no inliers flagged at threshold 0.6' );

		# The paired and split shapes agree with the flat ones.
		my $pairs = $f->score_predict_samples( \@data );
		my ( $s2, $l2 ) = $f->score_predict_split( \@data );
		my $pair_bad = grep {
				   abs( $pairs->[$_][0] - $scores->[$_] ) > 1e-12
				|| $pairs->[$_][1] != $labels->[$_]
				|| abs( $s2->[$_] - $scores->[$_] ) > 1e-12
				|| $l2->[$_] != $labels->[$_]
		} 0 .. $#$labels;
		is( $pair_bad, 0, 'score_predict_samples and score_predict_split agree with score_samples/predict' );
	}; ## end "majority scoring and prediction ($mode mode)" => sub
} ## end for my $mode (qw(axis extended))

SKIP: {
	skip 'C vs Perl comparison needs Inline::C', 1 unless $HAS_C;

	subtest 'C-backed and pure-Perl majority voting agree' => sub {
		for my $mode (qw(axis extended)) {
			my %args = (
				n_trees     => 40,
				sample_size => 32,
				seed        => 19,
				mode        => $mode,
				voting      => 'majority',
			);
			my $fc = $CLASS->new( %args, use_c => 1 )->fit( \@data );
			my $fp = $CLASS->new( %args, use_c => 0 )->fit( \@data );

			# Identical seed => bit-identical trees, and votes are integer
			# counts, so the fractions must match exactly.
			my $sc   = $fc->score_samples( \@data );
			my $sp   = $fp->score_samples( \@data );
			my $diff = grep { $sc->[$_] != $sp->[$_] } 0 .. $#$sc;
			is( $diff, 0, "$mode: vote fractions identical across backends" );

			my $lc = $fc->predict( \@data );
			my $lp = $fp->predict( \@data );
			$diff = grep { $lc->[$_] != $lp->[$_] } 0 .. $#$lc;
			is( $diff, 0, "$mode: labels identical across backends" );

			my ( $s1, $l1 ) = $fc->score_predict_split( \@data );
			my ( $s2, $l2 ) = $fp->score_predict_split( \@data );
			$diff = grep { $s1->[$_] != $s2->[$_] || $l1->[$_] != $l2->[$_] } 0 .. $#$s1;
			is( $diff, 0, "$mode: score_predict_split identical across backends" );
		} ## end for my $mode (qw(axis extended))
	}; ## end 'C-backed and pure-Perl majority voting agree' => sub
} ## end SKIP:

subtest 'persistence round trip preserves voting' => sub {
	my $f = $CLASS->new(
		n_trees     => 30,
		sample_size => 32,
		seed        => 23,
		voting      => 'majority',
	)->fit( \@data );

	my $json = $f->to_json;
	like( $json, qr/"voting"\s*:\s*"majority"/, 'to_json records the voting mode' );

	my $r = $CLASS->from_json($json);
	is( $r->{voting}, 'majority', 'from_json restores the voting mode' );

	my $s0   = $f->score_samples( \@data );
	my $s1   = $r->score_samples( \@data );
	my $diff = grep { abs( $s0->[$_] - $s1->[$_] ) > 1e-12 } 0 .. $#$s0;
	is( $diff, 0, 'reloaded model votes identically' );

	my $l0 = $f->predict( \@data );
	my $l1 = $r->predict( \@data );
	$diff = grep { $l0->[$_] != $l1->[$_] } 0 .. $#$l0;
	is( $diff, 0, 'reloaded model predicts identically' );

	# Models saved before the knob existed have no voting key at all;
	# they must come back as plain mean-aggregation models.
	require JSON::PP;
	my $payload = JSON::PP->new->decode($json);
	delete $payload->{params}{voting};
	my $old = $CLASS->from_json( JSON::PP->new->encode($payload) );
	is( $old->{voting}, 'mean', 'models without a voting key load as mean' );
}; ## end 'persistence round trip preserves voting' => sub

subtest 'contamination learns a per-tree cutoff' => sub {
	my $f = $CLASS->new(
		n_trees       => 100,
		sample_size   => 64,
		seed          => 42,
		voting        => 'majority',
		contamination => 0.05,
	)->fit( \@data );

	ok( defined $f->decision_threshold, 'a decision threshold was learned' );
	cmp_ok( $f->decision_threshold, '>', 0, 'threshold is positive' );
	cmp_ok( $f->decision_threshold, '<', 1, 'threshold is below 1' );

	my $flags   = $f->predict( \@data );
	my $flagged = grep { $_ } @$flags;
	my $k       = int( 0.05 * scalar(@data) + 0.5 );

	# Majority pivots are quantized, so ties at the boundary can shift the
	# attainable count off k -- but it must stay in the neighbourhood and
	# the planted outliers must be inside it.
	cmp_ok( $flagged, '>=', 1,      'at least one training point is flagged' );
	cmp_ok( $flagged, '<=', 3 * $k, 'flagged count stays near the requested fraction' );
	ok( ( grep { $flags->[$_] == 1 } @outlier_idx ) == @outlier_idx, 'the planted outliers are flagged' );
}; ## end 'contamination learns a per-tree cutoff' => sub

subtest 'higher per-tree threshold never flags more points' => sub {
	my $f = $CLASS->new(
		n_trees     => 50,
		sample_size => 32,
		seed        => 31,
		voting      => 'majority',
	)->fit( \@data );

	my $low  = grep { $_ } @{ $f->predict( \@data, 0.45 ) };
	my $mid  = grep { $_ } @{ $f->predict( \@data, 0.55 ) };
	my $high = grep { $_ } @{ $f->predict( \@data, 0.70 ) };
	cmp_ok( $low, '>=', $mid,  'flag count non-increasing from 0.45 to 0.55' );
	cmp_ok( $mid, '>=', $high, 'flag count non-increasing from 0.55 to 0.70' );
}; ## end 'higher per-tree threshold never flags more points' => sub

subtest 'set_voting switches an existing model' => sub {
	# A model switched to a mode reproduces one fit directly in that mode:
	# the trees are voting-independent, and set_voting relearns the
	# contamination threshold against the same training data.
	my %args = (
		n_trees       => 100,
		sample_size   => 64,
		seed          => 42,
		contamination => 0.05,
	);

	my $ref = $CLASS->new( %args, voting => 'majority' )->fit( \@data );

	my $sw       = $CLASS->new( %args, voting => 'mean' )->fit( \@data );
	my $mean_thr = $sw->decision_threshold;
	is( $sw->set_voting( 'majority', \@data ), $sw,        'set_voting returns $self for chaining' );
	is( $sw->{voting},                         'majority', 'voting mode updated' );

	isnt(
		sprintf( '%.12g', $sw->decision_threshold ),
		sprintf( '%.12g', $mean_thr ),
		'threshold was recalibrated, not left at the mean value'
	);
	cmp_ok( abs( $sw->decision_threshold - $ref->decision_threshold ),
		'<', 1e-12, 'recalibrated threshold matches a model fit directly as majority' );

	my $lr       = $ref->predict( \@data );
	my $ls       = $sw->predict( \@data );
	my $mismatch = grep { $lr->[$_] != $ls->[$_] } 0 .. $#$lr;
	is( $mismatch, 0, 'switched model predicts identically to the reference' );

	# Switching back to mean relearns the mean-mode cutoff.
	$sw->set_voting( 'mean', \@data );
	cmp_ok( abs( $sw->decision_threshold - $mean_thr ),
		'<', 1e-12, 'switching back to mean restores the mean-mode threshold' );

	# A no-op switch needs no data and returns self.
	is( $sw->set_voting('mean'), $sw, 'switching to the current mode is a no-op returning $self' );

	# A contamination-fitted model refuses to switch without the data.
	my $need = $CLASS->new( %args, voting => 'majority' )->fit( \@data );
	eval { $need->set_voting('mean') };
	like( $@, qr/requires the original training data/, 'contamination model croaks without data' );
	is( $need->{voting}, 'majority', 'mode unchanged after the croak' );

	# A model with no contamination switches freely, no data required.
	my $free = $CLASS->new( n_trees => 50, sample_size => 32, seed => 7, voting => 'mean' )->fit( \@data );
	$free->set_voting('majority');
	is( $free->{voting},           'majority', 'non-contamination model switches without data' );
	is( $free->decision_threshold, undef,      'no threshold to recalibrate when contamination was never set' );

	# Invalid values are rejected.
	eval { $free->set_voting('plurality') };
	like( $@, qr/must be 'mean' or 'majority'/, 'invalid voting value croaks' );

	# Switching before fit just records the mode for the eventual fit.
	my $pre = $CLASS->new( n_trees => 20, sample_size => 16, seed => 5 );
	$pre->set_voting('majority');
	is( $pre->{voting}, 'majority', 'set_voting before fit records the mode' );
	$pre->fit( \@data );
	is( $pre->{voting}, 'majority', 'mode survives the subsequent fit' );
}; ## end 'set_voting switches an existing model' => sub

subtest 'tagged single-row helpers work under majority voting' => sub {
	my $f = $CLASS->new(
		n_trees       => 30,
		sample_size   => 32,
		seed          => 13,
		voting        => 'majority',
		feature_names => [qw(x y z)],
	)->fit( \@data );

	my $out   = { x => 12,  y => 12,  z => 12 };
	my $in    = { x => 0.5, y => 0.5, z => 0.5 };
	my $score = $f->score_sample_tagged($out);
	cmp_ok( $score, '>', 0.5, 'tagged outlier row has a majority vote fraction' );
	is( $f->predict_tagged($out), 1, 'tagged outlier row predicted anomalous' );
	is( $f->predict_tagged($in),  0, 'tagged inlier row predicted normal' );

	my $pair = $f->score_predict_sample_tagged($out);
	is( abs( $pair->[0] - $score ) < 1e-12 ? 1 : 0, 1, 'tagged pair score matches score_sample_tagged' );
	is( $pair->[1],                                 1, 'tagged pair label matches predict_tagged' );
}; ## end 'tagged single-row helpers work under majority voting' => sub

# ------------------------------------------------------------------------
# CLI: fit --voting must validate the value and store it on the model.
# ------------------------------------------------------------------------
SKIP: {
	my $bin = File::Spec->rel2abs('bin/iforest');
	skip "bin/iforest not found", 1 unless -x $bin;

	subtest 'CLI fit --voting' => sub {
		require File::Temp;
		my ( $fh, $csv ) = File::Temp::tempfile( SUFFIX => '.csv', UNLINK => 1 );
		for my $row (@data) {
			print $fh join( ',', @$row ) . "\n";
		}
		close $fh;

		my $out = `$^X -Ilib $bin fit -i $csv -p --voting majority -s 5 2>&1`;
		is( $?, 0, 'fit --voting majority exits 0' );
		like( $out, qr/"voting"\s*:\s*"majority"/, 'printed model records voting => majority' );

		$out = `$^X -Ilib $bin fit -i $csv -p --voting bogus -s 5 2>&1`;
		isnt( $?, 0, 'fit --voting bogus exits non-zero' );
		like( $out, qr/must be either mean or majority/, 'bogus voting value is rejected' );
	}; ## end 'CLI fit --voting' => sub
} ## end SKIP:

# ------------------------------------------------------------------------
# CLI: set_voting flips a saved model, recalibrating when contamination
# was set and refusing to guess a threshold without the training data.
# ------------------------------------------------------------------------
SKIP: {
	my $bin = File::Spec->rel2abs('bin/iforest');
	skip "bin/iforest not found", 1 unless -x $bin;

	subtest 'CLI set_voting' => sub {
		require File::Temp;
		my ( $cfh, $csv ) = File::Temp::tempfile( SUFFIX => '.csv', UNLINK => 1 );
		print $cfh join( ',', @$_ ) . "\n" for @data;
		close $cfh;

		# A model with no contamination flips without needing the data, and
		# carries no threshold to recalibrate.
		my ( undef, $free ) = File::Temp::tempfile( SUFFIX => '.json', UNLINK => 1 );
		system("$^X -Ilib $bin fit -i $csv -o $free -w --voting mean -s 5 >/dev/null 2>&1");
		my $out = `$^X -Ilib $bin set_voting -m $free --voting majority 2>&1`;
		is( $?, 0, 'set_voting on a non-contamination model exits 0' );
		my $info = `$^X -Ilib $bin info -m $free 2>&1`;
		like( $info, qr/voting\s+majority/, 'model was rewritten as majority in place' );

		# A contamination model refuses to switch without -i...
		my ( undef, $cm ) = File::Temp::tempfile( SUFFIX => '.json', UNLINK => 1 );
		system("$^X -Ilib $bin fit -i $csv -o $cm -w --voting mean -c 0.05 -s 42 -n 60 >/dev/null 2>&1");
		$out = `$^X -Ilib $bin set_voting -m $cm --voting majority 2>&1`;
		isnt( $?, 0, 'switching a contamination model without -i exits non-zero' );
		like( $out, qr/-i CSV training data is required/, 'the error names the missing -i data' );

		# ...but succeeds with -i, and the recalibrated threshold matches a
		# model fit directly as majority with the same knobs.
		$out = `$^X -Ilib $bin set_voting -m $cm --voting majority -i $csv -p 2>&1`;
		is( $?, 0, 'set_voting --voting majority -i exits 0' );
		like( $out, qr/"voting"\s*:\s*"majority"/, 'printed model records voting => majority' );

		# fit.pm leaves sample_size at the module default, so match only the
		# knobs the CLI invocation set.
		my $ref
			= $CLASS->new( n_trees => 60, seed => 42, contamination => 0.05, voting => 'majority' )->fit( \@data );
		my $switched = $CLASS->from_json($out);
		cmp_ok( abs( $switched->decision_threshold - $ref->decision_threshold ),
			'<', 1e-9, 'CLI-recalibrated threshold matches a direct majority fit' );

		# Bogus value is rejected.
		$out = `$^X -Ilib $bin set_voting -m $free --voting bogus 2>&1`;
		isnt( $?, 0, 'set_voting --voting bogus exits non-zero' );
		like( $out, qr/must be either mean or majority/, 'bogus voting value is rejected' );
	}; ## end 'CLI set_voting' => sub
} ## end SKIP:

done_testing;
