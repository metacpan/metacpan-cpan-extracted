use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Gt

=abstract

Data-Object Array Function (Gt) Class

=synopsis

  use Data::Object::Func::Array::Gt;

  my $func = Data::Object::Func::Array::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Gt is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Gt';

ok 1 and done_testing;
