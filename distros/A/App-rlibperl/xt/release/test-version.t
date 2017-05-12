#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

eval "use Test::Version 0.04";
plan skip_all => "Test::Version 0.04 required for testing versions"
    if $@;

version_all_ok();
done_testing;
