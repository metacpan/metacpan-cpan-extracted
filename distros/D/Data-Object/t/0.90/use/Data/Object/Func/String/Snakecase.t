use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Snakecase

=abstract

Data-Object String Function (Snakecase) Class

=synopsis

  use Data::Object::Func::String::Snakecase;

  my $func = Data::Object::Func::String::Snakecase->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Snakecase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Snakecase';

ok 1 and done_testing;
