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

use CSS::DOM;

use tests 1; # insertRule
my $ss = new CSS::DOM;
ok eval{$ss->insertRule('a{ color: red }',0);1},
	'insertRule on empty style sheet doesn\'t die';
	# At one point during development, it did die because it was call-
	# ing methods on CSS::DOM::RuleParser which hadn’t been loaded.

