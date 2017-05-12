#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Crypt::AES::CTR' ) || print "Bail out!\n";
}

diag( "Testing Crypt::AES::CTR $Crypt::AES::CTR::VERSION, Perl $], $^X" );
