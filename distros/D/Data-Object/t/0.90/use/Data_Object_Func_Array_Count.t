use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Count

=abstract

Data-Object Array Function (Count) Class

=synopsis

  use Data::Object::Func::Array::Count;

  my $func = Data::Object::Func::Array::Count->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Count is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Count';

ok 1 and done_testing;
