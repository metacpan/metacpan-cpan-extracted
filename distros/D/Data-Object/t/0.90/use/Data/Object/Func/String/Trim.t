use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Trim

=abstract

Data-Object String Function (Trim) Class

=synopsis

  use Data::Object::Func::String::Trim;

  my $func = Data::Object::Func::String::Trim->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Trim is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Trim';

ok 1 and done_testing;
