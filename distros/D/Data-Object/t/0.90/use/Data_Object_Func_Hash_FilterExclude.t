use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::FilterExclude

=abstract

Data-Object Hash Function (FilterExclude) Class

=synopsis

  use Data::Object::Func::Hash::FilterExclude;

  my $func = Data::Object::Func::Hash::FilterExclude->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::FilterExclude is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::FilterExclude';

ok 1 and done_testing;
