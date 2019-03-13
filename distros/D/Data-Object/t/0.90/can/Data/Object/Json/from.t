use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

from

=usage

  # given $json

  my $data = $json->from($string);

  # {,...}

  my $string = $json->from($data);

  # '{"foo":...}'

=description

The from method calls C<dump> or C<load> based on the give data.

=signature

from(Any $arg1) : Any

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'from';

ok 1 and done_testing;