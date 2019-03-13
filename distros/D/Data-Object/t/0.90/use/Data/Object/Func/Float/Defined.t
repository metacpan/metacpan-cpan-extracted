use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Defined

=abstract

Data-Object Float Function (Defined) Class

=synopsis

  use Data::Object::Func::Float::Defined;

  my $func = Data::Object::Func::Float::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Defined is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Defined';

ok 1 and done_testing;
