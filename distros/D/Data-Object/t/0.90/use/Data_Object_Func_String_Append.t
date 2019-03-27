use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Append

=abstract

Data-Object String Function (Append) Class

=synopsis

  use Data::Object::Func::String::Append;

  my $func = Data::Object::Func::String::Append->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Append is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Append';

ok 1 and done_testing;
