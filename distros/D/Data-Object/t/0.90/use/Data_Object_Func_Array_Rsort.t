use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Rsort

=abstract

Data-Object Array Function (Rsort) Class

=synopsis

  use Data::Object::Func::Array::Rsort;

  my $func = Data::Object::Func::Array::Rsort->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Rsort is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Rsort';

ok 1 and done_testing;
