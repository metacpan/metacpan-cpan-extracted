use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_search

=usage

  my $plans = config_search;

=description

The config_search function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Search>.

=signature

config_search() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_search';

my $config = Data::Object::Config::config_search();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Search'];

ok 1 and done_testing;
