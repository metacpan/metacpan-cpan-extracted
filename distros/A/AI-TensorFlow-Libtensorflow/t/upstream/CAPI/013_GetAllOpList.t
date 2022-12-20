#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, GetAllOpList)" => sub {
	my $buf = Libtensorflow->GetAllOpList();
	ok $buf;
};

done_testing;
