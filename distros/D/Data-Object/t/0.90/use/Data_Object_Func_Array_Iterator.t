use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Iterator

=abstract

Data-Object Array Function (Iterator) Class

=synopsis

  use Data::Object::Func::Array::Iterator;

  my $func = Data::Object::Func::Array::Iterator->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Iterator is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Iterator';

ok 1 and done_testing;
