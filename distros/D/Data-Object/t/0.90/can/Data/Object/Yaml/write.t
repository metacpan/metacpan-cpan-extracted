use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

write

=usage

  # given $yaml

  my $string = $yaml->write($file, $data);

  # ...

=description

The write method writes the given data structure to a file as a YAML string.

=signature

writes(Str $arg1, HashRef $arg2) : Str

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'write';

ok 1 and done_testing;