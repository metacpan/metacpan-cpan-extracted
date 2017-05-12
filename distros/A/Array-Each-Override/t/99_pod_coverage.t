#! /usr/bin/perl

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
    if $@;
all_pod_coverage_ok({ trustme => [qw<unimport array_each array_keys array_values>] });
