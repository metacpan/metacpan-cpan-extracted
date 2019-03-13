use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Lt

=abstract

Data-Object Number Function (Lt) Class

=synopsis

  use Data::Object::Func::Number::Lt;

  my $func = Data::Object::Func::Number::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Lt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Lt';

ok 1 and done_testing;
