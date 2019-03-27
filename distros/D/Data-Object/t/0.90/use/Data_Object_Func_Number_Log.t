use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Log

=abstract

Data-Object Number Function (Log) Class

=synopsis

  use Data::Object::Func::Number::Log;

  my $func = Data::Object::Func::Number::Log->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Log is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Log';

ok 1 and done_testing;
