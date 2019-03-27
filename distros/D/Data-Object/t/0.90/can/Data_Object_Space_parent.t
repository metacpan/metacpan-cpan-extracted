use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parent

=usage

  # given $space (Foo::Bar)

  $space->parent();

  # Foo

=description

The parent method returns a new L<Data::Object::Space> object for the parent
package namespace.

=signature

parent() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'parent';

ok 1 and done_testing;
