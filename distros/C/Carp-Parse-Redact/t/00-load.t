#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Carp::Parse::Redact' ) || print "Bail out!\n";
}


diag( "Carp::Parse::Redact $Carp::Parse::Redact::VERSION, Perl $], $^X" );
