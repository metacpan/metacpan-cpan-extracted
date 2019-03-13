use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

file

=usage

  # given $space (Foo::Bar)

  $space->file();

  # Foo/Bar.pm

  $space->file('lib/%s');

  # lib/Foo/Bar.pm

=description

The file method returns a file string for the package namespace. This method
optionally takes a format string.

=signature

file(Str $arg1 = '%s') : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'file';

ok 1 and done_testing;
