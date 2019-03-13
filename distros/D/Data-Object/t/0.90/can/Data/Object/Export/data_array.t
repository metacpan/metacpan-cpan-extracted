use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_array

=usage

  # given [2..5];

  $data = data_array [2..5];
  $data->isa('Data::Object::Array');

=description

The data_array function returns a Data::Object::Array instance which wraps the
provided data type and can be used to perform operations on the data. The
type_array function is an alias to this function.

=signature

data_array(ArrayRef $arg1) : DoArray

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_array';

ok 1 and done_testing;
