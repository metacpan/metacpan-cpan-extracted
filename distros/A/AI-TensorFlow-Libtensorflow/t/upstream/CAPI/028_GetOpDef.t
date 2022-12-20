#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::Status;

subtest "(CAPI, GetOpDef)" => sub {
	my $status = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $buffer = AI::TensorFlow::Libtensorflow::Buffer->New;

	$graph->GetOpDef("Add", $buffer, $status);
	TF_Utils::AssertStatusOK($status);
	cmp_ok $buffer->length, '>', 0, 'Got Add OpDef buffer';

	pass 'Skipping these tests. Can not access tensorflow::OpDef C++.';

	$graph->GetOpDef("MyFakeOp", $buffer, $status);
	like $status, object {
		call GetCode => AI::TensorFlow::Libtensorflow::Status::NOT_FOUND;
		call Message => qr/\QOp type not registered 'MyFakeOp' in binary\E/;
	}, 'MyFakeOp is NOT_FOUND';
};

done_testing;
