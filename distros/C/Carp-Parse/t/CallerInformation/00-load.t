#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Carp::Parse::CallerInformation' ) || print "Bail out!\n";
}

diag( "Carp::Parse::CallerInformation $Carp::Parse::CallerInformation::VERSION, Perl $], $^X" );
