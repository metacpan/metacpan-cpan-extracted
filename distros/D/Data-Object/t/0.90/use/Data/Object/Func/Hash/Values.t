use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Values

=abstract

Data-Object Hash Function (Values) Class

=synopsis

  use Data::Object::Func::Hash::Values;

  my $func = Data::Object::Func::Hash::Values->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Values is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Values';

ok 1 and done_testing;
