use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_integer

=usage

  my $plans = config_integer;

=description

The config_integer function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Integer>.

=signature

config_integer() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_integer';

my $config = Data::Object::Config::config_integer();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Integer'];

ok 1 and done_testing;
