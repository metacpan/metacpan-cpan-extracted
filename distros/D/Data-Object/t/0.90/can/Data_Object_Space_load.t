use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

load

=usage

  # given $space (Foo::Bar)

  $space->load();

  # throws exception, unless Foo::Bar is loadable

=description

The load method check whether the package namespace is already loaded and if
not attempts to load the package. If the package is not loaded and is not
loadable, this method will throw an exception using C<croak>. If the package is
loadable, this method returns truthy with the package name.

=signature

load() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'load';

ok 1 and done_testing;
