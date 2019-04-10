use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

roles

=usage

  # given $string

  $string->roles;

=description

The roles method returns the list of roles attached to object. This method
returns an array value.

=signature

roles() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello');

my $roles = $data->roles();

is_deeply $roles->[0], 'Data::Object::Role::Detract';

is_deeply $roles->[1], 'Data::Object::Role::Dumper';

is_deeply $roles->[2], 'Data::Object::Role::Output';

is_deeply $roles->[3], 'Data::Object::Role::Throwable';

ok 1 and done_testing;
