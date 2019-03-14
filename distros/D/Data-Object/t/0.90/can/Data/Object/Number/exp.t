use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exp

=usage

  # given 0

  $number->exp; # 1

  # given 1

  $number->exp; # 2.71828182845905

  # given 1.5

  $number->exp; # 4.48168907033806

=description

The exp method returns e (the natural logarithm base) to the power of the
number. This method returns a L<Data::Object::Float> object.

=signature

exp() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->exp(), 162754.791419004;

ok 1 and done_testing;
