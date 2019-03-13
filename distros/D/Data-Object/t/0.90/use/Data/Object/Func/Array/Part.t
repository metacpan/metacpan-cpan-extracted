use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Part

=abstract

Data-Object Array Function (Part) Class

=synopsis

  use Data::Object::Func::Array::Part;

  my $func = Data::Object::Func::Array::Part->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Part is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Part';

ok 1 and done_testing;
