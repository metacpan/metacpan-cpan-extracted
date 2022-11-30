#!/usr/bin/env perl

use Test2::V0;
use aliased 'AI::TensorFlow::Libtensorflow' => 'tf';
use aliased 'AI::TensorFlow::Libtensorflow::Lib';
use aliased 'AI::TensorFlow::Libtensorflow::Tensor';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use FFI::Platypus::Buffer qw(window scalar_to_pointer);
use FFI::Platypus::Memory qw(memset free);
use AI::TensorFlow::Libtensorflow::Lib::_Alloc;

subtest "(CAPI, Tensor)" => sub {
	my $n = 6;
	my $num_bytes = $n * FLOAT->Size;
	my $values_ptr = AI::TensorFlow::Libtensorflow::Lib::_Alloc->_tf_aligned_alloc($num_bytes);
	window( my $values, $values_ptr, $num_bytes );
	my @dims = (2, 3);

	note "Creating tensor";
	my $deallocator_called = 0;
	my $t = Tensor->New(FLOAT, \@dims, \$values, sub {
			my ($pointer, $size, $arg) = @_;
			$deallocator_called = 1;
			AI::TensorFlow::Libtensorflow::Lib::_Alloc->_tf_aligned_free($pointer);
		});

	# Deallocator can be called on this data already because it might not
	# fit the alignment needed by TF.
	#
	# It should not be called in this case because aligned_alloc() is used.
	ok ! $deallocator_called, 'deallocator not called yet';

	is $t->Type, 'FLOAT', 'FLOAT TF_Tensor';
	is $t->NumDims, 2, '2D TF_Tensor';
	is $t->Dim(0), $dims[0], 'dim 0';
	is $t->Dim(1), $dims[1], 'dim 1';
	is $t->ByteSize, $num_bytes, 'bytes';
	is scalar_to_pointer(${$t->Data}), scalar_to_pointer($values),
		'data at same pointer address';
	undef $t;
	ok $deallocator_called, 'deallocated';
};

done_testing;
