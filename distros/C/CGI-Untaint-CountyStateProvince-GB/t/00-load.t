#!perl -T

use strict;
use Test::More tests => 3;

BEGIN {
	use_ok('CGI::Untaint');
	use_ok( 'CGI::Untaint::CountyStateProvince::GB' ) || print "Bail out!";
}

require_ok( 'CGI::Untaint::CountyStateProvince::GB' ) || print "Bail out!";

diag( "Testing CGI::Untaint::CountyStateProvince::GB $CGI::Untaint::CountyStateProvince::GB::VERSION, Perl $], $^X" );
