use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

path

=usage

  # given $space (Foo::Bar)

  $space->path();

  # Foo/Bar

  $space->path('lib/%s');

  # lib/Foo/Bar

=description

The path method returns a path string for the package namespace. This method
optionally takes a format string.

=signature

path(Str $arg1) : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'path';

ok 1 and done_testing;
