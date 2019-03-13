use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_regexp

=usage

  my $plans = config_regexp;

=description

The config_regexp function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Regexp>.

=signature

config_regexp() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_regexp';

my $config = Data::Object::Config::config_regexp();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Regexp'];

ok 1 and done_testing;
