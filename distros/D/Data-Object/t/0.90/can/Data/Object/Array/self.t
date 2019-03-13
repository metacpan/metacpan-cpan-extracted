use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

self

=usage

  my $self = $array->self();

=description

The self method returns the calling object (noop).

=signature

self() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->self(), $data;

ok 1 and done_testing;
