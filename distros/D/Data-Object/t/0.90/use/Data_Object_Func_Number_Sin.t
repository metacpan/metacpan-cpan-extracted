use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Sin

=abstract

Data-Object Number Function (Sin) Class

=synopsis

  use Data::Object::Func::Number::Sin;

  my $func = Data::Object::Func::Number::Sin->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Sin is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Sin';

ok 1 and done_testing;
