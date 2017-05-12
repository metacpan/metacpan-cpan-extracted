#!/usr/bin/perl -w
# $Id: 13init.t 1511 2010-08-21 23:24:49Z ian $

# init.t
#
# Ensure object initialisers are handled correctly.

use strict;
use Test::More  tests => 103;
use Test::Exception;

# We need to test whether
#   a) init functions are called
#   b) ensure that attribute values passed in from the constructor, or
#        default, are honoured in the init functions
#   c) init methods are invoked in inheritance order, from base class to
#        current class
#   d) ensure that a failed init method (returning undef) causes the
#       constructor to die
#   e) ensure the call to declare() fails if the value passed to the init
#       attribute of the constructor is not a code ref

# ok declare a class with a single (public) attribute and an init() method
package Test::Init::One;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { attribute => 1 } ,
                      init   => sub {
                        my  $self = __PACKAGE__->public( shift );
                          $self->attribute  *= 2;

                        return 1;
                      } # init()
                    );

1;

# return to main to run the tests
package main;

# test to see if we can create an instance of Test::Init::One
my  $object;
lives_ok { $object = Test::Init::One->new }
         'constructor with init() executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::One' ,
    'constructor with init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 2 , 'init() generated correct initial value' );

# create another object with an attribute value passed in to the constructor
lives_ok { $object = Test::Init::One->new( attribute => 2 ) }
         'constructor with init() and attribute value executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::One' ,
    'constructor with init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 4 , 'init() generated correct initial value' );

# ensure an undef returned by init() causes the call to new() to fail
package Test::Init::Two;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { attribute => 1 } ,
                      init   => sub { undef }      );
            
1;

# return to main for testing
package main;

# can we create an instance of a class whose init() returns false?
 dies_ok { $object = Test::Init::Two->new }
         'constructor with false init() dies';

# can we declare a package whose init() is defined but not a CODEREF?
 dies_ok {
  package Test::Init::Three;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => 1 );
  1;
} 'numerical init value fails';
 dies_ok {
  package Test::Init::Four;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => "cat" );
  1;
} 'string init value fails';
 dies_ok {
  package Test::Init::Five;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => \1 );
  1;
} 'scalar reference init value fails';
 dies_ok {
  package Test::Init::Six;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => [ 1 ] );
  1;
} 'array reference init value fails';
 dies_ok {
  package Test::Init::Seven;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => { a => 1 } );
  1;
} 'hash reference init value fails';
lives_ok {
  package Test::Init::Eight;
  use strict;
  use base qw( Class::Declare );
  __PACKAGE__->declare( init => undef );
  1;
} 'undefined init value succeeds';


# now we need to test multiple inheritence and hence multiple init() methods
#  - firstly, if we simply inherit from a class with an init, but with the
#    derived class not having an init mehotd, will the base init() be
#    called?

# define a package without an init() method that inherits from a class with
# an init method
package Test::Init::Nine;

use strict;
use base qw( Test::Init::One );

1;

# return to main to resume the tests
package main;

# test to see if we can create an instance of Test::Init::Nine
lives_ok { $object = Test::Init::Nine->new }
         'constructor with inherited init() executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with inherited init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::Nine' ,
    'constructor with inherited init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 2 ,
    'inherited init() generated correct initial value' );

# create another object with an attribute value passed in to the constructor
lives_ok { $object = Test::Init::Nine->new( attribute => 2 ) }
         'constructor with inherited init() and attribute value executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with inherited init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::Nine' ,
    'constructor with inherited init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 4 ,
    'inherited init() generated correct initial value' );


# define a package with an init() that inherits from a class without an init
# method, and ensure the init() is called
package Test::Init::Ten;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { attribute => 1 } );

1;


package Test::Init::Eleven;

use strict;
use base qw( Test::Init::Ten );

__PACKAGE__->declare( init   => sub {
                        my  $self = __PACKAGE__->public( shift );
                          $self->attribute  += 3;

                        return 1;
                      } # init()
                    );
1;

# return to main to resume the tests
package main;

# test to see if we can create an instance of Test::Init::Nine
lives_ok { $object = Test::Init::Eleven->new }
         'constructor with inherited init() executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with inherited init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::Eleven' ,
    'constructor with inherited init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 4 ,
    'inherited init() generated correct initial value' );

# create another object with an attribute value passed in to the constructor
lives_ok { $object = Test::Init::Eleven->new( attribute => 2 ) }
         'constructor with inherited init() and attribute value executes';
# ensure the value returned is a valid object
ok( $object , 'constructor with inherited init() returns non-null' );
ok( ref( $object ) eq 'Test::Init::Eleven' ,
    'constructor with inherited init() returns object of correct class' );
# ensure value of the attribute is 2, not one, as we'd expect from the
# constructor
ok( $object->attribute == 5 ,
    'inherited init() generated correct initial value' );


#  - now we need to test the order of init() invocation
#      we do this by creating an inheritance chain with multiple init()
#      methods where the order of execution of the init() methods will
#      affect the returned attribute value
#
#      init() methods should be invoked in reverse @ISA order to ensure the
#      primary base-classes (those closest to the left-hand end of the @ISA
#      array) are the last init() methods to be executed. If a class appears
#      multiple times (either directly or through inheritence) in a class's
#      @ISA array, then it's init() routine will only be invoked once, and
#      as early in the init() execution path as possible.
#
#      This makes sense when you consider that destructors are invoked in
#      forward @ISA order.

