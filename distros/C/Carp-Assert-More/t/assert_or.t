#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 5;

use Test::Exception;

use Carp::Assert::More;

my $af = qr/Assertion failed/;


OR: {
    lives_ok( sub { assert_or( 0, 'q' ) } );
    lives_ok( sub { assert_or( 'q', 0 ) } );
    lives_ok( sub { assert_or( 2112, 5150 ) } );

    throws_ok( sub { assert_or( 0, 0 ) }, $af );
    throws_ok( sub { assert_or( '', undef ) }, $af );
}


exit 0;
