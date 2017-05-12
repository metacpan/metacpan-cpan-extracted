#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 6;

use Test::Exception;

use Carp::Assert::More;

throws_ok( sub { assert_unlike( 'unlikely', qr/like/, 'Wango' ); }, qr/\QAssertion (Wango) failed!/, 'Testing simple matching' );
throws_ok( sub { assert_unlike( 'tempest', qr/te.*st/, 'Tango' ); }, qr/\QAssertion (Tango) failed!/, 'Testing simple matching' );
lives_ok(  sub { assert_unlike( 'passing', qr/fa.*il/, 'Flargle' ); }, 'Simple non-matching' );
lives_ok(  sub { assert_unlike( undef, qr/anything/ ); }, 'undef string is always unlike' );
throws_ok( sub { assert_unlike( 'Blah blah', undef, 'Bingo' ); }, qr/\QAssertion (Bingo) failed!/, 'undef regex always fails' );
throws_ok( sub {
    my $string = 'Blah blah';
    my $ref    = \$string;
    assert_unlike( $string, $ref, 'Dingo' );
}, qr/\QAssertion (Dingo) failed/, 'bad reference fails' );
