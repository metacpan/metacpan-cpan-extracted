use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

origin

=usage

  # given $json

  my $origin = $json->origin();

  # JSON::Tiny

=description

The origin method returns the package name of the underlying JSON library used.

=signature

origin() : Str

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'origin';

ok 1 and done_testing;