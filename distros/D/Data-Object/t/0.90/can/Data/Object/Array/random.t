use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

random

=usage

  # given [1..5]

  $array->random; # 4

=description

The random method returns a random element from the array. This method returns a
data type object to be determined after execution.

=signature

random() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

my $rand = $data->random();

ok $rand >= 1 && $rand <= 5;

ok 1 and done_testing;
