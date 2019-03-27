use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

root

=usage

  # given $space (root => 'Foo', parts => 'Bar')

  $space->root();

  # ['Foo']

=description

The root method returns the root package namespace segments (parts). Sometimes
separating the C<root> from the C<parts> helps identify how subsequent child
objects were derived.

=signature

root() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'root';

ok 1 and done_testing;
