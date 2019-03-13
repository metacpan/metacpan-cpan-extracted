use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Defined

=abstract

Data-Object Regexp Function (Defined) Class

=synopsis

  use Data::Object::Func::Regexp::Defined;

  my $func = Data::Object::Func::Regexp::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Defined is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Defined';

ok 1 and done_testing;
