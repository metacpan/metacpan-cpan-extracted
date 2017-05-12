#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

eval 'use Test::Pod';

plan skip_all => 'Test::Pod required for testing' if $@;

all_pod_files_ok();
