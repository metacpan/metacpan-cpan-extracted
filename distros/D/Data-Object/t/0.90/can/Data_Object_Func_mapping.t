use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

mapping

=usage

  my @data = $func->mapping;

=description

Returns the ordered list of named function object arguments.

=signature

mapping() : (Str)

=type

method

=cut

# TESTING

use Data::Object::Func;

can_ok "Data::Object::Func", "mapping";

my @data;

@data = Data::Object::Func->mapping();

is @data, 0;

ok 1 and done_testing;
