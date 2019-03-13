use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Eq

=abstract

Data-Object Float Function (Eq) Class

=synopsis

  use Data::Object::Func::Float::Eq;

  my $func = Data::Object::Func::Float::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Eq is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Eq';

ok 1 and done_testing;
