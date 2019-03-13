use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

validation

=usage

  my $validation = $self->validation();

=description

The validation method returns truthy if type check is valid.

=signature

validation(Object $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Json';

my $data = Data::Object::Type::Json->new();

can_ok $data, 'validation';

ok 1 and done_testing;
