#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, StatusEnum)" => sub {
	my $todo = todo 'Test not implemented. Casting between C++ and C Status enum is not needed.';
	pass;
};

done_testing;
