use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

append

=usage

  # given $space (Foo::Bar)

  $space->append('baz');

  "$space"

  # Foo::Bar::Baz

=description

The append method modifies the object by appending to the package namespace
parts.

=signature

append(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'append';

ok 1 and done_testing;
