use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_replace

=usage

  my $plans = config_replace;

=description

The config_replace function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Replace>.

=signature

config_replace() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_replace';

my $config = Data::Object::Config::config_replace();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Replace'];

ok 1 and done_testing;
