use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Any

=abstract

Data-Object Any Class

=synopsis

  use Data::Object::Any;

  my $any = Data::Object::Any->new(\*main);

=description

Data::Object::Any provides routines for operating on any Perl 5 data type.

=composition

This package inherits functionality from roles, adheres to constraints defined
in specs, and implements proxy methods as documented.

=roles

This package is comprised of the following roles.

=specs

This package is adheres to the following specs.

=cut

use_ok "Data::Object::Any";

ok 1 and done_testing;
