use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_array

=usage

  my $plans = config_array;

=description

The config_array function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Array>.

=signature

config_array() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_array';

my $config = Data::Object::Config::config_array();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Array'];

ok 1 and done_testing;
