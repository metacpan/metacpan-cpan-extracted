use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Ucfirst

=abstract

Data-Object String Function (Ucfirst) Class

=synopsis

  use Data::Object::Func::String::Ucfirst;

  my $func = Data::Object::Func::String::Ucfirst->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Ucfirst is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Ucfirst';

ok 1 and done_testing;
