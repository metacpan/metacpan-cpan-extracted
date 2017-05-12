#!perl -w

use strict;

use Test::More;

# basic testing of internal function _check_descriptor(), including
# set_class_ind() (but not set_key_ind() as that requires constructing
# RefHash['] objects. (See 3a.t for set_key_ind() testing)
#
# Also test attributes with names "class" & "key" stuff, including when class
# & key are redefined
# also test set_key_ind(), set_class_ind() with values not an identifier

use Array::To::Moose qw(:ALL :TESTING);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 37;


my $n1 = [ 1, 1, 1 ];
my $n2 = [ 2, 2, 2 ];
my $n3 = [ 3, 3, 3 ];
my $n4 = [ 4, 4, 4 ];

my $data = [ $n1, $n2, $n3, $n4 ];

#----------------------------------------
package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has [ qw( last first gender ) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

#----------------------------------------
package Person_w_Aliases;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'aliases' => (is => 'ro', isa => 'ArrayRef[Str]');

__PACKAGE__->meta->make_immutable;

#----------------------------------------
package Person_w_Visit;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'Visits' => (is => 'ro', isa => 'ArrayRef[Visit]');

__PACKAGE__->meta->make_immutable;

#----------------------------------------
package Person_w_Aliases_n_Visit;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person_w_Visit';

has 'aliases' => (is => 'ro', isa => 'ArrayRef[Str]');

__PACKAGE__->meta->make_immutable;

package main;

my ($class, $attrib, $rattrib, $sub_obj_desc);

#
# call errors
#

# simple object, no ref-attributes, no sub-objects,
my $desc = {
  class => 'Person',
  last  => 0,
  gender => 2,
};

# check returned values for simple object
lives_ok {
   ($class, $attrib, $rattrib, $sub_obj_desc) = _check_descriptor($data, $desc)
         } '_check_descriptor(Person) OK';

is($class, 'Person', "_check_descriptor()  returns class Person OK");

is_deeply($attrib, { 'last', 0, 'gender', 2 },
    "_check_descriptor(Person)  returns \$attrib OK");

is(@$rattrib, 0, "_check_descriptor() no ref attributes in Person OK");

ok(keys %$sub_obj_desc == 0, "_check_descriptor() no subobj in Person OK");

# object with ref attributes
$desc = {
  class   => 'Person_w_Aliases',
  last    => 0,
  first   => 1,
  aliases => [2],
};

lives_ok {
  ($class, $attrib, $rattrib, $sub_obj_desc) = _check_descriptor($data, $desc);
         } '_check_descriptor(Person_w_Alias) OK';

is($class, 'Person_w_Aliases',
              "_check_descriptor()  returns class Person_w_Alias OK");

is_deeply($attrib, { 'last', 0, 'first', 1 },
    "_check_descriptor(Person_w_Aliases)  returns \$attrib OK");

is_deeply($rattrib, { 'aliases', 2 },
    "_check_descriptor(Person_w_Aliases)  returns \$rattrib OK");

ok(keys %$sub_obj_desc == 0,
                "_check_descriptor() no subobj in Person_w_Alias");

# object with a sub-object
my $subdesc = {
  class => 'Visit',
  date  => 3,
};
$desc = { class  => 'Person_w_Visit',
          last   => 0,
          gender => 2,
          Visits => $subdesc,
};

lives_ok {
  ($class, $attrib, $rattrib, $sub_obj_desc) =
                _check_descriptor($data, $desc);
         } '_check_descriptor(Person_w_Visit) OK';

is($class, 'Person_w_Visit',
              "_check_descriptor()  returns class Person_w_Visit OK");

is_deeply($attrib, { 'last', 0, 'gender', 2 },
    "_check_descriptor(Person_w_Visit)  returns \$attrib OK");

is(@$rattrib, 0,
    "_check_descriptor() no ref attributes in Person_w_Visit OK");

is_deeply($sub_obj_desc, { 'Visits' => $subdesc },
      "_check_descriptor() Person_w_Visit \$sub_obj_desc OK");

# object with ref attrib and a sub-object 
$desc = {
  class   => 'Person_w_Aliases_n_Visit',
  last    => 0,
  first   => 1,
  aliases => [2],
  Visits => $subdesc,
};

lives_ok {
  ($class, $attrib, $rattrib, $sub_obj_desc) =
                  _check_descriptor($data, $desc);
         } '_check_descriptor(Person_w_Aliases_n_Visit) OK';

is($class, 'Person_w_Aliases_n_Visit',
              "_check_descriptor()  returns class Person_w_Aliases_n_Visit OK");

is_deeply($attrib, { 'last', 0, 'first', 1 },
    "_check_descriptor(Person_w_Aliases_n_Visit)  returns \$attrib OK");

is_deeply($rattrib, { 'aliases', 2 },
    "_check_descriptor(Person_w_Aliases_n_Visit)  returns \$rattrib OK");

is_deeply($sub_obj_desc, { 'Visits' => $subdesc },
      "_check_descriptor() Person_w_Aliases_n_Visit \$sub_obj_desc OK");


# "class => ..." and "key => ..." tests

throws_ok {
  _check_descriptor($data, { last => 0, gender => 2 });
         } qr/No class descriptor 'class =>/,
           '_check_attributes() No Class';

throws_ok {
  _check_descriptor($data, { class => '', last => 0, gender => 2 });
         } qr/No class descriptor 'class =>/,
           '_check_descriptor() empty Class';

# check that when we redefine the 'class' keyword it shows up in the error
# messages
set_class_ind('_klass');

lives_ok {
   _check_descriptor($data, { _klass => 'Person', last  => 0, gender => 2 })
         } "_check_descriptor(Person) set 'class' indicator to '_klass'";

throws_ok {
  _check_descriptor($data, { last => 0, gender => 2 });
         } qr/No class descriptor '_klass =>/,
           '_check_attributes() No _klass OK';

# set it back to default
set_class_ind();

lives_ok {
   _check_descriptor($data, { class => 'Person', last  => 0, gender => 2 })
         } "_check_descriptor(Person) reset 'class' indicator";

# end testing of set_class_ind()

throws_ok {
  _check_descriptor($data, {
                          # no 'class'
                          last => 0, gender => 2
                        }
                );
         } qr/No class descriptor 'class =>/,
           "_check_attributes() reset class ind to default: 'No class' OK";

throws_ok {
  _check_descriptor($data, { class => 'ePrson', last => 0, gender => 2 });
         } qr/Class 'ePrson' not defined/,
           '_check_descriptor() Class undefined';

throws_ok {
  _check_descriptor($data, { class => 'Person', name => 0, gender => 2 });
         } qr/Attribute 'name' not in 'Person' object/,
           '_check_descriptor() wrong attribute name';

# construct two classes with attrib 'class' and 'CLASS'
package Obj_Attr_class;
use namespace::autoclean;
use Moose;

has [ qw( name class ) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package Obj_Attr_CLASS;
use namespace::autoclean;
use Moose;

has [ qw( name CLASS ) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package main;

throws_ok {
  _check_descriptor($data,{ class => 'Obj_Attr_class', name => 0 })
          } qr/The 'Obj_Attr_class' object has an attribute called 'class'/,
            "_check_descriptor() object with attribute called 'class'";

# fix this with set_class_ind()
set_class_ind('CLASS');

lives_ok {
  _check_descriptor($data,{ CLASS => 'Obj_Attr_class', name => 0 })
         }
          "object with attribute called 'class' - fixed with set_class_ind()";

# but now this will fail
throws_ok {
  _check_descriptor($data,{ class => 'Obj_Attr_class', name => 0 })
          } qr/No class descriptor 'CLASS =>/,
            "_check_descriptor() no class when 'class' changed to 'CLASS'";

# and this too
throws_ok {
  _check_descriptor($data,{ CLASS => 'Obj_Attr_CLASS', name => 0 })
          } qr/The 'Obj_Attr_CLASS' object has an attribute called 'CLASS'/,
            "_check_descriptor() object with attribute called 'CLASS'";

# reset the class indicator
set_class_ind();

# construct two classes with attribs 'key' and 'KEY'
package Obj_Attr_key;
use namespace::autoclean;
use Moose;

has [ qw( name key ) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package Obj_Attr_KEY;
use namespace::autoclean;
use Moose;

has [ qw( name KEY ) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package main;

throws_ok {
  _check_descriptor($data,
      { class => 'Obj_Attr_key', name => 0, key => 2 })
          } qr/The 'Obj_Attr_key' object has an attribute called 'key'/,
            "_check_descriptor() object with attribute called 'key'";

# fix by setting key indicator
set_key_ind('KEY');

lives_ok {
  _check_descriptor($data, { class => 'Obj_Attr_key', name => 0, key => 2 })
         } "object with attribute called 'key' - fixed with set_key_ind()";

# key => ... isn't required, so can't do the same tests as with class => ...
# without constructing an object and testing if its the correct HashRef[']
# (tested somewhere else?)

# but we can do this test
throws_ok {
  _check_descriptor($data,
      { class => 'Obj_Attr_KEY', name => 0, KEY => 2 })
          } qr/The 'Obj_Attr_KEY' object has an attribute called 'KEY'/,
            "_check_descriptor() object with attribute called 'KEY'";

# check that set_class_ind() and set_key_ind() do the right thing with bad args
throws_ok {
  set_class_ind(' ')
          } qr/set_class_ind\(' '\) not a legal identifier/,
          "set_class_ind() not a legal identifier";

throws_ok {
  set_key_ind(' ')
          } qr/set_key_ind\(' '\) not a legal identifier/,
          "set_key_ind() not a legal identifier";

