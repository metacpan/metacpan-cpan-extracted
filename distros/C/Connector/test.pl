#!/usr/bin/env perl
#


use strict;
use warnings;

my $val1 = undef;
my $val2 = '';
my $val3 = 'abc';
my $test;

$test = $val1 || 'connector';
warn "test with val1: '$test'";

$test = $val2 || 'connector';
warn "test with val2: '$test'";

$test = $val3 || 'connector';
warn "test with val3: '$test'";
