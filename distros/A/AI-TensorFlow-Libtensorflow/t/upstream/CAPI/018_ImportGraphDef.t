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

subtest "(CAPI, ImportGraphDef)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Create a simple graph.';
	TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName( 'feed' ), 'got feed operation from graph';
	my $oper = TF_Utils::ScalarConst( $graph, $s, 'scalar', INT32, 3);
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName( 'scalar' ), 'got scalar operation from graph';
	TF_Utils::Neg( $oper, $graph, $s );
	TF_Utils::AssertStatusOK($s);
	ok $graph->OperationByName( 'neg' ), 'got neg operation from graph';

	note 'Export to a GraphDef.';
	my $graph_def = AI::TensorFlow::Libtensorflow::Buffer->New;
	$graph->ToGraphDef( $graph_def, $s );
	TF_Utils::AssertStatusOK($s);

	note 'Import it, with a prefix, in a fresh graph.';
	undef $graph;
	$graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->SetPrefix('imported');
	$graph->ImportGraphDef($graph_def, $opts, $s);
	TF_Utils::AssertStatusOK($s);

	ok my $scalar = $graph->OperationByName('imported/scalar'), 'imported/scalar';
	ok my $feed = $graph->OperationByName('imported/feed'), 'imported/feed';
	ok my $neg = $graph->OperationByName('imported/neg'), 'imported/neg';

	note 'Test basic structure of the imported graph.';
	is $scalar->NumInputs, 0, 'scalar.inputs == 0';
	is $feed->NumInputs, 0, 'feed.inputs == 0';
	is $neg->NumInputs, 1, 'neg.inputs == 1';
	my $neg_input = $neg->Input( $TFInput->coerce([$neg => 0]) );
	is $neg_input, object {
		call sub { shift->oper->Name }, $scalar->Name;
		call index => 0;
	}, 'scalar:0 -> neg:0';

	note q|Test that we can't see control edges involving the source and sink nodes.|;
	my $empty_control_inputs = object {
		call NumControlInputs => 0;
		call GetControlInputs => array { end; };
	};
	my $empty_control_outputs = object {
		call NumControlOutputs => 0;
		call GetControlOutputs => array { end; };
	};
	is $scalar, $empty_control_inputs, 'scalar control inputs';
	is $scalar, $empty_control_outputs, 'scalar control outputs';

	is $feed, $empty_control_inputs, 'feed control inputs';
	is $feed, $empty_control_outputs, 'feed control outputs';

	is $neg, $empty_control_inputs, 'neg control inputs';
	is $neg, $empty_control_outputs, 'neg control outputs';

	note q|Import it again, with an input mapping, return outputs, and a return
	operation, into the same graph.|;
	undef $opts;
	$opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->SetPrefix('imported2');
	$opts->AddInputMapping( 'scalar', 0, $TFOutput->coerce([$scalar=>0]));
	$opts->AddReturnOutput('feed', 0);
	$opts->AddReturnOutput('scalar', 0);
	is $opts->NumReturnOutputs, 2, 'num return outputs';
	$opts->AddReturnOperation('scalar');
	is $opts->NumReturnOperations, 1, 'num return operations';
	my $results = $graph->ImportGraphDefWithResults( $graph_def, $opts, $s );
	TF_Utils::AssertStatusOK($s);

	ok my $scalar2 = $graph->OperationByName("imported2/scalar"), "imported2/scalar";
	ok my $feed2 = $graph->OperationByName("imported2/feed"), "imported2/feed";
	ok my $neg2 = $graph->OperationByName("imported2/neg"), "imported2/neg";

	note 'Check input mapping';
	$neg_input = $neg->Input( $TFInput->coerce( [$neg => 0 ]) );
	is $neg_input, object {
		call sub { shift->oper->Name } => $scalar->Name;
		call index => 0;
	}, 'neg input';

	note 'Check return outputs';
	my $return_outputs = $results->ReturnOutputs;
	is $return_outputs, array {
		item 0 => object {
			call sub { shift->oper->Name } => $feed2->Name;
			call index => 0;
		};
		item 1 => object {
			# remapped
			call sub { shift->oper->Name } => $scalar->Name;
			call index => 0;
		};
		end;
	}, 'return outputs';

	note 'Check return operation';
	my $return_opers = $results->ReturnOperations;
	is $return_opers, array {
		item 0 => object {
			# not remapped
			call Name => $scalar2->Name;
		};
		end;
	}, 'return opers';

	undef $results;

	note 'Import again, with control dependencies, into the same graph.';
	undef $opts;
	$opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->SetPrefix("imported3");
	$opts->AddControlDependency($feed);
	$opts->AddControlDependency($feed2);
	$graph->ImportGraphDef($graph_def, $opts, $s);
	TF_Utils::AssertStatusOK($s);

	ok my $scalar3 = $graph->OperationByName("imported3/scalar"), "imported3/scalar";
	ok my $feed3 = $graph->OperationByName("imported3/feed"), "imported3/feed";
	ok my $neg3 = $graph->OperationByName("imported3/neg"), "imported3/neg";

	note q|Check that newly-imported scalar and feed have control deps (neg3 will
	inherit them from input)|;
	is $scalar3->GetControlInputs, array {
		item 0 => object { call Name => $feed->Name  };
		item 1 => object { call Name => $feed2->Name };
		end;
	}, 'scalar3 control inputs';

	is $feed3->GetControlInputs, array {
		item 0 => object { call Name => $feed->Name  };
		item 1 => object { call Name => $feed2->Name };
		end;
	}, 'feed3 control inputs';

	note 'Export to a graph def so we can import a graph with control dependencies';
	undef $graph_def;
	$graph_def = AI::TensorFlow::Libtensorflow::Buffer->New;
	$graph->ToGraphDef( $graph_def, $s );
	TF_Utils::AssertStatusOK($s);

	note 'Import again, with remapped control dependency, into the same graph';
	undef $opts;
	$opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;
	$opts->SetPrefix("imported4");
	$opts->RemapControlDependency("imported/feed", $feed );
	$graph->ImportGraphDef($graph_def, $opts, $s);
	TF_Utils::AssertStatusOK($s);

	ok my $scalar4 = $graph->OperationByName("imported4/imported3/scalar"),
		"imported4/imported3/scalar";
	ok my $feed4 = $graph->OperationByName("imported4/imported2/feed"),
		"imported4/imported2/feed";

	note q|Check that imported `imported3/scalar` has remapped control dep from
	original graph and imported control dep|;
	is $scalar4->GetControlInputs, array {
		item object { call Name => $feed->Name  };
		item object { call Name => $feed4->Name };
		end;
	}, 'scalar4 control inputs';

	undef $opts;
	undef $graph_def;

	note 'Can add nodes to the imported graph without trouble.';
	TF_Utils::Add( $feed, $scalar, $graph, $s );
	TF_Utils::AssertStatusOK($s);
};

done_testing;
