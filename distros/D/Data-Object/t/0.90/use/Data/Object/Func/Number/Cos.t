use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Cos

=abstract

Data-Object Number Function (Cos) Class

=synopsis

  use Data::Object::Func::Number::Cos;

  my $func = Data::Object::Func::Number::Cos->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Cos is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Cos';

ok 1 and done_testing;
