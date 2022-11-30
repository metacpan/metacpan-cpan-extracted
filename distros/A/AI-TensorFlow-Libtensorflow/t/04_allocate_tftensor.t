#!/usr/bin/env perl

use Test::More tests => 1;

use strict;
use warnings;

use AI::TensorFlow::Libtensorflow;
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use List::Util qw(product);
use PDL;
use PDL::Core ':Internal';

use FFI::Platypus::Memory;
use FFI::Platypus::Buffer qw(scalar_to_pointer);

subtest "Allocate a TFTensor" => sub {
	my $ffi = FFI::Platypus->new( api => 1 );

	my @dims = ( 1, 5, 12 );
	my $ndims = scalar @dims;
	my $data_size_bytes = product(howbig(float), @dims);
	my $t = AI::TensorFlow::Libtensorflow::Tensor->Allocate(
		FLOAT, \@dims, $data_size_bytes,
	);

	ok $t && $t->Data, 'Allocated TFTensor';

	my $pdl = sequence(float, @dims );

	memcpy scalar_to_pointer(${ $t->Data }),
		scalar_to_pointer(${ $pdl->get_dataref }),
		List::Util::min( $t->ByteSize, $data_size_bytes );

	is $t->Type, AI::TensorFlow::Libtensorflow::DataType::FLOAT, 'Check Type is FLOAT';
	is $t->NumDims, $ndims, 'Check NumDims';
};

done_testing;
