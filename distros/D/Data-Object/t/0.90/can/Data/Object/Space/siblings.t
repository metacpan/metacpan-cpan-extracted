use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

siblings

=usage

  # given $space (Foo::Bar)

  $space->siblings();

  # ['Foo::Baz', ...]

=description

The siblings method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each sibling namespace found (one level deep).

=signature

siblings() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'siblings';

ok 1 and done_testing;
