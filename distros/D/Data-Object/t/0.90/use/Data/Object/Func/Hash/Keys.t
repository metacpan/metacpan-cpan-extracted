use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Keys

=abstract

Data-Object Hash Function (Keys) Class

=synopsis

  use Data::Object::Func::Hash::Keys;

  my $func = Data::Object::Func::Hash::Keys->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Keys is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Keys';

ok 1 and done_testing;
