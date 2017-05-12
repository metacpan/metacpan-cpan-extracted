#!/usr/bin/perl -w
# $Id: 21dump.t 1511 2010-08-21 23:24:49Z ian $

# dump.t
#
# Ensure dump() behaves as it should.

use Test::More      tests => 63;
use Test::Exception;

# firstly, create a package that we can generate a dump of
#  - want to ensure it contains each type of attribute
package Test::Dump::Zero;

use strict;
use base qw( Class::Declare );

# add a routine for calling dump()
sub parent
{
  my  $self = __PACKAGE__->class( shift );
      $self->dump;
} # parent()

1;

package Test::Dump::One;

use strict;
use base qw( Test::Dump::Zero );

{
  my  $array    = [ 1 , 2 , 3 , 4 ];
  my  $hash     = { key => 'value' };
  my  $code     = sub { rand };
  my  $friends  = [ qw( main::dump Test::Dump::Three ) ];

__PACKAGE__->declare( class      => { my_class      => 1      } ,
                      static     => { my_static     => $code  } ,
                      restricted => { my_restricted => $array } ,
                      public     => { my_public     => $hash  } ,
                      private    => { my_private    => undef  } ,
                      protected  => { my_protected  => $hash  } ,
                      abstract   =>  'my_abstract'              ,
                      friends    =>  $friends                   );

# add a routine for calling the dump()
sub call
{
  my  $self = __PACKAGE__->class( shift );
      $self->dump;
} # call()

}

1;

# return to main for the tests
package main;

# create a test instance
my  $class  = 'Test::Dump::One';
my  $object = $class->new;


#
# define the expected results strings
#

my  $result = {

    # class only
    class => <<__EOR__ ,
Test::Dump::(?:One|Two)
    abstract:
        my_abstract
    class:
        my_class    = 1
__EOR__

    # class & restricted only
    restricted =>
qr#^Test::Dump::(?:One|Two)
    abstract:
        my_abstract
    class:
        my_class      = 1
    restricted:
        my_restricted = \[ 1, 2, 3, 4 \]
$# ,

    # class, static & restricted only
    static =>
qr#^Test::Dump::(?:One|Two)
    abstract:
        my_abstract
    class:
        my_class      = 1
    static:
        my_static     = CODE\(0x[a-f\d]+\)
    restricted:
        my_restricted = \[ 1, 2, 3, 4 \]
$# ,

    # class & public only
    public => 
qr#^Test::Dump::(?:One|Two)=SCALAR\(0x[a-f\d]+\)
    abstract:
        my_abstract
    class:
        my_class    = 1
    public:
        my_public   = \{ 'key' => 'value' \}
$# ,

    # class, restricted, public & protected only
    protected =>
qr#^Test::Dump::(One|Two)=SCALAR\(0x([a-f\d]+)\)
    abstract:
        my_abstract
    class:
        my_class      = 1
    restricted:
        my_restricted = \[ 1, 2, 3, 4 \]
    public:
        my_public     = \{ 'key' => 'value' \}
    protected:
        my_protected  = Test::Dump::\1=SCALAR\(0x\2\)->my_public
$# ,

    # all attributes
    private =>
qr#^Test::Dump::(One|Two)=SCALAR\(0x([a-f\d]+)\)
    abstract:
        my_abstract
    class:
        my_class      = 1
    static:
        my_static     = CODE\(0x[a-f\d]+\)
    restricted:
        my_restricted = \[ 1, 2, 3, 4 \]
    public:
        my_public     = \{ 'key' => 'value' \}
    private:
        my_private    = undef
    protected:
        my_protected  = Test::Dump::\1=SCALAR\(0x\2\)->my_public
$#  
  };


my  $dump;  # hold the output from the current dump

