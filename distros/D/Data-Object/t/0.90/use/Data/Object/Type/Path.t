use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Path

=abstract

Data-Object Path Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Path;

  register Data::Object::Type::Path;

  1;

=description

Type constraint for validating L<Data::Object::Path> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::Path";

ok 1 and done_testing;
