use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Dispatch

=abstract

Data-Object Dispatch Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Dispatch;

  register Data::Object::Type::Dispatch;

  1;

=description

Type constraint for validating L<Data::Object::Dispatch> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Dispatch";

ok 1 and done_testing;
