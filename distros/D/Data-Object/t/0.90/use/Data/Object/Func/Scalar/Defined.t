use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Defined

=abstract

Data-Object Scalar Function (Defined) Class

=synopsis

  use Data::Object::Func::Scalar::Defined;

  my $func = Data::Object::Func::Scalar::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Defined is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Defined';

ok 1 and done_testing;
