use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Gt

=abstract

Data-Object Undef Function (Gt) Class

=synopsis

  use Data::Object::Func::Undef::Gt;

  my $func = Data::Object::Func::Undef::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Gt is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Gt';

ok 1 and done_testing;
