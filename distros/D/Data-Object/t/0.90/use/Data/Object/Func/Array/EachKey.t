use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::EachKey

=abstract

Data-Object Array Function (EachKey) Class

=synopsis

  use Data::Object::Func::Array::EachKey;

  my $func = Data::Object::Func::Array::EachKey->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::EachKey is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::EachKey';

ok 1 and done_testing;
