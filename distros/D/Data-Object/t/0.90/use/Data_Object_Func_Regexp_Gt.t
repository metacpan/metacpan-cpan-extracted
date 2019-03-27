use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Gt

=abstract

Data-Object Regexp Function (Gt) Class

=synopsis

  use Data::Object::Func::Regexp::Gt;

  my $func = Data::Object::Func::Regexp::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Gt is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Gt';

ok 1 and done_testing;
