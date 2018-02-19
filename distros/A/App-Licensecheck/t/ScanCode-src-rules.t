#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 4827;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/rules)],
	't/ScanCode-src-rules.todo'
);

done_testing;
