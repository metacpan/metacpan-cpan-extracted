#!perl
use warnings;
use strict;

use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for POD tests' if $@;

all_pod_files_ok( all_pod_files('lib') );


