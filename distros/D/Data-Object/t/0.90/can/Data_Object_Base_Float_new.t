use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 9.9999

  package My::Float;

  use parent 'Data::Object::Base::Float';

  my $float = My::Float->new(9.9999);

=description

The new method expects a floating-point number and returns a new class instance.

=signature

new(Num $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Float;
use Data::Object::Base::Float;

can_ok "Data::Object::Base::Float", "new";

my $data;

# instantiate
$data = Data::Object::Float->new(5.25);
isa_ok $data, 'Data::Object::Base::Float';

# instantiate with object
$data = Data::Object::Base::Float->new($data);
isa_ok $data, 'Data::Object::Base::Float';

# instantiation error
ok !eval{Data::Object::Base::Float->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
