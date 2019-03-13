use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Gt

=abstract

Data-Object Number Function (Gt) Class

=synopsis

  use Data::Object::Func::Number::Gt;

  my $func = Data::Object::Func::Number::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Gt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Gt';

ok 1 and done_testing;
