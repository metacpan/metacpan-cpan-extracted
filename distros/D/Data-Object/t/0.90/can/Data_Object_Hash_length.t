use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

length

=usage

  # given {1..8}

  my $length = $hash->length; # 4

=description

The length method returns the number of keys in the hash. This method
return a L<Data::Object::Number> object.

=signature

length() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->length(), 4;

ok 1 and done_testing;
