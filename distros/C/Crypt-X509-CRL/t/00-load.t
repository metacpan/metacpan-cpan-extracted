#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Crypt::X509::CRL' ) || print "Bail out!\n";
}

diag( "Testing Crypt::X509::CRL $Crypt::X509::CRL::VERSION, Perl $], $^X" );
