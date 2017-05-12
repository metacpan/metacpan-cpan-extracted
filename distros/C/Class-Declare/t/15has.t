#!/usr/bin/perl -w
# $Id: 15has.t 1511 2010-08-21 23:24:49Z ian $

# has.t
#
# Ensure the has() method works correctly.

use strict;
use Test::More  tests => 6;

# define two packages: one with a method defined, and one that
# inheirts from the first
package Test::Has::One;
use base qw( Class::Declare );
sub method  { 1 };
1;

package Test::Has::Two;
use base qw( Test::Has::One );
1;

# commence the tests
package main;

#
# test the support for classes
#

#  - this should return a code reference to method()
ok(   defined Test::Has::One->has( 'method' ) ,
    'class method detected' );

#  - make sure this code reference returns what we expect
my  $ref  = Test::Has::One->has( 'method' );
ok( $ref->() == 1 ,
    'correct class method reference returned' );

#  - make sure has() fails on inherited classes
ok( ! defined Test::Has::Two->has( 'method' ) ,
    'class method not inherited' );

#
# test support for objects
#

my  $obj  = Test::Has::One->new;

#  - this should return a code refernece to method()
ok( defined $obj->has( 'method' ) ,
    'object method detected' );

#  - make sure the code reference returns what we expect
  $ref  = $obj->has( 'method' );
ok( $ref->() == 1 ,
    'correct object method reference returned' );

#  - make sure has() fails on inherited objects
  $obj  = Test::Has::Two->new;
ok( ! defined $obj->has( 'method' ) ,
    'inherited object method not inherited' );
