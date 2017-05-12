#!perl -T
# $Id: 10-session.t,v 1.2 2007/09/08 07:31:09 pauldoom Exp $

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::AppSamurai::Session' );
}

diag( "Testing Apache::AppSamurai::Session $Apache::AppSamurai::Session::VERSION, Perl $], $^X" );

