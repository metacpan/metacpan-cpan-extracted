use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  # given 0

  $number->ge(0); # 1

=description

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=signature

ge(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->ge(12), 1;

ok 1 and done_testing;
