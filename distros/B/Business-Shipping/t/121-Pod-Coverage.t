#!/bin/env perl

# Use Test::Pod::Coverage to check how much of the perl is documented.

use strict;
use warnings;
use Test::More;

eval { require Test::Pod::Coverage };
plan skip_all => 'Test::Pod::Coverage not installed.'
    if $@;    # I prefer a silent skip
import Test::Pod::Coverage;

plan skip_all => 'Author test. Set TEST_AUTHOR to run.'
    unless $ENV{TEST_AUTHOR};
plan 'no_plan';

my @all_modules = Test::Pod::Coverage::all_modules();
my @ignore;

#my @ignore = qw/
#    Business::Shipping::ClassInfo
#    Business::Shipping::KLogging
#    Business::Shipping::Tracking
#    /;

for my $ignore (@ignore) {
    @all_modules = grep(!/^${ignore}$/, @all_modules);
}

for (@all_modules) {
    pod_coverage_ok($_);
}

