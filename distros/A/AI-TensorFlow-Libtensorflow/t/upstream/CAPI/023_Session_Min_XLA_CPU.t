#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, Session_Min_XLA_CPU)" => sub {
	TF_Utils::RunMinTest( device => "", use_XLA => 1 );
};

done_testing;
