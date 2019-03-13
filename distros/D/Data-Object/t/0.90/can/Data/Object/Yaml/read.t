use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

read

=usage

  # given $yaml

  my $data = $yaml->read($file);

  # {,...}

=description

The read method reads YAML from the given file and returns a data structure.

=signature

read(Str $arg1) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'read';

ok 1 and done_testing;