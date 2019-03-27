use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

routines

=usage

  # given Foo/Bar

  $space->routines();

  # [,...]

=description

The routines method searches the package namespace for routines and returns
their names.

=signature

routines() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'routines';

ok 1 and done_testing;
