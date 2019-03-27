use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Get

=abstract

Data-Object Hash Function (Get) Class

=synopsis

  use Data::Object::Func::Hash::Get;

  my $func = Data::Object::Func::Hash::Get->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Get is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Get';

ok 1 and done_testing;
