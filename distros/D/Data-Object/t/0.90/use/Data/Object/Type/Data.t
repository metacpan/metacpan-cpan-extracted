use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Data

=abstract

Data-Object Data Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Data;

  register Data::Object::Type::Data;

  1;

=description

Type constraint for validating L<Data::Object::Data> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::Data";

ok 1 and done_testing;
