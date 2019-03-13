use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Sort

=abstract

Data-Object Hash Function (Sort) Class

=synopsis

  use Data::Object::Func::Hash::Sort;

  my $func = Data::Object::Func::Hash::Sort->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Sort is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Sort';

ok 1 and done_testing;
