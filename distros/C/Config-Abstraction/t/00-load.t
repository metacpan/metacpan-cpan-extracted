#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Config::Abstraction') || print 'Bail out!';
}

require_ok('Config::Abstraction') || print 'Bail out!';

diag("Testing Config::Abstraction $Config::Abstraction::VERSION, Perl $], $^X");
