use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Exists

=abstract

Data-Object Hash Function (Exists) Class

=synopsis

  use Data::Object::Func::Hash::Exists;

  my $func = Data::Object::Func::Hash::Exists->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Exists is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Exists';

ok 1 and done_testing;
