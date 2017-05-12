#!perl -T

use Test::More tests => 1;

require_ok( 'Acme::Canadian' );

diag( "Testing Acme::Canadian $Acme::Canadian::VERSION, Perl $], $^X" );
