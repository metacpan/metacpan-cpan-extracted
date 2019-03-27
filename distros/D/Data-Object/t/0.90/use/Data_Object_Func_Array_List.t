use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::List

=abstract

Data-Object Array Function (List) Class

=synopsis

  use Data::Object::Func::Array::List;

  my $func = Data::Object::Func::Array::List->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::List is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::List';

ok 1 and done_testing;
