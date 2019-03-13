use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_cli

=usage

  my $plans = config_cli;

=description

The config_cli function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Cli>.

=signature

config_cli() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_cli';

my $config = Data::Object::Config::config_cli();

is_deeply $config->[0], ['use', 'Data::Object::Class'];
is_deeply $config->[1], ['use', 'Data::Object::Config::Class', {replace=>1}, 'has'];
is_deeply $config->[2], ['call', 'extends', 'Data::Object::Cli'];

ok 1 and done_testing;
