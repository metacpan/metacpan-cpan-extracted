#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required" if $@;

# Main module: Strict coverage
pod_coverage_ok('Cron::Toolkit', { trustme => [qr/^_/] });

# Skip internals (private Tree::*; no POD needed for dist)
# (Add minimal =head1 NAME stubs if you want, but not required)

done_testing;
