use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Sqrt

=abstract

Data-Object Number Function (Sqrt) Class

=synopsis

  use Data::Object::Func::Number::Sqrt;

  my $func = Data::Object::Func::Number::Sqrt->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Sqrt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Sqrt';

ok 1 and done_testing;
