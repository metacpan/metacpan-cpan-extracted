use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given 1

  $integer->gt(1); # 0

=description

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

gt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Integer';

my $data = Data::Object::Integer->new(1);

is_deeply $data->gt(1), 0;

ok 1 and done_testing;
