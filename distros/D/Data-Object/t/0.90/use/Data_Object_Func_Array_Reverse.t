use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Reverse

=abstract

Data-Object Array Function (Reverse) Class

=synopsis

  use Data::Object::Func::Array::Reverse;

  my $func = Data::Object::Func::Array::Reverse->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Reverse is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Reverse';

ok 1 and done_testing;
