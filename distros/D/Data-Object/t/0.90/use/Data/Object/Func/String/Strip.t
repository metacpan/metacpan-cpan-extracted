use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Strip

=abstract

Data-Object String Function (Strip) Class

=synopsis

  use Data::Object::Func::String::Strip;

  my $func = Data::Object::Func::String::Strip->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Strip is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Strip';

ok 1 and done_testing;
