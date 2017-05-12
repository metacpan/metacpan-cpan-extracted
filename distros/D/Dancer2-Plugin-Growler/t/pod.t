#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod 1.14';
plan skip_all => 'Test::Pod v1.14 required for testing POD' if $@;
all_pod_files_ok();
