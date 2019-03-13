use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

origin

=usage

  # given $yaml

  my $origin = $yaml->origin();

  # YAML::Tiny

=description

The origin method returns the package name of the underlying YAML library used.

=signature

origin() : Str

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'origin';

ok 1 and done_testing;