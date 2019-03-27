use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

scalar

=usage

  # given Foo/Bar

  $space->scalar('VERSION');

  # 0.01

=description

The scalar method returns the value for the given package scalar variable name.

=signature

scalar(Str $arg1) : Any

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'scalar';

ok 1 and done_testing;
