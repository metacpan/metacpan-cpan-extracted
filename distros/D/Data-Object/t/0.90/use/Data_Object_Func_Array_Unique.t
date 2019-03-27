use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Unique

=abstract

Data-Object Array Function (Unique) Class

=synopsis

  use Data::Object::Func::Array::Unique;

  my $func = Data::Object::Func::Array::Unique->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Unique is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Unique';

ok 1 and done_testing;
