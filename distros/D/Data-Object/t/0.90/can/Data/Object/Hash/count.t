use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

count

=usage

  # given {1..4}

  my $count = $hash->count; # 2

=description

The count method returns the total number of keys defined. This method returns
a L<Data::Object::Number> object.

=signature

count() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->count(), 2;

ok 1 and done_testing;
