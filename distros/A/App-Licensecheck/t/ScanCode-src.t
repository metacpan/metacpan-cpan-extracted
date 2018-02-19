#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 1192;

are_licensed_like_scancode(
	[qw(src/licensedcode/data/licenses)],
	't/ScanCode-src.todo'
);

done_testing;
