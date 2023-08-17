#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod';
plan skip_all => "Test::Pod required to check files." if $@;
all_pod_files_ok();

done_testing;
