#!/usr/bin/perl -w
# $Id: 04instance.t 1511 2010-08-21 23:24:49Z ian $

# instance.t
#
# Ensure multiple instances have separate attribute namespaces.

use strict;
use Test::More  tests => 7;

# Declare the Class::Declare-derived package
package Test::Instance;

use base qw( Class::Declare );

# declare class and instance attributes
# NB: use references as values so that we can determine if the same
#     value is being used across instances, or if it has been cloned
__PACKAGE__->declare( public     => { mypublic     => \1 } ,
                      private    => { myprivate    => \2 } ,
                      protected  => { myprotected  => \3 } ,
                      class      => { myclass      => \4 } ,
                      static     => { mystatic     => \5 } ,
                      restricted => { myrestricted => \6 } );

# perform all comparisons within the defining class (don't have to
# worry then about public/private/etc access problems)
sub cmp_public
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->mypublic == $b->mypublic );
} # cmp_public()

sub cmp_private
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->myprivate == $b->myprivate );
} # cmp_private()

sub cmp_protected
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->myprotected == $b->myprotected );
} # cmp_protected()

sub cmp_class
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->myclass == $b->myclass );
} # cmp_class()

sub cmp_static
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->mystatic == $b->mystatic );
} # cmp_static()

sub cmp_restricted
{
  my  $self   = __PACKAGE__->class( shift );
  my  ( $a , $b ) = @_;
    ( $a->myrestricted == $b->myrestricted );
} # cmp_restricted()

1;


# begin the tests
package main;

# create two instances
my  $obj1 = Test::Instance->new;
my  $obj2 = Test::Instance->new;

# ensure the instances are different
ok( $obj1 != $obj2 , 'multiple distinct instance creation successful' );

# class attributes should be the same
ok(    Test::Instance->cmp_class     ( $obj1 , $obj2 ) ,
    'multiple instance class attribute equality'        );

# static attributes should be the same
ok(    Test::Instance->cmp_static    ( $obj1 , $obj2 ) ,
    'multiple instance static attribute equality'        );

# restricted attributes should be the same
ok(    Test::Instance->cmp_restricted( $obj1 , $obj2 ) ,
    'multiple instance restricted attribute equality'        );

# public attributes should be different
ok ( ! Test::Instance->cmp_public    ( $obj1 , $obj2 ) ,
     'multiple instance public attribute inequality'    );

# private attributes should be different
ok ( ! Test::Instance->cmp_private   ( $obj1 , $obj2 ) ,
     'multiple instance private attribute inequality'   );

# protected attributes should be different
ok ( ! Test::Instance->cmp_protected ( $obj1 , $obj2 ) ,
     'multiple instance protected attribute inequality' );
