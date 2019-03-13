use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Slice

=abstract

Data-Object Array Function (Slice) Class

=synopsis

  use Data::Object::Func::Array::Slice;

  my $func = Data::Object::Func::Array::Slice->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Slice is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Slice';

ok 1 and done_testing;
