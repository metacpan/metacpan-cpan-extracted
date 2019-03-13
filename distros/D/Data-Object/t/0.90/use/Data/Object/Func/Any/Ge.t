use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Ge

=abstract

Data-Object Any Function (Ge) Class

=synopsis

  use Data::Object::Func::Any::Ge;

  my $func = Data::Object::Func::Any::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Ge is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Ge';

ok 1 and done_testing;
