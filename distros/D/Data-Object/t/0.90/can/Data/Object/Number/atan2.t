use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

atan2

=usage

  # given 1

  $number->atan2(1); # 0.785398163397448

=description

The atan2 method returns the arctangent of Y/X in the range -PI to PI This
method returns a L<Data::Object::Float> object.

=signature

atan2(Num $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(1);

is_deeply $data->atan2(2), 0.463647609000806;

ok 1 and done_testing;
