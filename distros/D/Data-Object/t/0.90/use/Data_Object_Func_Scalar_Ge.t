use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Ge

=abstract

Data-Object Scalar Function (Ge) Class

=synopsis

  use Data::Object::Func::Scalar::Ge;

  my $func = Data::Object::Func::Scalar::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Ge is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Ge';

ok 1 and done_testing;
