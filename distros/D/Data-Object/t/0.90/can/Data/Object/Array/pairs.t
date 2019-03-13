use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pairs

=usage

  # given [1..5]

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=description

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=signature

pairs() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->pairs(), [[0,1],[1,2],[2,3],[3,4],[4,5]];

ok 1 and done_testing;
