#!perl

package Foo;

sub new { my $class = shift; return bless {@_}, $class; }

package main;

use warnings;
use strict;

use Test::More tests => 10;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

# {} is a hashref
lives_ok( sub { assert_hashref_nonempty( { foo => 'bar' } ) } );
throws_ok( sub { assert_hashref_nonempty( {} ) }, $FAILED );

# A ref to a hash with stuff in it is a hashref.
my %hash = ( foo => 'foo', bar => 'bar' );
lives_ok( sub { assert_hashref_nonempty( \%hash ) } );

my %hash_empty;
throws_ok( sub { assert_hashref_nonempty( \%hash_empty ) }, $FAILED );

# 3 is not a hashref.
throws_ok( sub { assert_hashref_nonempty( 3 ) }, $FAILED );

# A ref to 3 is not a hashref.
throws_ok( sub { assert_hashref_nonempty( \3 ) }, $FAILED );

# [] is not a hashref
throws_ok( sub { assert_hashref_nonempty( [] ) }, $FAILED );

# sub {} is not a hashref
my $coderef = sub {};
throws_ok( sub { assert_hashref_nonempty( $coderef ) }, $FAILED );

# Foo->new->isa("HASH") returns true, so do we
throws_ok( sub { assert_hashref_nonempty( Foo->new ) }, $FAILED );

lives_ok( sub { assert_hashref_nonempty( Foo->new( foo => 'bar' ) ) } );

exit 0;
