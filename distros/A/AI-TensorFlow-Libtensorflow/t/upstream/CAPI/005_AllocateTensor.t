#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use aliased 'AI::TensorFlow::Libtensorflow::Tensor';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);

subtest "(CAPI, AllocateTensor)" => sub {
	my $num_bytes = 6 * FLOAT->Size;
	my @dims = (2, 3);
	my $t = Tensor->Allocate(FLOAT, \@dims, $num_bytes);

	cmp_ok $t->Type, '==', FLOAT, 'a FLOAT TFTensor';
	is $t->NumDims, 2,  'with 2 dimensions';
	is $t->Dim(0), $dims[0], 'dim[0]';
	is $t->Dim(1), $dims[1], 'dim[1]';
	is $t->ByteSize, $num_bytes, 'size in bytes';
	is $t->ElementCount, 6, 'with 6 elements';
};

done_testing;
