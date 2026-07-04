#!perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Algorithm::Classifier::IsolationForest;

sub exception (&) {
	my $code = shift;
	my $ok   = eval { $code->(); 1 };
	return $ok ? undef : ( $@ // 'died' );
}

my $CLASS = 'Algorithm::Classifier::IsolationForest';

my @data;
for my $i ( -7 .. 7 ) {
	for my $j ( -7 .. 7 ) {
		push @data, [ $i / 7, $j / 7 ];
	}
}
push @data, ( [ 6, 6 ], [ -6, 6 ], [ 0, 8 ], [ 8, 0 ] );

# A query set distinct from the training set, to score before/after a round-trip.
my @query = ( [ 0, 0 ], [ 0.5, -0.5 ], [ 9, 9 ], [ -9, 1 ] );

sub scores_identical {
	my ( $a, $b, $label ) = @_;
	is( scalar @$a, scalar @$b, "$label: same number of scores" );
	my $diffs = grep { $a->[$_] != $b->[$_] } 0 .. $#$a;
	is( $diffs, 0, "$label: scores are bit-for-bit identical" );
}

my $orig = $CLASS->new(
	n_trees       => 50,
	sample_size   => 128,
	contamination => 0.05,
	seed          => 21,
);
$orig->fit( \@data );
my $orig_scores = $orig->score_samples( \@query );

subtest 'to_json produces a self-describing payload' => sub {
	my $json = $orig->to_json;
	ok( length $json, 'to_json returns a non-empty string' );
	like( $json, qr/Algorithm::Classifier::IsolationForest/, 'payload carries the format tag' );
	like( $json, qr/"trees"/,                                'payload includes the serialised trees' );
};

subtest 'from_json round-trip preserves scores' => sub {
	my $clone = $CLASS->from_json( $orig->to_json );
	isa_ok( $clone, $CLASS, 'from_json returns an object' );
	scores_identical( $orig_scores, $clone->score_samples( \@query ), 'from_json' );
	is( $clone->decision_threshold, $orig->decision_threshold, 'the learned threshold survives the round-trip' );
};

subtest 'save/load round-trip preserves scores' => sub {
	my ( $fh, $path ) = tempfile( UNLINK => 1 );
	close $fh;

	$orig->save($path);
	ok( -s $path, 'save() writes a non-empty model file' );

	my $loaded = $CLASS->load($path);
	isa_ok( $loaded, $CLASS, 'load returns an object' );
	scores_identical( $orig_scores, $loaded->score_samples( \@query ), 'save/load' );

	# A reloaded model predicts identically too.
	my $p1 = $orig->predict( \@query );
	my $p2 = $loaded->predict( \@query );
	is_deeply( $p2, $p1, 'predictions match after save/load' );
}; ## end 'save/load round-trip preserves scores' => sub

subtest 'from_json rejects bad input' => sub {
	like(
		exception { $CLASS->from_json('{}') },
		qr/not an IsolationForest model/,
		'a payload without the format tag is rejected'
	);
	like(
		exception { $CLASS->from_json('[]') },
		qr/not an IsolationForest model/,
		'a non-object payload is rejected'
	);
	like(
		exception {
			$CLASS->from_json('{"format":"Algorithm::Classifier::IsolationForest","trees":[]}');
		},
		qr/no trees/,
		'a model with an empty tree list is rejected'
	);
}; ## end 'from_json rejects bad input' => sub

subtest 'load reports a missing file' => sub {
	like(
		exception { $CLASS->load('/no/such/iforest/model.json') },
		qr/No such file or directory/,
		'load() croaks on an unreadable path'
	);
};

done_testing;
