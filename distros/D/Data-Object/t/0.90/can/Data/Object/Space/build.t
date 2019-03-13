use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

build

=usage

  # given $space (Foo::Bar)

  $space->build(@args);

  # bless(..., 'Foo::Bar')

=description

The build method attempts to call C<new> on the package namespace and if
successful returns the resulting object.

=signature

build(Any @args) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'build';

ok 1 and done_testing;
