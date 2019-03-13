use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

list

=usage

  # given $array

  my $list = $array->list;

=description

The list method returns a shallow copy of the underlying array reference as an
array reference. This method return a L<Data::Object::Array> object.

=signature

list() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply [$data->list()], [1..5];

ok 1 and done_testing;
