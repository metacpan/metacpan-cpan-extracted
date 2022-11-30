#!/usr/bin/env perl

use Test2::V0;
use aliased 'AI::TensorFlow::Libtensorflow' => 'tf';
use aliased 'AI::TensorFlow::Libtensorflow::Tensor';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use FFI::Platypus::Buffer qw(window scalar_to_pointer);
use FFI::Platypus::Memory qw(memset free);
use AI::TensorFlow::Libtensorflow::Lib::_Alloc;

subtest "(CAPI, MaybeMove)" => sub {
	my $num_bytes = 6 * FLOAT->Size;
	window( my $values,
		AI::TensorFlow::Libtensorflow::Lib::_Alloc->_tf_aligned_alloc($num_bytes),
		$num_bytes
	);

	my @dims = (2,3);
	my $deallocator_called = 0;
	my $t = Tensor->New(FLOAT, \@dims, \$values, sub {
		my $pointer = shift;
		AI::TensorFlow::Libtensorflow::Lib::_Alloc->_tf_aligned_free($pointer);
		$deallocator_called = 1;
	});
	ok !$deallocator_called, 'not deallocated';

	my $o = $t->MaybeMove;

	is $o, U(), 'it is unsafe to move memory TF might not own';

	undef $t;
	ok $deallocator_called, 'deallocated'
};

done_testing;
