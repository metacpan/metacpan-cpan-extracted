use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  # given -100

  $number->ne(100); # 1

=description

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

ne(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->ne(11), 1;

ok 1 and done_testing;
