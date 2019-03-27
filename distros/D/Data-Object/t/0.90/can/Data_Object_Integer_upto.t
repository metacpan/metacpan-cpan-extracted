use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

upto

=usage

  # given 1

  $integer->upto(2); # [1,2]

=description

The upto method returns an array reference containing integer increasing
values up to and including the limit. This method returns a
L<Data::Object::Array> object.

=signature

upto(Int $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Integer';

my $data = Data::Object::Integer->new(1);

is_deeply $data->upto(2), [1,2];

ok 1 and done_testing;
