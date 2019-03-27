use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Mod

=abstract

Data-Object Number Function (Mod) Class

=synopsis

  use Data::Object::Func::Number::Mod;

  my $func = Data::Object::Func::Number::Mod->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Mod is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Mod';

ok 1 and done_testing;
