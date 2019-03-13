use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Iterator

=abstract

Data-Object Hash Function (Iterator) Class

=synopsis

  use Data::Object::Func::Hash::Iterator;

  my $func = Data::Object::Func::Hash::Iterator->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Iterator is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Iterator';

ok 1 and done_testing;
