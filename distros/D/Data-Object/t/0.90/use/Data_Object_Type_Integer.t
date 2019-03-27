use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Integer

=abstract

Data-Object Integer Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Integer;

  register Data::Object::Type::Integer;

  1;

=description

Type constraint for validating L<Data::Object::Integer> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Integer";

ok 1 and done_testing;
