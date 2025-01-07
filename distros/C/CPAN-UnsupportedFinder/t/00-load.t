#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('CPAN::UnsupportedFinder') || print 'Bail out!';
}

require_ok('CPAN::UnsupportedFinder') || print 'Bail out!';

diag("Testing CPAN::UnsupportedFinder $CPAN::UnsupportedFinder::VERSION, Perl $], $^X");
