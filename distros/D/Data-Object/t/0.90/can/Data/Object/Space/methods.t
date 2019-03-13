use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

methods

=usage

  # given Foo/Bar

  $space->methods();

  # [,...]

=description

The methods method searches the package namespace for methods and returns
their names.

=signature

methods() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'methods';

ok 1 and done_testing;
