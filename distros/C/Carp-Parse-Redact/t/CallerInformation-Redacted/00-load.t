#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Carp::Parse::CallerInformation::Redacted' ) || print "Bail out!\n";
}

diag( "Carp::Parse::CallerInformation::Redacted $Carp::Parse::CallerInformation::Redacted::VERSION, Perl $], $^X" );
