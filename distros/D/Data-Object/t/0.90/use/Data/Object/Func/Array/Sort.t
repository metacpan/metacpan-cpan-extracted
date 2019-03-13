use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Sort

=abstract

Data-Object Array Function (Sort) Class

=synopsis

  use Data::Object::Func::Array::Sort;

  my $func = Data::Object::Func::Array::Sort->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Sort is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Sort';

ok 1 and done_testing;
