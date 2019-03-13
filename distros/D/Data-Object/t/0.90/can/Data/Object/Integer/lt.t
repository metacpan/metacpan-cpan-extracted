use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  # given 1

  $integer->lt(1); # 0

=description

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

lt(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Integer';

my $data = Data::Object::Integer->new(1);

is_deeply $data->lt(1), 0;

ok 1 and done_testing;
