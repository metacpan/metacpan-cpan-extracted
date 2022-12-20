#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, LibraryLoadFunctions)" => sub {
	my $todo = todo 'Test not implemented at this time. No library built to load.';
	pass;
};

done_testing;
