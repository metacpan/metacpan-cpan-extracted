use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepend

=usage

  # given $space (Foo::Bar)

  $space->prepend('via');

  "$space"

  # Via::Foo::Bar

=description

The prepend method modifies the object by prepending to the package namespace
parts.

=signature

prepend(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'prepend';

ok 1 and done_testing;