# OK, on 64-bit machines, the comparisons here will raise warnings about
# hexadecimal values being too great (i.e. not portable)
#   - that's OK, just ignore the warnings
{
  local $^W = 0;  # disable error reporting for this section

  # Now we need to verify that when we dump a class in an unrelated
  # environment (e.g. from main), we get only the class attribute
    $dump = $class->dump;
  # OK, the dump should be the following
    ok( $dump =~ $result->{ class } ,
        "Expected result from class dump in unrelated scope" );
  # OK, a dump of the object should include public attributes as well
    $dump = $object->dump;
  # here the result is a regular expression since we cannot know the memory
  # address of the object
    ok( $dump =~ $result->{ public } ,
        "Expected result from object dump in unrelated scope" );

  # OK, now let's take a dump from within the class - this time we should be
  # granted access to all types of attributes
    $dump = $class->call;
  # we should see class, static and restricted attributes
    ok( $dump =~ $result->{ static } ,
        "Expected result from class dump in own scope" );
  # now dump an object within it's own scope
    $dump = $object->call;
  # should get all types of attributes
    ok( $dump =~ $result->{ private } ,
        "Expected result from object dump in own scope" );
} # end of ignore warnings


# now create a derived class so that we can test the dump output from the
# derived scope
package Test::Dump::Two;

use strict;
use base qw( Test::Dump::One );

# add a local routine for calling dump()
sub dispatch
{
  my  $self = __PACKAGE__->class( shift );
    $self->dump;
} # dispatch()

1;

# return to main to resume the testing
package main;

# OK, now take a dump from within a derived class
  $class  = 'Test::Dump::Two';

# again, ignore warnings
{
  local $^W = 0;

  # from within the derived class we should see class and
  # restricted attributes
    $dump = $class->dispatch;
    ok( $dump =~ $result->{ restricted } ,
        "Expected result from inherited class dump in own scope" );

  # if we inherit the dump() call, we should also have access to static
  # attributes from within the base class
    $dump = $class->call;
    ok( $dump =~ $result->{ static } ,
        "Expected result from inherited class dump in inherited scope" );

  # OK, now repeat these last two tests with derived objects instead of
  # classes
    $object = $class->new;

  # from within the derived object we should see class, restricted,
  # public and protected attributes
    $dump = $object->dispatch;
  # NB: this also tests (as done before) the correct attribution of previously
  #     seen reference values
    ok( $dump =~ $result->{ protected } ,
        "Expected result from derived object dump() in own scope" );

  # now examine the output from the inherited method: we should see static and
  # private attributes as well
    $dump = $object->call;
    ok( $dump =~ $result->{ private } ,
        "Expected result from derived object dump() in inherited scope" );

  # Now test the behaviour of dump() on derived classes/objects in an
  # unrelated scope

  # from an unrelated scope, the class should show class attributes only
    $dump = $class->dump;
    ok( $dump =~ $result->{ class } ,
        "Expected result from inherited class dump in unrelated scope" );

  # for an object, class and public attributes should be accessible
    $dump = $object->dump;
    ok( $dump =~ $result->{ public } ,
        "Expected result from derived object dump in unrelated scope" );


  #
  # test that dump() honours class friends
  #

  # define main::dump(), which is a friend of Test::Dump::One
  sub main::dump($) { $_[ 0 ]->dump; } # main::dump()


  # for Test::Dump::One, main::dump() should report class, static and
  # restricted attributes
    $class  = 'Test::Dump::One';
    $dump = main::dump( $class );
    ok( $dump =~ $result->{ static } ,
        "Expected result from friend method in class dump" );

  # for a Test::Dump::One object, main::dump() should report all attributes
    $object = $class->new;
    $dump = main::dump( $object );
    ok( $dump =~ $result->{ private } ,
        "Expected result from friend method in object dump" );

} # end of ignore warnings


# define Test::Dump::Three, which is also a friend of Test::Dump::One
package Test::Dump::Three;

use strict;
use base qw( Class::Declare );

# define a print() routine that calls dump() on it's first argument
sub print
{
  my  $self = __PACKAGE__->class( shift );
  my  $target = shift;

    $target->dump;
} # print()

