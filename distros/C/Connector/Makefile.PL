use inc::Module::Install;

name     'Connector';
all_from 'lib/Connector.pm';
#license  'perl';

requires   'Moose';
requires    'Log::Log4perl';

recommends 'Config::Versioned' => '0.5';
recommends 'Config::Std';
recommends 'Net::LDAP';
recommends 'Net::SSL';
recommends 'YAML';

recommends 'Text::CSV_XS';

recommends 'Template';
recommends 'Proc::SafeExec';
recommends 'DBI';

build_requires 'Test::More';

test_requires 'Test::More';
test_requires 'Config::Versioned';
test_requires 'Config::Std';
test_requires 'YAML';
test_requires 'Template';
test_requires 'DBI';
test_requires 'DBD::SQLite';
test_requires 'Net::SSL';

auto_install;

WriteAll;

