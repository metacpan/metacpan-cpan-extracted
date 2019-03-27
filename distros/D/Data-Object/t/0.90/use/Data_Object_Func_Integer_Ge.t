use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Ge

=abstract

Data-Object Integer Function (Ge) Class

=synopsis

  use Data::Object::Func::Integer::Ge;

  my $func = Data::Object::Func::Integer::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Ge is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Ge';

ok 1 and done_testing;
