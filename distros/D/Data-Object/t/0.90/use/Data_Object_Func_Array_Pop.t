use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Pop

=abstract

Data-Object Array Function (Pop) Class

=synopsis

  use Data::Object::Func::Array::Pop;

  my $func = Data::Object::Func::Array::Pop->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Pop is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Pop';

ok 1 and done_testing;
