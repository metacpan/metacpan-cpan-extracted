use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

id

=usage

  # given $space (Foo::Bar)

  $space->id;

  # Foo_Bar

=description

The id method returns the fully-qualified package name as a label.

=signature

id() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'id';

ok 1 and done_testing;
