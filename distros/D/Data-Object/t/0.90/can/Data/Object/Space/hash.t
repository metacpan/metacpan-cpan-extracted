use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hash

=usage

  # given Foo/Bar

  $space->hash('EXPORT_TAGS');

  # (,...)

=description

The hashes method returns the value for the given package hash variable name.

=signature

hash(Str $arg1) : Any

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'hash';

ok 1 and done_testing;
