use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  # given 1.23

  $float->ne(1); # 1

=description

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

ne(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->ne(1), 1;

ok 1 and done_testing;
