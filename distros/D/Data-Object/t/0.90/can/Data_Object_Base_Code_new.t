use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given sub { shift + 1 }

  my $code = Data::Object::Base::Code->new(sub { shift + 1 });

=description

The new method expects a code reference and returns a new class instance.

=signature

new(CodeRef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Code;
use Data::Object::Base::Code;

can_ok "Data::Object::Base::Code", "new";

my $data;

# instantiate
$data = Data::Object::Code->new(sub {1});
isa_ok $data, 'Data::Object::Base::Code';

# instantiate with object
$data = Data::Object::Base::Code->new($data);
isa_ok $data, 'Data::Object::Base::Code';

# instantiation error
ok !eval{Data::Object::Base::Code->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
