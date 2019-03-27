use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Curry

=abstract

Data-Object Code Function (Curry) Class

=synopsis

  use Data::Object::Func::Code::Curry;

  my $func = Data::Object::Func::Code::Curry->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Curry is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Curry';

ok 1 and done_testing;
