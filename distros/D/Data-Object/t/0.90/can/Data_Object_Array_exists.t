use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exists

=usage

  # given [1,2,3,4,5]

  $array->exists(5); # 0; false
  $array->exists(0); # 1; true

=description

The exists method returns true if the element within the array at the index
specified by the argument exists, otherwise it returns false. This method
returns a L<Data::Object::Number> object.

=signature

exists(Int $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1,2,3,4,5]);

is_deeply $data->exists(5), 0;

is_deeply $data->exists(0), 1;

ok 1 and done_testing;
