use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

decr

=usage

  # given 123456789

  $number->decr; # 123456788

=description

The decr method returns the numeric number decremented by 1. This method returns
a data type object to be determined after execution.

=signature

decr(Num $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->decr(), 11;

ok 1 and done_testing;
