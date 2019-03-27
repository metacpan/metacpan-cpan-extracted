use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Lt

=abstract

Data-Object Float Function (Lt) Class

=synopsis

  use Data::Object::Func::Float::Lt;

  my $func = Data::Object::Func::Float::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Lt is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Lt';

ok 1 and done_testing;
