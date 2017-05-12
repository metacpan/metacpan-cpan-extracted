#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 7;

use Test::Exception;

use Carp::Assert::More;

lives_ok( sub { assert_like('unlikely', qr/like/ ); } );
lives_ok( sub { assert_like( 'tempest', qr/te.*st/ ); } );
lives_ok( sub { assert_like( 'quality inn', qr/qu.*inn/ ); } );
throws_ok( sub { assert_like( 'passing', qr/fa.*il/, 'Flargle' ); }, qr/\QAssertion (Flargle) failed!/ );
throws_ok( sub { assert_like( undef, qr/anything/, 'Bongo' ); }, qr/\QAssertion (Bongo) failed!/, 'undef string always fails' );
throws_ok( sub { assert_like( 'Blah blah', undef, 'Bingo' ); }, qr/\QAssertion (Bingo) failed!/, 'undef regex always fails' );
throws_ok( sub {
    my $string = 'Blah blah';
    my $ref    = \$string;
    assert_like( $string, $ref, 'Dingo' );
}, qr/\QAssertion (Dingo) failed/, 'bad reference fails' );
