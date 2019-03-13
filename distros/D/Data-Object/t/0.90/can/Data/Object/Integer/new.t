use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 9

  my $integer = Data::Object::Integer->new(9);

=description

The new method expects a number and returns a new class instance.

=signature

new(Int $arg1) : DoInt

=type

method

=cut

# TESTING

use Data::Object::Integer;

can_ok "Data::Object::Integer", "new";

my $data;

# instantiate
$data = Data::Object::Integer->new(-100);
isa_ok $data, 'Data::Object::Integer';

# instantiate with object
$data = Data::Object::Integer->new($data);
isa_ok $data, 'Data::Object::Integer';

# instantiation error
ok !eval{Data::Object::Integer->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
