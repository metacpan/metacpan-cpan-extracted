use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_scalar

=usage

  my $plans = config_scalar;

=description

The config_scalar function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Scalar>.

=signature

config_scalar() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_scalar';

my $config = Data::Object::Config::config_scalar();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Scalar'];

ok 1 and done_testing;
