use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::To

=abstract

Data-Object Float Function (To) Class

=synopsis

  use Data::Object::Func::Float::To;

  my $func = Data::Object::Func::Float::To->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::To is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::To';

ok 1 and done_testing;