1;

# return to main to resume the testing
package main;

{ # again, ignore warnings

  local $^W = 0;

  # For Test::Dump::One, Test::Dump::Three and instances of it should report
  # class, static and restricted attributes
    $class  = 'Test::Dump::Three';
    $dump = $class->print( 'Test::Dump::One' );
    ok( $dump =~ $result->{ static } ,
        "Expected result from friend class in class dump" );

  # for a Test::Dump::One instance we should get all attributes
    $dump = $class->print( Test::Dump::One->new );
    ok( $dump =~ $result->{ private } ,
        "Expected result from friend class in object dump" );


  # OK, now repeat these tests with instances of Test::Dump::Three

  # For Test::Dump::One, Test::Dump::Three and instances of it should report
  # class, static and restricted attributes
    $object = $class->new;
    $dump = $object->print( 'Test::Dump::One' );
    ok( $dump =~ $result->{ static } ,
        "Expected result from friend object in class dump" );

  # for a Test::Dump::One instance we should get all attributes
    $dump = $object->print( Test::Dump::One->new );
    ok( $dump =~ $result->{ private } ,
        "Expected result from friend object in object dump" );

} # end of ignore warnings


# Now derive a class from the friend class and ensure friendship isn't
# transfered

package Test::Dump::Four;

use strict;
use base qw( Test::Dump::Three );

# declare a method similar to Test::Dump::Three::print() so that we can test
# method inheritance within the derived friend class
sub show
{
  my  $self = __PACKAGE__->class( shift );
  my  $target = shift;

    $target->dump;
} # show()

1;

# return to main to resume testing
package main;

{ # again, ignore warnings

  local $^W = 0;

  # here, show() is not an inherited method, so we should only see class
  # attributes
    $class  = 'Test::Dump::Four';
    $dump = $class->show( 'Test::Dump::One' );;
    ok( $dump =~ $result->{ class } ,
        "Expected result from inherited friend class in "
      . "local class scope" );

  # for an object, only class and public attributes should be accessible
    $dump = $class->show( Test::Dump::One->new );
    ok( $dump =~ $result->{ public } ,
        "Expected result from inherited friend class in "
      . "local object scope" );

  # now, if we use the inherited print() method then we should see class,
  # static and restricted attributes for a class target, and all attributes
  # for an instance target
    $dump = $class->print( 'Test::Dump::One' );
    ok( $dump =~ $result->{ static } ,
        "Expected result from inherited friend class in "
      . "derived class scope" );

  # for a Test::Dump::One instance we should get all attributes
    $dump = $class->print( Test::Dump::One->new );
    ok( $dump =~ $result->{ private } ,
        "Expected result from inherited friend class in "
      . "derived object scope" );

  # repeat the above tests for derived instances

    $object = $class->new;
    $dump = $object->show( 'Test::Dump::One' );;
    ok( $dump =~ $result->{ class } ,
        "Expected result from derived friend object in "
      . "local class scope" );

  # for an object, only class and public attributes should be accessible
    $dump = $object->show( Test::Dump::One->new );
    ok( $dump =~ $result->{ public } ,
        "Expected result from derived friend object in "
      . "local object scope" );

  # now, if we use the inherited print() method then we should see class,
  # static and restricted attributes for a class target, and all attributes
  # for an instance target
    $dump = $object->print( 'Test::Dump::One' );
    ok( $dump =~ $result->{ static } ,
      "Expected result from derived friend object in "
    . "derived class scope" );

  # for a Test::Dump::One instance we should get all attributes
    $dump = $object->print( Test::Dump::One->new );
    ok( $dump =~ $result->{ private } ,
        "Expected result from derived friend object in "
      . "derived object scope" );

} # end of ignore warnigs

# OK, now test an unrelated class with an attribute that is a class
# and another attribute that is an instance

package Test::Dump::Five;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( class => { object =>  Test::Dump::One->new } );

