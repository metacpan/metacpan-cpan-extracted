use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given abcedfghi

  my $string = Data::Object::String->new('abcedfghi');

=description

The new method expects a string and returns a new class instance.

=signature

new(Str $arg1) : DoStr

=type

method

=cut

# TESTING

use Data::Object::String;

can_ok "Data::Object::String", "new";

my $data;

# instantiate
$data = Data::Object::String->new("hello world");
isa_ok $data, 'Data::Object::String';

# instantiate with object
$data = Data::Object::String->new($data);
isa_ok $data, 'Data::Object::String';

# no instantiation error
ok !Data::Object::String->new;

ok 1 and done_testing;
