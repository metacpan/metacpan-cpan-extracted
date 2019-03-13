use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

count

=usage

  # given [1..5]

  $array->count; # 5

=description

The count method returns the number of elements within the array. This method
returns a L<Data::Object::Number> object.

=signature

count() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->count(), 5;

ok 1 and done_testing;
