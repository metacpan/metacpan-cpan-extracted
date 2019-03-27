use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Map

=abstract

Data-Object Array Function (Map) Class

=synopsis

  use Data::Object::Func::Array::Map;

  my $func = Data::Object::Func::Array::Map->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Map is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Map';

ok 1 and done_testing;
