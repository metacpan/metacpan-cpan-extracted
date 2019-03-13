use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

roles

=usage

  # given $number

  $number->roles;

=description

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=signature

roles() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12345);

my $roles = $data->roles();

is $roles->[0], 'Data::Object::Role::Detract';

is $roles->[1], 'Data::Object::Role::Dumper';

is $roles->[2], 'Data::Object::Role::Output';

is $roles->[3], 'Data::Object::Role::Throwable';

is $roles->[4], 'Data::Object::Role::Type';

ok 1 and done_testing;
