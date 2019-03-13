use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Replace

=abstract

Data-Object String Function (Replace) Class

=synopsis

  use Data::Object::Func::String::Replace;

  my $func = Data::Object::Func::String::Replace->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Replace is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Replace';

ok 1 and done_testing;
