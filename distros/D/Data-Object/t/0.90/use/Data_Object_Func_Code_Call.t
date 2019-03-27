use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Call

=abstract

Data-Object Code Function (Call) Class

=synopsis

  use Data::Object::Func::Code::Call;

  my $func = Data::Object::Func::Code::Call->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Call is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Call';

ok 1 and done_testing;
