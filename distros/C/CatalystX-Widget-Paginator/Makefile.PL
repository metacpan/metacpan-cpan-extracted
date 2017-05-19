use inc::Module::Install;

name      'CatalystX-Widget-Paginator';
license   'perl';
all_from  'lib/CatalystX/Widget/Paginator.pm';

requires  'Catalyst::Plugin::Widget' => 0.03;

test_requires 'Catalyst::Model::DBIC::Schema';
test_requires 'Catalyst::Test';
test_requires 'DBD::SQLite';
test_requires 'DBI';
test_requires 'Test::More';

auto_install;

WriteAll;

