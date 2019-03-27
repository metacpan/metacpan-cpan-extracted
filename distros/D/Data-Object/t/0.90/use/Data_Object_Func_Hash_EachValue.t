use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::EachValue

=abstract

Data-Object Hash Function (EachValue) Class

=synopsis

  use Data::Object::Func::Hash::EachValue;

  my $func = Data::Object::Func::Hash::EachValue->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::EachValue is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::EachValue';

ok 1 and done_testing;
