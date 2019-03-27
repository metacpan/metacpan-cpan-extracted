use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

get

=usage

  my $get = $registry->get($key);

=description

The get method returns the value of the element with the specific key.

=signature

get(Str $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->get(), undef;

ok 1 and done_testing;
