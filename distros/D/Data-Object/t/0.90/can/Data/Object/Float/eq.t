use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  # given 1.23

  $float->eq(1); # 0

=description

The eq method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

eq(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->eq(1), 0;

ok 1 and done_testing;
