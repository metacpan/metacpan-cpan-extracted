use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Head

=abstract

Data-Object Hash Function (Head) Class

=synopsis

  use Data::Object::Func::Hash::Head;

  my $func = Data::Object::Func::Hash::Head->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Head is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Head';

ok 1 and done_testing;
