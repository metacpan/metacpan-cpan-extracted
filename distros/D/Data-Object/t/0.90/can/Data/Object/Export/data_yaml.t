use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_yaml

=usage

  # given $string

  my $data = data_yaml($string);

  # given $data

  my $string = data_yaml($data);

=description

The data_yaml function encodes Perl data to YAML or decodes YAML strings to
Perl.

=signature

data_yaml(Any @args) : Any

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok 'Data::Object::Export', 'data_yaml';

ok 1 and done_testing;