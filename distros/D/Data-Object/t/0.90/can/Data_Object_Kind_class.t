use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

class

=usage

  # given $self (Foo::Bar)

  $self->class();

  # Foo::Bar (string)

=description

The class method returns the class name for the given class or object.

=signature

class() : Str

=type

method

=cut

# TESTING

use Data::Object::Kind;

can_ok 'Data::Object::Kind', 'class';

ok 1 and done_testing;
