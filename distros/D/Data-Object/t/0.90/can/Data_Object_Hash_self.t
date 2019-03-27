use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

self

=usage

  # given $hash

  my $self = $hash->self();

=description

The self method returns the calling object (noop).

=signature

self() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->self(), $data;

ok 1 and done_testing;