# first, we can use Test::Init::One, as it's init() performs multiplication
# now, create a base class who's init() performs addition
# NB: they needn't provide the same attribute, but it won't hurt to
package Test::Init::Twelve;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { attribute => 1 } ,
                      init   => sub {
                        my  $self = __PACKAGE__->public( shift );
                          $self->attribute  += 3;

                        return 1;
                      } # init()
                    );
1;


# now, create a two classes that inherit from Test::Init::One and
# Test::Init::Twelve but in different orders
package Test::Init::Thirteen;

use strict;
use base qw( Test::Init::One Test::Init::Twelve );

1;


package Test::Init::Fourteen;

use strict;
use base qw( Test::Init::Twelve Test::Init::One );

1;

# return to main to resume the tests
package main;

# ensure object creation works with multiple init() methods
lives_ok { $object = Test::Init::Thirteen->new }
         'constructor with multiple init() routines executes';
# firstly, examine the attribute values when the default attribute value is
# used - for Test::Init::Thirteen, the value should be ( 1 + 3 ) * 2 = 8,
# which corresponds to Test::Init::Twelve before Test::Init::One
ok( $object->attribute == 8 ,
  'inheritence order observed by init() routines' );
# while for Test::Init::Fourteen, the value should be 1 * 2 + 3 = 5, which
# corresponds to Test::Init::One before Test::Init::Twelve
lives_ok { $object = Test::Init::Fourteen->new }
         'constructor with multiple init() routines executes';
ok( $object->attribute == 5 ,
  'inheritence order observed by init() routines' );

# ensure object creation works with multiple init() methods and a passed in
# attribute value
lives_ok { $object = Test::Init::Thirteen->new( attribute => 7 ) }
         'constructor with multiple init() routines executes';
# firstly, examine the attribute values when the default attribute value is
# used - for Test::Init::Thirteen, the value should be ( 7 + 3 ) * 2 = 20,
# which corresponds to Test::Init::Twelve before Test::Init::One
ok( $object->attribute == 20 ,
  'inheritence order observed by init() routines' );
# while for Test::Init::Fourteen, the value should be 7 * 2 + 3 = 17, which
# corresponds to Test::Init::One before Test::Init::Twelve
lives_ok { $object = Test::Init::Fourteen->new( attribute => 7 ) }
         'constructor with multiple init() routines executes';
ok( $object->attribute == 17 ,
  'inheritence order observed by init() routines' );

# ensure each init() method is only invoked once
package Test::Init::Fifteen;

use strict;
use base qw( Test::Init::One Test::Init::One );

1;

# return to main to resume the testing
package main;

# ensure object creation works with duplicate init() methods
lives_ok { $object = Test::Init::Fifteen->new }
         'constructor with duplicate init() routines executes';
# ensure the init method is only invoked once
ok( $object->attribute == 2 ,
   'duplicate init() method only invoked once' );
# ensure object creation works with duplicate init() methods and a passed in
# attribute value
lives_ok { $object = Test::Init::Fifteen->new( attribute => 2 ) }
         'constructor with duplicate init() routines executes';
# ensure the init method is only invoked once
ok( $object->attribute == 4 ,
   'duplicate init() method only invoked once' );


# we need to make sure that init() methods can access public, private,
# protected, etc attributes and methods
#   - let's automate this to save on typing
foreach my $type ( qw( class static restricted public private protected ) ) {
  local $@;

  # we need to test both attributes and methods
  foreach my $target ( qw( attribute method ) ) {
    # define the package for this type of attribute/method
    my  $pkg  = 'Test::Init::' . join( '::' , map { ucfirst }
                                                  ( $type , $target ) );
    my  $dfn  = <<__EODfN__;
package $pkg;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( $type => { attribute => 1 } ,
                      init  => sub {
                        my  \$self  = __PACKAGE__->public( shift );
                \$self->$target;
                      }
          );

sub method
{
  my  \$self  = __PACKAGE__->$type( shift );
  # NB: if we're dealing with a public, private or protected attribute
  #     then we should skip the value change as they are essentially
  #     constant
    \$self->attribute *= 2    unless (    '$type' eq 'class'
                                       || '$type' eq 'static'
                                       || '$type' eq 'restricted' );
  1;
} # method()

# we need a routine that can access all types of attributes, but just
# public and class, but static, private, etc
sub cmp
{
  my  \$self  = __PACKAGE__->public( shift );
  return ( \$self->attribute == shift );
} # cmp()

1;
__EODfN__

    # make sure the class compiles
    eval $dfn;
    warn $@ if ( $@ );
    ok ( ! $@ , "$pkg package compiled successfully" );

    # now, make sure we can create an instance of this class
    my  $object;
    lives_ok { $object = $pkg->new } "$pkg object creation executes";

    # make sure the returned object is defined and is of the right type
    ok( defined $object , "$pkg object is defined" );
    ok( ref( $object ) eq $pkg , "$pkg creation returns correct object" );

    # if we've called the method, and we're dealing with an
    # instance-type attribute (i.e. public, private or protected), then
    # the attribute should equal 2, otherwise it should equal 1
    ok( $object->cmp( ( $target eq 'method' )
                        ? (    $type eq 'public'
                            || $type eq 'private'
                            || $type eq 'protected' ) ? 2 : 1
                        : 1 ) ,
        "$pkg initialisation performed successfully"      );
  }
}