1;


# return to main to resume testing
package main;

#
# define the expected results
#

  $result   = {
    # unrelated class
    unrelated =>
qr#^Test::Dump::Five
    class:
        object = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                     abstract:
                         my_abstract
                     class:
                         my_class    = 1
                     public:
                         my_public   = \{ 'key' => 'value' \}
$# ,

    # unrelated instance
    foreign   =>
qr#^Test::Dump::Five=SCALAR\(0x[a-f\d]+\)
    class:
        object = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                     abstract:
                         my_abstract
                     class:
                         my_class    = 1
                     public:
                         my_public   = \{ 'key' => 'value' \}
$# ,

    # friend class/object
    friend    =>
qr#^(Test::Dump::Five(?:=SCALAR\(0x[a-f\d]+\))?)
    class:
        object = (Test::Dump::One=SCALAR\(0x[a-f\d]+\))
                     abstract:
                         my_abstract
                     class:
                         my_class      = 1
                     static:
                         my_static     = CODE\(0x[a-f\d]+\)
                     restricted:
                         my_restricted = \[ 1, 2, 3, 4 \]
                     public:
                         my_public     = \{ 'key' => 'value' \}
                     private:
                         my_private    = undef
                     protected:
                         my_protected  = \1->object->my_public
$#

  };


{ # again, ignore warnings

  local $^W = 0;

  # a dump of the class from an unrelated class should show class & public
  # attributes only
    $dump = $class->show( 'Test::Dump::Five' );
    ok( $dump =~ $result->{ unrelated } ,
        "Expected recursive result from "
      . "unrelated class" );

  # an instance dump should display the same results
    $dump = $class->show( Test::Dump::Five->new );
    ok( $dump =~ $result->{ foreign  } ,
        "Expected recursive result from "
      . "unrelated class with object target" );

  # a dump of the class from an unrelated object should show class & public
  # attributes only
    $dump = $object->show( 'Test::Dump::Five' );
    ok( $dump =~ $result->{ unrelated } ,
        "Expected recursive result from "
      . "unrelated object with class target" );

  # an instance dump should display the same results
    $dump = $object->show( Test::Dump::Five->new );
    ok( $dump =~ $result->{ foreign  } ,
        "Expected recursive result from "
      . "unrelated object with object target" );

  # by using print() we are accessing dump() as a friend of
  # Test::Dump::One, so we should see all attributes
    $dump = $class->print( 'Test::Dump::Five' );
    ok( $dump =~ $result->{ friend   } ,
        "Expected recursive result from "
      . "friend class with class target" );

    $dump = $class->print( Test::Dump::Five->new );
    ok( $dump =~ $result->{ friend    } ,
        "Expected recursive result from "
      . "friend class with object target" );

    $dump = $object->print( 'Test::Dump::Five' );
    ok( $dump =~ $result->{ friend    } ,
        "Expected recursive result from "
      . "friend object with class target" );

    $dump = $object->print( Test::Dump::Five->new );
    ok( $dump =~ $result->{ friend    } ,
        "Expected recursive result from "
      . "friend object with object target" );

  #
  # OK, now we want to test the reporting of friends
  #

  #
  # define the expected results
  #
    $result   =
    # class/object friend
qr#^Test::Dump::One(?:=SCALAR\(0x[a-f\d]+\))?
    friends:
        Test::Dump::Three
        main::dump
$#;

  # for the Test::Dump::One class we should see a list of the friend methods
  # and classes
    $class  = 'Test::Dump::One';
    $dump = $class->dump( friends => 1 );
    ok( $dump =~ $result ,
        "Expected friends output for class dump" );

    $object = $class->new;
    $dump = $object->dump( friends => 1 );
    ok( $dump =~ $result ,
        "Expected friends output for object dump" );

  # OK, now if the class has no friends, then we should get nothing listed
  # under the friends: heading
    $result   =
qr#^Test::Dump::Two(?:=SCALAR\(0x[a-f\d]+\))?
    friends:
$#;

  # Test::Dump::Two has no friends so we should get none listed
    $class  = 'Test::Dump::Two';
    $dump = $class->dump( friends => 1 );
    ok( $dump =~ $result ,
        "Expected friends output for friendless class dump" );

    $object = $class->new;
    $dump = $object->dump( friends => 1 );
    ok( $dump =~ $result ,
        "Expected friends output for friendless object dump" );

  # ensure dump() returns undef if we've asked for nothing
    ok( ! defined  $class->dump( all => undef ) ,
        "Expected undef from class dump" );
    ok( ! defined $object->dump( all => undef ) ,
        "Expected undef from object dump" );


  #
  # Now test accessing only abstract attributes and methods
  #

    $result =
qr#^Test::Dump::Two(?:=SCALAR\(0x[a-f\d]+\))?
    abstract:
        my_abstract
$#;
    $dump   = $object->dump( abstract => 1 );
    ok( $dump =~ $result ,
        "Expected abstract output for object dump" );

  #
  # OK, time to check that dump() behaves as expected (i.e. dies with a
  # message) when you explicitly ask for an attribute type that you do not
  # have access to.
  #

  # public attributes can be accessed anywhere, but only if you have an
  # instance
    $class  = 'Test::Dump::One';
    dies_ok { $class->dump( public => 1 ) }
            "dump() dies accessing prohibited attribute";
    dies_ok { $class->dump( static => 1 ) }
            "dump() dies accessing prohibited attribute";

    $object = $class->new;
    dies_ok { $object->dump( private => 1 ) }
            "dump() dies accessing prohibited attribute";
    dies_ok { $object->dump( static  => 1 ) }
            "dump() dies accessing prohibited attribute";

} # end of ignore warnings


