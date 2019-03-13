use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Last

=abstract

Data-Object Array Function (Last) Class

=synopsis

  use Data::Object::Func::Array::Last;

  my $func = Data::Object::Func::Array::Last->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Last is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Last';

ok 1 and done_testing;
