use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $any = Data::Object::Any->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : DoAny

=type

method

=cut

# TESTING

use Data::Object::Any;

can_ok "Data::Object::Any", "new";

my $data;

# instantiate
$data = Data::Object::Any->new(sub {1});
isa_ok $data, 'Data::Object::Any';

# instantiate with object
$data = Data::Object::Any->new($data);
isa_ok $data, 'Data::Object::Any';

# no instantiation error
ok eval { Data::Object::Any->new; 1 } && !$@;

ok 1 and done_testing;
