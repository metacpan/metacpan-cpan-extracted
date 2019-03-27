use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Any::Ne

=abstract

Data-Object Any Function (Ne) Class

=synopsis

  use Data::Object::Func::Any::Ne;

  my $func = Data::Object::Func::Any::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Any::Ne is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Func::Any::Ne';

ok 1 and done_testing;
