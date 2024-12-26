#!perl

use warnings;
use strict;

use Test::More tests => 7;

use Test::Exception;

use Carp::Assert::More;

my $af = qr/Assertion failed/;

MAIN: {
    lives_ok( sub { assert_integer_between( 5, 1, 10 ) } );
    lives_ok( sub { assert_integer_between( -5, -10, -1 ) } );
    lives_ok( sub { assert_integer_between( 57, 1, 100 ) } );

    throws_ok( sub { assert_integer_between( 3.14, 1, 10 ) }, $af );
    throws_ok( sub { assert_integer_between( -5, 1, 10 ) }, $af );
    throws_ok( sub { assert_integer_between( 'x', 1, 10 ) }, $af );
    throws_ok( sub { assert_integer_between( undef, 1, 10 ) }, $af );
}


exit 0;
