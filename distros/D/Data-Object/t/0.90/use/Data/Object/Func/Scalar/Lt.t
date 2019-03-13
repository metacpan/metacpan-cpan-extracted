use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Lt

=abstract

Data-Object Scalar Function (Lt) Class

=synopsis

  use Data::Object::Func::Scalar::Lt;

  my $func = Data::Object::Func::Scalar::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Lt is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Lt';

ok 1 and done_testing;
