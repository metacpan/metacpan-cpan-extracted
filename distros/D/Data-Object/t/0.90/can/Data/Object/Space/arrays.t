use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

arrays

=usage

  # given Foo/Bar

  $space->arrays();

  # [,...]

=description

The arrays method searches the package namespace for arrays and returns
their names.

=signature

arrays() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'arrays';

ok 1 and done_testing;
