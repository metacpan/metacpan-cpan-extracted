use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Ne

=abstract

Data-Object Regexp Function (Ne) Class

=synopsis

  use Data::Object::Func::Regexp::Ne;

  my $func = Data::Object::Func::Regexp::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Ne is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Ne';

ok 1 and done_testing;
