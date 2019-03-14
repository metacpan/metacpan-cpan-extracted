use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

none

=usage

  # given [2..5]

  $array->none('$value <= 1'); # 1; true
  $array->none('$value <= 2'); # 0; false

=description

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=signature

none(CodeRef $arg1, Any $arg2) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->none('$value <= 1'), 1;

is_deeply $data->none('$value <= 2'), 0;

ok 1 and done_testing;
