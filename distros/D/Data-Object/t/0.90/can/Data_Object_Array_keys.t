use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

keys

=usage

  # given ['a'..'d']

  $array->keys; # [0,1,2,3]

=description

The keys method returns an array reference consisting of the indicies of the
array. This method returns a L<Data::Object::Array> object.

=signature

keys() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'d']);

is_deeply $data->keys(), [0,1,2,3];

ok 1 and done_testing;
