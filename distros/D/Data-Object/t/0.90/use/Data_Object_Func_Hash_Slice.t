use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Slice

=abstract

Data-Object Hash Function (Slice) Class

=synopsis

  use Data::Object::Func::Hash::Slice;

  my $func = Data::Object::Func::Hash::Slice->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Slice is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Slice';

ok 1 and done_testing;
