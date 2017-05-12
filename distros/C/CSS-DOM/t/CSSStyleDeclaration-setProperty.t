#!/usr/bin/perl -T

# This test is in its own file, because it checks to make sure that a cer-
# tain method does a ‘require’. We can’t test it if some other method has
# already done it.

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Style;

use tests 1;
my $s = new CSS::DOM::Style;
ok eval{$s->setProperty('foo'=>1);1},
	'setProperty works with ::Style is loaded before ::Parser';
