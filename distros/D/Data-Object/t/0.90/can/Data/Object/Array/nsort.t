use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

nsort

=usage

  # given [5,4,3,2,1]

  $array->nsort; # [1,2,3,4,5]

=description

The nsort method returns an array reference containing the values in the array
sorted numerically. This method returns a L<Data::Object::Array> object.

=signature

nsort() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([5,4,3,2,1]);

is_deeply $data->nsort(), [1,2,3,4,5];

ok 1 and done_testing;
