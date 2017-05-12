#!perl -T

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


can_ok(
	'LocalTest',
	'get_database_handle',
);

isa_ok(
	LocalTest::get_database_handle(),
	'DBI::db',
	'Return value for get_database_handle()',
);
