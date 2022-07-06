#!/usr/bin/perl
use Test::More;
eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum version" if $@;
all_minimum_version_ok('5.006');
