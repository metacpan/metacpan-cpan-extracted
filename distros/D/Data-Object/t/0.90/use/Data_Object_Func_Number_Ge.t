use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Ge

=abstract

Data-Object Number Function (Ge) Class

=synopsis

  use Data::Object::Func::Number::Ge;

  my $func = Data::Object::Func::Number::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Ge is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Ge';

ok 1 and done_testing;
