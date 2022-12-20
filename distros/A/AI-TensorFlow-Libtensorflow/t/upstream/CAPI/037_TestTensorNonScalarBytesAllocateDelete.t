#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(STRING);;
use List::Util qw(product);
use FFI::Platypus::Buffer qw(scalar_to_pointer);

subtest "(CAPI, TestTensorNonScalarBytesAllocateDelete)" => sub {
	my $sz_tstring = AI::TensorFlow::Libtensorflow::TString::SIZEOF_TF_TString;

	my $batch_size = 4;
	my @dims = ( $batch_size, 1 );
	my $num_elements = product(@dims);
	my $t = AI::TensorFlow::Libtensorflow::Tensor->Allocate( STRING, \@dims,
		$sz_tstring * $num_elements );

	my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
	my $data_ptr = scalar_to_pointer( ${ $t->Data } );
	for my $i (0..$batch_size-1) {
		my $data_i_ptr = $data_ptr + $sz_tstring * $i;
		my $data_i = $ffi->cast('opaque', 'TF_TString', $data_i_ptr );
		$data_i->Init;
		$data_i->{owner} = $t; # do not want to free the pointer
		# The following input string length is large enough to make sure that
		# copy to tstring in large mode.
		$data_i->Copy(
			"This is the " . ($i + 1) . "th. data element\n"
		);
	}

	undef $t;

	pass 'Created TF_STRING tensor and deallocated';
};

done_testing;
