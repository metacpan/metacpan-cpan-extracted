use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

read

=usage

  # given $json

  my $data = $json->read($file);

  # {,...}

=description

The read method reads JSON from the given file and returns a data structure.

=signature

read(Str $arg1) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'read';

ok 1 and done_testing;