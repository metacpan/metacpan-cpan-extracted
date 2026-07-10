#!perl
# 38-online-basic.t
#
# Basic behaviour of Algorithm::Classifier::IsolationForest::Online:
# constructor validation, learn/score sanity on an easy anomaly setup,
# determinism under a fixed seed, missing-value handling, window
# bookkeeping, and the tagged-row methods.

use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Algorithm::Classifier::IsolationForest::Online');
}

my $class = 'Algorithm::Classifier::IsolationForest::Online';

# Deterministic gaussian helper (Box-Muller off Perl's rand()).
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

subtest 'constructor validation' => sub {
	ok( eval { $class->new; 1 }, 'defaults construct' );

	my %bad = (
		'n_trees must be >= 1'      => [ n_trees          => 0 ],
		'max_leaf_samples >= 1'     => [ max_leaf_samples => 0 ],
		'bad growth'                => [ growth           => 'bogus' ],
		'bad missing'               => [ missing          => 'impute' ],
		'subsample 0'               => [ subsample        => 0 ],
		'subsample > 1'             => [ subsample        => 1.5 ],
		'contamination 0'           => [ contamination    => 0 ],
		'contamination > 0.5'       => [ contamination    => 0.7 ],
		'window under leaf samples' => [ window_size      => 8, max_leaf_samples => 32 ],
	);
	for my $desc ( sort keys %bad ) {
		ok( !eval { $class->new( @{ $bad{$desc} } ); 1 }, "croaks: $desc" );
	}

	# window_size 0 / undef both mean unbounded.
	for my $ws ( 0, undef ) {
		my $m = $class->new( window_size => $ws );
		is( $m->{window_size}, 0, 'window_size ' . ( defined $ws ? $ws : 'undef' ) . ' => unbounded' );
	}
}; ## end 'constructor validation' => sub

subtest 'scoring before any data croaks' => sub {
	my $m = $class->new;
	ok( !eval { $m->score_samples( [ [ 1, 2 ] ] ); 1 }, 'score_samples croaks unlearned' );
	like( $@, qr/learn/, 'error mentions learn()' );
	ok( !eval { $m->predict( [ [ 1, 2 ] ] );      1 }, 'predict croaks unlearned' );
	ok( !eval { $m->path_lengths( [ [ 1, 2 ] ] ); 1 }, 'path_lengths croaks unlearned' );
};

subtest 'learn/score sanity' => sub {
	srand(7);
	my $m = $class->new(
		seed             => 42,
		n_trees          => 50,
		window_size      => 256,
		max_leaf_samples => 16,
	);
	my $ret = $m->learn( cluster( 400, 0 ) );
	is( $ret, $m, 'learn returns $self' );

	my $scores = $m->score_samples( [ [ 0, 0 ], [ 8, 8 ], [ -7, 7 ] ] );
	is( scalar @$scores, 3, 'one score per sample' );
	for my $s (@$scores) {
		ok( $s > 0 && $s <= 1, "score $s in (0, 1]" );
	}
	cmp_ok( $scores->[1], '>', $scores->[0] + 0.03, 'far outlier scores above the cluster centre' );
	cmp_ok( $scores->[2], '>', $scores->[0] + 0.03, 'other outlier scores above the cluster centre' );

	my $depths = $m->path_lengths( [ [ 0, 0 ], [ 8, 8 ] ] );
	cmp_ok( $depths->[0], '>', $depths->[1], 'inlier isolates deeper than the outlier' );

	my ( $s2, $l2 ) = $m->score_predict_split( [ [ 0, 0 ], [ 8, 8 ] ], $scores->[0] + 0.01 );
	is_deeply( $l2, [ 0, 1 ], 'score_predict_split labels against an explicit threshold' );
	my $pairs = $m->score_predict_samples( [ [ 0, 0 ], [ 8, 8 ] ], $scores->[0] + 0.01 );
	is_deeply( [ map { $_->[1] } @$pairs ], [ 0, 1 ], 'score_predict_samples labels agree' );
}; ## end 'learn/score sanity' => sub

subtest 'window bookkeeping' => sub {
	srand(8);
	my $m = $class->new( seed => 1, n_trees => 10, window_size => 64, max_leaf_samples => 16 );
	$m->learn( cluster( 200, 0 ) );
	is( $m->window_count, 64,  'window is capped at window_size' );
	is( $m->seen,         200, 'seen counts the whole stream' );
	for my $tree ( @{ $m->{trees} } ) {
		is( $tree->{count},   64, 'tree count tracks the window (subsample 1)' );
		is( $tree->{root}[1], 64, 'root node count tracks the window' );
	}
}; ## end 'window bookkeeping' => sub

subtest 'determinism under a fixed seed' => sub {
	my @runs;
	for ( 1 .. 2 ) {
		srand(9);
		my $m = $class->new( seed => 1234, n_trees => 20, window_size => 128, max_leaf_samples => 16 );
		$m->learn( cluster( 300, 0 ) );
		push @runs, [ $m->to_json, join( ',', @{ $m->score_samples( [ [ 0, 0 ], [ 5, 5 ] ] ) } ) ];
	}
	is( $runs[0][0], $runs[1][0], 'same seed + same stream => identical model JSON' );
	is( $runs[0][1], $runs[1][1], 'same seed + same stream => identical scores' );
}; ## end 'determinism under a fixed seed' => sub

