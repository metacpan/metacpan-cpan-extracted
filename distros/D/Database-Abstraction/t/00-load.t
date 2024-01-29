#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Database::Abstraction') || print 'Bail out!';
}

require_ok('Database::Abstraction') || print 'Bail out!';

diag("Testing Database::Abstraction $Database::Abstraction::VERSION, Perl $], $^X");
