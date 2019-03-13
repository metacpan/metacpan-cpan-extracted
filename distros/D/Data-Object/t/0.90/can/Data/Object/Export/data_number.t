use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_number

=usage

  # given 100;

  $object = data_number 100;
  $object->isa('Data::Object::Number');

=description

The data_number function returns a L<Data::Object::Number> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_number> function is an alias to this function.

=signature

data_number(Num $arg1) : DoNum

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_number';

ok 1 and done_testing;
