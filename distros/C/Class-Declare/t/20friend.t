#!/usr/bin/perl -w
# $Id: 20friend.t 1511 2010-08-21 23:24:49Z ian $

# friend.t
#
# Ensure friends are permitted to access private and protected
# attributes and methods.

use strict;
use Test::More  tests => 342;
use Test::Exception;

# create a class with attributes and methods or each of the types
# (e.g. public, private, protected, etc)
use constant  PKG   => <<__EOP__;
package Test::Friend::CLASS;

use strict;
use base qw( Class::Declare );

# define attributes of all the different types
__PACKAGE__->declare( public     => { a_public     => 1 } ,
                      private    => { a_private    => 2 } ,
            protected  => { a_protected  => 3 } ,
            class      => { a_class      => 4 } ,
            static     => { a_static     => 5 } ,
            restricted => { a_restricted => 6 } ,
            friends    => FRIENDS               ,
            strict     => STRICT                );

# define methods of all the different types
sub m_public {
  my  \$self  = __PACKAGE__->public( shift );
  return 'a';
} # m_public()

sub m_private {
  my  \$self  = __PACKAGE__->private( shift );
  return 'b';
} # m_private()

sub m_protected {
  my  \$self  = __PACKAGE__->protected( shift );
  return 'c';
} # m_protected()

sub m_class {
  my  \$self  = __PACKAGE__->class( shift );
  return 'd';
} # m_class()

sub m_static {
  my  \$self  = __PACKAGE__->static( shift );
  return 'e';
} # m_static()

sub m_restricted {
  my  \$self  = __PACKAGE__->restricted( shift );
  return 'f';
} # m_restricted()

# declare accessor methods for accessing methods and attributes
sub call { # object|class , method|attribute
  my  \$self  = __PACKAGE__->class( shift );
  my  \$object  = shift;
  my  \$target  = shift;
    \$object->\$target();
} # call()

1;
__EOP__

# declare Test::Friend::One
#
# make package Test::Friend::Three, an unrelated package, a friend
BEGIN {
  my  $one  =  PKG;
    $one  =~ s#CLASS#One#o;
    $one  =~ s#FRIENDS#'Test::Friend::Three'#o;
    $one  =~ s#STRICT#undef#o;
    eval $one   or die $@;
}


# declare Test::Friend::Four
#
# make two methods within the main package a friend
BEGIN {
  my  $three  =  PKG;
    $three  =~ s#CLASS#Four#o;
    $three  =~ s#FRIENDS#[ qw( main::attribute main::method ) ]#o;
    $three  =~ s#STRICT#undef#;
    eval $three   or die $@;
}


# declare Test::Friend::Seven
#
# make package Test::Friends::Three, an unrelated package, a friend, and
# turn strict access checking off
BEGIN {
  my  $seven  =  PKG;
    $seven  =~ s#CLASS#Seven#o;
    $seven  =~ s#FRIENDS#'Test::Friend::Three'#o;
    $seven  =~ s#STRICT#0#o;
    eval $seven   or die $@;
}


# declare Test::Friend::Eight
#
# make two methods within the main package a friend, and turn strict access
# checking explicitly off
BEGIN {
  my  $eight  =  PKG;
    $eight  =~ s#CLASS#Eight#o;
    $eight  =~ s#FRIENDS#[ qw( main::attribute main::method ) ]#o;
    $eight  =~ s#STRICT#0#o;
    eval $eight   or die $@;
}


# declare Test::Friend::Nine
#
# make package Test::Friends::Three, an unrelated package, a friend, and
# turn strict access checking explicitly on
BEGIN {
  my  $nine =  PKG;
    $nine =~ s#CLASS#Nine#o;
    $nine =~ s#FRIENDS#'Test::Friend::Three'#o;
    $nine =~ s#STRICT#1#o;
    eval $nine    or die $@;
}


# declare Test::Friend::Ten
#
# make two methods within the main package a friend, and turn strict access
# checking explicitly on
BEGIN {
  my  $ten  =  PKG;
    $ten  =~ s#CLASS#Ten#o;
    $ten  =~ s#FRIENDS#[ qw( main::attribute main::method ) ]#o;
    $ten  =~ s#STRICT#1#o;
    eval $ten   or die $@;
}


