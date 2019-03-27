use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Split

=abstract

Data-Object String Function (Split) Class

=synopsis

  use Data::Object::Func::String::Split;

  my $func = Data::Object::Func::String::Split->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Split is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Split';

ok 1 and done_testing;
