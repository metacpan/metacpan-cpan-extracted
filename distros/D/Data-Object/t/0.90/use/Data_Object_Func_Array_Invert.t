use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Invert

=abstract

Data-Object Array Function (Invert) Class

=synopsis

  use Data::Object::Func::Array::Invert;

  my $func = Data::Object::Func::Array::Invert->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Invert is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Invert';

ok 1 and done_testing;
