#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, TensorEncodeDecodeStrings)" => sub {
	my $todo = todo 'Test not implemented at this time. Upstream test uses C++ tensorflow::Tensor.';
	pass;
};

done_testing;
