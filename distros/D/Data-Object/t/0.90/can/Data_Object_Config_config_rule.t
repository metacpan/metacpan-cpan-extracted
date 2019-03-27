use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_rule

=usage

  my $plans = config_rule;

=description

The config_rule function returns plans for configuring a package to be a
L<Data::Object::Rule>.

=signature

config_rule() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_rule';

my $config = Data::Object::Config::config_rule();

is_deeply $config->[0], ['use', 'Data::Object::Rule'];
is_deeply $config->[1], ['use', 'Data::Object::RoleHas'];

ok 1 and done_testing;
