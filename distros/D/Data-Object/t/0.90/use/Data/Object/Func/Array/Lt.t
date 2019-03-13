use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Lt

=abstract

Data-Object Array Function (Lt) Class

=synopsis

  use Data::Object::Func::Array::Lt;

  my $func = Data::Object::Func::Array::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Lt is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Lt';

ok 1 and done_testing;
