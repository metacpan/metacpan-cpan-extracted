use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Class

=abstract

Data-Object Class Declaration

=synopsis

  package Person;

  use Data::Object Class;

  extends 'Identity';

  has fullname => (
    is => 'ro',
    isa => 'Str'
  );

  1;

=description

Data::Object::Class modifies the consuming package making it a class.

=cut

use_ok "Data::Object::Class";

ok 1 and done_testing;
