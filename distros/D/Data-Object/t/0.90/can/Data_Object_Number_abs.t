use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

abs

=usage

  # given 12

  $number->abs; # 12

  # given -12

  $number->abs; # 12

=description

The abs method returns the absolute value of the number. This method returns a
L<Data::Object::Number> object.

=signature

abs() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(-12);

is_deeply $data->abs(), 12;

ok 1 and done_testing;
