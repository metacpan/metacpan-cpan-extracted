use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::PairsHash

=abstract

Data-Object Array Function (PairsHash) Class

=synopsis

  use Data::Object::Func::Array::PairsHash;

  my $func = Data::Object::Func::Array::PairsHash->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::PairsHash is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::PairsHash';

ok 1 and done_testing;
