use inc::Module::Install;

name     'Connector';
all_from 'lib/Connector.pm';
#license  'perl';
repository 'https://github.com/mrscotty/connector';
bugtracker 'https://github.com/mrscotty/connector/issues';

requires   'Moose';
requires    'Log::Log4perl';

recommends 'Config::Versioned' => '0.5';
recommends 'Config::Std';
recommends 'Net::LDAP';
recommends 'YAML';

recommends 'Text::CSV_XS';

recommends 'Template';
recommends 'Proc::SafeExec';
recommends 'DBI';
recommends 'IO::Socket::SSL';
recommends 'LWP::Protocol::https';
recommends 'LWP::UserAgent';
recommends 'JSON';

build_requires 'Test::More';

test_requires 'Test::More';
test_requires 'Config::Merge';
test_requires 'Config::Versioned';
test_requires 'Config::Std';
test_requires 'Proc::SafeExec';
test_requires 'YAML';
test_requires 'Template';
test_requires 'DBI';
test_requires 'DBD::SQLite';
test_requires 'IO::Socket::SSL';
test_requires 'LWP::UserAgent';
test_requires 'LWP::Protocol::https';
test_requires 'JSON';

auto_install;

WriteAll;

