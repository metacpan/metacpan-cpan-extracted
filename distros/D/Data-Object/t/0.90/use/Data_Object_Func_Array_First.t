use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::First

=abstract

Data-Object Array Function (First) Class

=synopsis

  use Data::Object::Func::Array::First;

  my $func = Data::Object::Func::Array::First->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::First is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::First';

ok 1 and done_testing;
