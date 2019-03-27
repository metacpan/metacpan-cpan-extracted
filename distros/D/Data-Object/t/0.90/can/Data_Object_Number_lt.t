use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  # given 86

  $number->lt(88); # 1

=description

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=signature

lt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->lt(12), 0;

ok 1 and done_testing;
