use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Le

=abstract

Data-Object Regexp Function (Le) Class

=synopsis

  use Data::Object::Func::Regexp::Le;

  my $func = Data::Object::Func::Regexp::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Le is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Le';

ok 1 and done_testing;
