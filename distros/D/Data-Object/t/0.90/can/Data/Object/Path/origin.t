use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

origin

=usage

  # given $origin

  $path->origin();

  # Path::Tiny

=description

The origin method returns the package name of the proxy used.

=signature

origin() : Str

=type

method

=cut

# TESTING

use Data::Object::Path;

can_ok 'Data::Object::Path', 'origin';

ok 1 and done_testing;