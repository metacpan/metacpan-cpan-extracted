#!perl

use warnings;
use strict;

use Test::More tests => 4;

use Test::Exception;

use Carp::Assert::More;

my $af = qr/Assertion failed/;


XOR: {
    lives_ok( sub { assert_xor( 0, 'q' ) } );
    lives_ok( sub { assert_xor( 'q', 0 ) } );

    throws_ok( sub { assert_xor( 0, 0 ) }, $af );
    throws_ok( sub { assert_xor( 1, 1 ) }, $af );
}


exit 0;
