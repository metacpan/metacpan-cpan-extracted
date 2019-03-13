use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_float

=usage

  # given 5.25;

  $object = data_float 5.25;
  $object->isa('Data::Object::Float');

=description

The data_float function returns a L<Data::Object::Float> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_float> function is an alias to this function.

=signature

data_float(Str $arg1) : DoFloat

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_float';

ok 1 and done_testing;
