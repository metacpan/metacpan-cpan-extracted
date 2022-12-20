#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(UINT64);;
use FFI::Platypus::Memory qw(memcpy);
use FFI::Platypus::Buffer qw(scalar_to_pointer);

subtest "(CAPI, TestBitcastFrom_Reshape)" => sub {
	my @dims = (2, 3);
	is my $t_a = AI::TensorFlow::Libtensorflow::Tensor->Allocate(
		UINT64, \@dims
	), object {
		call ElementCount => 6;
		call ByteSize     => 6 * UINT64->Size;
	}, '2x3 TFTensor';
	is my $t_b = AI::TensorFlow::Libtensorflow::Tensor->Allocate(
		UINT64, undef
	), object {
		call ElementCount => 1;
		call ByteSize     => UINT64->Size;
	}, 'scalar TFTensor';

	my @new_dims = (3, 2);
	my $status = AI::TensorFlow::Libtensorflow::Status->New;
	$t_a->BitcastFrom( UINT64, $t_b, \@new_dims, $status );
	TF_Utils::AssertStatusOK($status);

	my $same_tftensor = object {
		call ElementCount => 6;
		call ByteSize     => 6 * UINT64->Size;
	};
	is $t_a, $same_tftensor, '6 elements in 2x3';
	is $t_b, $same_tftensor, '6 elements in 3x2';

	my $UINT64_pack = 'Q';
	my $set_first_value = sub {
		my ($t, $v) = @_;
		memcpy scalar_to_pointer(${$t->Data}),
			scalar_to_pointer(pack($UINT64_pack, $v)),
			UINT64->Size;
	};
	my $get_first_value = sub { my ($t) = @_; unpack $UINT64_pack, ${$t->Data}; };
	note 'Check that a write to one tensor shows up in the other.';
	$set_first_value->($t_a, 4);
	is $get_first_value->($t_b), 4, 'got 4 in tensor b';
	$set_first_value->($t_b, 6);
	is $get_first_value->($t_a), 6, 'got 6 in tensor a';
};

done_testing;
