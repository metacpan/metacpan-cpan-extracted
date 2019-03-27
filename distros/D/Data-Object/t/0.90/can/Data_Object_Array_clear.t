use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

clear

=usage

  # given ['a'..'g']

  $array->clear; # []

=description

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Undef> object. This method is an alias to the empty method.
Note: This method modifies the array.

=signature

clear() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->clear(), [];

ok 1 and done_testing;
