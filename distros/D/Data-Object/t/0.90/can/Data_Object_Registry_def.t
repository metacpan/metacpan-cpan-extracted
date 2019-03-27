use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

def

=usage

  my $def = $registry->def();

=description

Returns the default type library.

=signature

def() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->def(), 'Data::Object::Library';

ok 1 and done_testing;
