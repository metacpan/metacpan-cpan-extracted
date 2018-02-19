#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 7;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/composites/rules)],
	't/ScanCode-src-composites-rules.todo'
);

done_testing;
