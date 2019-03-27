use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Unshift

=abstract

Data-Object Array Function (Unshift) Class

=synopsis

  use Data::Object::Func::Array::Unshift;

  my $func = Data::Object::Func::Array::Unshift->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Unshift is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Unshift';

ok 1 and done_testing;
