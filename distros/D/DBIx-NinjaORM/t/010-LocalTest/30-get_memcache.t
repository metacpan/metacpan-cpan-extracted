#!perl -T

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


can_ok(
	'LocalTest',
	'get_memcache',
);

lives_ok(
	sub
	{
		LocalTest::get_memcache();
	},
	'Retrieve the memcache object.',
);

