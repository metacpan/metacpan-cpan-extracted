use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Unfold

=abstract

Data-Object Hash Function (Unfold) Class

=synopsis

  use Data::Object::Func::Hash::Unfold;

  my $func = Data::Object::Func::Hash::Unfold->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Unfold is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Unfold';

ok 1 and done_testing;
