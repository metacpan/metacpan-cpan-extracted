use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Pow

=abstract

Data-Object Number Function (Pow) Class

=synopsis

  use Data::Object::Func::Number::Pow;

  my $func = Data::Object::Func::Number::Pow->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Pow is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Pow';

ok 1 and done_testing;
