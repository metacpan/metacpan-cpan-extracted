use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  my $set = $registry->set($key, $val);

=description

Set the supplied key and value, and return the value.

=signature

set(Str $arg1, Any $arg2) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->set('foo', 'bar'), 1;

ok 1 and done_testing;
