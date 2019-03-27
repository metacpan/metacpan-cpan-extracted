use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Le

=abstract

Data-Object Any Function (Le) Class

=synopsis

  use Data::Object::Func::Any::Le;

  my $func = Data::Object::Func::Any::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Le is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Le';

ok 1 and done_testing;
