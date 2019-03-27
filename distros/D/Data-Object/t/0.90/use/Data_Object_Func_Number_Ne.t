use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Ne

=abstract

Data-Object Number Function (Ne) Class

=synopsis

  use Data::Object::Func::Number::Ne;

  my $func = Data::Object::Func::Number::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Ne is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Ne';

ok 1 and done_testing;
