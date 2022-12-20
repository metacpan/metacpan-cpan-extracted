#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(INT32);

subtest "(CAPI, ImportGraphDef_WithReturnOutputs)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Create a graph with two nodes: x and 3';
	TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName("feed"), 'get feed';
	my $oper = TF_Utils::ScalarConst( $graph, $s, 'scalar', INT32, 3);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName("scalar"), "get scalar";
	TF_Utils::Neg( $oper, $graph, $s );
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName("neg"), "get neg";

	note 'Export to a GraphDef.';
	my $graph_def = AI::TensorFlow::Libtensorflow::Buffer->New;
	$graph->ToGraphDef( $graph_def, $s );
	TF_Utils::AssertStatusOK($s);

	note 'Import it in a fresh graph with return outputs.';
	undef $graph;
	$graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->AddReturnOutput('feed', 0);
	$opts->AddReturnOutput('scalar', 0);
	is $opts->NumReturnOutputs, 2, '2 return outputs';
	my $return_outputs = $graph->ImportGraphDefWithReturnOutputs(
		$graph_def, $opts, $s
	);
	TF_Utils::AssertStatusOK($s);

	is [
		my ($scalar, $feed, $neg) = map $graph->OperationByName($_),
			qw(scalar feed neg)
	], array {
		item D() for 0..2;
		end;
	}, 'get operations';

	note 'Check return outputs';
	is $return_outputs, array {
		item 0 => object {
			call sub { shift->oper->Name } => $feed->Name;
			call index => 0;
		};
		item 1 => object {
			call sub { shift->oper->Name } => $scalar->Name;
			call index => 0;
		};
	}, 'return outputs';
};

done_testing;
