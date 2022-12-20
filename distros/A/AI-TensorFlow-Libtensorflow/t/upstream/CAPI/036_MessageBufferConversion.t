#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, MessageBufferConversion)" => sub {
	pass 'Skip test with NodeDef. Can not use C++ tensorflow::NodeDef* to check';
};

done_testing;
