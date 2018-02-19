#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 8;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/non-english/licenses)],
	't/ScanCode-src-foreign.todo'
);

done_testing;
