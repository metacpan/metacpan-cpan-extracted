#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Calendar::Hijri' ) || print "Bail out!"; }
diag( "Testing Calendar::Hijri $Calendar::Hijri::VERSION, Perl $], $^X" );
