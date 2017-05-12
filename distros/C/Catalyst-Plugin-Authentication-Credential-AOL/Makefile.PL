use inc::Module::Install;
name 'Catalyst-Plugin-Authentication-Credential-AOL';
all_from 'lib/Catalyst/Plugin/Authentication/Credential/AOL.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
