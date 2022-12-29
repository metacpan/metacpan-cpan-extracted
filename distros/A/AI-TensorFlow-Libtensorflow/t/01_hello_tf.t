#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use TF_TestQuiet;
use AI::TensorFlow::Libtensorflow;

subtest "Get version of Tensorflow" => sub {
	my $version = AI::TensorFlow::Libtensorflow->Version;
	note $version;
	pass;
};

done_testing;
