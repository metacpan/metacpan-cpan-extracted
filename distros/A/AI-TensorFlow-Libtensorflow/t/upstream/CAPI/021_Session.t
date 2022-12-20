#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(INT32);

subtest "(CAPI, Session)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Make a placeholder operation.';
	my $feed = TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);

	note 'Make a constant operation with the scalar "2".';
	my $two = TF_Utils::ScalarConst($graph, $s, 'two', INT32, 2);
	TF_Utils::AssertStatusOK($s);

	note 'Add operation.';
	my $add = TF_Utils::Add($feed, $two, $graph, $s);
	TF_Utils::AssertStatusOK($s);

	note 'Create a session for this graph.';
	my $csession = TF_Utils::CSession->new( graph => $graph, status => $s );
	TF_Utils::AssertStatusOK($s);

	note 'Run the graph.';
	$csession->SetInputs( [ $feed, TF_Utils::Int32Tensor(3) ]);
	$csession->SetOutputs($add);
	$csession->Run($s);
	TF_Utils::AssertStatusOK($s);
	is $csession->output_tensor(0), object {
		call Type => INT32;
		call NumDims => 0; # scalar
		call ByteSize => INT32->Size;
		call sub {
			[ unpack "l*", ${ shift->Data } ];
		} => [ 3 + 2 ];
	}, 'Add( Feed() = 3 , Const(2) )';;

	note 'Add another operation to the graph.';
	my $neg = TF_Utils::Neg( $add, $graph, $s );
	TF_Utils::AssertStatusOK($s);

	note 'Run up to the new operation.';
	$csession->SetInputs( [ $feed, TF_Utils::Int32Tensor(7) ]);
	$csession->SetOutputs( $neg );
	$csession->Run($s);
	TF_Utils::AssertStatusOK($s);
	is $csession->output_tensor(0), object {
		call Type => INT32;
		call NumDims => 0; # scalar
		call ByteSize => INT32->Size;
		call sub {
			[ unpack "l*", ${ shift->Data } ];
		} => [ -(7 + 2) ];
	}, 'Neg( Add( Feed() = 7, Const(2) ) )';
};

done_testing;
