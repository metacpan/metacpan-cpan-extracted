use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_any

=usage

  # given 0;

  $object = data_any 0;
  $object->isa('Data::Object::Any');

=description

The data_any function returns a L<Data::Object::Any> instance which
wraps the provided data type and can be used to perform operations on the data.
The C<type_any> function is an alias to this function.

=signature

data_any(Any $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_any';

ok 1 and done_testing;
