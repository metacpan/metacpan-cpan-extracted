use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

invert

=usage

  # given [1..5]

  $array->invert; # [5,4,3,2,1]

=description

The invert method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=signature

invert() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->invert(), [5,4,3,2,1];

ok 1 and done_testing;
