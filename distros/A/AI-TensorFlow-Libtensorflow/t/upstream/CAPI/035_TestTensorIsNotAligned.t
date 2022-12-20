#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);
use AI::TensorFlow::Libtensorflow::Lib::_Alloc

subtest "(CAPI, TestTensorIsNotAligned)" => sub {
	pass 'Skipping due to no access to C++ tensorflow::Tensor';
};

done_testing;
