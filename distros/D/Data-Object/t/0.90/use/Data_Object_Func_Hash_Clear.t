use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Clear

=abstract

Data-Object Hash Function (Clear) Class

=synopsis

  use Data::Object::Func::Hash::Clear;

  my $func = Data::Object::Func::Hash::Clear->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Clear is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Clear';

ok 1 and done_testing;
