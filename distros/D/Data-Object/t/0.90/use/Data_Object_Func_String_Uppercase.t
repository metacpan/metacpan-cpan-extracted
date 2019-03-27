use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Uppercase

=abstract

Data-Object String Function (Uppercase) Class

=synopsis

  use Data::Object::Func::String::Uppercase;

  my $func = Data::Object::Func::String::Uppercase->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Uppercase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Uppercase';

ok 1 and done_testing;
