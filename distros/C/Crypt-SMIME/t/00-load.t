#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::SMIME' );
}

diag( "Testing Crypt::SMIME $Crypt::SMIME::VERSION, Perl $], $^X" );
