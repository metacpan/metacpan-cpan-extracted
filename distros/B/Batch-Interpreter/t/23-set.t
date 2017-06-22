#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 2;
use Batch::Interpreter::TestSupport qw(get_test_attr compare_output);

my $test_attr = get_test_attr;
compare_output { %$test_attr, skip_stderr => 1 }, undef, 't/set.bat';
