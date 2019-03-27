use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

tail

=usage

  # given [1..5]

  $array->tail; # [2,3,4,5]

=description

The tail method returns an array reference containing the second through the
last elements in the array omitting the first. This method returns a
L<Data::Object::Array> object.

=signature

tail() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->tail(), [2,3,4,5];

ok 1 and done_testing;
