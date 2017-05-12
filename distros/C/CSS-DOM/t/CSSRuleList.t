#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::RuleList';

require CSS::DOM;
my $ss = CSS::DOM::parse('a{text-decoration: none} p { margin: 0 }');
my $list = cssRules $ss;

use tests 1; # isa
isa_ok $list, 'CSS::DOM::RuleList';

use tests 1; # length
is $list->length, @$list, 'length';

use tests 2; # item
is $list->item($_), $list->[$_], 'item ' . 'again' x $_ for 0..1;
	
