#!perl
# 39-online-stream.t
#
# Streaming behaviour of Algorithm::Classifier::IsolationForest::Online:
# drift adaptation through the sliding window (learning AND forgetting),
# subtree collapse bookkeeping, contamination thresholds, unbounded
# (window_size 0) operation, and persistence -- including resuming the
# stream after a save/load round trip and loading through the parent
# class's format dispatch.

use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();
use File::Temp                                     qw(tempdir);

my $class = 'Algorithm::Classifier::IsolationForest::Online';

use constant PI => 3.14159265358979;

sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	my $z  = sqrt( -2 * log($u1) ) * cos( 2 * PI * $u2 );
	return $mu + $sigma * $z;
}

sub cluster {
	my ( $n, $mu ) = @_;
	return [ map { [ gaussian( $mu, 1 ), gaussian( $mu, 1 ) ] } 1 .. $n ];
}

subtest 'drift adaptation via the sliding window' => sub {
	srand(7);
	my $m = $class->new( seed => 5, n_trees => 50, window_size => 512, max_leaf_samples => 32 );

	# Phase A: the stream sits at (0, 0).
	$m->learn( cluster( 600, 0 ) );
	my ( $a_before, $b_before ) = @{ $m->score_samples( [ [ 0, 0 ], [ 6, 6 ] ] ) };
	cmp_ok( $b_before, '>', $a_before, 'phase A: (6,6) is the anomaly' );

	# Phase B: the stream drifts to (6, 6); phase A ages out of the window.
	$m->learn( cluster( 600, 6 ) );
	my ( $a_after, $b_after ) = @{ $m->score_samples( [ [ 0, 0 ], [ 6, 6 ] ] ) };
	cmp_ok( $a_after, '>', $b_after,  'phase B: (0,0) is now the anomaly' );
	cmp_ok( $a_after, '>', $a_before, '(0,0) became more anomalous after the drift' );
	cmp_ok( $b_after, '<', $b_before, '(6,6) became less anomalous after the drift' );

	# Forgetting kept the model's size bounded rather than accreting
	# structure from both phases.
	is( $m->window_count, 512, 'window stayed capped across the drift' );
	for my $tree ( @{ $m->{trees} } ) {
		is( $tree->{count}, 512, 'per-tree count stayed pinned to the window' );
	}
}; ## end 'drift adaptation via the sliding window' => sub

subtest 'forgetting collapses structure' => sub {
	srand(8);
	my $m = $class->new( seed => 9, n_trees => 20, window_size => 128, max_leaf_samples => 16 );
	$m->learn( cluster( 400, 0 ) );

	my $count_nodes;
	$count_nodes = sub {
		my ($node) = @_;
		return 0 unless defined $node;
		return 1 unless $node->[0];
		return 1 + $count_nodes->( $node->[6] ) + $count_nodes->( $node->[7] );
	};

	my $total = 0;
	$total += $count_nodes->( $_->{root} ) for @{ $m->{trees} };
	ok( $total > 0, 'trees have structure' );

	# The depth budget bounds the node count: a binary tree limited to
	# depth ceil(log(window/eta)/log(4)) + 1 levels of splitting can never
	# exceed 2**(depth+2) nodes; with drift churn the practical count sits
	# far below even that.  This catches collapse failing outright (node
	# counts growing with the stream instead of the window).
	my $depth_budget = log( 128 / 16 ) / log(4);
	my $per_tree_cap = 2**( int($depth_budget) + 3 );
	cmp_ok( $total / 20, '<=', $per_tree_cap, "average nodes per tree bounded by the depth budget" );

	# Stream a long tail and confirm the size stays flat rather than
	# accumulating.
	$m->learn( cluster( 1000, 0 ) );
	my $total2 = 0;
	$total2 += $count_nodes->( $_->{root} ) for @{ $m->{trees} };
	cmp_ok( $total2 / 20, '<=', $per_tree_cap, 'node count still bounded after a long stream' );
}; ## end 'forgetting collapses structure' => sub

