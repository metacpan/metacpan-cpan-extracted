use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

sibling

=usage

  # given $space (Foo::Bar)

  $space->sibling('Baz');

  # Foo::Baz

=description

The sibling method returns a new L<Data::Object::Space> object for the sibling
package namespace.

=signature

sibling(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'sibling';

ok 1 and done_testing;
