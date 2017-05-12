#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Business::CyberSource::Report::PaymentEvents' ) || print "Bail out!\n";
}

diag( "Testing Business::CyberSource::Report $Business::CyberSource::Report::PaymentEvents::VERSION, Perl $], $^X" );
