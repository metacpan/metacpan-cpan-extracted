use inc::Module::Install;
name 'Catalyst-Plugin-Authentication-Credential-Livedoor';
all_from 'lib/Catalyst/Plugin/Authentication/Credential/Livedoor.pm';

build_requires 'Test::More';
requires 'Catalyst' => '5.700';
requires 'WebService::Livedoor::Auth' => '0.01';

use_test_base;
auto_include;
WriteAll;
