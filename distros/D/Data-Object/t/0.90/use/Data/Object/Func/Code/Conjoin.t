use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Conjoin

=abstract

Data-Object Code Function (Conjoin) Class

=synopsis

  use Data::Object::Func::Code::Conjoin;

  my $func = Data::Object::Func::Code::Conjoin->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Conjoin is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Conjoin';

ok 1 and done_testing;
