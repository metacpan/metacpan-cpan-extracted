use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Tail

=abstract

Data-Object Hash Function (Tail) Class

=synopsis

  use Data::Object::Func::Hash::Tail;

  my $func = Data::Object::Func::Hash::Tail->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Tail is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Tail';

ok 1 and done_testing;
