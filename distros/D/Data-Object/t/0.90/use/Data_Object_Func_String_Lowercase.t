use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Lowercase

=abstract

Data-Object String Function (Lowercase) Class

=synopsis

  use Data::Object::Func::String::Lowercase;

  my $func = Data::Object::Func::String::Lowercase->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Lowercase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Lowercase';

ok 1 and done_testing;
