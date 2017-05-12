#!/usr/bin/perl -w
# $Id: 03new.t 1511 2010-08-21 23:24:49Z ian $

# new.t
#
# Ensure new() behaves appropriately. Test such things as:
#   - returns a valid Class::Declare object
#   - honours default values
#   - allows setting of public only attributes

use strict;
use Test::More tests => 43;
use Test::Exception;

# Declare the a Class::Declare package
package Test::New::One;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( public    => { mypublic    => 1 } ,
                      private   => { myprivate   => 1 } ,
                      protected => { myprotected => 1 } ,
                      class     => { myclass     => 1 } ,
                      abstract  =>  'myabstract'        );

1;

package main;

# does object creation work
my  $obj;
lives_ok { $obj = Test::New::One->new } 'object creation succeeds';

# is $obj an object?
ok( ref $obj  , 'object is a reference' );

# is $obj a Class::Declare object
ok( $obj->isa( 'Class::Declare' ) , 'object is a Class::Declare object' );

# is the public attribute honoured?
ok( $obj->mypublic == 1 , 'public attribute default value is honoured' );

# is the abstract attribute present?
dies_ok { $obj->myabstract } 'abstract attribute present and inaccessible';

# can we change the default value for the public attribute?
lives_ok { $obj = Test::New::One->new( mypublic => 2 ) }
         'constructor calling with public attribute values';

# was this value set?
ok( $obj->mypublic == 2 , 'constructor setting of public attributes' );

# shouldn't be able to set private, protected, class or abstract values
# in the constructor
dies_ok { $obj = Test::New::One->new( myprivate   => 2 ) }
        'private attribute setting in the constructor';
dies_ok { $obj = Test::New::One->new( myprotected => 2 ) }
        'protected attribute setting in the constructor';
dies_ok { $obj = Test::New::One->new( myclass     => 2 ) }
        'class attribute setting in the constructor';
dies_ok { $obj = Test::New::One->new( myabstract  => 2 ) }
        'abstract attribute setting in the constructor';


# make sure single attribute declarations (i.e. only the attribute name is
# given for a type of attribute), and lists of attributes work successfully

package Test::New::Two;

use strict;
use base qw( Class::Declare );

__PACKAGE__->declare( class  => 'my_class'  ,
                      public => [ qw( a b ) ] );

1;

# return to main to resume testing
package main;

my  $class  = 'Test::New::Two';

# make sure the new() call lives
lives_ok { $obj = $class->new }
         "new() with singleton & array reference attributes lives";

# make sure we can access the class attribute accessor
lives_ok { $class->my_class }
         "singleton attribute accessor defined via class";
lives_ok {   $obj->my_class }
         "singleton attribute accessor defined via object";

# make sure the class attribute is undefined
ok( ! defined $class->my_class , "class attribute via class is undefined" );
ok( ! defined   $obj->my_class , "class attribute via object is undefined" );

# make sure the instance attributes can be accessed
lives_ok { $obj->a } "list of attribute names accessort created";
lives_ok { $obj->b } "list of attribute names accessort created";

# make sure the instance attributes are undefined
ok( ! defined $obj->a , "list of attributes default to undef" );
ok( ! defined $obj->b , "list of attributes default to undef" );

# make sure lists of attributes can be set in the constructor
lives_ok { $obj = $class->new( a => 1 , b => 2 ) }
         "attributes specified as list ok in constructor";

# make sure the attributes have the value from the constructor call
ok( $obj->a == 1 , "constructor performs correct initialisation" );
ok( $obj->b == 2 , "constructor performs correct initialisation" );


# make sure the 'new' attribute of declare() is honoured

package Test::New::Three;

use base qw( Class::Declare );

__PACKAGE__->declare(

  public     => { mypublic     => 1 } ,
  private    => { myprivate    => 1 } ,
  protected  => { myprotected  => 1 } ,
  class      => { myclass      => 1 } ,
  restricted => { myrestricted => 1 } ,
  static     => { mystatic     => 1 } ,

  # permit the setting of all attributes other than the public attributes
  new        => [ qw( myprivate
                      myprotected ) ]

);  # declare()

# equal( <target> , <attribute> , <value> )
#
sub equal
{
  my  $self   = shift;
  my  $attr   = shift;
  my  $value  = shift;
  
  return $self->$attr() == $value;
} # equal()

1;  # Test::New::Three


package main;

$class  = 'Test::New::Three';

# make sure new() call lives
lives_ok { $obj = $class->new }
         "new() with 'new' attribute lives";

# make sure new() allows the setting of the attributes listed in the 'new'
# attribute
lives_ok { $obj = $class->new( myprivate    => 2 ,
                               myprotected  => 2 ) }
         "new() with 'new' attribute lives with attributes";
# ensure the constructed object has the correct attribute values
ok( $obj->equal( mypublic     => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myprivate    => 2 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myprotected  => 2 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myclass      => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myrestricted => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( mystatic     => 1 ) ,
    "constructor performs correct initialisation" );

# make sure new() no longer allows setting of public attributes
dies_ok { $obj = $class->new( mypublic => 2 ) }
        "constructor denies access to public attribute";


# ensure inheritence works for the 'new' attribute
package Test::New::Four;

use base qw( Test::New::Three );

__PACKAGE__->declare(

  public  => { myattr   => 1 } ,
  private => { myhidden => 1 } ,

);

1;  # Test::New::Four


package main;

$class  = 'Test::New::Four';

# make sure new() call lives
lives_ok { $obj = $class->new }
         "new() with 'new' attribute lives";

# make sure new() allows the setting of the attributes listed in the 'new'
# attribute from the parent class, as well as the public attribute from this
# class
lives_ok { $obj = $class->new( myattr       => 2 ,
                               myprivate    => 2 ,
                               myprotected  => 2 ) }
         "new() with 'new' attribute lives with attributes";
# ensure the constructed object has the correct attribute values
ok( $obj->equal( myattr       => 2 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( mypublic     => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myprivate    => 2 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myprotected  => 2 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myclass      => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( myrestricted => 1 ) ,
    "constructor performs correct initialisation" );
ok( $obj->equal( mystatic     => 1 ) ,
    "constructor performs correct initialisation" );

# make sure new() no longer allows setting of public attributes
dies_ok { $obj = $class->new( mypublic => 2 ) }
        "constructor denies access to public attribute";
dies_ok { $obj = $class->new( myhidden => 2 ) }
        "constructor denies access to private attribute";
