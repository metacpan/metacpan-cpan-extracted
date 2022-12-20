#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';

subtest "(CAPI, Session_Min_XLA_GPU)" => sub {
	my $gpu_device = TF_Utils::GPUDeviceName();
	plan skip_all => "No GPU available" unless $gpu_device;

	TF_Utils::RunMinTest( device => $gpu_device, use_XLA => 1 );
};

done_testing;
