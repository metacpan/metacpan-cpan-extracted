use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Titlecase

=abstract

Data-Object String Function (Titlecase) Class

=synopsis

  use Data::Object::Func::String::Titlecase;

  my $func = Data::Object::Func::String::Titlecase->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Titlecase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Titlecase';

ok 1 and done_testing;
