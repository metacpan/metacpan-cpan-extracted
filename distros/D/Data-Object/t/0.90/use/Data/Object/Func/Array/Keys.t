use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Keys

=abstract

Data-Object Array Function (Keys) Class

=synopsis

  use Data::Object::Func::Array::Keys;

  my $func = Data::Object::Func::Array::Keys->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Keys is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Keys';

ok 1 and done_testing;
