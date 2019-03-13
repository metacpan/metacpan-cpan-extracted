use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::EachNValues

=abstract

Data-Object Hash Function (EachNValues) Class

=synopsis

  use Data::Object::Func::Hash::EachNValues;

  my $func = Data::Object::Func::Hash::EachNValues->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::EachNValues is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::EachNValues';

ok 1 and done_testing;
