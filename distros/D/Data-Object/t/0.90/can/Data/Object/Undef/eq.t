use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  # given $undef

  $undef->eq; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

eq(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Undef';

my $data = Data::Object::Undef->new(undef);

ok !eval { $data->eq() };

ok 1 and done_testing;
