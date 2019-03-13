use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Lookup

=abstract

Data-Object Hash Function (Lookup) Class

=synopsis

  use Data::Object::Func::Hash::Lookup;

  my $func = Data::Object::Func::Hash::Lookup->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Lookup is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Lookup';

ok 1 and done_testing;
