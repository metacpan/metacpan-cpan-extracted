#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Calendar::Gregorian' ) || print "Bail out!"; }
diag( "Testing Calendar::Gregorian $Calendar::Gregorian::VERSION, Perl $], $^X" );
