use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  # given $array

  $array->eq; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

eq(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

ok !eval { $data->eq() };

ok 1 and done_testing;
