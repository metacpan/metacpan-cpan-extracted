use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

validator

=usage

  my $validator = $data->validator();

=description

The validator method returns the built type constraint object.

=signature

validator() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'validator';

ok 1 and done_testing;
