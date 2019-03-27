use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Hash

=abstract

Data-Object Array Function (Hash) Class

=synopsis

  use Data::Object::Func::Array::Hash;

  my $func = Data::Object::Func::Array::Hash->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Hash is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Hash';

ok 1 and done_testing;
