use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Gt

=abstract

Data-Object Integer Function (Gt) Class

=synopsis

  use Data::Object::Func::Integer::Gt;

  my $func = Data::Object::Func::Integer::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Gt is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Gt';

ok 1 and done_testing;
