#!/usr/bin/perl -w
# $Id: 14multiple.t 1511 2010-08-21 23:24:49Z ian $

# multiple.t
#
# Ensure multiple inheritance works as advertised.

use strict;
use Test::More  tests => 253;
use Test::Exception;

# so what are we testing in multiple inheritance?
#   a) are attributes and methods accessible when they are inherited?
#   b) can we redeclare attributes/methods in child classes?
#   c) can we alter the type of attributes/methods by redeclaring them?
# other aspects of multiple inheritance are either implemented by Perl
# itself (and therefore we can assume to work), or have been tested in other
# test scripts (such as execution of object initialisation routines)

# firstly, create three base classes to inherit from so that we can examine
# various permutations of multiple inheritance
#   - for these classes we're only interested in public attributes and
#       methods since we know that the other types of attributes and methods
#       will be handled correctly (as determined by the specific
#       attribute/method type tests)
#   - OK, this is putting a lot of faith in those tests, but that's what
#       they are there for

my  %__attr__;
my  %__inc__;
# create the classes
BEGIN {
  # create a mapping of attribute names and values
  %__attr__ = reverse ( one => 1 , two => 2 , three => 3 );

  # define the different packages and ensure they compile
  foreach ( sort keys %__attr__ ) {
    local $@;

    # extract the name of this class's attribute and method
    my  $attribute  = $__attr__{ $_ };
    my  $method   = chr( ord( 'a' ) - 1 + $_ );

    # create the name of the package
    my  $pkg    = 'Test::Multi::' . ucfirst( $attribute );

    # create the package definition
    my  $dfn    = <<__EODfN__;
package $pkg;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { $attribute => $_ } );

sub $method
{
  my  \$self  = __PACKAGE__->public( shift );
  $_;
} # $method()

1;  # end of module
__EODfN__

    # make sure we can compile this module
    eval $dfn;
    ok( ! $@ , "$pkg compiled successfully" );

    # if the compilation succeeds, then add this package to the list of
    # included/generated packages
    $__inc__{ $pkg }  = 1   unless ( $@ );
  }
}

# OK, now we need to create derived classes
# There are a number of inheritance scenarios we should look at, and these
# will be represented by the @isa array below, where each number represents
# the base class to inherit from - two digit numbers indicates a base class
# that has been derived from two other base clases
my  @isa  = ( [ 1            ] ,  # single inheritance
              [ 1   ,  2     ] ,  # double inheritance of two single classes
              [ 1   ,  2 , 3 ] ,  # triple inheritance of single classes
              [ 12           ] ,  # inheritance with a derived class
              [ 3   , 12     ] ,  # inheritance with a derived class
              [ 123          ] ); # inheritance with a derived class

# need a routine for generating alternate class names from a given class
# name (see the explanation half-way down the following foreach() loop
my  $__rename__ = sub { # <class name>
      my    $class       = shift;
      my  ( $base , $last )  = m/(.*)::(.[^:]+)$/o;
          $base       .= '::Derived';

      return join '::' , $base , map { m/([A-Z][a-z]+)/go } $last;
    }; # $__rename__()

# OK, time to create these derived classes
foreach my $isa ( @isa ) {
  local $@;

  # derive the class names
  my  @classes  = map { join '' , map { ucfirst $_ }
                                        map { $__attr__{ $_ } } split //
                      } @{ $isa };

  # create the overall package name (derived from the inherited packages)
  my  $pkg    = 'Test::Multi::Derived::' . join( '::' , @classes );
    @classes  = map { 'Test::Multi::' . $_ } @classes;

  # the above naming convention ensures that all classes have unique
  # names. hoever, it also means that the names in @classes may not
  # correspond to derived class names
  #   e.g. if One and Two are the base classes, then the class One::Two
  #   will be generated, while @classes will refer to it as OneTwo
  # therefore we need to catch these cases and insert the correct (or
  # equivalent) class names
    @classes  = map { ( exists $__inc__{ $_ } )
                               ? $_
                               : $__rename__->( $_ )
                    } @classes;

  # create the class definition
  my  $dfn    = <<__EODfN__;
package $pkg;

use strict;
use base qw( @classes );

1;
__EODfN__

  # make sure we can compile this module
  eval $dfn;
  ok( ! $@ , "$pkg compiled successfully" );

  # if the compilation succeeds, then add it the the list of included
  # pacakges
  $__inc__{ $pkg }  = 1   unless ( $@ );
}

# OK, we have created the classes, so now we need to create instances of
# these classes and ensure that we can
#    a) access the attributes and methods
#    c) set the attributes in the constructor

# define the object test routines
my  $test = sub {
    my  ( $type , $object , $target , $value )  = @_;

    # make sure we can access the attribute
    lives_ok { $object->$target }
             ref( $object ) . " access to $type granted";
    # make sure the attribute has the right value
          ok ( $object->$target == $_[ 3 ] ,
             ref( $object ) . " $type has correct value" );
  }; # $test()

