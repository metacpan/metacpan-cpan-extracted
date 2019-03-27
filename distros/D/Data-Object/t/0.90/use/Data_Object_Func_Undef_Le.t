use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Le

=abstract

Data-Object Undef Function (Le) Class

=synopsis

  use Data::Object::Func::Undef::Le;

  my $func = Data::Object::Func::Undef::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Le is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Le';

ok 1 and done_testing;
