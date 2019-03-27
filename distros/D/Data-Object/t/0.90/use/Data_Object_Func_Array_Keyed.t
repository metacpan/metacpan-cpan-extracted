use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Keyed

=abstract

Data-Object Array Function (Keyed) Class

=synopsis

  use Data::Object::Func::Array::Keyed;

  my $func = Data::Object::Func::Array::Keyed->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Keyed is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Keyed';

ok 1 and done_testing;