# extract all the derived package names
foreach ( grep { m/Derived/o } sort keys %__inc__ ) {
  # create an instance of this object
  my  $object;
  lives_ok { $object = $_->new } "$_ object creation succeeds";

  # OK, attempt to access the attributes and methods
  #  - classes derived from Test::Multi::One
  /One/o    && do {
    $test->( attribute => $object => one   => 1 );
    $test->( method    => $object => a     => 1 );
  };
  #  - classes derived from Test::Multi::Two
  /Two/o    && do {
    $test->( attribute => $object => two   => 2 );
    $test->( method    => $object => b     => 2 );
  };
  #  - classes derived from Test::Multi::Three
  /Three/o  && do {
    $test->( attribute => $object => three => 3 );
    $test->( method    => $object => c     => 3 );
  };

  # now we should test to make sure that we can set the attributes in the
  # call to the constructor
  my  ( $one  , $two , $three ) = map { rand } ( 1 .. 3 );
  # create the argument list for this class
  my  %args;  undef %args;
    $args{ one   }        = $one    if ( /One/o   );
    $args{ two   }        = $two    if ( /Two/o   );
    $args{ three }        = $three  if ( /Three/o );

  # make sure we can create an instance with the constructor having
  # attribute values
  my  $new;
  lives_ok { $new = $_->new( %args ) }
           "$_ object creation with arguments succeeds";

  # OK, now we should test to make sure the attributes have the values
  # passed to the constructor, and that the first object created still has
  # the same attribute values
  #  - classes derived from Test::Multi::One
  /One/o    && do {
    $test->( attribute => $new    => one   => $one   );
    $test->( method    => $new    => a     => 1      );
    $test->( attribute => $object => one   => 1      );
  };
  #  - classes derived from Test::Multi::Two
  /Two/o    && do {
    $test->( attribute => $new    => two   => $two   );
    $test->( method    => $new    => b     => 2      );
    $test->( attribute => $object => two   => 2      );
  };
  #  - classes derived from Test::Multi::Three
  /Three/o  && do {
    $test->( attribute => $new    => three => $three );
    $test->( method    => $new    => c     => 3      );
    $test->( attribute => $object => three => 3      );
  };
}

# OK, now we want to check to see if we can redefine attributes in a derived
# class
foreach ( grep { m/Derived/o } sort keys %__inc__ ) {
  local $@;

  # create the name of the new class
  my  $pkg; ( $pkg = $_ ) =~ s#Derived#Redefine#o;
  
  # generate the class definition
  my  $dfn  = <<__EODfN__;
package $pkg;

use strict;
use base qw( $_ );

__PACKAGE__->declare( public => { one   => 4 ,
                                  two   => 5 ,
                                  three => 6 }
                    );
;
__EODfN__

  # make sure we can complie this module
  eval $dfn;
  ok( ! $@ , "$pkg compiled successfully" );

  # make sure we can create an instance of this object
  my  $object;
  lives_ok { $object = $pkg->new } "$pkg object creation succeeds";

  # make sure the attributes and methods have the right values
  #  - we have support for all attributes
  $test->( attribute => $object => one   => 4 );
  $test->( attribute => $object => two   => 5 );
  $test->( attribute => $object => three => 6 );

  #  - test the method access
  #  - classes derived from Test::Multi::One
  /One/o    && do { $test->( method => $object => a => 1 ); };
  #  - classes derived from Test::Multi::Two
  /Two/o    && do { $test->( method => $object => b => 2 ); };
  #  - classes derived from Test::Multi::Three
  /Three/o  && do { $test->( method => $object => c => 3 ); };
}

# OK, now we need to make sure that we can redeclare attributes with
# different access rights and have those rights correctly honoured

# First, create two classes, one with a public attribute and the other with
# a static attribute - make sure these classes provide unique accessor
# methods for these attributes
foreach ( qw( public static ) ) {
  local $@;

  # generate the package name
  my  $pkg  = 'Test::Multi::' . ucfirst;

  # generate the package definition
  my  $dfn  = <<__EODfN__;
package $pkg;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( $_ => { attribute => '$_' } );

# create the accessor for this package
sub get_$_
{
  my  \$self  = __PACKAGE__->public( shift );
    \$self->attribute;
} # get_$_()

# create the setter for this package
sub set_$_
{
  my  \$self  = __PACKAGE__->public( shift );
    \$self->attribute = shift;
} # set_$_()
__EODfN__

  # make sure this package compiles
  eval $dfn;
  ok( ! $@ , "$pkg compiled successfully" );
}

# now create two derived classes using these classes as a base class, but
# altering the order of inheritance
foreach my $first ( qw( Public Static ) ) {
  foreach my $second ( grep { $_ ne $first } qw( Public Static ) ) {
    local $@;

    # create the package name
    my  $pkg  = 'Test::Multi::' . join( '::' , $first , $second );

    # generate the package definition
    my  $dfn  = <<__EODfN__;
package $pkg;

use strict;
use base qw( Test::Multi::$first Test::Multi::$second );

1;
__EODfN__

    # make sure these classes compile
    eval $dfn;
    ok( ! $@ , "$pkg compiled successfully" );

    # create an instance of this class
    my  $object;
    lives_ok { $object = $pkg->new } "$pkg object creation succeeds";

    # OK, we need to know which is the first base class for the derived
    # class to determine which tests to run
    #  - the first class (dominant) is public
    if ( $first eq 'Public' ) {
      # therefore we expect to be able to access the attribute
      lives_ok { $object->attribute }
               "$pkg general attribute access succeeds";

      # we can get the attribute value
      lives_ok { $object->get_public } "$pkg public get succeeds";
      lives_ok { $object->get_static } "$pkg static get succeeds";

      # we can set the attribute
      lives_ok { $object->set_public( rand ) } "$pkg public set succeeds";
      lives_ok { $object->set_static( rand ) } "$pkg static set succeeds";

    #  - the first class (dominant) is static
    } else {
      # therefore we expect to be able to access the attribute
       dies_ok { $object->attribute }
               "$pkg general attribute access denied";

      # we can get the attribute value
       dies_ok { $object->get_public } "$pkg public get denied";
      # the get_static() routine is public, so it permits access to
      # the static attribute since it will access the static attribute
      # from within the defining class
      lives_ok { $object->get_static } "$pkg static get permitted";

      # we can set the attribute
       dies_ok { $object->set_public( rand ) } "$pkg public set denied";
       dies_ok { $object->set_static( rand ) } "$pkg static set denied";
    }
  }
}
