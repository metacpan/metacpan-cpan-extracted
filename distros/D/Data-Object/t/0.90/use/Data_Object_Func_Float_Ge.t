use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Ge

=abstract

Data-Object Float Function (Ge) Class

=synopsis

  use Data::Object::Func::Float::Ge;

  my $func = Data::Object::Func::Float::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Ge is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Ge';

ok 1 and done_testing;
