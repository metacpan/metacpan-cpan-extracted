use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Reset

=abstract

Data-Object Hash Function (Reset) Class

=synopsis

  use Data::Object::Func::Hash::Reset;

  my $func = Data::Object::Func::Hash::Reset->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Reset is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Reset';

ok 1 and done_testing;
