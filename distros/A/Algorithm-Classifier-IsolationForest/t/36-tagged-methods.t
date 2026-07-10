#!perl
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

sub exception (&) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes)
	my $code = shift;
	my $ok   = eval { $code->(); 1 };
	return $ok ? undef : ( $@ // 'died' );
}

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

# Dense grid of normal points in [0,1]^3.
my @normal = map { [ $_ / 10, ( 10 - $_ ) / 10, 0.5 ] } 0 .. 10;
push @normal, map { [ rand, rand, rand ] } 1 .. 150;

my @names = qw(x y z);

my $m = $CLASS->new(
	seed          => 42,
	n_trees       => 80,
	sample_size   => 128,
	feature_names => \@names,
);
$m->fit( \@normal );

# A model without stored feature_names.
my $m_nonames = $CLASS->new( seed => 42, n_trees => 80, sample_size => 128 );
$m_nonames->fit( \@normal );

# A model with a contamination-learned threshold.
my $m_contam = $CLASS->new(
	seed          => 42,
	n_trees       => 80,
	sample_size   => 128,
	contamination => 0.05,
	feature_names => \@names,
);
$m_contam->fit( \@normal );

my %normal_row  = ( x => 0.5, y =>  0.5, z => 0.5 );
my %outlier_row = ( x => 999, y => -999, z => 0 );

# ---------------------------------------------------------------------------
# tagged_row_to_array
# ---------------------------------------------------------------------------

subtest 'tagged_row_to_array - happy path' => sub {
	can_ok( $m, 'tagged_row_to_array' );

	my $vec = $m->tagged_row_to_array( \%normal_row, 'test' );
	is( ref $vec,     'ARRAY',        'returns an arrayref' );
	is( scalar @$vec, 3,              'length matches number of features' );
	is( $vec->[0],    $normal_row{x}, 'x is in position 0' );
	is( $vec->[1],    $normal_row{y}, 'y is in position 1' );
	is( $vec->[2],    $normal_row{z}, 'z is in position 2' );
}; ## end 'tagged_row_to_array - happy path' => sub

subtest 'tagged_row_to_array - key order follows feature_names not hash order' => sub {
	# Supply keys in a different order; result must follow @names.
	my $vec = $m->tagged_row_to_array( { z => 3, x => 1, y => 2 }, 'test' );
	is( $vec->[0], 1, 'x (index 0) correct despite hash ordering' );
	is( $vec->[1], 2, 'y (index 1) correct despite hash ordering' );
	is( $vec->[2], 3, 'z (index 2) correct despite hash ordering' );
};

subtest 'tagged_row_to_array - undef values are passed through' => sub {
	my $vec = $m->tagged_row_to_array( { x => undef, y => 0.5, z => 0.1 }, 'test' );
	is( $vec->[0], undef, 'undef value is preserved at position 0' );
};

subtest 'tagged_row_to_array - errors' => sub {
	like(
		exception { $m->tagged_row_to_array( [ 1, 2, 3 ], 'caller_x' ) },
		qr/caller_x requires a hashref/,
		'arrayref input croaks with caller name'
	);
	like(
		exception { $m->tagged_row_to_array( 'string', 'caller_x' ) },
		qr/caller_x requires a hashref/,
		'scalar input croaks with caller name'
	);
	like(
		exception { $m_nonames->tagged_row_to_array( \%normal_row, 'test' ) },
		qr/no stored feature_names/,
		'model without feature_names croaks'
	);
	like(
		exception {
			$m->tagged_row_to_array( { x => 1, y => 2, z => 3, BAD => 4 }, 'test' );
		},
		qr/unknown feature name.*BAD/,
		'unknown key croaks and names the offender'
	);
	like(
		exception { $m->tagged_row_to_array( { x => 1, y => 2 }, 'test' ) },
		qr/missing feature name.*z/,
		'missing key croaks and names the absent feature'
	);
}; ## end 'tagged_row_to_array - errors' => sub

# ---------------------------------------------------------------------------
# predict_tagged
# ---------------------------------------------------------------------------

subtest 'predict_tagged - can call and returns 0 or 1' => sub {
	can_ok( $m, 'predict_tagged' );
	my $label = $m->predict_tagged( \%normal_row );
	ok( defined $label,             'returns a defined value' );
	ok( $label == 0 || $label == 1, "label is 0 or 1 (got $label)" );
};