# now test to ensure when we select certain attributes only, that's all we
# get

package Test::Dump::Six;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public  => { my_public  => $object } ,
                      private => { my_private => $object } ,
                      static  => { my_static  => $object } ,
                      class   => { my_class   => $object } );

# accessor method so that we can call dump() within the scope of this
# package
sub print
{
  my  $self = __PACKAGE__->class( shift );
      $self->dump( @_ );
} # print()

1;


# return to main to resume the testing
package main;

{ # again, ignore warnings

  local $^W = 0;

    $class  = 'Test::Dump::Six';
    $object = $class->new;
  # if we ask for public only, then we should get public only
    $dump = $object->dump( public => 1 );
  # define the expected result
    $result =
qr#Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
    public:
        my_public = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                        abstract:
                            my_abstract
                        class:
                            my_class    = 1
                        public:
                            my_public   = \{ 'key' => 'value' \}
#;
    ok( $dump =~ $result , "dump() returns limited results as requested" );

  # now, let's select a number of attributes to show
    $dump = $object->print( static => 1 , private => 1 , class => 1 );
  # NB: class attributes aren't cloned, while instance attributes are to
  #     ensure each instance has it's own copy
    $result =
qr#(Test::Dump::Six=SCALAR\(0x[a-f\d]+\))
    class:
        my_class   = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                         abstract:
                             my_abstract
                         class:
                             my_class    = 1
                         public:
                             my_public   = \{ 'key' => 'value' \}
    static:
        my_static  = \1->my_class
    private:
        my_private = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                         abstract:
                             my_abstract
                         class:
                             my_class    = 1
                         public:
                             my_public   = \{ 'key' => 'value' \}
#;
    ok( $dump =~ $result , "dump() returns limited results as requested" );

  # repeat the above test, but this time with back-trace disabled
    $dump = $object->print( static    => 1     ,
                            private   => 1     ,
                            class     => 1     ,
                            backtrace => undef );
    $result =
qr#Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
    class:
        my_class   = (Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                         abstract:
                             my_abstract
                         class:
                             my_class    = 1
                         public:
                             my_public   = \{ 'key' => 'value' \})
    static:
        my_static  = \1
    private:
        my_private = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                         abstract:
                             my_abstract
                         class:
                             my_class    = 1
                         public:
                             my_public   = \{ 'key' => 'value' \}
#;
    ok( $dump =~ $result , "dump() ignored back-traces as requested" );


  # OK, now test the indentation to make sure it can be set at run time
    $dump = $object->dump( indent => 1 );
    $result =
qr#Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
 class:
  my_class  = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
               abstract:
                my_abstract
               class:
                my_class    = 1
               public:
                my_public   = \{ 'key' => 'value' \}
 public:
  my_public = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
               abstract:
                my_abstract
               class:
                my_class    = 1
               public:
                my_public   = \{ 'key' => 'value' \}
#;
    ok( $dump =~ $result , "dump() honours indentation" );

} # end of ignore warnings

