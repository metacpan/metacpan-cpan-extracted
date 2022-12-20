#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use PDL::Primitive qw(random);
use PDL::Core;
use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);

use aliased 'AI::TensorFlow::Libtensorflow::Output';
use aliased 'AI::TensorFlow::Libtensorflow::Tensor';

use FFI::Platypus::Buffer qw(scalar_to_pointer);
use FFI::Platypus::Memory qw(memcpy);

subtest "Session run" => sub {
	my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
	my $graph = TF_Utils::LoadGraph('t/models/graph.pb');
	ok $graph, 'graph';
	my $input_op = Output->New({
		oper => $graph->OperationByName( 'input_4' ),
		index => 0 });
	die "Can not init input op" unless $input_op;

	use PDL;
	my $p_data = float(
		-0.4809832, -0.3770838, 0.1743573, 0.7720509, -0.4064746, 0.0116595, 0.0051413, 0.9135732, 0.7197526, -0.0400658, 0.1180671, -0.6829428,
		-0.4810135, -0.3772099, 0.1745346, 0.7719303, -0.4066443, 0.0114614, 0.0051195, 0.9135003, 0.7196983, -0.0400035, 0.1178188, -0.6830465,
		-0.4809143, -0.3773398, 0.1746384, 0.7719052, -0.4067171, 0.0111654, 0.0054433, 0.9134697, 0.7192584, -0.0399981, 0.1177435, -0.6835230,
		-0.4808300, -0.3774327, 0.1748246, 0.7718700, -0.4070232, 0.0109549, 0.0059128, 0.9133330, 0.7188759, -0.0398740, 0.1181437, -0.6838635,
		-0.4807833, -0.3775733, 0.1748378, 0.7718275, -0.4073670, 0.0107582, 0.0062978, 0.9131795, 0.7187147, -0.0394935, 0.1184392, -0.6840039,
	);
	$p_data->reshape(1,5,12);

	my $input_tensor = AI::TensorFlow::Libtensorflow::Tensor->New(
		FLOAT, [ $p_data->dims ], $p_data->get_dataref,
		sub { undef $p_data }
	);


	my $output_op = Output->New({
		oper => $graph->OperationByName( 'output_node0'),
		index => 0 } );
	die "Can not init output op" unless $output_op;

	my $status = AI::TensorFlow::Libtensorflow::Status->New;
	my $options = AI::TensorFlow::Libtensorflow::SessionOptions->New;
	my $session = AI::TensorFlow::Libtensorflow::Session->New($graph, $options, $status);
	die "Could not create session" unless $status->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;

	my @output_values;
	my $target_op_a = undef;
	$session->Run(
		undef,
		[$input_op ], [$input_tensor],
		[$output_op], \@output_values,
		undef,
		undef,
		$status
	);

	die "run failed" unless $status->GetCode == AI::TensorFlow::Libtensorflow::Status::OK;

	my $output_tensor = $output_values[0];
	my $output_pdl = zeros(float,( map $output_tensor->Dim($_), 0..$output_tensor->NumDims-1) );

	memcpy scalar_to_pointer( ${$output_pdl->get_dataref} ),
		scalar_to_pointer( ${$output_tensor->Data} ),
		$output_tensor->ByteSize;
	$output_pdl->upd_data;

	my $expected_pdl = float( -0.409784, -0.302862, 0.0152587, 0.690515 )->transpose;

	ok approx( $output_pdl, $expected_pdl )->all, 'got expected data';

	$session->Close($status);

	is $status->GetCode, AI::TensorFlow::Libtensorflow::Status::OK, 'status ok';
};

done_testing;
