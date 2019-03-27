use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete

=usage

  # given [1..5]

  $array->delete(2); # 3

=description

The delete method returns the value of the element within the array at the
index specified by the argument after removing it from the array. This method
returns a data type object to be determined after execution. Note: This method
modifies the array.

=signature

delete(Int $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->delete(2), 3;

ok 1 and done_testing;
