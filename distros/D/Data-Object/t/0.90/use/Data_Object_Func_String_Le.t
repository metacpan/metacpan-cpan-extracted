use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Le

=abstract

Data-Object String Function (Le) Class

=synopsis

  use Data::Object::Func::String::Le;

  my $func = Data::Object::Func::String::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Le is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Le';

ok 1 and done_testing;
