use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

replace

=usage

  # given 'Hello World'

  $string->replace('World', 'Universe'); # Hello Universe
  $string->replace('world', 'Universe', 'i'); # Hello Universe
  $string->replace(qr/world/i, 'Universe'); # Hello Universe
  $string->replace(qr/.*/, 'Nada'); # Nada

=description

The replace method performs a smart search and replace operation and returns the
modified string (if any modification occurred). This method optionally takes a
replacement modifier as it's final argument. Note, this operation expects the
2nd argument to be a replacement String. This method returns a
string object.

=signature

replace(Str $arg1, Str $arg2) : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('Hello World');

is_deeply $data->replace('World', 'Universe'), 'Hello Universe';

is_deeply $data->replace('world', 'Universe', 'i'), 'Hello Universe';

is_deeply $data->replace(qr/world/i, 'Universe'), 'Hello Universe';

is_deeply $data->replace(qr/.*/, 'Nada'), 'Nada';

ok 1 and done_testing;
