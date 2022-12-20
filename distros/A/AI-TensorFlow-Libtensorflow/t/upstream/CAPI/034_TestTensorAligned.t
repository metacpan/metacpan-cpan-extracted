#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use AI::TensorFlow::Libtensorflow::Lib::_Alloc

subtest "(CAPI, TestTensorAligned)" => sub {
	my $dim = 7;
	my $tensor_size_bytes = $dim * FLOAT->Size;
	my $t_a = AI::TensorFlow::Libtensorflow::Tensor->Allocate(
		FLOAT, [$dim], $tensor_size_bytes
	);

	if( $AI::TensorFlow::Libtensorflow::Lib::_Alloc::EIGEN_MAX_ALIGN_BYTES > 0 ) {
		ok $t_a->IsAligned, 'is aligned';
	} else {
		pass 'No alignment set for library';
	}
};

done_testing;
