use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Tail

=abstract

Data-Object Array Function (Tail) Class

=synopsis

  use Data::Object::Func::Array::Tail;

  my $func = Data::Object::Func::Array::Tail->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Tail is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Tail';

ok 1 and done_testing;
