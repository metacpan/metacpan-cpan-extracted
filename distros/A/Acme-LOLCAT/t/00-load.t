#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::LOLCAT' );
}

diag( "Testing Acme::LOLCAT $Acme::LOLCAT::VERSION, Perl $], $^X" );
