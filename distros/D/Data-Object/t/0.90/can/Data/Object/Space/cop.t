use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

cop

=usage

  # given $space (Foo::Bar)

  $space->cop(@args);

  # ...

=description

The cop method attempts to curry the given subroutine on the package namespace and if
successful returns a closure.

=signature

cop(Any @args) : CodeRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'cop';

ok 1 and done_testing;
