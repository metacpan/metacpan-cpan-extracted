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
subtest "(CAPI, UpdateEdge)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Make two scalar constants.';
	my $one = TF_Utils::ScalarConst($graph, $s, 'one', INT32, 1);
	TF_Utils::AssertStatusOK($s);

	my $two = TF_Utils::ScalarConst($graph, $s, 'two', INT32, 2);
	TF_Utils::AssertStatusOK($s);

	note 'Add oper.';
	my $add = TF_Utils::Add($one, $two, $graph, $s, 'add');
	TF_Utils::AssertStatusOK($s);

	note 'Add another oper to the graph.';
	my $neg = TF_Utils::Neg( $add, $graph, $s, 'neg' );
	TF_Utils::AssertStatusOK($s);

	pass 'Skip test with NodeDef. Can not use C++ tensorflow::NodeDef* to check';

	note 'update edge of neg';
	$graph->UpdateEdge(
		$TFOutput->coerce([$one => 0]),
		$TFInput->coerce([$neg => 0]),
		$s
	);

	pass 'Skip test with NodeDef, no C++ tensorflow::NodeDef* to check';
	my $neg_input_0 = $neg->Input( $TFInput->coerce([ $neg => 0 ]) );
	is $neg_input_0, object {
		call sub { shift->oper->Name } => $one->Name;
		call index => 0;
	}, 'one:0 -> neg:0';
};

done_testing;
