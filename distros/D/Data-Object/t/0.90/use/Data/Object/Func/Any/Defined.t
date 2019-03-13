use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Defined

=abstract

Data-Object Any Function (Defined) Class

=synopsis

  use Data::Object::Func::Any::Defined;

  my $func = Data::Object::Func::Any::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Defined is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Defined';

ok 1 and done_testing;
