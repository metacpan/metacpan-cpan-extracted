use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Ne

=abstract

Data-Object Hash Function (Ne) Class

=synopsis

  use Data::Object::Func::Hash::Ne;

  my $func = Data::Object::Func::Hash::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Ne is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Ne';

ok 1 and done_testing;
