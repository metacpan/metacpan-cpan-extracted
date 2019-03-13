use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Map

=abstract

Data-Object Hash Function (Map) Class

=synopsis

  use Data::Object::Func::Hash::Map;

  my $func = Data::Object::Func::Hash::Map->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Map is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Map';

ok 1 and done_testing;
