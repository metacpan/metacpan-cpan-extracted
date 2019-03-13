use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

unique

=usage

  # given [1,1,1,1,2,3,1]

  $array->unique; # [1,2,3]

=description

The unique method returns an array reference consisting of the unique elements
in the array. This method returns a L<Data::Object::Array> object.

=signature

unique() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1,1,1,1,2,3,1]);

is_deeply $data->unique(), [1,2,3];

ok 1 and done_testing;
