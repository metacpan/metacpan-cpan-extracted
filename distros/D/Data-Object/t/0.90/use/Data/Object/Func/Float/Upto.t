use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Upto

=abstract

Data-Object Float Function (Upto) Class

=synopsis

  use Data::Object::Func::Float::Upto;

  my $func = Data::Object::Func::Float::Upto->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Upto is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Upto';

ok 1 and done_testing;
