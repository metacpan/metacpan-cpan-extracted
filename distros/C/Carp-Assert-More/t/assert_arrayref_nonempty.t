#!perl

package Foo;

sub new { my $class = shift; return bless [@_], $class; }

package main;

use warnings;
use strict;

use Test::More tests => 11;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

# {} is not an arrayref.
throws_ok( sub { assert_arrayref_nonempty( {} ) }, $FAILED );

# A ref to a hash with stuff in it is not an arrayref.
my $ref = { foo => 'foo', bar => 'bar' };
throws_ok( sub { assert_arrayref_nonempty( $ref ) }, $FAILED );

# 3 is not an arrayref.
throws_ok( sub { assert_arrayref_nonempty( 3 ) }, $FAILED );

# [] is a nonempty arrayref.
lives_ok( sub { assert_arrayref_nonempty( [ 3 ] ) } );
lives_ok( sub { assert_arrayref_nonempty( [ undef ] ) } );

# [] is an empty arrayref.
throws_ok( sub { assert_arrayref_nonempty( [] ) }, $FAILED );

# A ref to a list with stuff in it is an arrayref.
my @ary = ('foo', 'bar', 'baaz');
lives_ok( sub { assert_arrayref_nonempty( \@ary ) } );

my @empty_ary = ();
throws_ok( sub { assert_arrayref_nonempty( \@empty_ary ) }, $FAILED );

# A coderef is not an arrayref.
my $coderef = sub {};
throws_ok( sub { assert_arrayref_nonempty( $coderef ) }, $FAILED );

# Foo->new->isa("ARRAY") returns true, but check emptiness.
lives_ok( sub { assert_arrayref_nonempty( Foo->new( 14 ) ) } );
throws_ok( sub { assert_arrayref_nonempty( Foo->new ) }, $FAILED );

exit 0;
