use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

values

=usage

  # given [1..5]

  $array->values; # [1,2,3,4,5]

=description

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container. This method returns a L<Data::Object::Array> object.

=signature

values(Str $arg1) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->values(), [1,2,3,4,5];

ok 1 and done_testing;
