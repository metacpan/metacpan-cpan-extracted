use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Count

=abstract

Data-Object Hash Function (Count) Class

=synopsis

  use Data::Object::Func::Hash::Count;

  my $func = Data::Object::Func::Hash::Count->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Count is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Count';

ok 1 and done_testing;
