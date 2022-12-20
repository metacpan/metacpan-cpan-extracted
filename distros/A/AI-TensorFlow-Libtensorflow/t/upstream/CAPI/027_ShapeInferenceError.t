#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, ShapeInferenceError)" => sub {
	note q|TF_FinishOperation should fail if the shape of the added operation cannot
	be inferred.|;
	my $status = AI::TensorFlow::Libtensorflow::Status->New;
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note q|Create this failure by trying to add two nodes with incompatible shapes
	(A tensor with shape [2] and a tensor with shape [3] cannot be added).|;
	my @data = 1..3;

	my $vec2_tensor = TF_Utils::Int8Tensor([ @data[0..1] ]);
	my $vec2 = TF_Utils::Const($graph, $status, "vec2", $vec2_tensor );
	TF_Utils::AssertStatusOK($status);

	my $vec3_tensor = TF_Utils::Int8Tensor([ @data[0..2] ]);
	my $vec3 = TF_Utils::Const( $graph, $status, "vec3", $vec3_tensor );
	TF_Utils::AssertStatusOK($status);

	my $add = TF_Utils::AddNoCheck($vec2, $vec3, $graph, $status);
	TF_Utils::AssertStatusNotOK($status);
	is $add, U();
};

done_testing;
