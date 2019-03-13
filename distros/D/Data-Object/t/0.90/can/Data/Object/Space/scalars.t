use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

scalars

=usage

  # given Foo/Bar

  $space->scalars();

  # [,...]

=description

The scalars method searches the package namespace for scalars and returns
their names.

=signature

scalars() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'scalars';

ok 1 and done_testing;
