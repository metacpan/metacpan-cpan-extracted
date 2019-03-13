use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

one

=usage

  # given [2..5]

  $array->one('$value == 5'); # 1; true
  $array->one('$value == 6'); # 0; false

=description

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=signature

one(CodeRef $arg1, Any $arg2) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->one('$value == 5'), 1;

is_deeply $data->one('$value == 6'), 0;

ok 1 and done_testing;
