use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Eq

=abstract

Data-Object Hash Function (Eq) Class

=synopsis

  use Data::Object::Func::Hash::Eq;

  my $func = Data::Object::Func::Hash::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Eq is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Eq';

ok 1 and done_testing;
