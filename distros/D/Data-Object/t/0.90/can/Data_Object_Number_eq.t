use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  # given 12345

  $number->eq(12346); # 0

=description

The eq method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

eq(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->eq(12), 1;

is_deeply $data->eq(11), 0;

ok 1 and done_testing;
