use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_state

=usage

  my $plans = config_state;

=description

The config_state function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::State>.

=signature

config_state() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_state';

my $config = Data::Object::Config::config_state();

is_deeply $config->[0], ['use', 'Data::Object::State'];
is_deeply $config->[1], ['use', 'Data::Object::Config::Class', {replace=>1}, 'has'];

ok 1 and done_testing;
