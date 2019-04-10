use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given undef

  package My::Undef;

  use parent 'Data::Object::Base::Undef';

  my $undef = My::Undef->new(undef);

=description

The new method expects an undefined value and returns a new class instance.

=signature

new(Undef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Undef;
use Data::Object::Base::Undef;

can_ok "Data::Object::Base::Undef", "new";

my $data;

# instantiate
$data = Data::Object::Undef->new(undef);
isa_ok $data, 'Data::Object::Base::Undef';

# instantiate with object
$data = Data::Object::Base::Undef->new($data);
isa_ok $data, 'Data::Object::Base::Undef';

# no instantiation error
ok !${Data::Object::Base::Undef->new};

ok 1 and done_testing;
