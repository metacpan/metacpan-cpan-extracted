use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Eq

=abstract

Data-Object String Function (Eq) Class

=synopsis

  use Data::Object::Func::String::Eq;

  my $func = Data::Object::Func::String::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Eq is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Eq';

ok 1 and done_testing;
