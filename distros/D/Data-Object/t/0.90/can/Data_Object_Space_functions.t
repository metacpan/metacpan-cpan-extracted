use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

functions

=usage

  # given Foo/Bar

  $space->functions();

  # [,...]

=description

The functions method searches the package namespace for functions and returns
their names.

=signature

functions() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'functions';

ok 1 and done_testing;
