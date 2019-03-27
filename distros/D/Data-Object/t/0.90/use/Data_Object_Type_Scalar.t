use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Scalar

=abstract

Data-Object Scalar Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Scalar;

  register Data::Object::Type::Scalar;

  1;

=description

Type constraint for validating L<Data::Object::Scalar> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Scalar";

ok 1 and done_testing;
