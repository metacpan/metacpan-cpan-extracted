use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Defined

=abstract

Data-Object Undef Function (Defined) Class

=synopsis

  use Data::Object::Func::Undef::Defined;

  my $func = Data::Object::Func::Undef::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Defined is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Defined';

ok 1 and done_testing;
