use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Downto

=abstract

Data-Object Integer Function (Downto) Class

=synopsis

  use Data::Object::Func::Integer::Downto;

  my $func = Data::Object::Func::Integer::Downto->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Downto is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Downto';

ok 1 and done_testing;
