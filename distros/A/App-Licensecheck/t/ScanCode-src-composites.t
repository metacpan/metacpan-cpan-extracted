#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 18;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/composites/licenses)],
	't/ScanCode-src-composites.todo'
);

done_testing;
