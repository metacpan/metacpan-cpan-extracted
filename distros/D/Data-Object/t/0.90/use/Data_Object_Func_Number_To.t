use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::To

=abstract

Data-Object Number Function (To) Class

=synopsis

  use Data::Object::Func::Number::To;

  my $func = Data::Object::Func::Number::To->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::To is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::To';

ok 1 and done_testing;
