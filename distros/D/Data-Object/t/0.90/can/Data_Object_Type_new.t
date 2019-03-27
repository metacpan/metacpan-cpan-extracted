use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $data = Data::Object::Type->new();

=description

Construct a new object.

=signature

new() : Object

=type

method

=cut

# TESTING

use Data::Object::Type;

can_ok "Data::Object::Type", "new";

my $data;

# instantiate
$data = Data::Object::Type->new();
isa_ok $data, 'Data::Object::Type';

ok 1 and done_testing;
