use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_scalar

=usage

  # given \*main;

  $object = data_scalar \*main;
  $object->isa('Data::Object::Scalar');

=description

The data_scalar function returns a L<Data::Object::Scalar> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_scalar> function is an alias to this function.

=signature

data_scalar(Any $arg1) : DoScalar

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_scalar';

ok 1 and done_testing;
