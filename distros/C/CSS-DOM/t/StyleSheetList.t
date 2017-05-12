#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::StyleSheetList';

use tests 1; # constructor
isa_ok my $list = CSS::DOM::StyleSheetList->new(1,2,3), 
	'CSS::DOM::StyleSheetList';

use tests 1; # length
is $list->length, @$list, 'length';

use tests 3; # item
is $list->item($_), $list->[$_], 'item ' . 'again' x $_ for 0..2;
	
