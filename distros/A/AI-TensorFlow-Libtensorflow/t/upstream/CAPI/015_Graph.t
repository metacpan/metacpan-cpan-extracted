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
subtest "(CAPI, Graph)" => sub {
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'Make a placeholder operation.';
	my $feed = TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);

	subtest 'Test TF_Operation*() query functions.' => sub {
		is $feed->Name, 'feed', 'name';
		is $feed->OpType, 'Placeholder', 'optype';
		is $feed->Device, '', 'device';
		is $feed->NumOutputs, 1, 'num outputs';
		cmp_ok $feed->OutputType(
			$TFOutput->coerce({oper => $feed, index => 0})
		), 'eq', INT32, 'output 0 type';

		is $feed->OutputListLength("output", $s), 1, 'output list length';
		TF_Utils::AssertStatusOK($s);

		is $feed->NumInputs, 0, 'num inputs';
		is $feed->OutputNumConsumers(
			$TFOutput->coerce({oper => $feed, index => 0})
		), 0, 'output 0 num consumers';
		is $feed->NumControlInputs, 0, 'num control inputs';
		is $feed->NumControlOutputs, 0, 'num control outputs';
	};

	subtest 'Test not found errors in TF_Operation*() query functions.' => sub {
		is $feed->OutputListLength('bogus', $s), -1, 'bogus output';
		note TF_Utils::AssertStatusNotOK($s);
	};

	note 'Make a constant oper with the scalar "3".';
	my $three = TF_Utils::ScalarConst($graph, $s, 'scalar', INT32, 3);
	TF_Utils::AssertStatusOK($s);

	note 'Add oper.';
	my $add = TF_Utils::Add($feed, $three, $graph, $s);
	TF_Utils::AssertStatusOK($s);

	subtest 'Test TF_Operation*() query functions.' => sub {
		is $add->Name, 'add', 'name';
		is $add->OpType, 'AddN', 'op type';
		is $add->Device, '', 'device';
		is $add->NumOutputs, 1, 'num outputs';
		cmp_ok $add->OutputType($TFOutput->coerce([$add => 0])),
			'eq', INT32, 'output type';
		is $add->OutputListLength('sum', $s), 1, 'output list length';
		TF_Utils::AssertStatusOK($s);
		is $add->NumInputs, 2, 'num inputs';
		is $add->InputListLength("inputs", $s), 2, 'InputListLength';
		TF_Utils::AssertStatusOK($s);
		cmp_ok $add->InputType( $TFInput->coerce([$add, 0])  ),
			'eq', INT32, 'input type 0';
		cmp_ok $add->InputType( $TFInput->coerce([$add, 1])),
			'eq', INT32, 'input type 1';
		my $add_in_0 = $add->Input($TFInput->coerce([$add, 0]));
		is $add_in_0->oper->Name, $feed->Name, 'feed.out[0] -> add.in[0] by name';
		is $add_in_0->index, 0, 'by index';
		my $add_in_1 = $add->Input( $TFInput->coerce([$add, 1]) );
		is $add_in_1->oper->Name, $three->Name, 'three.out[0] -> add.in[1] by name';
		is $add_in_1->index, 0, 'by index';
		is $add->OutputNumConsumers(
			$TFOutput->coerce([$add, 0])),
			0, 'no consumers of add.out[0]';
		is $add->NumControlInputs, 0, 'no control inputs';
		is $add->NumControlOutputs, 0, 'no control outputs';
	};

	subtest 'Placeholder oper now has a consumer.' => sub {
		is $feed->OutputNumConsumers(
				$TFOutput->coerce([$feed, 0])
			), 1, 'feed has 1 consumer';
		my ($feed_port) = @{ $feed->OutputConsumers(
			$TFOutput->coerce([$feed => 0])
		) };
		is $feed_port->oper->Name, $add->Name, 'feed.out[0] -> add.in[0], by name';
		is $feed_port->index, 0, 'by index';

		note 'The scalar const oper also has a consumer.';
		is $three->OutputNumConsumers(
			$TFOutput->coerce([$three, 0])
		), 1, '1 consumer of scalar three';
		my ($three_port) = @{ $three->OutputConsumers(
			$TFOutput->coerce([$three => 0])
		) };
		is $three_port->oper->Name, $add->Name, 'three.out[0] -> add.in[1], by name';
		is $three_port->index, 1, 'by index';
	};

	subtest 'Serialize to GraphDef.' => sub {
		skip_all "Can not use C++ tensorflow::GraphDef* to check";
	};

	note 'Add another oper to the graph.';
	my $neg = TF_Utils::Neg( $add, $graph, $s );
	TF_Utils::AssertStatusOK($s);
	is $neg->Name, 'neg', 'neg name';
	is $neg->OpType, 'Neg', 'neg op type';

	subtest 'Serialize to NodeDef.' => sub {
		skip_all 'Can not use C++ tensorflow::NodeDef* to check';
	};

	subtest 'Test iterating through the nodes of a graph.' => sub {
		my $pos = 0;
		my %oper_by_name;
		while( my $oper = $graph->NextOperation(\$pos) ) {
			$oper_by_name{$oper->Name} = $oper;
		}
		is \%oper_by_name, hash {
			field feed => D();
			field scalar => D();
			field add => D();
			field neg => D();
			end();
		}, 'got all operations';
	};
};

done_testing;
