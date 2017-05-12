#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


plan skip_all => 'Set RELEASE_TESTING to enable this test (developer only)'
	unless $ENV{RELEASE_TESTING};
plan skip_all => 'Test::CheckManifest 0.9 required for this test'
	unless eval('use Test::CheckManifest 0.9; 1');

ok_manifest();


done_testing;
