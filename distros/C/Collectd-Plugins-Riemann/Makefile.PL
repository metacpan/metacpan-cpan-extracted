use inc::Module::Install;

name     'Collectd-Plugins-Riemann';
all_from 'lib/Collectd/Plugins/Riemann.pm';
author   q{Fabien Wernli <wernli@in2p3.fr>};
license  'CeCILL';

# this is somehow needed for EU::MM
configure_requires 'version' => '0.88';

test_requires 'Test::More';
test_requires 'Test::MockModule';
test_requires 'Test::Collectd::Plugins' => '0.1007';

requires 'Collectd::Plugins::Common';
requires 'Riemann::Client';

# these are indirectly needed
requires 'IPC::Cmd';
requires 'Socket';

install_share qw(share);

# auto_install;

WriteAll;

