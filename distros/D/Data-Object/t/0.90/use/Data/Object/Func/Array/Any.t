use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Any

=abstract

Data-Object Array Function (Any) Class

=synopsis

  use Data::Object::Func::Array::Any;

  my $func = Data::Object::Func::Array::Any->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Any is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Any';

ok 1 and done_testing;
