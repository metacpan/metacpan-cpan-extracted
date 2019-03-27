use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Rindex

=abstract

Data-Object String Function (Rindex) Class

=synopsis

  use Data::Object::Func::String::Rindex;

  my $func = Data::Object::Func::String::Rindex->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Rindex is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Rindex';

ok 1 and done_testing;
