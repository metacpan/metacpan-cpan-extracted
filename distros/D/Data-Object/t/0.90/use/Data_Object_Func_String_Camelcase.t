use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Camelcase

=abstract

Data-Object String Function (Camelcase) Class

=synopsis

  use Data::Object::Func::String::Camelcase;

  my $func = Data::Object::Func::String::Camelcase->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Camelcase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Camelcase';

ok 1 and done_testing;
