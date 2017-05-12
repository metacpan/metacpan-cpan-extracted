#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


plan skip_all => 'Set RELEASE_TESTING to enable this test (developer only)'
	unless $ENV{RELEASE_TESTING};
plan skip_all => 'Test::Pod 1.14 required for this test'
	unless eval('use Test::Pod 1.14; 1');

all_pod_files_ok();


done_testing;
