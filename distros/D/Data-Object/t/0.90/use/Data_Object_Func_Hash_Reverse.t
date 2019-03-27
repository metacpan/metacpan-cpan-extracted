use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Reverse

=abstract

Data-Object Hash Function (Reverse) Class

=synopsis

  use Data::Object::Func::Hash::Reverse;

  my $func = Data::Object::Func::Hash::Reverse->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Reverse is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Reverse';

ok 1 and done_testing;
