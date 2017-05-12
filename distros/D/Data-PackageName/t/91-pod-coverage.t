#!perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::More;
plan skip_all => 'Set TEST_AUTHOR to a true value to run these tests' unless $ENV{TEST_AUTHOR};

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required to run POD coverage tests' if $@;

all_pod_coverage_ok();