# now create a class with strict checking off and ensure dump() still
# honours the intent of the access controls

package Test::Dump::Seven;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( class      => { my_class      => 1 } ,
                      static     => { my_static     => 2 } ,
                      restricted => { my_restricted => 3 } ,
                      public     => { my_public     => 4 } ,
                      private    => { my_private    => 5 } ,
                      protected  => { my_protected  => 6 } ,
                      strict     => 0                      );

1;

# return to main to resume testing
package main;

{ # again, ignore warnings

  local $^W = 0;

    $class  = 'Test::Dump::Seven';
  # first, try a class dump
    $dump = $class->dump;
    $result = <<__EOR__;
Test::Dump::Seven
    class:
        my_class = 1
__EOR__
    ok( $dump eq $result , "dump() ignores strict in class dump" );

  # now, try an object dump
    $object = $class->new;
    $dump = $object->dump;
    $result =
qr#Test::Dump::Seven=SCALAR\(0x[a-f\d]+\)
    class:
        my_class  = 1
    public:
        my_public = 4
#;
    ok( $dump =~ $result , "dump() ignores strict in object dump" );

} # end of ignore warnings


# now check to ensure the depth paramter of dump() is honoured

package Test::Dump::Eight;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { my_public => Test::Dump::Six->new } );

1;


package Test::Dump::Nine;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public => { my_public => Test::Dump::Eight->new } );

1;


# return to main to resume testing
package main;

  $class  = 'Test::Dump::Nine';
  $object = $class->new;

# define the expected results
  $result = [

# no depth restrictions
qr#Test::Dump::Nine=SCALAR\(0x[a-f\d]+\)
 public:
  my_public = Test::Dump::Eight=SCALAR\(0x[a-f\d]+\)
               public:
                my_public = Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
                             class:
                              my_class  = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                                           abstract:
                                            my_abstract
                                           class:
                                            my_class    = 1
                                           public:
                                            my_public   = \{ 'key' => 'value' \}
                             public:
                              my_public = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                                           abstract:
                                            my_abstract
                                           class:
                                            my_class    = 1
                                           public:
                                            my_public   = \{ 'key' => 'value' \}
# ,

# limit the depth to 0
#   - show only the current object's attributes
qr#Test::Dump::Nine=SCALAR\(0x[a-f\d]+\)
 public:
  my_public = Test::Dump::Eight=SCALAR\(0x[a-f\d]+\)
# ,

# limit the depth to 1
#   - show the current object's attribute's objects
qr#Test::Dump::Nine=SCALAR\(0x[a-f\d]+\)
 public:
  my_public = Test::Dump::Eight=SCALAR\(0x[a-f\d]+\)
               public:
                my_public = Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
# ,

# limit the depth to 2
#   - one more level of display compared with the last
qr#Test::Dump::Nine=SCALAR\(0x[a-f\d]+\)
 public:
  my_public = Test::Dump::Eight=SCALAR\(0x[a-f\d]+\)
               public:
                my_public = Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
                             class:
                              my_class  = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                             public:
                              my_public = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
# ,

# limit the depth to 3
#    - one more level of display compared with the last
qr#Test::Dump::Nine=SCALAR\(0x[a-f\d]+\)
 public:
  my_public = Test::Dump::Eight=SCALAR\(0x[a-f\d]+\)
               public:
                my_public = Test::Dump::Six=SCALAR\(0x[a-f\d]+\)
                             class:
                              my_class  = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                                           abstract:
                                            my_abstract
                                           class:
                                            my_class    = 1
                                           public:
                                            my_public   = HASH\(0x[a-f\d]+\)
                             public:
                              my_public = Test::Dump::One=SCALAR\(0x[a-f\d]+\)
                                           abstract:
                                            my_abstract
                                           class:
                                            my_class    = 1
                                           public:
                                            my_public   = HASH\(0x[a-f\d]+\)
#

    ]; # $result

  # make sure dump() behaves as expected
  my  @depth  = ( undef , 0 .. 4 );
  for ( my $indx = 0 ; $indx < scalar @depth ; $indx++ ) {
    # again, ignore warnings
    local $^W = 0;

    my  $depth  = $depth[ $indx ];
    # generate the dump at this depth
        $dump   = $object->dump( indent => 1 , depth => $depth );

    # at depth 4 we should get the same result as shown for the case
    # with no depth limit (only 4 levels of nesting)
    ok( $dump =~ $result->[ $indx % 5 ] ,
        "dump() correct at depth" . ( defined $depth ? " $depth" : '' ) );
  }

