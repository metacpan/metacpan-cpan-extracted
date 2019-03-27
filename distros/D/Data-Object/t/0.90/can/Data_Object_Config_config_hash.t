use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_hash

=usage

  my $plans = config_hash;

=description

The config_hash function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Hash>.

=signature

config_hash() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_hash';

my $config = Data::Object::Config::config_hash();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Hash'];

ok 1 and done_testing;
