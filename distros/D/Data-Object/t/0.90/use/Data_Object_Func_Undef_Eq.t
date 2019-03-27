use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Eq

=abstract

Data-Object Undef Function (Eq) Class

=synopsis

  use Data::Object::Func::Undef::Eq;

  my $func = Data::Object::Func::Undef::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Eq is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Eq';

ok 1 and done_testing;
