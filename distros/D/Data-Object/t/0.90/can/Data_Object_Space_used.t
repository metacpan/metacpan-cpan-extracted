use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

used

=usage

  # given $space (Foo::Bar)

  $space->used();

  # undef, unless Foo::Bar is in %INC

=description

The used method searches C<%INC> for the package namespace and if found returns
the filepath and complete filepath for the loaded package, otherwise returns
undef.

=signature

used() : ArrayRef | Undef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'used';

ok 1 and done_testing;
