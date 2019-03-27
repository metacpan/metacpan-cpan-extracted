use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  # given 1.23

  $float->lt(1.24); # 1

=description

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

lt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->lt(1.24), 1;

ok 1 and done_testing;
