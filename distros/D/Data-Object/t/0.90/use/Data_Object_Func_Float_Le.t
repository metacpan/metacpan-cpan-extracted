use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Le

=abstract

Data-Object Float Function (Le) Class

=synopsis

  use Data::Object::Func::Float::Le;

  my $func = Data::Object::Func::Float::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Le is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Le';

ok 1 and done_testing;
