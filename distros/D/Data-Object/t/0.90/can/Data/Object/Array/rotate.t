use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rotate

=usage

  # given [1..5]

  $array->rotate; # [2,3,4,5,1]
  $array->rotate; # [3,4,5,1,2]
  $array->rotate; # [4,5,1,2,3]

=description

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called. This method returns a L<Data::Object::Array> object.
Note: This method modifies the array.

=signature

rotate() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->rotate(), [2,3,4,5,1];

is_deeply $data->rotate(), [3,4,5,1,2];

is_deeply $data->rotate(), [4,5,1,2,3];

ok 1 and done_testing;
