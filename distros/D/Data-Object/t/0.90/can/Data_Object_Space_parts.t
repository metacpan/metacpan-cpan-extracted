use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parts

=usage

  # given $space (Foo::Bar)

  $space->parts();

  # ['Foo', 'Bar']

=description

The parts method returns an arrayref of package namespace segments (parts).

=signature

parts() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'parts';

ok 1 and done_testing;
