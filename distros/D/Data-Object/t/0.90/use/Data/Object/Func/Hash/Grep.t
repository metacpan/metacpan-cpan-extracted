use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Grep

=abstract

Data-Object Hash Function (Grep) Class

=synopsis

  use Data::Object::Func::Hash::Grep;

  my $func = Data::Object::Func::Hash::Grep->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Grep is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Grep';

ok 1 and done_testing;
