use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given qr(something to match against)

  my $re = Data::Object::Regexp->new(qr(something to match against));

=description

The new method expects a regular-expression object and returns a new class
instance.

=signature

new(RegexpRef $arg1) : DoRegexp

=type

method

=cut

# TESTING

use Data::Object::Regexp;

can_ok "Data::Object::Regexp", "new";

my $data;

# instantiate
$data = Data::Object::Regexp->new(qr/test/);
isa_ok $data, 'Data::Object::Regexp';

# instantiate with object
$data = Data::Object::Regexp->new($data);
isa_ok $data, 'Data::Object::Regexp';

# instantiation error
ok !eval{Data::Object::Regexp->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
