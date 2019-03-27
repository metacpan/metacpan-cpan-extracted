use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

variables

=usage

  # given Foo/Bar

  $space->variables();

  # [,...]

=description

The variables method searches the package namespace for variables and returns
their names.

=signature

variables() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'variables';

ok 1 and done_testing;
