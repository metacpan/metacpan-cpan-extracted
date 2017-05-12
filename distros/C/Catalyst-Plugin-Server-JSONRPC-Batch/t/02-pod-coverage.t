#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More;


plan(skip_all => 'Test::Pod::Coverage 1.08 required for this test')
	unless eval('use Test::Pod::Coverage 1.08; 1');
plan(skip_all => 'Pod::Coverage 0.18 required for this test')
	unless eval('use Pod::Coverage 0.18; 1');
plan(skip_all => 'Set TEST_POD to enable this test (developer only)')
	unless $ENV{TEST_POD};

all_pod_coverage_ok();