subtest 'feature count is locked by the first sample' => sub {
	my $m = $class->new( n_trees => 5 );
	$m->learn( [ [ 1, 2, 3 ] ] );
	is( $m->{n_features}, 3, 'n_features learned from the first row' );
	ok( !eval { $m->learn( [ [ 1, 2 ] ] ); 1 }, 'mismatched feature count croaks' );
	like( $@, qr/expects 3/, 'error names the expected count' );
};

subtest 'missing-value handling' => sub {
	my $die = $class->new( n_trees => 5 );
	ok( !eval { $die->learn( [ [ 1, undef ] ] ); 1 }, "missing => 'die' croaks on undef" );
	like( $@, qr/undef feature value/, 'error mentions the undef cell' );

	my $zero = $class->new( n_trees => 5, missing => 'zero', window_size => 64, max_leaf_samples => 16, seed => 3 );
	ok(
		eval {
			$zero->learn( [ map { [ $_ % 5, ( $_ % 2 ? undef : 1 ) ] } 1 .. 50 ] );
			1;
		},
		"missing => 'zero' learns undef cells"
	) or diag $@;

	# Scoring tolerates undef regardless of strategy (mapped to 0).
	srand(10);
	my $m = $class->new( seed => 4, n_trees => 10, window_size => 64, max_leaf_samples => 16 );
	$m->learn( cluster( 100, 0 ) );
	ok( eval { $m->score_samples( [ [ undef, 1 ] ] ); 1 }, 'scoring a row with undef works' );
}; ## end 'missing-value handling' => sub

subtest 'score_learn is prequential' => sub {
	srand(11);
	my $m     = $class->new( seed => 5, n_trees => 10, window_size => 64, max_leaf_samples => 16 );
	my $first = $m->score_learn( [ [ 1, 1 ] ] );
	is( scalar @$first, 1,   'one score per sample' );
	is( $first->[0],    1.0, 'the very first point of a stream scores 1.0' );
	is( $m->seen,       1,   'the point was learned' );

	my $rows   = cluster( 200, 0 );
	my $scores = $m->score_learn($rows);
	is( scalar @$scores, 200, 'one score per streamed sample' );
	is( $m->seen,        201, 'stream advanced' );

	# Against the now-warm model, an outlier still scores above an inlier
	# through score_learn.
	my $pair = $m->score_learn( [ [ 0, 0 ], [ 9, 9 ] ] );
	cmp_ok( $pair->[1], '>', $pair->[0], 'outlier ranks above inlier prequentially' );
}; ## end 'score_learn is prequential' => sub

subtest 'growth => fixed' => sub {
	srand(12);
	my $m = $class->new( seed => 6, n_trees => 10, window_size => 128, max_leaf_samples => 16, growth => 'fixed' );
	$m->learn( cluster( 200, 0 ) );
	my $scores = $m->score_samples( [ [ 0, 0 ], [ 8, 8 ] ] );
	cmp_ok( $scores->[1], '>', $scores->[0], 'fixed growth still separates outliers' );
};

subtest 'subsample' => sub {
	srand(13);
	my $m = $class->new( seed => 7, n_trees => 10, window_size => 128, max_leaf_samples => 16, subsample => 0.5 );
	$m->learn( cluster( 300, 0 ) );
	is( $m->window_count, 128, 'window is forest-level, unaffected by subsample' );
	my $scores = $m->score_samples( [ [ 0, 0 ], [ 8, 8 ] ] );
	cmp_ok( $scores->[1], '>', $scores->[0], 'subsampled forest still separates outliers' );
};

subtest 'tagged methods' => sub {
	srand(14);
	my $m = $class->new(
		seed             => 8,
		n_trees          => 20,
		window_size      => 128,
		max_leaf_samples => 16,
		feature_names    => [ 'x', 'y' ],
	);
	$m->learn_tagged( { x => 0.1, y => -0.2 } );
	is( $m->seen, 1, 'learn_tagged learned one point' );
	$m->learn( cluster( 200, 0 ) );

	my $score = $m->score_sample_tagged( { x => 8, y => 8 } );
	ok( $score > 0 && $score <= 1, 'score_sample_tagged returns a score' );

	my $label = $m->predict_tagged( { x => 8, y => 8 }, 0.99 );
	is( $label, 0, 'predict_tagged honours an explicit threshold' );

	my $pair = $m->score_predict_sample_tagged( { x => 8, y => 8 }, 0.99 );
	is_deeply( [ $pair->[0] > 0, $pair->[1] ], [ 1, 0 ], 'score_predict_sample_tagged pair shape' );

	my $sl = $m->score_learn_tagged( { x => 0.2, y => 0.1 } );
	ok( $sl > 0 && $sl <= 1, 'score_learn_tagged returns a score' );

	ok( !eval { $m->score_sample_tagged( { x => 1, z => 2 } ); 1 }, 'unknown feature name croaks' );
	ok( !eval { $m->score_sample_tagged( { x => 1 } );         1 }, 'missing feature name croaks' );

	my $untagged = $class->new( n_trees => 5 );
	$untagged->learn( [ [ 1, 2 ] ] );
	ok(
		!eval { $untagged->score_sample_tagged( { x => 1, y => 2 } ); 1 },
		'tagged scoring croaks without stored feature_names'
	);
}; ## end 'tagged methods' => sub

done_testing;