subtest 'contamination threshold' => sub {
	srand(9);
	my $m = $class->new(
		seed             => 11,
		n_trees          => 50,
		window_size      => 512,
		max_leaf_samples => 32,
		contamination    => 0.05,
	);
	$m->learn( cluster( 600, 0 ) );
	is( $m->decision_threshold, undef, 'threshold not learned until a predict-family call' );

	my $labels = $m->predict( [ [ 0, 0 ], [ 7, 7 ] ] );
	ok( defined $m->decision_threshold, 'first predict learned the threshold from the window' );
	is_deeply( $labels, [ 0, 1 ], 'inlier passes, outlier flagged at the learned threshold' );

	# The learned cutoff should flag roughly the contamination fraction of
	# the window itself.
	my $flags = $m->predict( $m->{window} );
	my $rate  = 0;
	$rate += $_ for @$flags;
	$rate /= scalar @$flags;
	cmp_ok( $rate, '>=', 0.02, 'window flag rate not far below contamination' );
	cmp_ok( $rate, '<=', 0.09, 'window flag rate not far above contamination' );

	# relearn_threshold tracks drift.
	my $old_thr = $m->decision_threshold;
	$m->learn( cluster( 600, 6 ) );
	my $ret = $m->relearn_threshold;
	is( $ret, $m, 'relearn_threshold chains' );
	isnt( $m->decision_threshold, $old_thr, 'threshold moved with the stream' );
	is( $m->predict( [ [ 6, 6 ] ] )->[0], 0, 'post-drift centre passes at the refreshed threshold' );

	ok(
		!eval { $class->new( n_trees => 5 )->relearn_threshold; 1 },
		'relearn_threshold croaks without contamination'
	);
}; ## end 'contamination threshold' => sub

subtest 'window_size 0 disables forgetting' => sub {
	srand(10);
	my $m = $class->new( seed => 13, n_trees => 20, window_size => 0, max_leaf_samples => 16 );
	$m->learn( cluster( 300, 0 ) );
	is( $m->window_count, 0,   'no window is retained' );
	is( $m->seen,         300, 'stream counted' );
	for my $tree ( @{ $m->{trees} } ) {
		is( $tree->{count}, 300, 'trees learned the whole stream' );
	}
	my $scores = $m->score_samples( [ [ 0, 0 ], [ 8, 8 ] ] );
	cmp_ok( $scores->[1], '>', $scores->[0], 'still separates outliers' );

	my $c = $class->new( n_trees => 5, window_size => 0, contamination => 0.05 );
	$c->learn( cluster( 100, 0 ) );
	ok( !eval { $c->relearn_threshold; 1 }, 'relearn_threshold without a window croaks without data' );
	ok( eval { $c->relearn_threshold( cluster( 100, 0 ) ); 1 }, '... but accepts caller-supplied data' )
		or diag $@;
	ok( defined $c->decision_threshold, 'threshold learned from the supplied data' );
}; ## end 'window_size 0 disables forgetting' => sub

subtest 'persistence round trip' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	srand(11);
	my $m = $class->new(
		seed             => 17,
		n_trees          => 30,
		window_size      => 256,
		max_leaf_samples => 16,
		contamination    => 0.05,
		feature_names    => [ 'x', 'y' ],
	);
	$m->learn( cluster( 400, 0 ) );
	$m->predict( [ [ 0, 0 ] ] );    # force the threshold to exist

	my @grid   = map { [ $_ / 2 - 3, $_ / 3 - 2 ] } 0 .. 20;
	my $before = $m->score_samples( \@grid );

	my $path = "$dir/oiforest_model.json";
	$m->save($path);
	ok( -s $path, 'model file written' );

	my $re    = $class->load($path);
	my $after = $re->score_samples( \@grid );
	for my $i ( 0 .. $#grid ) {
		cmp_ok( abs( $before->[$i] - $after->[$i] ), '<', 1e-9, "grid point $i scores match after reload" );
	}
	is( $re->window_count,       $m->window_count,       'window survived the round trip' );
	is( $re->seen,               $m->seen,               'seen survived the round trip' );
	is( $re->decision_threshold, $m->decision_threshold, 'threshold survived the round trip' );
	is_deeply( $re->feature_names, [ 'x', 'y' ], 'feature names survived the round trip' );

	# The stream can resume: learning after a reload keeps the window
	# bookkeeping intact.
	$re->learn( cluster( 100, 0 ) );
	is( $re->window_count, 256, 'window still capped after resuming' );
	is( $re->seen,         500, 'seen kept counting after resuming' );
	for my $tree ( @{ $re->{trees} } ) {
		is( $tree->{count}, 256, 'per-tree counts consistent after resuming' );
	}

	# Parent-class load dispatches on the format tag.
	my $via_parent = Algorithm::Classifier::IsolationForest->load($path);
	isa_ok( $via_parent, $class, 'parent load() returns an online model' );

	# And the online class refuses a batch model.
	srand(12);
	my $batch = Algorithm::Classifier::IsolationForest->new( n_trees => 5, seed => 1 );
	$batch->fit( cluster( 64, 0 ) );
	ok( !eval { $class->from_json( $batch->to_json );    1 }, 'online from_json rejects a batch model' );
	ok( !eval { $class->from_json('{"format":"bogus"}'); 1 }, 'online from_json rejects unknown formats' );
}; ## end 'persistence round trip' => sub

done_testing;
