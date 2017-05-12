#!perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::More;
plan skip_all => 'Set TEST_AUTHOR to a true value to run these tests' unless $ENV{TEST_AUTHOR};

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for POD tests' if $@;

all_pod_files_ok( all_pod_files('lib') );

