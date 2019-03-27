use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Downto

=abstract

Data-Object Float Function (Downto) Class

=synopsis

  use Data::Object::Func::Float::Downto;

  my $func = Data::Object::Func::Float::Downto->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Downto is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Downto';

ok 1 and done_testing;
