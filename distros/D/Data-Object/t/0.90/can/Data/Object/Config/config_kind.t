use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_kind

=usage

  my $plans = config_kind;

=description

The config_kind function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Kind>.

=signature

config_kind() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_kind';

my $config = Data::Object::Config::config_kind();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Kind'];

ok 1 and done_testing;
