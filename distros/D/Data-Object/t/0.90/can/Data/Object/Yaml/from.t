use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

from

=usage

  # given $yaml

  my $data = $yaml->from($string);

  # {,...}

  my $string = $yaml->from($data);

  # '--- {foo: ...}'

=description

The from method calls C<dump> or C<load> based on the give data.

=signature

from(Any $arg1) : Any

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'from';

ok 1 and done_testing;