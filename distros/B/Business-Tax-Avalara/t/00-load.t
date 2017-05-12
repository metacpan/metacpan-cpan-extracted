#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Business::Tax::Avalara' ) || print "Bail out!\n";
}

diag( "Business::Tax::Avalara $Business::Tax::Avalara::VERSION, Perl $], $^X" );
