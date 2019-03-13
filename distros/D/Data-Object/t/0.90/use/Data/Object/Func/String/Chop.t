use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Chop

=abstract

Data-Object String Function (Chop) Class

=synopsis

  use Data::Object::Func::String::Chop;

  my $func = Data::Object::Func::String::Chop->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Chop is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Chop';

ok 1 and done_testing;
