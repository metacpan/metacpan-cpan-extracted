use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 1_000_000

  package My::Number;

  use parent 'Data::Object::Base::Number';

  my $number = My::Number->new(1_000_000);

=description

The new method expects a number and returns a new class instance.

=signature

new(Int $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Number;
use Data::Object::Base::Number;

can_ok "Data::Object::Base::Number", "new";

my $data;

# instantiate
$data = Data::Object::Number->new(100);
isa_ok $data, 'Data::Object::Base::Number';

# instantiate with object
$data = Data::Object::Base::Number->new($data);
isa_ok $data, 'Data::Object::Base::Number';

# instantiation error
ok !eval{Data::Object::Base::Number->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
