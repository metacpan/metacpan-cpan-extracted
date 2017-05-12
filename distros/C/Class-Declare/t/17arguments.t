#!/usr/bin/perl -w
# $Id: 17arguments.t 1511 2010-08-21 23:24:49Z ian $

# arguments.t
#
# Ensure the arguments() function works correctly.

use strict;
use Test::More  tests => 27;
use Test::Exception;

# load the Class::Declare module for the argument() method
use Class::Declare;

# create a method with named arguments
sub named
{
  my  %args = Class::Declare->arguments( \@_ => { a => 1 } );

  # return the argument passed in
  return $args{ a };
} # named()

# create a method that accepts any arguments
sub any
{
  my  %args = Class::Declare->arguments( \@_ );

  return 1;
} # any()


# ensure Class::Declare::arguments() can be called
lives_ok { Class::Declare->arguments } 'arguments() can be called';

# ensure arguments() returns undef when called with no parameters
ok( ! defined Class::Declare->arguments ,  'arguments() returns undef' );

# ensure arguments() dies if the first argument is not an array
# reference
 dies_ok { Class::Declare->arguments( 123   ) } 'scalar argument fails';
 dies_ok { Class::Declare->arguments( \12   ) } 'scalar reference fails';
 dies_ok { Class::Declare->arguments( {}    ) } 'hash reference fails';
 dies_ok { Class::Declare->arguments( sub{} ) } 'code reference fails';
lives_ok { Class::Declare->arguments( []    ) } 'array reference lives';

# ensure arguments() fails if the first argument is a list with an
# odd number of elements
 dies_ok { Class::Declare->arguments( [ 1 ] ) } 'odd length array fails';

# ensure arguments() fails if the second argument (if defined) is not
# a hash reference, an array reference or a scalar
lives_ok { Class::Declare->arguments( [] => 123   ) } 'scalar argument fails';
 dies_ok { Class::Declare->arguments( [] => \12   ) } 'scalar reference fails';
lives_ok { Class::Declare->arguments( [] => []    ) } 'array reference fails';
 dies_ok { Class::Declare->arguments( [] => sub{} ) } 'code reference fails';
lives_ok { Class::Declare->arguments( [] => {}    ) } 'hash reference lives';

# ensure arguments() returns the default values correctly
#   - as an array (hash)
my  %hash = Class::Declare->arguments( [] => { a => 1 } );
ok(   $hash{ a } == 1 , 'default values return as a list' );

#   - as a hash reference
my  $hash = Class::Declare->arguments( [] => { a => 1 } );
ok( $hash->{ a } == 1 , 'default values return as a hash reference' );

# ensure passed arguments are honoured
#    - defined arguments
  $hash = Class::Declare->arguments( [ a => 2 ] => { a => 1 } );
ok( $hash->{ a } == 2 , 'passed argument values honoured' );

#    - undefined arguments
  $hash = Class::Declare->arguments( [ a => undef ] => { a => 1 } );
ok( ! defined $hash->{ a } , 'passed undefined argument values honoured' );

# ensure unknown arguments raise an error
 dies_ok { Class::Declare->arguments( [ b => 2 ] => { a => 1 } ) }
         'unknown arguments raise an error with defaults';

# ensure unknown arguments are OK when we don't specify defaults
lives_ok { Class::Declare->arguments( [ b => 2 ] => undef ) }
         'unknown arguments are OK without defaults';

# ensure a scalar default argument is mapped to an argument name
  $hash = Class::Declare->arguments( [] => 'a' );
ok(   defined $hash        , "scalar default arguments accepted" );
ok(    exists $hash->{ a } , "scalar default mepped to argument" );
ok( ! defined $hash->{ a } , "scalar default mepped to argument" );

# ensure a list reference default argument is mapped to argument names
  $hash = Class::Declare->arguments( [] => [ qw( a b ) ] );
ok(   defined $hash        , "array reference default arguments accepted" );
ok(    exists $hash->{ a } , "array reference default mapped to arugment" );
ok(    exists $hash->{ b } , "array reference default mapped to arugment" );
ok( ! defined $hash->{ a } , "array reference default mapped to arugment" );
ok( ! defined $hash->{ b } , "array reference default mapped to arugment" );
