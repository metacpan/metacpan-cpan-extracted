use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

size

=usage

  # given [1..5]

  $array->size; # 5

=description

The size method is an alias to the length method. This method returns a
L<Data::Object::Number> object. This method is an alias to the length method.

=signature

size() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->size(), 5;

ok 1 and done_testing;
