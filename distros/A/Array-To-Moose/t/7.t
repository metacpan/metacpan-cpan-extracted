#!perl -w

use strict;

# test errors caught at the ATM level, but also 'class' and 'key' clashes,
# and desc attribs being refs, all of which are actually detected
# by _check_attribs(),  and not ATM

use Test::More;

use Array::To::Moose qw(:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 11;

#----------------------------------------
package Patient;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(last first gender) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;
package main;

my $data = [ [1, 2, 3, 4] ];

throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'Patient' }
                           )
          } qr/no attributes with column numbers in descriptor:/,
          "no numeric attributes";

#----------------------------------------
# using set_class_ind()

package ObjWclass;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(class other) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package main;

throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'ObjWclass', other => 0 }
                           )
          } qr/The 'ObjWclass' object has an attribute called 'class'/,
          "Object has 'class' attribute";

set_class_ind('_CLASS_');
lives_ok { array_to_moose (
      data => $data,
      desc => { _CLASS_ => 'ObjWclass', other => 1 }
                           )
          } "Redefined 'key' keyword";

# remember to reset
set_class_ind();

#----------------------------------------
# using set_key_ind()

package ObjWkey;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(key other) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package main;

# only get error if class has key AND desc has key ...
lives_ok { array_to_moose ( data => $data,
                             desc => { class => 'ObjWkey', other => 0 }
                           )
          } "Object has 'key' attribute but 'desc => ...' doesn't";

# ... like this
throws_ok { array_to_moose (
      data => $data,
      desc => { class => 'ObjWkey', key => 0, other => 1 }
                           )
          } qr/The 'ObjWkey' object has an attribute called 'key'/,
          "Object and desc both have 'key'";

# solved by:
set_key_ind('_KEY_');

lives_ok { array_to_moose (
      data => $data,
      desc => { class => 'ObjWkey', _KEY_ => 0, key => 0, other => 1 }
                           )
          } "Object and desc both have 'key', solved by set_key_ind()";

# But resetting...
set_key_ind();

# ... brings back error
throws_ok { array_to_moose (
    data => $data,
    desc => { class => 'ObjWkey', key => 0, other => 1 }
                           )
        } qr/The 'ObjWkey' object has an attribute called 'key'/,
        "Object and desc both have 'key' - error returns after set_key_ind()";



#----------------------------------------
my $tmp = "Hello";
throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'Patient', last => \$tmp }
                           )
          } qr/attribute 'last' can't be a 'SCALAR' reference/,
          "non-sub attribute is SCALAR ref";

throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'Patient', last => sub { } }
                           )
          } qr/attribute 'last' can't be a 'CODE' reference/,
          "non-sub attribute is CODE ref";

#----------------------------------------
package Other;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(other) ] => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;
package main;

package Typeless;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(this that SubObj) ] => (is => 'rw');  # no types!

__PACKAGE__->meta->make_immutable;
package main;

throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'Typeless',
                                       that => 0,
                                       SubObj => {
                                         other => 1,
                                       }
                                     }
                                      )
                      } qr/Moose class 'Typeless', attrib 'that' has no type/,
                      "typeless sub-object attribute";

package Typeless1;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(this that) ] => (is => 'rw', isa => 'Str');
has         'SubObj'  => (is => 'rw');  # no types!

__PACKAGE__->meta->make_immutable;
package main;

throws_ok { array_to_moose ( data => $data,
                             desc => { class => 'Typeless1',
                                       that => 0,
                                       SubObj => {
                                         other => 1,
                                       }
                                     }
                                      )
                      } qr/Moose attribute 'SubObj' has no type/,
                      "typeless sub-object attribute";

