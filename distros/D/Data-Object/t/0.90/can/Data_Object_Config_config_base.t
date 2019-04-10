use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_base

=usage

  my $plans = config_base;

=description

The config_base function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Base>.

=signature

config_base() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_base';

my $config = Data::Object::Config::config_base();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Base'];

ok 1 and done_testing;
