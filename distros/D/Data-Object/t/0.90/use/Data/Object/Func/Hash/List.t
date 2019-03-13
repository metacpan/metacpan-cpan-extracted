use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::List

=abstract

Data-Object Hash Function (List) Class

=synopsis

  use Data::Object::Func::Hash::List;

  my $func = Data::Object::Func::Hash::List->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::List is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::List';

ok 1 and done_testing;
