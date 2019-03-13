use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rsort

=usage

  # given ['a'..'d']

  $array->rsort; # ['d','c','b','a']

=description

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse. This method returns a L<Data::Object::Array>
object.

=signature

rsort() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'d']);

is_deeply $data->rsort(), ['d','c','b','a'];

ok 1 and done_testing;
