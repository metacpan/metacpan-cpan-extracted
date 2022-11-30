#!/usr/bin/env perl

use Test::More tests => 1;

use lib 't/lib';

use AI::TensorFlow::Libtensorflow;

subtest "Get version of Tensorflow" => sub {
	my $version = AI::TensorFlow::Libtensorflow->Version;
	note $version;
	pass;
};

done_testing;
