use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Ne

=abstract

Data-Object Float Function (Ne) Class

=synopsis

  use Data::Object::Func::Float::Ne;

  my $func = Data::Object::Func::Float::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Ne is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Ne';

ok 1 and done_testing;
