use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Func

=abstract

Data-Object Func Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Func;

  register Data::Object::Type::Func;

  1;

=description

Type constraint for validating L<Data::Object::Func> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Func";

ok 1 and done_testing;
