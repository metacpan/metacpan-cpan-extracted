use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

slice

=usage

  # given [1..5]

  $array->slice(2,4); # [3,5]

=description

The slice method returns an array reference containing the elements in the
array at the index(es) specified in the arguments. This method returns a
L<Data::Object::Array> object.

=signature

slice(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->slice(2,4), [3,5];

ok 1 and done_testing;
