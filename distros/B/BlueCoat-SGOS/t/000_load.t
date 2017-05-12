#!perl -T
#
#
#
use strict;
use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok('BlueCoat::SGOS') || print "Bail out!\n";
}

diag("Testing BlueCoat::SGOS $BlueCoat::SGOS::VERSION, Perl $], $^X");
