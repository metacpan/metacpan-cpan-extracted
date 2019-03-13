use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

load

=usage

  # given $json

  my $data = $json->load($string);

  # {,...}

=description

The load method converts a string into a Perl data structure.

=signature

load(Str $arg1) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'load';

ok 1 and done_testing;