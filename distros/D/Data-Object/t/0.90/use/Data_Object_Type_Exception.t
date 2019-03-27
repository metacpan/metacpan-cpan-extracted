use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Exception

=abstract

Data-Object Exception Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Exception;

  register Data::Object::Type::Exception;

  1;

=description

Type constraint for validating L<Data::Object::Exception> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Exception";

ok 1 and done_testing;
