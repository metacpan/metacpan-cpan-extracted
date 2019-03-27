use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Ge

=abstract

Data-Object Undef Function (Ge) Class

=synopsis

  use Data::Object::Func::Undef::Ge;

  my $func = Data::Object::Func::Undef::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Ge is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Ge';

ok 1 and done_testing;
