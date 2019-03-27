use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_float

=usage

  my $plans = config_float;

=description

The config_float function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Float>.

=signature

config_float() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_float';

my $config = Data::Object::Config::config_float();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Float'];

ok 1 and done_testing;
