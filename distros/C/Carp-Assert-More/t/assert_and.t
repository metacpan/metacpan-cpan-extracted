#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 5;

use Test::Exception;

use Carp::Assert::More;

my $af = qr/Assertion failed/;


AND: {
    lives_ok( sub { assert_and( 1, 'q' ) } );

    throws_ok( sub { assert_and( 1, 0 ) }, $af );
    throws_ok( sub { assert_and( 0, 1 ) }, $af );
    throws_ok( sub { assert_and( 'q', undef ) }, $af );
    throws_ok( sub { assert_and( '', 'whatever' ) }, $af );
}


exit 0;
