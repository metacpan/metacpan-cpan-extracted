#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

die "usage: $0 <test name>" unless @ARGV;

Test::Catch::run(@ARGV);

done_testing();

