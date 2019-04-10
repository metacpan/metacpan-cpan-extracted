use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given qr(something to match against)

  package My::Regexp;

  use parent 'Data::Object::Base::Regexp';

  my $re = My::Regexp->new(qr(something to match against));

=description

The new method expects a regular-expression object and returns a new class
instance.

=signature

new(RegexpRef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Regexp;
use Data::Object::Base::Regexp;

can_ok "Data::Object::Base::Regexp", "new";

my $data;

# instantiate
$data = Data::Object::Regexp->new(qr/test/);
isa_ok $data, 'Data::Object::Base::Regexp';

# instantiate with object
$data = Data::Object::Base::Regexp->new($data);
isa_ok $data, 'Data::Object::Base::Regexp';

# instantiation error
ok !eval{Data::Object::Base::Regexp->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
