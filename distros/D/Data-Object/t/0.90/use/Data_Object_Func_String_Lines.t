use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Lines

=abstract

Data-Object String Function (Lines) Class

=synopsis

  use Data::Object::Func::String::Lines;

  my $func = Data::Object::Func::String::Lines->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Lines is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Lines';

ok 1 and done_testing;
