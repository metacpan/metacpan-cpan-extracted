#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Calendar::Hebrew' ) || print "Bail out!"; }
diag( "Testing Calendar::Hebrew $Calendar::Hebrew::VERSION, Perl $], $^X" );
