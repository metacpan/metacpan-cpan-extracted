use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Eq

=abstract

Data-Object Scalar Function (Eq) Class

=synopsis

  use Data::Object::Func::Scalar::Eq;

  my $func = Data::Object::Func::Scalar::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Eq is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Eq';

ok 1 and done_testing;
