use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Each

=abstract

Data-Object Array Function (Each) Class

=synopsis

  use Data::Object::Func::Array::Each;

  my $func = Data::Object::Func::Array::Each->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Each is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Each';

ok 1 and done_testing;
