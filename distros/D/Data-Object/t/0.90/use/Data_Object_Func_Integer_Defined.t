use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Defined

=abstract

Data-Object Integer Function (Defined) Class

=synopsis

  use Data::Object::Func::Integer::Defined;

  my $func = Data::Object::Func::Integer::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Defined is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Defined';

ok 1 and done_testing;
