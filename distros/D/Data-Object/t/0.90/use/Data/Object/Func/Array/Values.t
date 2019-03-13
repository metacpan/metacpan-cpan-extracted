use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Values

=abstract

Data-Object Array Function (Values) Class

=synopsis

  use Data::Object::Func::Array::Values;

  my $func = Data::Object::Func::Array::Values->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Values is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Values';

ok 1 and done_testing;
