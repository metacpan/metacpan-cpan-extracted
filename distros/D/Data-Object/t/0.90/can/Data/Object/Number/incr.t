use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

incr

=usage

  # given 123456789

  $number->incr; # 123456790

=description

The incr method returns the numeric number incremented by 1. This method returns
a data type object to be determined after execution.

=signature

incr(Num $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->incr(), 13;

ok 1 and done_testing;