subtest 'predict_tagged - consistent with predict() for same row' => sub {
	my $row_vec = [ $normal_row{x}, $normal_row{y}, $normal_row{z} ];

	my $tagged = $m->predict_tagged( \%normal_row );
	my $array  = $m->predict( [$row_vec] )->[0];
	is( $tagged, $array, 'predict_tagged matches predict() at default threshold' );

	$tagged = $m->predict_tagged( \%outlier_row, 0.4 );
	$array  = $m->predict( [ [ $outlier_row{x}, $outlier_row{y}, $outlier_row{z} ] ], 0.4 )->[0];
	is( $tagged, $array, 'predict_tagged matches predict() at explicit threshold' );
}; ## end 'predict_tagged - consistent with predict() for same row' => sub

subtest 'predict_tagged - uses contamination threshold by default' => sub {
	my $tagged = $m_contam->predict_tagged( \%normal_row );
	my $array  = $m_contam->predict( [ [ @normal_row{@names} ] ] )->[0];
	is( $tagged, $array, 'predict_tagged respects contamination-learned threshold' );
};

subtest 'predict_tagged - outlier scores higher than normal' => sub {
	my $s_normal  = $m->score_samples( [ [ @normal_row{@names} ] ] )->[0];
	my $s_outlier = $m->score_samples( [ [ @outlier_row{@names} ] ] )->[0];
	ok( $s_outlier > $s_normal, 'outlier score > normal score' );
};

subtest 'predict_tagged - errors delegate to tagged_row_to_array' => sub {
	like(
		exception { $m->predict_tagged( [ 1, 2, 3 ] ) },
		qr/predict_tagged requires a hashref/,
		'non-hashref croaks'
	);
	like(
		exception { $m_nonames->predict_tagged( \%normal_row ) },
		qr/no stored feature_names/,
		'no feature_names croaks'
	);
	like(
		exception { $m->predict_tagged( { x => 1, y => 2, BOGUS => 3 } ) },
		qr/unknown feature name.*BOGUS/,
		'unknown key croaks'
	);
	like(
		exception { $m->predict_tagged( { x => 1, z => 3 } ) },
		qr/missing feature name.*y/,
		'missing key croaks'
	);
}; ## end 'predict_tagged - errors delegate to tagged_row_to_array' => sub

# ---------------------------------------------------------------------------
# score_sample_tagged
# ---------------------------------------------------------------------------

subtest 'score_sample_tagged - returns a scalar score in (0,1]' => sub {
	can_ok( $m, 'score_sample_tagged' );
	my $score = $m->score_sample_tagged( \%normal_row );
	ok( defined $score,            'returns a defined value' );
	ok( $score > 0 && $score <= 1, "score $score is in (0,1]" );
};

subtest 'score_sample_tagged - consistent with score_samples() for same row' => sub {
	for my $row ( \%normal_row, \%outlier_row ) {
		my $tagged = $m->score_sample_tagged($row);
		my $array  = $m->score_samples( [ [ map { $row->{$_} } @names ] ] )->[0];
		is( $tagged, $array,
			'score_sample_tagged matches score_samples() for row ' . join( ',', map { "$_=$row->{$_}" } @names ) );
	}
};

subtest 'score_sample_tagged - outlier scores higher than normal point' => sub {
	my $s_normal  = $m->score_sample_tagged( \%normal_row );
	my $s_outlier = $m->score_sample_tagged( \%outlier_row );
	ok( $s_outlier > $s_normal, "outlier ($s_outlier) scores higher than normal ($s_normal)" );
};

subtest 'score_sample_tagged - errors delegate to tagged_row_to_array' => sub {
	like(
		exception { $m->score_sample_tagged( [ 1, 2, 3 ] ) },
		qr/score_sample_tagged requires a hashref/,
		'non-hashref croaks'
	);
	like(
		exception { $m_nonames->score_sample_tagged( \%normal_row ) },
		qr/no stored feature_names/,
		'no feature_names croaks'
	);
	like(
		exception { $m->score_sample_tagged( { x => 1, y => 2, BOGUS => 3 } ) },
		qr/unknown feature name.*BOGUS/,
		'unknown key croaks'
	);
	like(
		exception { $m->score_sample_tagged( { x => 1, z => 3 } ) },
		qr/missing feature name.*y/,
		'missing key croaks'
	);
}; ## end 'score_sample_tagged - errors delegate to tagged_row_to_array' => sub

# ---------------------------------------------------------------------------
# score_predict_sample_tagged
# ---------------------------------------------------------------------------

subtest 'score_predict_sample_tagged - returns [$score, $label]' => sub {
	can_ok( $m, 'score_predict_sample_tagged' );
	my $pair = $m->score_predict_sample_tagged( \%normal_row );
	is( ref $pair,     'ARRAY', 'return value is an arrayref' );
	is( scalar @$pair, 2,       'arrayref has exactly two elements' );
	my ( $score, $label ) = @$pair;
	ok( $score > 0 && $score <= 1,  "score $score is in (0,1]" );
	ok( $label == 0 || $label == 1, "label is 0 or 1 (got $label)" );
};

