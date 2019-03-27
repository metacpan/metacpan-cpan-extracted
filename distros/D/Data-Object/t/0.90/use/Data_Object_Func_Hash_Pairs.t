use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Pairs

=abstract

Data-Object Hash Function (Pairs) Class

=synopsis

  use Data::Object::Func::Hash::Pairs;

  my $func = Data::Object::Func::Hash::Pairs->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Pairs is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Pairs';

ok 1 and done_testing;
