use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Role::Codifiable

=abstract

Data-Object Codifiable Role

=synopsis

  use Data::Object Class;

  with Data::Object::Role::Codifiable;

=description

Data::Object::Role::Codifiable is a role which provides functionality for
converting a specially formatted strings into code references.

=cut

# TESTING

use_ok 'Data::Object::Role::Codifiable';

ok 1 and done_testing;
