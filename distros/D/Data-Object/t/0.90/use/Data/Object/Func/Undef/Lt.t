use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Undef::Lt

=abstract

Data-Object Undef Function (Lt) Class

=synopsis

  use Data::Object::Func::Undef::Lt;

  my $func = Data::Object::Func::Undef::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Undef::Lt is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Func::Undef::Lt';

ok 1 and done_testing;
