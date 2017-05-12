#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::URL' );
}

diag( "Testing Acme::URL $Acme::URL::VERSION, Perl $], $^X" );
