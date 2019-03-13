use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_json

=usage

  # given $string

  my $data = data_json($string);

  # given $data

  my $string = data_json($data);

=description

The data_json function encodes Perl data to JSON or decodes JSON strings to
Perl.

=signature

data_json(Any @args) : Any

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok 'Data::Object::Export', 'data_json';

ok 1 and done_testing;