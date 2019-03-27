use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::None

=abstract

Data-Object Array Function (None) Class

=synopsis

  use Data::Object::Func::Array::None;

  my $func = Data::Object::Func::Array::None->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::None is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::None';

ok 1 and done_testing;
