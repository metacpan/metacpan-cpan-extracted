#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Very::Modern::Perl' );
}

diag( "Testing Acme::Very::Modern::Perl $Acme::Very::Modern::Perl::VERSION, Perl $], $^X" );
