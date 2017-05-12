#!/usr/bin/perl

use Class::Easy;

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
	if $@;

plan tests => 3;
pod_coverage_ok ("Class::Easy");
# pod_coverage_ok ("Class::Easy::Log");
pod_coverage_ok ("Class::Easy::Timer");
pod_coverage_ok ("Class::Easy::Base");
