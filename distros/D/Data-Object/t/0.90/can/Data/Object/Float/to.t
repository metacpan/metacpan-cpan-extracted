use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

to

=usage

  # given 1.23

  $float->to(2); # [1,2]
  $float->to(0); # [1,0]

=description

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object. This method returns a
L<Data::Object::Array> object.

=signature

to(Int $arg1) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->to(2), [1,2];

is_deeply $data->to(0), [1,0];

ok 1 and done_testing;
