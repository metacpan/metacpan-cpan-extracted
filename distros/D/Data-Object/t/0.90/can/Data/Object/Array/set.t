use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  # given [1..5]

  $array->set(4,6); # [1,2,3,4,6]

=description

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second argument.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=signature

set(Str $arg1, Any $arg2) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->set(4,6), 6;

ok 1 and done_testing;
