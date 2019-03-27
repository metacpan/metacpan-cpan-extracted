use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Clear

=abstract

Data-Object Array Function (Clear) Class

=synopsis

  use Data::Object::Func::Array::Clear;

  my $func = Data::Object::Func::Array::Clear->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Clear is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Clear';

ok 1 and done_testing;
