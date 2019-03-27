use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

last

=usage

  # given [1..5]

  $array->last; # 5

=description

The last method returns the value of the last element in the array. This method
returns a data type object to be determined after execution.

=signature

last() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->last(), 5;

ok 1 and done_testing;
