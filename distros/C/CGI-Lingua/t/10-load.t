#!perl -T

use strict;
use Test::Most tests => 2;

BEGIN {
	use_ok( 'CGI::Lingua' ) || print "Bail out!
";
}

require_ok('CGI::Info') || print 'Bail out!';

diag( "Testing CGI::Lingua $CGI::Lingua::VERSION, Perl $], $^X" );
