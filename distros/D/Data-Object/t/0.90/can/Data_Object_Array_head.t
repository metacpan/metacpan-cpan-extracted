use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

head

=usage

  # given [9,8,7,6,5]

  my $head = $array->head; # 9

=description

The head method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=signature

head() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([9,8,7,6,5]);

is_deeply $data->head(), 9;

ok 1 and done_testing;
