use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Ge

=abstract

Data-Object Array Function (Ge) Class

=synopsis

  use Data::Object::Func::Array::Ge;

  my $func = Data::Object::Func::Array::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Ge is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Ge';

ok 1 and done_testing;
