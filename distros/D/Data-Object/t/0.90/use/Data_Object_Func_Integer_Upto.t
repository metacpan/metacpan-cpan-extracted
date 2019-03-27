use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Upto

=abstract

Data-Object Integer Function (Upto) Class

=synopsis

  use Data::Object::Func::Integer::Upto;

  my $func = Data::Object::Func::Integer::Upto->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Upto is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Upto';

ok 1 and done_testing;
