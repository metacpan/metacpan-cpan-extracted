#!perl -T
# $Id: 50-authbase.t,v 1.2 2007/09/08 07:31:09 pauldoom Exp $

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::AppSamurai::AuthBase' );
}

diag( "Testing Apache::AppSamurai::AuthBase $Apache::AppSamurai::AuthBase::VERSION, Perl $], $^X" );