# create a derived package
package Test::Friend::Two;
use strict;
use base qw( Test::Friend::One );

# declare accessor methods for accessing methods and attributes
sub dispatch { # object|class , method|attribute
  my  $self = __PACKAGE__->class( shift );
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # call()

1;

# create an unrelated package that is a friend of Test::Friend::One
package Test::Friend::Three;

use strict;
use base qw( Class::Declare );

# declare accessor methods for accessing methods and attributes
sub call { # object|class , method|attribute
  my  $self = __PACKAGE__->class( shift );
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # call()

1;

# create a derived package
package Test::Friend::Five;
use strict;
use base qw( Test::Friend::Three );

# declare accessor methods for accessing methods and attributes
sub dispatch { # object|class , method|attribute
  my  $self = __PACKAGE__->class( shift );
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # dispatch()


# create an unrelated package
package Test::Friend::Six;
use strict;
use base qw( Class::Declare );

# declare accessor methods for accessing methods and attributes
sub call { # object|class , method|attribute
  my  $self = __PACKAGE__->class( shift );
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # call()

1;


# return to the main package to perform the tests
package main;

# define methods within main that will also be friends of
# Test::Friend::Four
#   - these methods are the same: what we are testing here is
#       a) the specification of specific methods as friends
#       b) the specification of multiple friends
sub attribute
{
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # attribute()

sub method
{
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # method()

# declare a method that isn't a friend
sub untrusted
{
  my  $object = shift;
  my  $target = shift;
    $object->$target();
} # untrusted()


sub dispatch
{
  no strict 'refs';
  goto &{ shift() };
} # dispatch()

# define the accessor methods to call on classes
my  @ctargets = qw( a_class  a_static  a_restricted
                    m_class  m_static  m_restricted );
# define the accessor methods to call on instances
my  @itargets = qw( a_public a_private a_protected
                    m_public m_private m_protected  );

# OK, check to make sure the friendship of Test::Friend::Three is
# honoured by Test::Friend::One
#   - need to test access from the class and from a class instance
foreach my $caller ( 'Test::Friend::Three' , Test::Friend::Three->new ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::One';
  foreach my $target ( @ctargets ) {
    lives_ok { $caller->call( $object => $target ) }
             "$target honoured by base class";
  }

  # check object methods/attributes
  #   - also test the class attributes/methods from an instance object
    $object = $object->new;
  foreach my $target ( @ctargets , @itargets ) {
    lives_ok { $caller->call( $object => $target ) }
             "$target honoured by base class";
  }
}


# OK, check to make sure the friendship of the main::* methods is
# honoured by Test::Friend::Four
# NB: this also tests that multiple friends is supported, as well as
#     method- rather than class-level friends are also supported.
foreach my $caller ( map { 'main::' . $_ }
                         qw( attribute method untrusted ) ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::Four';
  foreach my $target ( @ctargets ) {
    no strict 'refs';
    local $@;

    # dispatch the call
    eval { $caller->( $object => $target ) };

    # OK, now we must determine if we wanted that call to live or die
    #   - calls to untrusted method that aren't for the class
    #       attributee or method will fail
    if ( $caller =~ m/untrusted$/o && $target !~ m/class$/o ) {
      ok(   $@ , "$caller() access to $target denied" );

    #   - all other calls should succeed
    } else {
      ok( ! $@ , "$caller() access to $target honoured" );
    }
  }

  # check object methods/attributes
    $object = $object->new;
  foreach my $target ( @itargets ) {
    no strict 'refs';
    local $@;

    # dispatch the call
    eval { $caller->( $object => $target ) };

    # OK, now we must determmine if we wanted that call to live or die
    #   - calls to untrusted method that aren't for the class or
    #       public attribute or method will fail
    if ( $caller =~ m/untrusted$/o && $target !~ m/class$/o
                                   && $target !~ m/public$/o ) {
      ok(   $@ , "$caller() access to $target denied" );

    #   - all other calls should succeed
    } else {
      ok( ! $@ , "$caller() access to $target honoured" );
    }
  }
}

# OK, friendship is inherited on the condition that the calling method is
# also inherited (i.e. not implemented in the derived class). So, if call()
# is inherited, then the friendship will be honoured, since call() is from
# a trusted package. However, if another method is used from the inherited
# class, then the friendship will not be honoured
foreach my $caller ( 'Test::Friend::Five' , Test::Friend::Five->new ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::One';
  foreach my $target ( @ctargets ) {
    # calls to inherited call() will be honoured
    lives_ok { $caller->call( $object => $target ) }
             "$target honoured in derived class by inherted call()";

    # otherwise, the invoking method should be denied (unless
    # we're dealing with publicly accessible attributes or
    # methods)

    # class attributes and methods should still be honoured
    if ( $target =~ m/class$/o ) {
      lives_ok { $caller->dispatch( $object => $target ) }
               "$target honoured by derived class";
    } else {
       dies_ok { $caller->dispatch( $object => $target ) }
               "$target not honoured by derived class";
    }
  }

  # check object methods/attributes
  #   - also test the class attributes/methods from an instance object
    $object = $object->new;
  foreach my $target ( @ctargets , @itargets ) {
    # calls to inherited call() will be honoured
    lives_ok { $caller->call( $object => $target ) }
             "$target honoured in derived class by inherted call()";

    # otherwise, the invoking method should be denied (unless
    # we're dealing with publicly accessible attributes or
    # methods)

    # class and public attributes and methods should still be honoured
    if ( $target =~ m/class$/o || $target =~ m/public$/o ) {
      lives_ok { $caller->dispatch( $object => $target ) }
               "$target honoured by derived class";
    } else {
       dies_ok { $caller->dispatch( $object => $target ) }
               "$target not honoured by derived class";
    }
  }
}

# make sure friendships don't break the expected behaviour of access
# restrictions
#  - test this with an unrelated class
foreach my $caller ( 'Test::Friend::Six' , Test::Friend::Six->new ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::One';
  foreach my $target ( @ctargets ) {
    if ( $target =~ m/class$/o ) {
      lives_ok { $caller->call( $object => $target ) }
               "normal $target behaviour honoured";
    } else {
       dies_ok { $caller->call( $object => $target ) }
               "normal $target behaviour honoured";
    }
  }

  # check object methods/attributes
    $object = $object->new;
  foreach my $target ( @itargets ) {
    if ( $target =~ m/class$/o || $target =~ m/public$/o ) {
      lives_ok { $caller->call( $object => $target ) }
               "normal $target behaviour honoured";
    } else {
       dies_ok { $caller->call( $object => $target ) }
               "normal $target behaviour honoured";
    }
  }
}

#  - test this with a derived class
#    NB: we need to use a method from within the caller class, hence
#       dispatch() rather than call()
foreach my $caller ( 'Test::Friend::Two' , Test::Friend::Two->new ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::One';
  foreach my $target ( @ctargets ) {
    # the inherited method call() will succeed
    lives_ok { $caller->call( $object => $target ) }
             "normal inherited $target behaviour honoured";

    # now test the non-inherited dispatch() method
    if ( $target =~ m/class$/o || $target =~ m/restricted$/o ) {
      lives_ok { $caller->dispatch( $object => $target ) }
               "normal $target behaviour honoured";
    } else {
       dies_ok { $caller->dispatch( $object => $target ) }
               "normal $target behaviour honoured";
    }
  }

  # check object methods/attributes
    $object = $object->new;
  foreach my $target ( @itargets ) {
    # the inherited method call() will succeed
    lives_ok { $caller->call( $object => $target ) }
             'normal inherited $target behviour honoured';

    # now test the non-inherited dispatch() method
    if ( $target =~ m/class$/o      || $target =~ m/public$/o    ||
         $target =~ m/restricted$/o || $target =~ m/protected$/o    ) {
      lives_ok { $caller->dispatch( $object => $target ) }
               "normal $target behaviour honoured";
    } else {
       dies_ok { $caller->dispatch( $object => $target ) }
               "normal $target behaviour honoured";
    }
  }
}

#  - test this with the base class
foreach my $caller ( 'Test::Friend::One' , Test::Friend::One->new ) {
  # check class methods/attributes
  my  $object = 'Test::Friend::One';
  foreach my $target ( @ctargets ) {
    # all access should be successful
    lives_ok { $caller->call( $object => $target ) }
             "normal $target behaviour honoured";
  }

  # check object methods/attributes
    $object = $object->new;
  foreach my $target ( @itargets ) {
    # all access should be successful
    lives_ok { $caller->call( $object => $target ) }
             "normal $target behaviour honoured";
  }
}

# need to test the Class::Declare::friend() method which returns true if the
# caller is a friend of the subject object or class
#   - this should be tested with strict access checking explicitly turned
#     on, turned off and left as a default
#   - to that end, we have the following class mappings:
#
#        : strict == undef     : strict == 0          : strict == 1
#        ------------------    -------------------    ------------------
#        Test::Friend::One     Test::Friend::Seven    Test::Friend::Nine
#        Test::Friend::Four    Test::Friend::Eight    Test::Friend::Ten
#
#   - changing the access control checking of a class should not alter the
#     behaviour of friend() as it's designed as a runtime optimisation, not
#     a change in program logic.

# create the mapping of equivalent classes for testing the variation of
# strict access control setting
my  @map  = ( [ qw( One   Four  ) ] ,
              [ qw( Seven Eight ) ] ,
              [ qw( Nine  Ten   ) ] );

# iterate through all combinations, testing the behaviour of friend()
foreach ( @map ) {

  # create the  class names
  my  @class  = map { 'Test::Friend::' . $_ } @{ $_ };

  # extract the class and instances of interest
  my  $class  = $class[ 1 ];  #'Test::Friend::Four';
  my  $object = $class->new;

  # - main is not a friend of Test::Friend::Four
  ok( !  $class->friend , 'foreign class not a class friend' );
  ok( ! $object->friend , 'foreign class not an object friend' );

  # - main::method is a friend of Test::Friend::Four
  ok(      method( $class  => 'friend' ) ,
      'friend method reported correctly'  );
  ok(      method( $object => 'friend' ) ,
      'friend method reported correctly'  );

  # - main::untrusted is not a friend of Test::Friend::Four
  ok( ! untrusted( $class  => 'friend' ) ,
      'unknown method reported correctly' );
  ok( ! untrusted( $object => 'friend' ) ,
      'unknown method reported correctly' );

  # now we need to test Class::Declare::friend() for friend classes, not
  # methods, as the above tests showed

  # the base class is a friend
  foreach my $caller ( 'Test::Friend::Three' , Test::Friend::Three->new ) {
    foreach my $object ( $class[ 0 ] , $class[ 0 ]->new ) {
      ok( $caller->call( $object => 'friend' ) ,
          "class friend reported correctly" );
    }
  }

  # an inherited class is not a friend
  foreach my $caller ( 'Test::Friend::Three' , Test::Friend::Three->new ) {
    foreach my $object ( 'Test::Friend::Two' , Test::Friend::Two->new ) {
      ok( ! $caller->call( $object => 'friend' ) ,
          "class inherited friendship reported correctly" );
    }
  }

  # a class derived from a friend class is a friend *if* the method of access
  # is a member of the friend class, and not implemented by the derived class
  foreach my $caller ( 'Test::Friend::Five' , Test::Friend::Five->new ) {
    foreach my $object ( $class[ 0 ] , $class[ 0 ]->new ) {
      # the inherited method() call is a friend
      ok(   $caller->call( $object => 'friend' ) ,
          "inhreited class friend reported correctly (inherited method)" );
      # the new method dispatch() is not a friend
      ok( ! $caller->dispatch( $object => 'friend' ) ,
          "inhreited class friend reported correctly (local method)" );
    }
  }

  # an unrelated class is not a friend
  foreach my $caller ( 'Test::Friend::Six' , Test::Friend::Six->new ) {
    foreach my $object ( 'Test::Friend::Two' , Test::Friend::Two->new ,
                        $class[ 0 ] , $class[ 0 ]->new ) {
      ok( ! $caller->call( $object => 'friend' ) ,
          "unrelated class friendship reported correctly" );
    }
  }

  # freindship is not transfered through inheritance
  foreach my $caller ( 'Test::Friend::Five' , Test::Friend::Five->new ) {
    foreach my $object ( 'Test::Friend::Two' , Test::Friend::Two->new ) {
      ok ( ! $caller->call( $object => 'friend' ) ,
           'inhreited friendship reported correctly' );
    }
  }
}
