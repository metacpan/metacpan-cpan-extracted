use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Words

=abstract

Data-Object String Function (Words) Class

=synopsis

  use Data::Object::Func::String::Words;

  my $func = Data::Object::Func::String::Words->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Words is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Words';

ok 1 and done_testing;
