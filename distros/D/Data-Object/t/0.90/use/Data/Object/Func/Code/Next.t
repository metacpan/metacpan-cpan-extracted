use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Next

=abstract

Data-Object Code Function (Next) Class

=synopsis

  use Data::Object::Func::Code::Next;

  my $func = Data::Object::Func::Code::Next->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Next is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Next';

ok 1 and done_testing;
