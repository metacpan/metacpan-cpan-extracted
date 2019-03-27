use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Incr

=abstract

Data-Object Number Function (Incr) Class

=synopsis

  use Data::Object::Func::Number::Incr;

  my $func = Data::Object::Func::Number::Incr->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Incr is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Incr';

ok 1 and done_testing;
