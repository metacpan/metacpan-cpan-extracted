#!perl -Tw

package Foo;

sub new { my $class = shift; return bless [@_], $class; }

package main;

use warnings;
use strict;

use Test::More tests => 10;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

MAIN: {
    # {} is not an arrayref.
    throws_ok( sub { assert_arrayref_of( {}, 'Foo' ) }, $FAILED );

    # A ref to a hash with stuff in it is not an arrayref.
    my $ref = { foo => 'foo', bar => 'bar' };
    throws_ok( sub { assert_arrayref_of( $ref, 'Foo' ) }, $FAILED );

    # 3 is not an arrayref.
    throws_ok( sub { assert_arrayref_of( 3, 'Foo' ) }, $FAILED );

    # [] is a nonempty arrayref.
    lives_ok( sub { assert_arrayref_of( [ Foo->new ], 'Foo' ) } );

    # [] is an empty arrayref.
    throws_ok( sub { assert_arrayref_of( [], 'Foo' ) }, $FAILED );

    my @empty_ary = ();
    throws_ok( sub { assert_arrayref_of( \@empty_ary, 'Foo' ) }, $FAILED );

    # A coderef is not an arrayref.
    my $coderef = sub {};
    throws_ok( sub { assert_arrayref_of( $coderef, 'Foo' ) }, $FAILED );

}

WHICH_ELEMENT: {
    lives_ok( sub { assert_arrayref_of( [ Foo->new, Foo->new ], 'Foo' ) } );

    # Check for both parts of the message.
    throws_ok( sub { assert_arrayref_of( [ Foo->new, Foo->new, {} ], 'Foo' ) }, $FAILED );
    throws_ok( sub { assert_arrayref_of( [ Foo->new, Foo->new, {} ], 'Foo' ) }, qr/Element #2/ );
}



exit 0;
