use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Concat

=abstract

Data-Object String Function (Concat) Class

=synopsis

  use Data::Object::Func::String::Concat;

  my $func = Data::Object::Func::String::Concat->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Concat is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Concat';

ok 1 and done_testing;
