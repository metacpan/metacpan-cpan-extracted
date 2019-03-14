use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  # given 1.23

  $float->ge(1); # 1

=description

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=signature

ge(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->ge(1), 1;

ok 1 and done_testing;
