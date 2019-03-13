use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given [1,2,undef,4,5]

  $array->defined(2); # 0; false
  $array->defined(1); # 1; true

=description

The defined method returns true if the element within the array at the index
specified by the argument meets the criteria for being defined, otherwise it
returns false. This method returns a L<Data::Object::Number> object.

=signature

defined() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1,2,undef,4,5]);

is_deeply $data->defined(), 1;

is_deeply $data->defined(2), 0;

is_deeply $data->defined(1), 1;

ok 1 and done_testing;
