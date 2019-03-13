use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $data = Data::Object::Dispatch->new("Data::Object::Export");

=description

Construct a new object.

=signature

new(ClassName $arg1, Any @args) : Object

=type

method

=cut

# TESTING

use Data::Object::Dispatch;

can_ok "Data::Object::Dispatch", "new";

my $data;

# instantiate
$data = Data::Object::Dispatch->new("Data::Object::Export");
isa_ok $data, 'Data::Object::Dispatch';

ok 1 and done_testing;
