#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, InputFromDifferentGraphError)" => sub {
	my $todo = todo 'Test not implemented at this time. Commented out as TODO in upstream.';
	pass;
};

done_testing;
