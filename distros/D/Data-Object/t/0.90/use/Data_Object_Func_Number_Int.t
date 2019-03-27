use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Int

=abstract

Data-Object Number Function (Int) Class

=synopsis

  use Data::Object::Func::Number::Int;

  my $func = Data::Object::Func::Number::Int->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Int is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Int';

ok 1 and done_testing;
