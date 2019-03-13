use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Length

=abstract

Data-Object String Function (Length) Class

=synopsis

  use Data::Object::Func::String::Length;

  my $func = Data::Object::Func::String::Length->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Length is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Length';

ok 1 and done_testing;
