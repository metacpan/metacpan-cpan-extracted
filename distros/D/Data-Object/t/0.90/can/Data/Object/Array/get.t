use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  # given [1..5]

  $array->get(0); # 1;

=description

The get method returns the value of the element in the array at the index
specified by the argument. This method returns a data type object to be
determined after execution.

=signature

get(Int $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->get(0), 1;

is_deeply $data->get(1), 2;

ok 1 and done_testing;
