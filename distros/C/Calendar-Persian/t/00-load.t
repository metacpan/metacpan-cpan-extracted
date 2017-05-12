#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Calendar::Persian' ) || print "Bail out!"; }
diag( "Testing Calendar::Persian $Calendar::Persian::VERSION, Perl $], $^X" );
