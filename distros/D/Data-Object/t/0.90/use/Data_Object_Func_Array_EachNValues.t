use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::EachNValues

=abstract

Data-Object Array Function (EachNValues) Class

=synopsis

  use Data::Object::Func::Array::EachNValues;

  my $func = Data::Object::Func::Array::EachNValues->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::EachNValues is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::EachNValues';

ok 1 and done_testing;
