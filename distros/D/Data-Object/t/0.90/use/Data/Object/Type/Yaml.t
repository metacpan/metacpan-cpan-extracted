use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Yaml

=abstract

Data-Object Yaml Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Yaml;

  register Data::Object::Type::Yaml;

  1;

=description

Type constraint for validating L<Data::Object::Yaml> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::Yaml";

ok 1 and done_testing;
