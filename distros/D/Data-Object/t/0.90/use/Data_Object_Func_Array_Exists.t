use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Exists

=abstract

Data-Object Array Function (Exists) Class

=synopsis

  use Data::Object::Func::Array::Exists;

  my $func = Data::Object::Func::Array::Exists->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Exists is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Exists';

ok 1 and done_testing;
