use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Eq

=abstract

Data-Object Number Function (Eq) Class

=synopsis

  use Data::Object::Func::Number::Eq;

  my $func = Data::Object::Func::Number::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Eq is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Eq';

ok 1 and done_testing;
