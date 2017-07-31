#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Calendar::Julian' ) || print "Bail out!"; }
diag( "Testing Calendar::Julian $Calendar::Julian::VERSION, Perl $], $^X" );
