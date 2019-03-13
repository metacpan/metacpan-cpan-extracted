use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  # given 1

  $integer->ne(0); # 1

=description

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

ne(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Integer';

my $data = Data::Object::Integer->new(1);

is_deeply $data->ne(0), 1;

ok 1 and done_testing;
