use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Lt

=abstract

Data-Object Any Function (Lt) Class

=synopsis

  use Data::Object::Func::Any::Lt;

  my $func = Data::Object::Func::Any::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Lt is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Lt';

ok 1 and done_testing;
