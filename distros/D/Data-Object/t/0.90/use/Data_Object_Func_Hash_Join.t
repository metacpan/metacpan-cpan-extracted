use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Join

=abstract

Data-Object Hash Function (Join) Class

=synopsis

  use Data::Object::Func::Hash::Join;

  my $func = Data::Object::Func::Hash::Join->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Join is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Join';

ok 1 and done_testing;
