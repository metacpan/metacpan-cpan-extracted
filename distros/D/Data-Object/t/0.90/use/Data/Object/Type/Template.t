use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Template

=abstract

Data-Object Template Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Template;

  register Data::Object::Type::Template;

  1;

=description

Type constraint for validating L<Data::Object::Template> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

use_ok "Data::Object::Type::Template";

ok 1 and done_testing;
