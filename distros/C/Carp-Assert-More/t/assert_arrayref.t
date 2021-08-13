#!perl -Tw

package Foo;

sub new { my $class = shift; return bless [@_], $class; }

package main;

use warnings;
use strict;

use Test::More tests => 7;

use Carp::Assert::More;

use Test::Exception;

my $FAILED = qr/Assertion failed/;

# {} is not an arrayref.
throws_ok( sub { assert_arrayref( {} ) }, $FAILED );

# A ref to a hash with stuff in it is not an arrayref.
my $ref = { foo => 'foo', bar => 'bar' };
throws_ok( sub { assert_arrayref( $ref ) }, $FAILED );

# 3 is not an arrayref.
throws_ok( sub { assert_arrayref( 3 ) }, $FAILED );

# [] is an arrayref.
lives_ok( sub { [] } );

# A ref to a list with stuff in it is an arrayref.
my @ary = ('foo', 'bar', 'baaz');
lives_ok( sub { assert_arrayref( \@ary ) } );

# A coderef is not an arrayref.
my $coderef = sub {};
throws_ok( sub { assert_arrayref( $coderef ) }, $FAILED );

# Foo->new->isa("ARRAY") returns true, so do we
lives_ok( sub { assert_arrayref( Foo->new ) } );

exit 0;
