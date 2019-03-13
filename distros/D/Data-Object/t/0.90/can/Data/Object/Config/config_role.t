use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_role

=usage

  my $plans = config_role;

=description

The config_role function returns plans for configuring the package to be a
L<Data::Object::Role>.

=signature

config_role() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_role';

my $config = Data::Object::Config::config_role();

is_deeply $config->[0], ['use', 'Data::Object::Role'];
is_deeply $config->[1], ['use', 'Data::Object::Config::Role', {replace=>1}, 'has'];

ok 1 and done_testing;
