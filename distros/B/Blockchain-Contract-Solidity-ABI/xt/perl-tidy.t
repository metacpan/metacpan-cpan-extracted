#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

## no critic
eval 'use Test::Code::TidyAll';
plan skip_all => "Test::Code::TidyAll required to check files." if $@;
tidyall_ok();

done_testing;

