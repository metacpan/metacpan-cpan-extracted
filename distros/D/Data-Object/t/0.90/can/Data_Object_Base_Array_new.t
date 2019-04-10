use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  package My::Array;

  use parent 'Data::Object::Base::Array';

  # given 1..9

  my $array = My::Array->new([1..9]);

=description

The new method expects a list or array reference and returns a new class
instance.

=signature

new(ArrayRef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Array;
use Data::Object::Base::Array;

can_ok "Data::Object::Base::Array", "new";

my $data;

# instantiate
$data = Data::Object::Array->new([1..4]);
isa_ok $data, 'Data::Object::Base::Array';

# instantiate with object
$data = Data::Object::Base::Array->new($data);
isa_ok $data, 'Data::Object::Base::Array';

# instantiation error
ok !eval{Data::Object::Base::Array->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
