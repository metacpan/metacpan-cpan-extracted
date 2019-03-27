use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hashes

=usage

  # given Foo/Bar

  $space->hashes();

  # [,...]

=description

The hashes method searches the package namespace for hashes and returns
their names.

=signature

hashes() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'hashes';

ok 1 and done_testing;
