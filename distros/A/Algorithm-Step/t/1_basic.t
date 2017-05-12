#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use Test::More tests => 2;

BEGIN {
	use_ok 'Algorithm::Step';
}

ok('Algorithm::Step'->can('algorithm'), 'Algorithm::Step can begin algorithm');


