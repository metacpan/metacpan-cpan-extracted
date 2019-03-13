use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Float

=abstract

Data-Object Float Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Float;

  register Data::Object::Type::Float;

  1;

=description

Type constraint for validating L<Data::Object::Float>
objects. This type constraint is registered in the
L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::Float";

ok 1 and done_testing;
