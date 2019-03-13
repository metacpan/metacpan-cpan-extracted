use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::String

=abstract

Data-Object String Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::String;

  register Data::Object::Type::String;

  1;

=description

Type constraint for validating L<Data::Object::String> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::String";

ok 1 and done_testing;
