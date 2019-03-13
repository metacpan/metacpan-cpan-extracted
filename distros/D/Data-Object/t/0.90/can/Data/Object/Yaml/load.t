use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

load

=usage

  # given $yaml

  my $data = $yaml->load($string);

  # {,...}

=description

The load method converts a string into a Perl data structure.

=signature

load(Str $arg1) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'load';

ok 1 and done_testing;