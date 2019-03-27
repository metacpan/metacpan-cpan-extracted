use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Ne

=abstract

Data-Object Integer Function (Ne) Class

=synopsis

  use Data::Object::Func::Integer::Ne;

  my $func = Data::Object::Func::Integer::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Ne is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Ne';

ok 1 and done_testing;
