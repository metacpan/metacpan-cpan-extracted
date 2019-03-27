use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Eq

=abstract

Data-Object Any Function (Eq) Class

=synopsis

  use Data::Object::Func::Any::Eq;

  my $func = Data::Object::Func::Any::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Eq is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Eq';

ok 1 and done_testing;
