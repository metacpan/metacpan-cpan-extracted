use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_dispatch

=usage

  my $plans = config_dispatch;

=description

The config_dispatch function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Dispatch>.

=signature

config_dispatch() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_dispatch';

my $config = Data::Object::Config::config_dispatch();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Dispatch'];

ok 1 and done_testing;
