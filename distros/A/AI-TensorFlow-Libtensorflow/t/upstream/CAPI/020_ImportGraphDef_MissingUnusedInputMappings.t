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

subtest "(CAPI, ImportGraphDef_MissingUnusedInputMappings)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Create a graph with two nodes: x and 3';
	TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName( 'feed' ), 'feed';
	my $oper = TF_Utils::ScalarConst( $graph, $s, 'scalar', INT32, 3);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName('scalar'), 'scalar';
	TF_Utils::Neg( $oper, $graph, $s );
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName('neg'), 'neg';

	note 'Export to a GraphDef.';
	my $graph_def = AI::TensorFlow::Libtensorflow::Buffer->New;
	$graph->ToGraphDef( $graph_def, $s );
	TF_Utils::AssertStatusOK($s);

	note 'Import it in a fresh graph.';
	undef $graph;
	$graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$graph->ImportGraphDef($graph_def, $opts, $s);
	TF_Utils::AssertStatusOK($s);

	my $scalar = $graph->OperationByName('scalar');

	note 'Import it in a fresh graph with an unused input mapping.';
	undef $opts;
	$opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->SetPrefix("imported");
	$opts->AddInputMapping("scalar", 0, $TFOutput->coerce([$scalar, 0]));
	$opts->AddInputMapping("fake", 0, $TFOutput->coerce([$scalar, 0]));
	my $results = $graph->ImportGraphDefWithResults($graph_def, $opts, $s);
	TF_Utils::AssertStatusOK($s);

	note 'Check unused input mappings';
	is my $srcs = $results->MissingUnusedInputMappings, array {
		item [ 'fake', 0 ];
		end;
	}, 'missing unused input mappings';
};

done_testing;