subtest 'score_predict_sample_tagged - consistent with score_predict_samples()' => sub {
	for my $threshold ( undef, 0.4, 0.6 ) {
		for my $row ( \%normal_row, \%outlier_row ) {
			my $pair_tagged
				= defined $threshold
				? $m->score_predict_sample_tagged( $row, $threshold )
				: $m->score_predict_sample_tagged($row);

			my $pair_array
				= defined $threshold
				? $m->score_predict_samples( [ [ map { $row->{$_} } @names ] ], $threshold )->[0]
				: $m->score_predict_samples( [ [ map { $row->{$_} } @names ] ] )->[0];

			my $label = defined $threshold ? "threshold=$threshold" : 'default threshold';
			is( $pair_tagged->[0], $pair_array->[0], "score matches score_predict_samples ($label)" );
			is( $pair_tagged->[1], $pair_array->[1], "label matches score_predict_samples ($label)" );
		} ## end for my $row ( \%normal_row, \%outlier_row )
	} ## end for my $threshold ( undef, 0.4, 0.6 )
}; ## end 'score_predict_sample_tagged - consistent with score_predict_samples()' => sub

subtest 'score_predict_sample_tagged - score and label are coherent' => sub {
	for my $threshold ( 0.3, 0.5, 0.7 ) {
		for my $row ( \%normal_row, \%outlier_row ) {
			my ( $score, $label )
				= @{ $m->score_predict_sample_tagged( $row, $threshold ) };
			my $expected_label = $score >= $threshold ? 1 : 0;
			is( $label, $expected_label, "label $label is consistent with score $score at threshold $threshold" );
		}
	}
}; ## end 'score_predict_sample_tagged - score and label are coherent' => sub

subtest 'score_predict_sample_tagged - uses contamination threshold by default' => sub {
	my $tagged = $m_contam->score_predict_sample_tagged( \%normal_row );
	my $array  = $m_contam->score_predict_samples( [ [ map { $normal_row{$_} } @names ] ] )->[0];
	is( $tagged->[0], $array->[0], 'score matches under contamination threshold' );
	is( $tagged->[1], $array->[1], 'label matches under contamination threshold' );
};

subtest 'score_predict_sample_tagged - errors delegate to tagged_row_to_array' => sub {
	like(
		exception { $m->score_predict_sample_tagged( [ 1, 2, 3 ] ) },
		qr/score_predict_sample_tagged requires a hashref/,
		'non-hashref croaks'
	);
	like(
		exception { $m_nonames->score_predict_sample_tagged( \%normal_row ) },
		qr/no stored feature_names/,
		'no feature_names croaks'
	);
	like(
		exception {
			$m->score_predict_sample_tagged( { x => 1, y => 2, BOGUS => 3 } );
		},
		qr/unknown feature name.*BOGUS/,
		'unknown key croaks'
	);
	like(
		exception { $m->score_predict_sample_tagged( { x => 1, z => 3 } ) },
		qr/missing feature name.*y/,
		'missing key croaks'
	);
}; ## end 'score_predict_sample_tagged - errors delegate to tagged_row_to_array' => sub

# ---------------------------------------------------------------------------
# Persistence: feature_names survive to_json/from_json and tagged methods
# work on a reloaded model.
# ---------------------------------------------------------------------------

subtest 'feature_names round-trips through to_json/from_json' => sub {
	my $clone = $CLASS->from_json( $m->to_json );

	is_deeply( $clone->feature_names, \@names, 'feature_names are identical after from_json' );

	my $orig_score  = $m->score_sample_tagged( \%normal_row );
	my $clone_score = $clone->score_sample_tagged( \%normal_row );
	is( $clone_score, $orig_score, 'score_sample_tagged matches on reloaded model' );

	my $orig_label  = $m->predict_tagged( \%normal_row );
	my $clone_label = $clone->predict_tagged( \%normal_row );
	is( $clone_label, $orig_label, 'predict_tagged matches on reloaded model' );

	my $orig_pair  = $m->score_predict_sample_tagged( \%normal_row );
	my $clone_pair = $clone->score_predict_sample_tagged( \%normal_row );
	is_deeply( $clone_pair, $orig_pair, 'score_predict_sample_tagged matches on reloaded model' );
}; ## end 'feature_names round-trips through to_json/from_json' => sub

done_testing;
