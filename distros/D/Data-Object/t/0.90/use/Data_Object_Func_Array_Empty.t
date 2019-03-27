use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Empty

=abstract

Data-Object Array Function (Empty) Class

=synopsis

  use Data::Object::Func::Array::Empty;

  my $func = Data::Object::Func::Array::Empty->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Empty is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Empty';

ok 1 and done_testing;
