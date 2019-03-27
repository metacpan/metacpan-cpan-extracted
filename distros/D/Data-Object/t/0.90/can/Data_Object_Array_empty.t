use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

empty

=usage

  # given ['a'..'g']

  $array->empty; # []

=description

The empty method drops all elements from the array. This method returns a
L<Data::Object::Array> object. Note: This method modifies the array.

=signature

empty() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'g']);

is_deeply $data->empty(), [];

ok 1 and done_testing;
