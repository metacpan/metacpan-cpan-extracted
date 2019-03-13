use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

write

=usage

  # given $json

  my $string = $json->write($file, $data);

  # ...

=description

The write method writes the given data structure to a file as a JSON string.

=signature

writes(Str $arg1, HashRef $arg2) : Str

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'write';

ok 1 and done_testing;