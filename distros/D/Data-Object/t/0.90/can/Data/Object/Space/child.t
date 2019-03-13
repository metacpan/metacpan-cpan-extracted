use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

child

=usage

  # given $space (Foo::Bar)

  $space->child('baz');

  # Foo::Bar::Baz

=description

The child method returns a new L<Data::Object::Space> object for the child
package namespace.

=signature

child(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'child';

ok 1 and done_testing;
