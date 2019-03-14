use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

all

=usage

  # given [2..5]

  $array->all('$value > 1'); # 1; true
  $array->all('$value > 3'); # 0; false|

=description

The all method returns true if all of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=signature

all(CodeRef $arg1, Any @args) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->all('$value > 1'), 1;

is_deeply $data->all('$value > 3'), 0;

ok 1 and done_testing;
