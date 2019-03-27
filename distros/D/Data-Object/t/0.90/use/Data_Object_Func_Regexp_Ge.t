use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Ge

=abstract

Data-Object Regexp Function (Ge) Class

=synopsis

  use Data::Object::Func::Regexp::Ge;

  my $func = Data::Object::Func::Regexp::Ge->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Ge is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Ge';

ok 1 and done_testing;
