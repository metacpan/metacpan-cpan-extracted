use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

downto

=usage

  # given 10

  $number->downto(5); # [10,9,8,7,6,5]

=description

The downto method returns an array reference containing integer decreasing
values down to and including the limit. This method returns a
L<Data::Object::Array> object.

=signature

downto(Int $arg1) : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->downto(6), [12,11,10,9,8,7,6];

ok 1 and done_testing;
