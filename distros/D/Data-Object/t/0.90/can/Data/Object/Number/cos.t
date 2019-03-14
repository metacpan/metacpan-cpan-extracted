use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

cos

=usage

  # given 12

  $number->cos; # 0.843853958732492

=description

The cos method computes the cosine of the number (expressed in radians). This
method returns a L<Data::Object::Float> object.

=signature

cos() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->cos(), 0.843853958732492;

ok 1 and done_testing;
