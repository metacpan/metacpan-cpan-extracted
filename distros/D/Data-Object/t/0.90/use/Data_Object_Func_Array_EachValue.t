use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::EachValue

=abstract

Data-Object Array Function (EachValue) Class

=synopsis

  use Data::Object::Func::Array::EachValue;

  my $func = Data::Object::Func::Array::EachValue->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::EachValue is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::EachValue';

ok 1 and done_testing;
