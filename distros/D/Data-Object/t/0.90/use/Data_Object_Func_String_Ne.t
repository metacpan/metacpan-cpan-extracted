use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Ne

=abstract

Data-Object String Function (Ne) Class

=synopsis

  use Data::Object::Func::String::Ne;

  my $func = Data::Object::Func::String::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Ne is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Ne';

ok 1 and done_testing;
