use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Ne

=abstract

Data-Object Undef Function (Ne) Class

=synopsis

  use Data::Object::Func::Undef::Ne;

  my $func = Data::Object::Func::Undef::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Ne is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Ne';

ok 1 and done_testing;
