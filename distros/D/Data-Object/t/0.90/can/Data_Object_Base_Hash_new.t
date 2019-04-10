use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 1..4

  package My::Hash;

  use parent 'Data::Object::Base::Hash';

  my $hash = My::Hash->new({1..4});

=description

The new method expects a list or hash reference and returns a new class
instance.

=signature

new(HashRef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Hash;
use Data::Object::Base::Hash;

can_ok "Data::Object::Base::Hash", "new";

my $data;

# instantiate
$data = Data::Object::Hash->new({1..4});
isa_ok $data, 'Data::Object::Base::Hash';

# instantiate with object
$data = Data::Object::Base::Hash->new($data);
isa_ok $data, 'Data::Object::Base::Hash';

# instantiation error
ok !eval{Data::Object::Base::Hash->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
