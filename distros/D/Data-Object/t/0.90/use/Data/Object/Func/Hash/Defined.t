use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Defined

=abstract

Data-Object Hash Function (Defined) Class

=synopsis

  use Data::Object::Func::Hash::Defined;

  my $func = Data::Object::Func::Hash::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Defined is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Defined';

ok 1 and done_testing;
