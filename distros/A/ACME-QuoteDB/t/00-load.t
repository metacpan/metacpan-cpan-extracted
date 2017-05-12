#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'ACME::QuoteDB' );
}

diag( "Testing ACME::QuoteDB $ACME::QuoteDB::VERSION, Perl $], $^X" );
