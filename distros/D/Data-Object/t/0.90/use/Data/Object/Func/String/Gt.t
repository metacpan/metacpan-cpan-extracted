use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Gt

=abstract

Data-Object String Function (Gt) Class

=synopsis

  use Data::Object::Func::String::Gt;

  my $func = Data::Object::Func::String::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Gt is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Gt';

ok 1 and done_testing;
