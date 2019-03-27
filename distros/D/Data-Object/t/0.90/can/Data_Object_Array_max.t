use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

max

=usage

  # given [8,9,1,2,3,4,5]

  $array->max; # 9

=description

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=signature

max() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([8,9,1,2,3,4,5]);

is_deeply $data->max(), 9;

ok 1 and done_testing;
