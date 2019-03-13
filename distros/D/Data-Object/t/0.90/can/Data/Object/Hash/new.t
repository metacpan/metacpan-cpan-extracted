use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 1..4

  my $hash = Data::Object::Hash->new(1..4);
  my $hash = Data::Object::Hash->new({1..4});

=description

The new method expects a list or hash reference and returns a new class
instance.

=signature

new(HashRef $arg1) : DoHash

=type

method

=cut

# TESTING

use Data::Object::Hash;

can_ok "Data::Object::Hash", "new";

my $data;

# instantiate
$data = Data::Object::Hash->new({1..4});
isa_ok $data, 'Data::Object::Hash';

# instantiate with object
$data = Data::Object::Hash->new($data);
isa_ok $data, 'Data::Object::Hash';

# instantiation error
ok !eval{Data::Object::Hash->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
