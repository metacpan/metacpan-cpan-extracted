use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

reverse

=usage

  # given [1..5]

  $array->reverse; # [5,4,3,2,1]

=description

The reverse method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=signature

reverse() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->reverse(), [5,4,3,2,1];

ok 1 and done_testing;
