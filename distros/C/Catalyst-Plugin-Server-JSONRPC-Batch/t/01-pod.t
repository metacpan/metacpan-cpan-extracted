#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More;


plan(skip_all => 'Test::Pod 1.22 required for this test')
	unless eval('use Test::Pod 1.22; 1');
plan(skip_all => 'Set TEST_POD to enable this test (developer only)')
	unless $ENV{TEST_POD};

all_pod_files_ok();
