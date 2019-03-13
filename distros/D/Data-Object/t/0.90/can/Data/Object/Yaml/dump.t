use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  # given $yaml

  my $string = $yaml->dump($data);

  # '--- {name: ...}'

=description

The dump method converts a data structure into a YAML string.

=signature

dump(HashRef $arg1) : Str

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'dump';

ok 1 and done_testing;