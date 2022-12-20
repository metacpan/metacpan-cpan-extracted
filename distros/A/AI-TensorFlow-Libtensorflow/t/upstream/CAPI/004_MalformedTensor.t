#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use aliased 'AI::TensorFlow::Libtensorflow::Tensor';
use AI::TensorFlow::Libtensorflow::DataType qw(FLOAT);

subtest "(CAPI, MalformedTensor)" => sub {
	my $noop_dealloc = sub {};
	my $t = Tensor->New(FLOAT, [], \undef, $noop_dealloc);
	ok ! defined $t, 'No data passed in so no tensor created';
};

done_testing;
