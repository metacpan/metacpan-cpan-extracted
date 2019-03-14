use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pow

=usage

  # given 12345

  $number->pow(3); # 1881365963625

=description

The pow method returns a number, the result of a math operation, which is the
number to the power of the argument. This method returns a
L<Data::Object::Number> object.

=signature

pow() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->pow(0), 1;

is_deeply $data->pow(1), 12;

is_deeply $data->pow(2), 144;

ok 1 and done_testing;
