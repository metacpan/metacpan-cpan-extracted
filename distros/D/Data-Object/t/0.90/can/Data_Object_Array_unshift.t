use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

unshift

=usage

  # given [1..5]

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

=description

The unshift method prepends the array by pushing the agruments onto it and
returns itself. This method returns a data type object to be determined after
execution. Note: This method modifies the array.

=signature

unshift() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->unshift(-2,-1,0), [-2,-1,0,1,2,3,4,5];

ok 1 and done_testing;
