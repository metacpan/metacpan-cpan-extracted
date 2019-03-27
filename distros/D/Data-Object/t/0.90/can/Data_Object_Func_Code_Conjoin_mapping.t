use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

mapping

=usage

  my @data = $self->mapping;

=description

Returns the ordered list of named function object arguments.

=signature

mapping() : (Str)

=type

method

=cut

# TESTING

use Data::Object::Func::Code::Conjoin;

can_ok "Data::Object::Func::Code::Conjoin", "mapping";

my @data;

@data = Data::Object::Func::Code::Conjoin->mapping();

is @data, 2;

is $data[0], 'arg1';
is $data[1], 'arg2';

ok 1 and done_testing;
