#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use aliased 'AI::TensorFlow::Libtensorflow::Graph';
use aliased 'AI::TensorFlow::Libtensorflow::Status';
use aliased 'AI::TensorFlow::Libtensorflow::Output';
use AI::TensorFlow::Libtensorflow::DataType qw(INT32);

subtest "(CAPI, SetShape)" => sub {
	my $s     = Status->New;
	my $graph = Graph->New;

	my $feed = TF_Utils::Placeholder($graph, $s);
	TF_Utils::AssertStatusOK($s);

	my $feed_out_0 = Output->New({ oper => $feed, index => 0 });

	my $num_dims;

	note 'Fetch the shape, it should be completely unknown';
	$num_dims = $graph->GetTensorNumDims($feed_out_0, $s);
	TF_Utils::AssertStatusOK($s);
	is $num_dims, -1, 'Dims are unknown';

	note 'Set the shape to be unknown, expect no change';
	$graph->SetTensorShape($feed_out_0, undef, $s);
	$num_dims = $graph->GetTensorNumDims($feed_out_0, $s);
	TF_Utils::AssertStatusOK($s);
	is $num_dims, -1, 'Dims are still unknown';

	note 'Set the shape to be 2 x Unknown';
	my $dims = [2, -1];
	$graph->SetTensorShape( $feed_out_0, $dims, $s);
	TF_Utils::AssertStatusOK($s);

	note 'Fetch the shape and validate it is 2 by -1.';
	$num_dims = $graph->GetTensorNumDims($feed_out_0, $s);
	TF_Utils::AssertStatusOK($s);
	is $num_dims, 2, '2 dimensions';

	my $returned_dims;
	$returned_dims = $graph->GetTensorShape( $feed_out_0, $s );
	TF_Utils::AssertStatusOK($s);
	is $returned_dims, $dims, "Got shape [ @$dims ]";


	note 'Set to a new valid shape: [2, 3]';
	$dims->[1] = 3;
	$graph->SetTensorShape( $feed_out_0, $dims, $s);
	TF_Utils::AssertStatusOK($s);

	note 'Fetch and see that the new value is returned.';
	$returned_dims = $graph->GetTensorShape( $feed_out_0, $s );
	TF_Utils::AssertStatusOK($s);
	is $returned_dims, $dims, "Got shape [ @$dims ]";

	note q{
		Try to set 'unknown' with unknown rank on the shape and see that
		it doesn't change.
	};
	$graph->SetTensorShape($feed_out_0, undef, $s);
	TF_Utils::AssertStatusOK($s);
	$num_dims = $graph->GetTensorNumDims( $feed_out_0, $s );
	$returned_dims = $graph->GetTensorShape( $feed_out_0, $s );
	TF_Utils::AssertStatusOK($s);
	is $num_dims, 2, 'unchanged numdims';
	is $returned_dims, [2,3], 'dims still [2 3]';

	note q{
		Try to set 'unknown' with same rank on the shape and see that
		it doesn't change.
	};
	$graph->SetTensorShape($feed_out_0, [-1, -1], $s);
	TF_Utils::AssertStatusOK($s);
	$returned_dims = $graph->GetTensorShape( $feed_out_0, $s );
	TF_Utils::AssertStatusOK($s);
	is $returned_dims, [2,3], 'dims still [2 3]';

	note 'Try to fetch a shape with the wrong num_dims';
	pass 'This test not implemented for binding. Not possible to have invalid argument for num_dims.';

	note 'Try to set an invalid shape (cannot change 2x3 to a 2x5).';
	$dims->[1] = 5;
	$graph->SetTensorShape( $feed_out_0, $dims, $s);
	note TF_Utils::AssertStatusNotOK($s);

	note 'Test for a scalar.';
	my $three = TF_Utils::ScalarConst($graph, $s, 'scalar', INT32, 3);
	TF_Utils::AssertStatusOK($s);
	my $three_out_0 = Output->New({ oper => $three, index => 0 });

	$num_dims = $graph->GetTensorNumDims( $three_out_0, $s );
	TF_Utils::AssertStatusOK($s);
	is $num_dims, 0, 'zero dims';
	$returned_dims = $graph->GetTensorShape( $three_out_0, $s );
	is $returned_dims, [], 'dims is empty ArrayRef';
};

done_testing;
