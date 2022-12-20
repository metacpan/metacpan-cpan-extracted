#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, Version)" => sub {
	note 'Version: ', Libtensorflow->Version;
	isnt Libtensorflow->Version, '';
};

done_testing;
