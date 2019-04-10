use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given abcedfghi

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

=description

The new method expects a string and returns a new class instance.

=signature

new(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::String;
use Data::Object::Base::String;

can_ok "Data::Object::Base::String", "new";

my $data;

# instantiate
$data = Data::Object::String->new("hello world");
isa_ok $data, 'Data::Object::Base::String';

# instantiate with object
$data = Data::Object::Base::String->new($data);
isa_ok $data, 'Data::Object::Base::String';

# no instantiation error
ok !${Data::Object::Base::String->new};

ok 1 and done_testing;
