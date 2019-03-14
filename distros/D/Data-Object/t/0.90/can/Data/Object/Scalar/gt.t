use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given $scalar

  $scalar->gt; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

gt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Scalar';

my $data = Data::Object::Scalar->new(12345);

ok !eval { $data->gt() };

ok 1 and done_testing;
