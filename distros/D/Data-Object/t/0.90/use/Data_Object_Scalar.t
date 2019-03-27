use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Scalar

=abstract

Data-Object Scalar Class

=synopsis

  use Data::Object::Scalar;

  my $scalar = Data::Object::Scalar->new(\*main);

=description

Data::Object::Scalar provides routines for operating on Perl 5 scalar
objects. Scalar methods work on data that meets the criteria for being a scalar.

=cut

use_ok "Data::Object::Scalar";

ok 1 and done_testing;
