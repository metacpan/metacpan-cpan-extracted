#!perl -T
# $Id: 15-tracker.t,v 1.2 2007/09/08 07:31:09 pauldoom Exp $

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::AppSamurai::Tracker' );
}

diag( "Testing Apache::AppSamurai::Tracker $Apache::AppSamurai::Tracker::VERSION, Perl $], $^X" );
 
