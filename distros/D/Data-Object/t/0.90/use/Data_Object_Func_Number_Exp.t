use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Exp

=abstract

Data-Object Number Function (Exp) Class

=synopsis

  use Data::Object::Func::Number::Exp;

  my $func = Data::Object::Func::Number::Exp->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Exp is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Exp';

ok 1 and done_testing;
