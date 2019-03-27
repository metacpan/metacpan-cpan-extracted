use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Role::Catchable

=abstract

Data-Object Catchable Role

=synopsis

  use Data::Object 'Class';

  with Data::Object::Role::Catchable;

=description

Data::Object::Role::Catchable is a role which provides functionality for
catching thrown exceptions.

=cut

# TESTING

use_ok 'Data::Object::Role::Catchable';

ok 1 and done_testing;
