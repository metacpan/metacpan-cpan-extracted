use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Lt

=abstract

Data-Object Integer Function (Lt) Class

=synopsis

  use Data::Object::Func::Integer::Lt;

  my $func = Data::Object::Func::Integer::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Lt is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Lt';

ok 1 and done_testing;
