use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  # given $space (Foo::Bar)

  $space->name;

  # Foo::Bar

=description

The name method returns the fully-qualified package name.

=signature

name() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'name';

ok 1 and done_testing;