# added tests to make sure dump() fails if requests are made for 'shared'
# attributes (now that shared has been renamed 'restricted')
throws_ok {  $class->dump( shared => 1 ) } "/Unknown parameter 'shared'/" ,
          "caught unknwon 'shared' parameter in class dump";
throws_ok { $object->dump( shared => 1 ) } "/Unknown parameter 'shared'/" ,
          "caught unknwon 'shared' parameter in object dump";

# if we have an empty class (no attributes), then calling dump() should just
# return the class name
  $class  = 'Test::Dump::Zero';
  $result = qr#$class
#;
# - use parent() to call dump() from within the class as this will output
#   the maximum number of attributes for that class 
  $dump   = $class->parent;
  ok( $dump =~ $result , "Empty class shows just the class name" );

# does the same happen for an instance of this class? it should
  $result = qr#$class=SCALAR\(0x[a-f\d]+\)
#;
  $object = $class->new;
  $dump   = $object->parent;
  ok( $dump =~ $result , "Empty class instance shows just the class name" );

# now, test to see if the parent has the same level of access as the
# class itself
  $class  = 'Test::Dump::One';
  $result = $class->call;
  $dump   = $class->parent;
  ok( $dump eq $result , "Parent access the same as child access" );

# what about the instance of the class?
  $object = $class->new;
  $result = $object->call;
  $dump   = $object->parent;
  ok( $dump eq $result ,
      "Parent instance access the same as child instance access" );


# previous versions of dump() threw a warning trying to print strings like
# the following (due to the method used to determine whether a value is a
# number) ... should probably use Scalar::Util, but will restrain for now
  $object->my_public  = 'http://a.b.c/d/e/f.g?h=i&j=k;123';
  my  $msg            = '';
  {
    local $SIG{__WARN__}  = sub { $msg  .= $_   foreach ( @_ ) };
          $result         = eval { $object->dump( public => 1 ) };
  }
  ok( 0 == length $msg , "dump with '&' throws no warnings" );

# dump()ing a value that looks like a hex, but isn't can cause errors, so this
# has been corrected through warning suppression in dump()
#   - need to check that this still holds
  $object->my_public  = '0xabcdef0123456789abcdef';
      $msg            = '';
  {
    local $SIG{__WARN__}  = sub { $msg  .= $_   foreach ( @_ ) };
          $result         = eval { $object->dump( public => 1 ) };
  }
  ok( 0 == length $msg , "dump with hex-a-like throws no warnings" );
