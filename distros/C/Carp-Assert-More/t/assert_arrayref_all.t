#!perl

use warnings;
use strict;

use Test::More tests => 10;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

my $api = \&assert_positive_integer;

MAIN: {
    # {} is not an arrayref.
    throws_ok( sub { assert_arrayref_all( {}, $api ) }, $FAILED );

    # A ref to a hash with stuff in it is not an arrayref.
    my $ref = { foo => 'foo', bar => 'bar' };
    throws_ok( sub { assert_arrayref_all( $ref, $api ) }, $FAILED );

    # 3 is not an arrayref.
    throws_ok( sub { assert_arrayref_all( 3, $api ) }, $FAILED );

    # [] is a nonempty arrayref.
    lives_ok( sub { assert_arrayref_all( [ 3 ], $api ) } );

    # [] is an empty arrayref.
    throws_ok( sub { assert_arrayref_all( [], $api ) }, $FAILED );

    my @empty_ary = ();
    throws_ok( sub { assert_arrayref_all( \@empty_ary, $api ) }, qr/Array contains no elements/ );

    # A coderef is not an arrayref.
    my $coderef = sub {};
    throws_ok( sub { assert_arrayref_all( $coderef, $api ) }, $FAILED );

    # An arrayref is not a coderef.
    throws_ok( sub { assert_arrayref_all( \@empty_ary, [] ) }, qr/assert_arrayref_all requires a code reference/ );
}


MASS_ASSERTIONS: {
    my @things = ( 1, 2, 4.3 );

    throws_ok(
        sub { assert_arrayref_all( \@things, $api ) },
        qr/assert_arrayref_all: Element #2/,
        'Automatic name comes back OK'
    );

    throws_ok(
        sub { assert_arrayref_all( \@things, $api, 'All gotta be posint' ) },
        qr/All gotta be posint: Element #2/,
        'Automatic name comes back OK'
    );

    @things = 1..400;
    assert_arrayref_all( \@things, $api, 'Must all be positive integer' );
}


exit 0;
