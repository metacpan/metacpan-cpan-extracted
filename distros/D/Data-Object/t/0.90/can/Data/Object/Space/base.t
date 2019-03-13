use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

base

=usage

  # given $space (Foo::Bar)

  $space->base();

  # Bar

=description

The base method returns the last segment of the package namespace parts.

=signature

base() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'base';

ok 1 and done_testing;
