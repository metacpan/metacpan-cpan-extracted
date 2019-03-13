use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Replace

=abstract

Data-Object Regexp Function (Replace) Class

=synopsis

  use Data::Object::Func::Regexp::Replace;

  my $func = Data::Object::Func::Regexp::Replace->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Replace is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Replace';

ok 1 and done_testing;
