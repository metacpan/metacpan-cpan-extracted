use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Random

=abstract

Data-Object Array Function (Random) Class

=synopsis

  use Data::Object::Func::Array::Random;

  my $func = Data::Object::Func::Array::Random->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Random is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Random';

ok 1 and done_testing;
