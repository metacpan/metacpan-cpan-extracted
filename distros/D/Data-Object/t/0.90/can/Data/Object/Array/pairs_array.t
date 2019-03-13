use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pairs_array

=usage

  # given [1..5]

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=description

The pairs_array method returns an array reference consisting of array references
where each sub-array reference has two elements corresponding to the index and
value of each element in the array. This method returns a L<Data::Object::Array>
object.

=signature

pairs() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->pairs_array(), [[0,1],[1,2],[2,3],[3,4],[4,5]];

ok 1 and done_testing;
