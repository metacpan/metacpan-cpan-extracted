use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Abs

=abstract

Data-Object Number Function (Abs) Class

=synopsis

  use Data::Object::Func::Number::Abs;

  my $func = Data::Object::Func::Number::Abs->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Abs is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Abs';

ok 1 and done_testing;
