use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given 1.23

  $float->gt(1); # 1

=description

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

gt(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->gt(1), 1;

ok 1 and done_testing;
