#!/usr/bin/perl -w
# $Id: 26readonly.t 1511 2010-08-21 23:24:49Z ian $

# readonly.t
#
# Ensure read-only attributes behave appropriately.

use strict;
use Test::More  tests => 39;
use Test::Exception;

# declare a package with read-only instance attributes
package Test::Read::Only;

use strict;
use Class::Declare qw( :read-only );
use vars           qw( @ISA       );
                       @ISA = qw( Class::Declare );

# declare a random attribute value
use constant  RANDOM  => rand;

__PACKAGE__->declare( class      => { my_class      => ro RANDOM } ,
                      static     => { my_static     => ro RANDOM } ,
                      restricted => { my_restricted => ro RANDOM } ,
                      public     => { my_public     => ro RANDOM } ,
                      private    => { my_private    => ro RANDOM } ,
                      protected  => { my_protected  => ro RANDOM } );

# create a class method so that we can access all attributes of this class
sub cmp
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  $value    = shift;

  return ( $self->$attribute() == $value );
} # cmp()

# define a method for setting the attribute value by lvalue assignment
sub lvalue
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  $value    = shift;

  eval "\$self->$attribute = \$value";
  die $@    if ( $@ );    # die if we have an error

  1;  # the assignment didn't die
} # lvalue()

# define a method for setting the attribute value by argument
sub argument
{
  my  $self   = __PACKAGE__->class( shift );
  my  $attribute  = shift;
  my  $value    = shift;

  $self->$attribute( $value );
} # argument()

1;

# return to main to resume testing
package main;

# create an instance of this object
my  $class  = 'Test::Read::Only';
my  $object;
lives_ok { $object = $class->new } "new() with read-only attributes executes";

# make sure the attributes all have the correct value
foreach ( qw( class static restricted public private protected ) ) {
  my  $attr = 'my_' . $_;

  # the attribute should have the correct value
  ok( $object->cmp( $attr => $class->RANDOM ) ,
      "read-only $_ attribute set correctly"  );

  # lvalue assignment should fail
  dies_ok { $object->lvalue( $attr => $_ ) }
          "read-only attributes may not be assigned to";

  # argument assignment should not die, but the value should not be
  # assigned, either
  lives_ok { $object->argument( $attr => length $_ ) }
           "read-only attributes argument assignment lives";
  ok( ! $object->cmp( $attr => length $_ ) ,
      "read-only attribute argument assignment failed" );
}


# make sure that read-only public attributes may be set during object
# creation (the above tests show that they cannot be modified after
# creation)
my  $random = rand;
lives_ok { $object = $class->new( my_public => $random ) }
         "read-only public attributes may be set in call to new()";
# make sure the value from the constructor took
ok( $object->my_public == $random ,
    "read-only public attributes set correctly in call to new()" );


# make sure the class attributes may still be accessed through the class and
# that they behave as before
foreach ( qw( class static restricted ) ) {
  my  $attr = 'my_' . $_;

  # the attribute should have the correct value
  ok( $class->cmp( $attr => $class->RANDOM ) ,
      "read-only $_ attribute set correctly (via class)" );

  # lvalue assignment should fail
  dies_ok { $class->lvalue( $attr => length $_ ) }
          "read-only attributes may not be assigned to (via class)";

  # argument assignment should not die, but the value should not be
  # assigned, either
  lives_ok { $class->argument( $attr => length $_ ) }
           "read-only attributes argument assignment lives (via class)";
  ok( ! $class->cmp( $attr => length $_ ) ,
      "read-only attribute argument assignment failed (via class)" );
}
