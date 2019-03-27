use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::All

=abstract

Data-Object Array Function (All) Class

=synopsis

  use Data::Object::Func::Array::All;

  my $func = Data::Object::Func::Array::All->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::All is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::All';

ok 1 and done_testing;
