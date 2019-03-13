use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

mod

=usage

  # given 12

  $number->mod(1); # 0
  $number->mod(2); # 0
  $number->mod(3); # 0
  $number->mod(4); # 0
  $number->mod(5); # 2

=description

The mod method returns the division remainder of the number divided by the
argment. This method returns a L<Data::Object::Number> object.

=signature

mod() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->mod(1), 0;

is_deeply $data->mod(2), 0;

is_deeply $data->mod(3), 0;

is_deeply $data->mod(4), 0;

is_deeply $data->mod(5), 2;

ok 1 and done_testing;
