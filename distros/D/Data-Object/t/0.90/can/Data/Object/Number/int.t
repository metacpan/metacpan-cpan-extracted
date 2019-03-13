use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

int

=usage

  # given 12.5

  $number->int; # 12

=description

The int method returns the integer portion of the number. Do not use this
method for rounding. This method returns a L<Data::Object::Number> object.

=signature

int() : DoInt

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12.5);

is_deeply $data->int(), 12;

ok 1 and done_testing;
