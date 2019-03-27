use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pop

=usage

  # given [1..5]

  $array->pop; # 5

=description

The pop method returns the last element of the array shortening it by one. Note,
this method modifies the array. This method returns a data type object to be
determined after execution. Note: This method modifies the array.

=signature

pop() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->pop(), 5;

ok 1 and done_testing;
