#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Crypt::DRBG' ) || print "Bail out!\n";
    use_ok( 'Crypt::DRBG::HMAC' ) || print "Bail out!\n";
}

diag( "Testing Crypt::DRBG $Crypt::DRBG::VERSION, Perl $], $^X" );
