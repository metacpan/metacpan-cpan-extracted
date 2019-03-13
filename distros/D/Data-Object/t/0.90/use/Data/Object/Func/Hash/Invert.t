use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Invert

=abstract

Data-Object Hash Function (Invert) Class

=synopsis

  use Data::Object::Func::Hash::Invert;

  my $func = Data::Object::Func::Hash::Invert->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Invert is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Invert';

ok 1 and done_testing;
