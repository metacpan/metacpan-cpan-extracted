use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Length

=abstract

Data-Object Hash Function (Length) Class

=synopsis

  use Data::Object::Func::Hash::Length;

  my $func = Data::Object::Func::Hash::Length->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Length is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Length';

ok 1 and done_testing;
