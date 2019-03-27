use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

routine

=usage

  # given Foo/Bar

  $space->routine('import');

  # ...

=description

The routine method returns the subroutine reference for the given subroutine
name.

=signature

routine(Str $arg1) : CodeRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'routine';

ok 1 and done_testing;
