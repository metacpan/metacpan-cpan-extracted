use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

call

=usage

  # given $space (Foo::Bar)

  $space->call(@args);

  # ...

=description

The call method attempts to call the given subroutine on the package namespace and if
successful returns the resulting value.

=signature

call(Any @args) : Any

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'call';

ok 1 and done_testing;
