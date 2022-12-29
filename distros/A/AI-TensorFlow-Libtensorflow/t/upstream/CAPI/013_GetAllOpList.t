#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, GetAllOpList)" => sub {
	my $buf = AI::TensorFlow::Libtensorflow::TFLibrary->GetAllOpList();
	ok $buf;
};

done_testing;
