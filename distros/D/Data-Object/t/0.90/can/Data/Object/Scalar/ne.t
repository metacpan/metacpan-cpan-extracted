use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  # given $scalar

  $scalar->ne; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

ne(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Scalar';

my $data = Data::Object::Scalar->new(12345);

ok !eval { $data->ne() };

ok 1 and done_testing;
