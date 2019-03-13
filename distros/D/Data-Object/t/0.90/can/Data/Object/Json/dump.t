use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  # given $json

  my $string = $json->dump($data);

  # '{"foo":...}'

=description

The dump method converts a data structure into a JSON string.

=signature

dump(HashRef $arg1) : Str

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'dump';

ok 1 and done_testing;