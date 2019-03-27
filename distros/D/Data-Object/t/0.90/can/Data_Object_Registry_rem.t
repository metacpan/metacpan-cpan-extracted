use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rem

=usage

  my $rem = $registry->rem($key, $val);

=description

Remove the registered type library from a given namespace.

=signature

rem(Str $arg1, Str $arg2) : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->rem(), undef;

ok 1 and done_testing;
