use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Defined

=abstract

Data-Object String Function (Defined) Class

=synopsis

  use Data::Object::Func::String::Defined;

  my $func = Data::Object::Func::String::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Defined is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Defined';

ok 1 and done_testing;
