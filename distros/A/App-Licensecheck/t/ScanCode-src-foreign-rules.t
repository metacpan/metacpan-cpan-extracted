#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 1;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/non-english/rules)],
	't/ScanCode-src-foreign-rules.todo'
);

done_testing;
