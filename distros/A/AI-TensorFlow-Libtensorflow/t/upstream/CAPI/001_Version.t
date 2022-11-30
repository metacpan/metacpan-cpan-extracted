#!/usr/bin/env perl

use Test2::V0;
use aliased 'AI::TensorFlow::Libtensorflow' => 'tf';

subtest "(CAPI, Version)" => sub {
	note 'Version: ', tf->Version;
	isnt tf->Version, '';
};

done_testing;
