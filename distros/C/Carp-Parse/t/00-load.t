#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Carp::Parse' ) || print "Bail out!\n";
}

diag( "Carp::Parse $Carp::Parse::VERSION, Perl $], $^X" );
