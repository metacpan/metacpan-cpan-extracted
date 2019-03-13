use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pairs_hash

=usage

  # given [1..5]

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=description

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=signature

pairs() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->pairs_hash(), {0=>1,1=>2,2=>3,3=>4,4=>5};

ok 1 and done_testing;
