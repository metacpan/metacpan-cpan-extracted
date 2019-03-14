use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

iterator

=usage

  # given {1..8}

  my $iterator = $hash->iterator;
  while (my $value = $iterator->next) {
      say $value; # 2
  }

=description

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point
the iterator will return an undefined value. This method returns a
L<Data::Object::Code> object.

=signature

iterator() : CodeObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

my $iterator = $data->iterator();

is_deeply $iterator->(), 2;

is_deeply $iterator->(), 4;

is_deeply $iterator->(), undef;

ok 1 and done_testing;
