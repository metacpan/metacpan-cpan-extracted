use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given 99

  $number->gt(50); # 1

=description

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

gt(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->gt(12), 0;

ok 1 and done_testing;
