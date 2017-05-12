#!/usr/bin/perl -w
# $Id: 12modifiers.t 1515 2010-08-22 14:41:53Z ian $

# modifiers.t
#
# Ensure the attribute modifiers behave as expected.

use strict;
use Test::More		tests	=> 10;
use Test::Exception;
use Class::Declare::Attributes	qw( :modifiers );

# define a random value for read-write/read-only tests
use constant		RANDOM	=> rand;

# ensure the modifiers return Class::Declare::Read objects
my	$object;

# make sure ro() behaves as expected
lives_ok { $object = ro RANDOM } "ro() executes";
# make sure ro() returns an object
ok( ref( $object ) ,
    "ro() returns object" );
# make sure ro() returns a Class::Declare::Read object
ok(      $object->isa( 'Class::Declare::Read' ) ,
    "ro() returns Class::Dclare::Read object" );
# make sure this object indicates the value is read-only
ok(    ! $object->write ,
    "ro() returns object with false write flag" );
# make sure the object value is correct
ok(      $object->value == RANDOM ,
    "ro() returns object with correct value" );

# make sure rw() behaves as expected
lives_ok { $object = rw RANDOM } "rw() executes";
# make sure ro() returns an object
ok( ref( $object ) ,
    "rw() returns object" );
# make sure ro() returns a Class::Declare::Read object
ok(      $object->isa( 'Class::Declare::Read' ) ,
    "rw() returns Class::Dclare::Read object" );
# make sure this object indicates the value is read-only
ok(      $object->write ,
    "rw() returns object with true write flag" );
# make sure the object value is correct
ok(      $object->value == RANDOM ,
    "rw() returns object with correct value" );
