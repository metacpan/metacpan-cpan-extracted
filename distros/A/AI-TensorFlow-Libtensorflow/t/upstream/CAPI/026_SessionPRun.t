#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(INT32);
use AI::TensorFlow::Libtensorflow::Lib::Types qw(
	TFOutput TFOutputFromTuple
	TFInput  TFInputFromTuple
);
use Types::Standard qw(HashRef);

my $TFOutput = TFOutput->plus_constructors(
		HashRef, 'New'
	)->plus_coercions(TFOutputFromTuple);
my $TFInput = TFInput->plus_constructors(
		HashRef, 'New'
	)->plus_coercions(TFInputFromTuple);

subtest "(CAPI, SessionPRun)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Construct the graph: A + 2 + B';
	my $op_a = TF_Utils::Placeholder($graph, $s, "A");
	TF_Utils::AssertStatusOK($s);

	my $op_b = TF_Utils::Placeholder($graph, $s, "B");
	TF_Utils::AssertStatusOK($s);

	my $two = TF_Utils::ScalarConst($graph, $s, 'scalar', INT32, 2);
	TF_Utils::AssertStatusOK($s);

	my $plus2 = TF_Utils::Add( $op_a, $two, $graph, $s, "plus2");
	TF_Utils::AssertStatusOK($s);

	my $plusB = TF_Utils::Add($plus2, $op_b, $graph, $s, "plusB");
	TF_Utils::AssertStatusOK($s);

	note q{Setup a session and a partial run handle.  The partial run will allow
	computation of A + 2 + B in two phases (calls to TF_SessionPRun):
	1. Feed A and get (A+2)
	2. Feed B and get (A+2)+B};
	my $opts = AI::TensorFlow::Libtensorflow::SessionOptions->New;
	my $sess = AI::TensorFlow::Libtensorflow::Session->New($graph, $opts, $s);

	my @feeds = $TFOutput->map([ $op_a => 0 ], [$op_b => 0]);
	my @fetches = $TFOutput->map([$plus2 => 0], [$plusB => 0]);

	my $handle = $sess->PRunSetup( \@feeds, \@fetches, undef, $s);

	note 'Feed A and fetch A + 2.';
	my @feeds1 = $TFOutput->map( [$op_a => 0] );
	my @fetches1 = $TFOutput->map( [$plus2 => 0] );
	my @feedValues1 = ( TF_Utils::Int32Tensor(1) );
	my @fetchValues1;
	$sess->PRun( $handle,
		\@feeds1, \@feedValues1,
		\@fetches1, \@fetchValues1,
		undef,
		$s );
	TF_Utils::AssertStatusOK($s);
	is unpack("l", ${ $fetchValues1[0]->Data }), 3,
		'(A := 1) + Const(2) = 3';
	undef @feedValues1;
	undef @fetchValues1;

	note 'Feed B and fetch (A + 2) + B.';
	my @feeds2 = $TFOutput->map( [$op_b => 0] );
	my @fetches2 = $TFOutput->map( [$plusB => 0] );
	my @feedValues2 = ( TF_Utils::Int32Tensor(4) );
	my @fetchValues2;
	$sess->PRun($handle,
		\@feeds2, \@feedValues2,
		\@fetches2, \@fetchValues2,
		undef,
		$s);
	TF_Utils::AssertStatusOK($s);
	is unpack("l", ${ $fetchValues2[0]->Data }), 7,
		'( (A := 1) + Const(2) ) + ( B := 4 ) = 7';

	undef $handle;
	$sess->Close($s);
	TF_Utils::AssertStatusOK($s);
	undef $graph;
	undef $s;
};

done_testing;
