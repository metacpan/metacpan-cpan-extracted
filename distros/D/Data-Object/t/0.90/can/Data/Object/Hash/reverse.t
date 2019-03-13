use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

reverse

=usage

  # given {1..8,9,undef}

  $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

=description

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped. This method
returns a L<Data::Object::Hash> object.

=signature

reverse() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8,9,undef});

is_deeply $data->reverse(), {8=>7,6=>5,4=>3,2=>1};

ok 1 and done_testing;
