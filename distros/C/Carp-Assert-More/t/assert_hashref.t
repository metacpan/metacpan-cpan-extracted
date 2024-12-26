#!perl

package Foo;

sub new { my $class = shift; return bless {@_}, $class; }

package main;

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

# {} is a hashref
lives_ok( sub { assert_hashref( {} ) } );

# A ref to a hash with stuff in it is a hashref.
my %hash = ( foo => 'foo', bar => 'bar' );
lives_ok( sub { assert_hashref( \%hash ) } );

# 3 is not a hashref.
throws_ok( sub { assert_hashref( 3 ) }, $FAILED );

# A ref to 3 is not a hashref.
throws_ok( sub { assert_hashref( \3 ) }, $FAILED );

# [] is not a hashref
throws_ok( sub { assert_hashref( [] ) }, $FAILED );

# sub {} is not a hashref
my $coderef = sub {};
throws_ok( sub { assert_hashref( $coderef ) }, $FAILED );

# Foo->new->isa("HASH") returns true, so do we
lives_ok( sub { assert_hashref( Foo->new ) } );

exit 0;
