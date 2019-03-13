use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Neg

=abstract

Data-Object Number Function (Neg) Class

=synopsis

  use Data::Object::Func::Number::Neg;

  my $func = Data::Object::Func::Number::Neg->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Neg is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Neg';

ok 1 and done_testing;
