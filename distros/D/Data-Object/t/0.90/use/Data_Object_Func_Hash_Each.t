use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Each

=abstract

Data-Object Hash Function (Each) Class

=synopsis

  use Data::Object::Func::Hash::Each;

  my $func = Data::Object::Func::Hash::Each->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Each is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Each';

ok 1 and done_testing;
