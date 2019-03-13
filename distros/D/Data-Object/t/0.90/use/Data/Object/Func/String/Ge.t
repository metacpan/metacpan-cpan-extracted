use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Ge

=abstract

Data-Object String Function (Ge) Class

=synopsis

  use Data::Object::Func::String::Ge;

  my $func = Data::Object::Func::String::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Ge is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Ge';

ok 1 and done_testing;
