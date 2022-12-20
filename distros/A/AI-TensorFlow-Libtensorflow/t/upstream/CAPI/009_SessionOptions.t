#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';
use aliased 'AI::TensorFlow::Libtensorflow::SessionOptions';

subtest "(CAPI, SessionOptions)" => sub {
	my $opt = SessionOptions->New;
	ok $opt, 'created session options';
};

done_testing;
