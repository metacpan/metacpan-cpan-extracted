#!/usr/bin/perl -w
# $Id: 22clone.t 1511 2010-08-21 23:24:49Z ian $

# clone.t
#
# Ensure Class::Declare::new() clones objects correctly when called as an
# instance method.

use strict;
use Test::More  tests => 42;
use Test::Exception;

# define a Class::Declare package
package Test::Clone::One;

use strict;
use base qw( Class::Declare );

# declare all types of attributes
__PACKAGE__->declare( class      => { my_class      => \1 } ,
                      static     => { my_static     => \2 } ,
            restricted => { my_restricted => \3 } ,
            public     => { my_public     => \4 } ,
            private    => { my_private    => \5 } ,
            protected  => { my_protected  => \6 } );

# define methods for comparing class and instance attributes
sub cmp_class
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  ( $a , $b ) = @_;

  # class attributes should have the rame reference and the same value
  return (       $a->$attribute   ==    $b->$attribute
           && ${ $a->$attribute } == ${ $b->$attribute } );
} # cmp_class()

sub cmp_instance
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  ( $a , $b ) = @_;

  # instance attributes should be cloned (i.e. references should be
  # different, but the values should be the same
  return (       $a->$attribute   !=    $b->$attribute
           && ${ $a->$attribute } == ${ $b->$attribute } );
} # cmp_instance()

1;

# return to main to resume testing
package main;

# create an instance of the test class and the clone it
my  $class  = 'Test::Clone::One';
my  $object = $class->new;
# make sure cloning works
my  $clone;
lives_ok { $clone = $object->new } "CODEREF new() execution succeeds";

# make sure they are different objects
ok( $clone != $object , "clone and object are not the same reference" );
ok( ref( $clone ) , "clone is a reference" );
ok( ref( $clone ) eq ref( $object ) ,
    "clone and object represent the same class" );

# OK, now compare the attribute values for these objects
#   - start with the class attributes
ok( $class->cmp_class( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( class static restricted ) );

#   - now the object attributes
ok( $class->cmp_instance( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( public private protected ) );

# NB: CODEREFs cannot be cloned, so let's make sure they are copied
# correctly

# define a new test package with CODEREFs as attribute values
package Test::Clone::Two;

use strict;
use base qw( Class::Declare );

# declare a random constant
use constant  RANDOM  => rand;

# declare all types of attributes
__PACKAGE__->declare( class      => { my_class      => sub { RANDOM + 1 } } ,
                      static     => { my_static     => sub { RANDOM + 2 } } ,
            restricted => { my_restricted => sub { RANDOM + 3 } } ,
            public     => { my_public     => sub { RANDOM + 4 } } ,
            private    => { my_private    => sub { RANDOM + 5 } } ,
            protected  => { my_protected  => sub { RANDOM + 6 } } );

# define methods for comparing class and instance attributes
sub cmp
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  ( $a , $b ) = @_;

  # for CODEREFs, class and instance attributes should have the same
  # reference and hence return the same value
  return (    $a->$attribute     == $b->$attribute
           && $a->$attribute->() == $b->$attribute->() );
} # cmp()

1;

# return to main to resume testing
package main;

# create an instance of the test class and the clone it
  $class  = 'Test::Clone::Two';
  $object = $class->new;
# make sure cloning works
lives_ok { $clone = $object->new }
         "new() execution succeeds with COEDREF attributes";

# make sure they are different objects
ok( $clone != $object , "clone and object are not the same reference" );
ok( ref( $clone ) , "clone is a reference" );
ok( ref( $clone ) eq ref( $object ) ,
    "clone and object represent the same class" );

# OK, now compare the attribute values for these objects
#   - start with the class attributes
ok( $class->cmp( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( class static restricted ) );

#   - now the object attributes
ok( $class->cmp( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( public private protected ) );

#
# need to ensure cloning will honour public attribute values passed to the
# constructor
#

# first, test with Test::Clone::One
  $class  = 'Test::Clone::One';
  $object = $class->new;
lives_ok { $clone = $object->new( my_public => \7 ) }
         "cloning accepts public attributes";

# make sure they are different objects
ok( $clone != $object , "clone and object are not the same reference" );
ok( ref( $clone ) , "clone is a reference" );
ok( ref( $clone ) eq ref( $object ) ,
    "clone and object represent the same class" );

# OK, now compare the attribute values for these objects
#   - start with the class attributes
ok( $class->cmp_class( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( class static restricted ) );

#   - now the object attributes (except the public attribute)
ok( $class->cmp_instance( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( private protected ) );

#   - make sure the public attributes are different
ok(   $object->my_public    !=    $clone->my_public ,
    "public attribute references not cloned when set in constructor" );
ok( ${ $object->my_public } != ${ $clone->my_public } ,
    "public attribute values not cloned when set in constructor" );


# make sure cloning honours multiple inheritance

package Test::Clone::Three;

use strict;
use base qw( Test::Clone::One );

__PACKAGE__->declare( public => { my_instance => \42 } );

1;

# return to main to resume testing
package main;

  $class  = 'Test::Clone::Three';
  $object = $class->new;
# make sure cloning works
lives_ok { $clone = $object->new } "cloning with inheritance succeeds";

# make sure they are different objects
ok( $clone != $object , "clone and object are not the same reference" );
ok( ref( $clone ) , "clone is a reference" );
ok( ref( $clone ) eq ref( $object ) ,
    "clone and object represent the same class" );

# OK, now compare the attribute values for these objects
#   - start with the class attributes
ok( $class->cmp_class( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( class static restricted ) );

#   - now the object attributes (except the public attribute)
ok( $class->cmp_instance( "my_" . $_ , $object , $clone ) ,
    "$_ attributes cloned correctly" )
    foreach ( qw( public private protected instance ) );
