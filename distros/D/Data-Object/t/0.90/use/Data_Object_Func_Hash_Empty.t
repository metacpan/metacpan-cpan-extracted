use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Empty

=abstract

Data-Object Hash Function (Empty) Class

=synopsis

  use Data::Object::Func::Hash::Empty;

  my $func = Data::Object::Func::Hash::Empty->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Empty is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Empty';

ok 1 and done_testing;
