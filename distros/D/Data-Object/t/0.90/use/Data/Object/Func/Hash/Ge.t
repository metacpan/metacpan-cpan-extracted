use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Ge

=abstract

Data-Object Hash Function (Ge) Class

=synopsis

  use Data::Object::Func::Hash::Ge;

  my $func = Data::Object::Func::Hash::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Ge is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Ge';

ok 1 and done_testing;
