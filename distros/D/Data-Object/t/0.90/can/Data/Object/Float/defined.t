use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given $float

  $float->defined; # 1

=description

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=signature

defined() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->defined(), 1;

ok 1 and done_testing;
